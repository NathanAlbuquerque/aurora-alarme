package com.example.aurora_alarm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.io.File
import java.io.FileOutputStream
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
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    private var alarmId: Int = 1
    private var title: String = "Aurora Alarme"
    private var sound: String = "dan-da-dan"
    private var vibrate: Boolean = true
    private var mission: String = "none"

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

        // 1. Wake physical display and enable over-lockscreen presentation
        wakeAndShowOverLockscreen()

        // 2. Parse alarm configuration from intent extras
        parseAlarmIntent(intent)

        // 3. Set modern Aurora-themed XML layout
        setContentView(R.layout.activity_alarm_ringing)
        initViews()

        // 4. Start live clock updates
        timeHandler.post(clockRunnable)

        // 5. Start audio ringtone loop
        startAlarmAudio()

        // 6. Start rhythmic vibration loop if enabled
        if (vibrate) {
            startVibration()
        }

        Log.d(TAG, "AlarmRingingActivity created and ringing for alarm #$alarmId ('$title')")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeAndShowOverLockscreen()
        parseAlarmIntent(intent)
        updateAlarmUi()
    }

    private fun parseAlarmIntent(intent: Intent?) {
        if (intent == null) return
        alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, 1)
        title = intent.getStringExtra(AlarmScheduler.EXTRA_TITLE) ?: "Aurora Alarme"
        sound = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND) ?: "dan-da-dan"
        vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)
        mission = intent.getStringExtra(AlarmScheduler.EXTRA_MISSION) ?: "none"
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
        btnSnooze.text = "Soneca (+${SNOOZE_DURATION_MINUTES}m)"
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
     * Resolves the asset path for the alarm sound and plays it in an infinite loop
     * using the Android hardware ALARM audio stream.
     */
    private fun startAlarmAudio() {
        try {
            stopAlarmAudio()

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                .build()

            val assetPath = resolveSoundAssetPath(sound)
            Log.d(TAG, "Attempting to play alarm asset: '$assetPath' (from sound '$sound')")

            var afd: AssetFileDescriptor? = null
            try {
                afd = assets.openFd(assetPath)
            } catch (e: Exception) {
                Log.w(TAG, "Direct openFd failed for '$assetPath': ${e.message}. Trying cache fallback.")
            }

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(audioAttributes)

                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                } else {
                    // Cache stream fallback if asset is compressed inside APK
                    val cacheFile = copyAssetToCache(assetPath)
                    if (cacheFile != null && cacheFile.exists()) {
                        setDataSource(cacheFile.absolutePath)
                    } else {
                        // Safe fallback to system alarm ringtone
                        val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        setDataSource(this@AlarmRingingActivity, fallbackUri)
                    }
                }

                isLooping = true
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
            Log.d(TAG, "Alarm sound playback started in loop")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start alarm audio playback: ${e.message}", e)
        }
    }

    private fun resolveSoundAssetPath(soundName: String?): String {
        val clean = soundName?.lowercase()?.trim() ?: ""
        return when {
            clean.contains("kompa") -> "flutter_assets/assets/sounds/ringtone-kompa.ogg"
            clean.contains("santa") || clean.contains("fe") -> "flutter_assets/assets/sounds/ringtone-santa-fe.ogg"
            clean.contains("dan") -> "flutter_assets/assets/sounds/ringtone-dan-da-dan.ogg"
            clean.startsWith("assets/") -> "flutter_assets/$clean"
            clean.startsWith("flutter_assets/") -> clean
            else -> "flutter_assets/assets/sounds/ringtone-dan-da-dan.ogg"
        }
    }

    private fun copyAssetToCache(assetPath: String): File? {
        return try {
            val file = File(cacheDir, "current_alarm_sound.ogg")
            assets.open(assetPath).use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
            file
        } catch (e: Exception) {
            Log.e(TAG, "Error copying asset to cache: ${e.message}")
            null
        }
    }

    private fun stopAlarmAudio() {
        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping audio: ${e.message}")
        }
    }

    /**
     * Starts continuous rhythmic vibration for the ringing alarm.
     */
    private fun startVibration() {
        try {
            stopVibration()

            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            val pattern = longArrayOf(0, 600, 400, 600, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0 /* repeat from index 0 */))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
            Log.d(TAG, "Alarm vibration loop started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting vibration: ${e.message}")
        }
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
            vibrator = null
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping vibration: ${e.message}")
        }
    }

    /**
     * Handles the "Desligar" action:
     * - Stops audio and vibration
     * - Notifies Flutter via NativeAlarmBridge
     * - If mission is active, opens MainActivity for the challenge
     * - Closes the Activity
     */
    private fun handleDismiss() {
        Log.d(TAG, "Alarm #$alarmId dismissed by user")
        stopAlarmAudio()
        stopVibration()

        // 1. Notify Flutter via NativeAlarmBridge
        NativeAlarmBridge.notifyAlarmDismissed(alarmId)

        // 2. If challenge is required, route to Flutter UI
        if (mission != "none") {
            val challengeIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("payload", alarmId.toString())
                putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            }
            startActivity(challengeIntent)
        }

        // 3. Close native activity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            finishAndRemoveTask()
        } else {
            finish()
        }
    }

    /**
     * Handles the "Soneca" action:
     * - Stops audio and vibration
     * - Schedules the snooze alarm natively for +10 minutes
     * - Notifies Flutter via NativeAlarmBridge
     * - Closes the Activity
     */
    private fun handleSnooze() {
        Log.d(TAG, "Alarm #$alarmId snoozed (+${SNOOZE_DURATION_MINUTES}m) by user")
        stopAlarmAudio()
        stopVibration()

        // 1. Schedule exact native snooze alarm for +10 minutes
        val snoozeTimeMillis = System.currentTimeMillis() + (SNOOZE_DURATION_MINUTES * 60 * 1000L)
        val scheduler = AlarmScheduler(this)
        scheduler.scheduleAlarm(
            id = alarmId,
            triggerTimeMillis = snoozeTimeMillis,
            title = title,
            sound = sound,
            vibrate = vibrate,
            mission = mission,
            snoozeMinutes = SNOOZE_DURATION_MINUTES
        )

        // 2. Notify Flutter via NativeAlarmBridge
        NativeAlarmBridge.notifyAlarmSnoozed(alarmId, SNOOZE_DURATION_MINUTES)

        // 3. Close native activity
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
        stopAlarmAudio()
        stopVibration()

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
