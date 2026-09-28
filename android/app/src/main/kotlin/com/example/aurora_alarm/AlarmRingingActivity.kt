package com.example.aurora_alarm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Native Full-Screen Activity prepared to display over Android's lock screen when an alarm rings.
 * Serves as the base foundation for the native ringing experience in the hybrid architecture.
 */
class AlarmRingingActivity : Activity() {

    companion object {
        private const val TAG = "AlarmRingingActivity"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmId: Int = 1
    private var title: String = "Aurora Alarme"
    private var sound: String = "dan-da-dan"
    private var vibrate: Boolean = true
    private var mission: String = "none"
    private var snoozeMinutes: Int = 5

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeAndShowOverLockscreen()
        parseIntent(intent)
        setupPreparedUi()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeAndShowOverLockscreen()
        parseIntent(intent)
    }

    private fun parseIntent(intent: Intent?) {
        if (intent == null) return
        alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, 1)
        title = intent.getStringExtra(AlarmScheduler.EXTRA_TITLE) ?: "Aurora Alarme"
        sound = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND) ?: "dan-da-dan"
        vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)
        mission = intent.getStringExtra(AlarmScheduler.EXTRA_MISSION) ?: "none"
        snoozeMinutes = intent.getIntExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, 5)
        Log.d(TAG, "Parsed alarm intent: id=$alarmId, title='$title', sound='$sound', mission='$mission'")
    }

    private fun wakeAndShowOverLockscreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            @Suppress("DEPRECATION")
            wakeLock = pm?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "aurora_alarm:AlarmRingingWakeLock"
            )?.apply {
                setReferenceCounted(false)
                acquire(10 * 60 * 1000L /* 10 minutes */)
            }
            Log.d(TAG, "Acquired screen WakeLock in AlarmRingingActivity")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock: ${e.message}")
        }
    }

    private fun setupPreparedUi() {
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#07080F"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setPadding(48, 48, 48, 48)
        }

        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val timeView = TextView(this).apply {
            text = timeFormat.format(Date())
            textSize = 64f
            setTextColor(Color.parseColor("#00E5FF"))
            gravity = Gravity.CENTER
        }

        val titleView = TextView(this).apply {
            text = title
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 48)
        }

        val buttonsLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val snoozeBtn = Button(this).apply {
            text = "Soneca (+${snoozeMinutes}m)"
            setBackgroundColor(Color.parseColor("#2A1B4E"))
            setTextColor(Color.parseColor("#E0AAFF"))
            setPadding(32, 16, 32, 16)
            setOnClickListener { handleSnooze() }
        }

        val dismissBtn = Button(this).apply {
            text = if (mission != "none") "Desafio ($mission)" else "Desligar"
            setBackgroundColor(Color.parseColor("#E6007A"))
            setTextColor(Color.WHITE)
            setPadding(32, 16, 32, 16)
            setOnClickListener { handleDismiss() }
        }

        val space = TextView(this).apply {
            width = 32
        }

        buttonsLayout.addView(snoozeBtn)
        buttonsLayout.addView(space)
        buttonsLayout.addView(dismissBtn)

        rootLayout.addView(timeView)
        rootLayout.addView(titleView)
        rootLayout.addView(buttonsLayout)

        setContentView(rootLayout)
    }

    private fun handleDismiss() {
        Log.d(TAG, "handleDismiss called for alarm #$alarmId")
        if (mission != "none") {
            // Forward to Flutter MainActivity for challenge completion
            val challengeIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("payload", alarmId.toString())
                putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            }
            startActivity(challengeIntent)
        }
        finish()
    }

    private fun handleSnooze() {
        Log.d(TAG, "handleSnooze called for alarm #$alarmId")
        val scheduler = AlarmScheduler(this)
        val snoozeTime = System.currentTimeMillis() + (snoozeMinutes * 60 * 1000L)
        scheduler.scheduleAlarm(
            id = alarmId,
            triggerTimeMillis = snoozeTime,
            title = title,
            sound = sound,
            vibrate = vibrate,
            mission = mission,
            snoozeMinutes = snoozeMinutes
        )
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Prevent accidental dismissal via back gesture
    }

    override fun onDestroy() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wakeLock: ${e.message}")
        }
        super.onDestroy()
    }
}
