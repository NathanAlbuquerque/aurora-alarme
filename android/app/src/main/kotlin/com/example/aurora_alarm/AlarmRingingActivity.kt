package com.example.aurora_alarm

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Fully native Full-Screen Alarm Activity designed to wake the device and display
 * directly over Android's lock screen without requiring user credentials/PIN.
 *
 * Implements high-priority alarm audio playback in loop, rhythmic vibration,
 * live clock updates, and communication back to Flutter via NativeAlarmBridge.
 */
class AlarmRingingActivity : Activity() {

    companion object {
        private const val TAG = "AlarmRingingActivity"
        private const val SNOOZE_DURATION_MINUTES = 10

        private var activeActivityRef: WeakReference<AlarmRingingActivity>? = null

        fun finishIfActive(targetAlarmId: Int? = null) {
            val activity = activeActivityRef?.get()
            if (activity != null && (targetAlarmId == null || activity.alarmId == targetAlarmId)) {
                Log.d(TAG, "finishIfActive: closing active AlarmRingingActivity for alarm #$targetAlarmId")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    activity.finishAndRemoveTask()
                } else {
                    activity.finish()
                }
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    private var alarmId: Int = 1
    private var title: String = "Aurora Alarme"
    private var sound: String = "dan-da-dan"
    private var vibrate: Boolean = true
    private var mission: String = "none"
    private var snoozeMinutes: Int = 10

    private lateinit var tvClock: TextView
    private lateinit var tvDate: TextView
    private lateinit var tvTitle: TextView
    private lateinit var btnSnooze: Button
    private lateinit var btnDismiss: Button

    private val timeHandler = Handler(Looper.getMainLooper())
    private val clockRunnable = object : Runnable {
        override fun run() {
            updateClockUi()
            timeHandler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activeActivityRef = WeakReference(this)

        // 1. Wake physical display and enable over-lockscreen presentation
        wakeAndShowOverLockscreen()

        // 2. Parse alarm configuration from intent extras
        parseAlarmIntent(intent)

        // 3. Set modern Aurora-themed XML layout
        setContentView(R.layout.activity_alarm_ringing)
        initViews()

        // 4. Start live clock updates
        timeHandler.post(clockRunnable)

        // 5. Ensure native audio & vibration loop is playing
        NativeAlarmSoundPlayer.start(
            context = this,
            alarmId = alarmId,
            soundName = sound,
            vibrate = vibrate
        )

        Log.d(TAG, "AlarmRingingActivity created and active for alarm #$alarmId ('$title')")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeAndShowOverLockscreen()
        parseAlarmIntent(intent)
        updateAlarmUi()

        NativeAlarmSoundPlayer.start(
            context = this,
            alarmId = alarmId,
            soundName = sound,
            vibrate = vibrate
        )
    }

    private fun parseAlarmIntent(intent: Intent?) {
        if (intent == null) return
        alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, 1)
        title = intent.getStringExtra(AlarmScheduler.EXTRA_TITLE) ?: "Aurora Alarme"
        sound = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND) ?: "dan-da-dan"
        vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)
        mission = intent.getStringExtra(AlarmScheduler.EXTRA_MISSION) ?: "none"
        snoozeMinutes = intent.getIntExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, SNOOZE_DURATION_MINUTES)
    }

    private fun initViews() {
        tvClock = findViewById(R.id.tvClock)
        tvDate = findViewById(R.id.tvDate)
        tvTitle = findViewById(R.id.tvTitle)
        btnSnooze = findViewById(R.id.btnSnooze)
        btnDismiss = findViewById(R.id.btnDismiss)

        updateAlarmUi()

        btnDismiss.setOnClickListener {
            handleDismiss()
        }

        btnSnooze.setOnClickListener {
            handleSnooze()
        }
    }

    private fun updateAlarmUi() {
        tvTitle.text = title
        btnSnooze.text = "Soneca (+${snoozeMinutes}m)"
        btnDismiss.text = if (mission != "none") "DESAFIAR ($mission)" else "DESLIGAR"
        updateClockUi()
    }

    private fun updateClockUi() {
        val now = Date()
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        tvClock.text = timeFormat.format(now)

        val dateFormat = SimpleDateFormat("EEEE, d 'de' MMMM", Locale("pt", "BR"))
        val dateFormatted = dateFormat.format(now)
        tvDate.text = dateFormatted.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }

    /**
     * Powers on the display and unlocks window drawing over the lock screen.
     * Note: We intentionally avoid requestDismissKeyguard to never demand PIN/credentials.
     */
    private fun wakeAndShowOverLockscreen() {
        // API 27+ (Android 8.1+) native lockscreen display
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        // WindowManager flags for comprehensive compatibility
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // Acquire hardware WakeLock to awaken the display from deep sleep
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            @Suppress("DEPRECATION")
            wakeLock = pm?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "aurora_alarm:AlarmRingingActivityWakeLock"
            )?.apply {
                setReferenceCounted(false)
                acquire(10 * 60 * 1000L /* 10 minutes */)
            }
            Log.d(TAG, "Screen WakeLock acquired successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock: ${e.message}")
        }
    }

    /**
     * Handles the "Desligar" action:
     * - Stops audio and vibration
     * - Clears notification
     * - Notifies Flutter via NativeAlarmBridge
     * - If mission is active, opens MainActivity for the challenge
     * - Closes the Activity
     */
    private fun handleDismiss() {
        Log.d(TAG, "Alarm #$alarmId dismissed by user on screen")
        NativeAlarmSoundPlayer.stop()

        // 1. Cancel fallback notification
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(alarmId)
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling notification: ${e.message}")
        }

        // 2. Mark alarm as dismissed in shared preferences for Flutter offline sync
        try {
            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("flutter.dismissed_alarm_$alarmId", true)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error marking alarm dismissed in prefs: ${e.message}")
        }

        // 3. Notify Flutter via NativeAlarmBridge
        NativeAlarmBridge.notifyAlarmDismissed(alarmId)

        // 3. If challenge is required, route to Flutter UI
        if (mission != "none") {
            val challengeIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("payload", "challenge:$alarmId")
                putExtra("challenge_mission", mission)
                putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            }
            startActivity(challengeIntent)
        }

        // 4. Close native activity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    /**
     * Handles the "Soneca" action:
     * - Stops audio and vibration
     * - Clears notification
     * - Schedules the snooze alarm natively for +snoozeMinutes
     * - Notifies Flutter via NativeAlarmBridge
     * - Closes the Activity
     */
    private fun handleSnooze() {
        Log.d(TAG, "Alarm #$alarmId snoozed (+${snoozeMinutes}m) by user on screen")
        NativeAlarmSoundPlayer.stop()

        // 1. Cancel active notification
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(alarmId)
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling notification: ${e.message}")
        }

        // 2. Schedule exact native snooze alarm
        val snoozeTimeMillis = System.currentTimeMillis() + (snoozeMinutes * 60 * 1000L)
        val scheduler = AlarmScheduler(this)
        scheduler.scheduleAlarm(
            id = alarmId,
            triggerTimeMillis = snoozeTimeMillis,
            title = title,
            sound = sound,
            vibrate = vibrate,
            mission = mission,
            snoozeMinutes = snoozeMinutes
        )

        // 3. Notify Flutter via NativeAlarmBridge
        NativeAlarmBridge.notifyAlarmSnoozed(alarmId, snoozeMinutes)

        // 4. Close native activity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Prevent accidental dismissal of the alarm via back gesture
    }

    override fun onDestroy() {
        timeHandler.removeCallbacks(clockRunnable)
        if (activeActivityRef?.get() == this) {
            activeActivityRef = null
        }

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock in onDestroy: ${e.message}")
        }

        super.onDestroy()
    }
}
