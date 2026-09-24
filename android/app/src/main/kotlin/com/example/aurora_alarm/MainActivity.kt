package com.example.aurora_alarm

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "aurora_alarm/screen_control"
    private var methodChannel: MethodChannel? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var latestAlarmPayload: String? = null

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeAndShowOverLockscreen()
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeAndShowOverLockscreen()
        handleIncomingIntent(intent)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        wakeAndShowOverLockscreen()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "wakeUpScreen" -> {
                        wakeAndShowOverLockscreen()
                        result.success(true)
                    }
                    "dismissLockscreen" -> {
                        dismissLockscreen()
                        result.success(true)
                    }
                    "getInitialAlarmPayload" -> {
                        val payload = latestAlarmPayload
                        latestAlarmPayload = null
                        result.success(payload)
                    }
                    "canUseFullScreenIntent" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            result.success(nm?.canUseFullScreenIntent() ?: true)
                        } else {
                            result.success(true)
                        }
                    }
                    "openFullScreenIntentSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error opening full-screen intent settings: ${e.message}")
                                result.success(false)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "canDrawOverlays" -> {
                        result.success(Settings.canDrawOverlays(this@MainActivity))
                    }
                    "openOverlaySettings" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error opening overlay settings: ${e.message}")
                            result.success(false)
                        }
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnored = pm?.isIgnoringBatteryOptimizations(packageName) ?: true
                        result.success(isIgnored)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error requesting battery optimizations ignore: ${e.message}")
                            result.success(false)
                        }
                    }
                    "launchAlarmFullScreen" -> {
                        val payload = call.argument<String>("payload")
                        val alarmId = call.argument<Int>("alarmId")
                        launchAlarmFullScreen(payload, alarmId)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // If an intent arrived before Flutter engine finished configuring, dispatch it now
        latestAlarmPayload?.let { payload ->
            methodChannel?.invokeMethod("onAlarmTriggered", payload)
        }
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val payload = intent.getStringExtra("payload")
            ?: intent.getStringExtra("notification_payload")
            ?: if (intent.hasExtra("alarm_id")) intent.getIntExtra("alarm_id", 0).toString()
            else if (intent.hasExtra("notification_id")) intent.getIntExtra("notification_id", 0).toString()
            else null

        if (payload != null && payload.isNotEmpty()) {
            latestAlarmPayload = payload
            methodChannel?.invokeMethod("onAlarmTriggered", payload)
        }
    }

    private fun wakeAndShowOverLockscreen() {
        // 1. API 27+ (Android 8.1+) ShowWhenLocked & TurnScreenOn
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        // 2. WindowManager flags for all Android versions (Oreo, 10, 11, 12, 13, 14, 15)
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // 3. Hardware PowerManager WakeLock with ACQUIRE_CAUSES_WAKEUP (powers on display from deep sleep)
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (powerManager != null && wakeLock?.isHeld != true) {
                @Suppress("DEPRECATION")
                wakeLock = powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                    "AuroraAlarm:ScreenWakeLock"
                ).apply {
                    setReferenceCounted(false)
                    acquire(10 * 60 * 1000L /* 10 minutes */)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }

        // 4. Request Keyguard dismissal for swipe/non-secure lock screens
        try {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                keyguardManager?.requestDismissKeyguard(this, null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request dismiss keyguard: ${e.message}")
        }
    }

    private fun dismissLockscreen() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock: ${e.message}")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun launchAlarmFullScreen(payload: String?, alarmId: Int?) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = "com.aurora.alarm.RING"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("payload", payload ?: (alarmId?.toString() ?: "1"))
            if (alarmId != null) putExtra("alarm_id", alarmId)
        }
        try {
            startActivity(launchIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch alarm full screen: ${e.message}")
        }
    }

    override fun onDestroy() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock on destroy: ${e.message}")
        }
        super.onDestroy()
    }
}
