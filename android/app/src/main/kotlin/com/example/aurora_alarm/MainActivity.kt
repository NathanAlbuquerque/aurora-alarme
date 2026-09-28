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
    private val NATIVE_CHANNEL = "aurora_alarm/native"
    private var methodChannel: MethodChannel? = null
    private var nativeMethodChannel: MethodChannel? = null
    private var alarmScheduler: AlarmScheduler? = null
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

    override fun onStart() {
        super.onStart()
        wakeAndShowOverLockscreen()
    }

    override fun onResume() {
        super.onResume()
        wakeAndShowOverLockscreen()
        latestAlarmPayload?.let { payload ->
            Log.d(TAG, "onResume: dispatching pending latestAlarmPayload='$payload'")
            methodChannel?.invokeMethod("onAlarmTriggered", payload)
        }
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

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            wakeAndShowOverLockscreen()
        }
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
                    "clearAlarmPayload" -> {
                        latestAlarmPayload = null
                        intent?.removeExtra("payload")
                        intent?.removeExtra("notification_payload")
                        intent?.removeExtra("notificationPayload")
                        intent?.removeExtra("alarm_id")
                        intent?.removeExtra("alarmId")
                        intent?.removeExtra("notification_id")
                        intent?.removeExtra("notificationId")
                        result.success(true)
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

        // Initialize Native AlarmScheduler and aurora_alarm/native MethodChannel
        alarmScheduler = AlarmScheduler(this)
        nativeMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val id = call.argument<Int>("id") ?: 1
                        val triggerTime = call.argument<Long>("triggerTimeMillis")
                            ?: (call.argument<Number>("triggerTime")?.toLong() ?: 0L)
                        val title = call.argument<String>("title")
                        val sound = call.argument<String>("sound")
                        val vibrate = call.argument<Boolean>("vibrate") ?: true
                        val mission = call.argument<String>("mission")
                        val snoozeMinutes = call.argument<Int>("snoozeMinutes") ?: 5

                        val success = alarmScheduler?.scheduleAlarm(
                            id = id,
                            triggerTimeMillis = triggerTime,
                            title = title,
                            sound = sound,
                            vibrate = vibrate,
                            mission = mission,
                            snoozeMinutes = snoozeMinutes
                        ) ?: false
                        result.success(success)
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id") ?: 1
                        val success = alarmScheduler?.cancelAlarm(id) ?: false
                        result.success(success)
                    }
                    "cancelAllAlarms" -> {
                        val ids = call.argument<List<Int>>("ids")
                        val success = alarmScheduler?.cancelAllAlarms(ids) ?: false
                        result.success(success)
                    }
                    "canScheduleExactAlarms" -> {
                        val canSchedule = alarmScheduler?.canScheduleExactAlarms() ?: true
                        result.success(canSchedule)
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error opening exact alarm settings: ${e.message}")
                                result.success(false)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Bridge NativeAlarmBridge events (dismiss/snooze from AlarmRingingActivity) to Flutter
        NativeAlarmBridge.setListener(object : NativeAlarmBridge.AlarmEventListener {
            override fun onAlarmDismissed(alarmId: Int) {
                nativeMethodChannel?.invokeMethod("onAlarmDismissed", mapOf("alarmId" to alarmId))
            }

            override fun onAlarmSnoozed(alarmId: Int, snoozeMinutes: Int) {
                nativeMethodChannel?.invokeMethod(
                    "onAlarmSnoozed",
                    mapOf("alarmId" to alarmId, "snoozeMinutes" to snoozeMinutes)
                )
            }
        })

        // If an intent arrived before Flutter engine finished configuring, dispatch it now
        latestAlarmPayload?.let { payload ->
            Log.d(TAG, "configureFlutterEngine: dispatching latestAlarmPayload='$payload'")
            methodChannel?.invokeMethod("onAlarmTriggered", payload)
        }
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val payload = intent.getStringExtra("payload")
            ?: intent.getStringExtra("notification_payload")
            ?: intent.getStringExtra("notificationPayload")
            ?: if (intent.hasExtra("notificationId")) intent.getIntExtra("notificationId", 0).toString()
            else if (intent.hasExtra("notification_id")) intent.getIntExtra("notification_id", 0).toString()
            else if (intent.hasExtra("alarm_id")) intent.getIntExtra("alarm_id", 0).toString()
            else if (intent.hasExtra("alarmId")) intent.getIntExtra("alarmId", 0).toString()
            else null

        Log.d(TAG, "handleIncomingIntent: extracted payload='$payload', action=${intent.action}")

        if (!payload.isNullOrEmpty()) {
            latestAlarmPayload = payload
            methodChannel?.invokeMethod("onAlarmTriggered", payload)
        }
    }

    private fun wakeAndShowOverLockscreen() {
        Log.d(TAG, "wakeAndShowOverLockscreen() invoked")

        // 1. Android 8.1+ (API 27+) native lockscreen display and screen turn on
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

        // 3. Hardware WakeLock with ACQUIRE_CAUSES_WAKEUP to physically illuminate screen from deep sleep
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (powerManager != null) {
                if (wakeLock?.isHeld == true) {
                    try {
                        wakeLock?.release()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error releasing previous wakeLock: ${e.message}")
                    }
                }
                @Suppress("DEPRECATION")
                wakeLock = powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                    "aurora_alarm:screen_wake_lock"
                ).apply {
                    setReferenceCounted(false)
                    acquire(10 * 60 * 1000L /* 10 minutes */)
                }
                Log.d(TAG, "Acquired WakeLock with ACQUIRE_CAUSES_WAKEUP successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }

        // NOTE: We intentionally DO NOT call requestDismissKeyguard() here!
        // Calling requestDismissKeyguard() on a secured device prompts the user for PIN/Password/Fingerprint.
        // Alarm apps must render directly over the lockscreen with setShowWhenLocked(true)
        // without demanding user credentials until the user chooses to unlock.
    }

    private fun dismissLockscreen() {
        Log.d(TAG, "dismissLockscreen() invoked")
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
        wakeAndShowOverLockscreen()
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
        NativeAlarmBridge.setListener(null)
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
