package com.example.aurora_alarm

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import java.io.File
import java.io.FileOutputStream

/**
 * Singleton Audio & Vibration manager for native alarm ringing.
 * Can be triggered directly from AlarmReceiver (background/killed state)
 * and managed/stopped by AlarmRingingActivity or notification action handlers.
 */
object NativeAlarmSoundPlayer {

    private const val TAG = "NativeAlarmSoundPlayer"

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null

    var isRinging: Boolean = false
        private set

    var currentAlarmId: Int? = null
        private set

    @Synchronized
    fun start(
        context: Context,
        alarmId: Int,
        soundName: String?,
        vibrate: Boolean
    ) {
        if (isRinging && currentAlarmId == alarmId) {
            Log.d(TAG, "Audio already ringing for alarm #$alarmId, keeping active")
            return
        }

        stop()

        currentAlarmId = alarmId
        isRinging = true

        // 1. Keep CPU awake while alarm is sounding
        try {
            val powerManager = context.applicationContext.getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "aurora_alarm:NativeAlarmSoundPlayerWakeLock"
            )?.apply {
                setReferenceCounted(false)
                acquire(10 * 60 * 1000L /* 10 minutes timeout */)
            }
            Log.d(TAG, "Acquired WakeLock in NativeAlarmSoundPlayer")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }

        // 2. Start hardware ALARM audio stream in infinite loop
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                .build()

            val assetPath = resolveSoundAssetPath(soundName)
            Log.d(TAG, "Playing alarm asset: '$assetPath' (requested: '$soundName')")

            var afd: AssetFileDescriptor? = null
            try {
                afd = context.assets.openFd(assetPath)
            } catch (e: Exception) {
                Log.w(TAG, "Direct openFd failed for '$assetPath': ${e.message}. Using cache fallback.")
            }

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(audioAttributes)

                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                } else {
                    val cacheFile = copyAssetToCache(context, assetPath)
                    if (cacheFile != null && cacheFile.exists()) {
                        setDataSource(cacheFile.absolutePath)
                    } else {
                        val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        setDataSource(context, fallbackUri)
                    }
                }

                isLooping = true
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
            Log.d(TAG, "Native audio playback started successfully for alarm #$alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting alarm audio playback: ${e.message}", e)
        }

        // 3. Start rhythmic vibration loop if enabled
        if (vibrate) {
            try {
                vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vm?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                }

                val pattern = longArrayOf(0, 600, 400, 600, 800)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0 /* repeat from index 0 */))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }
                Log.d(TAG, "Native vibration started successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error starting vibration: ${e.message}")
            }
        }
    }

    @Synchronized
    fun stop() {
        if (!isRinging && mediaPlayer == null && vibrator == null) return

        Log.d(TAG, "Stopping native alarm audio & vibration (alarm was #${currentAlarmId})")

        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer: ${e.message}")
        } finally {
            mediaPlayer = null
        }

        try {
            vibrator?.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling Vibrator: ${e.message}")
        } finally {
            vibrator = null
        }

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        } finally {
            wakeLock = null
        }

        isRinging = false
        currentAlarmId = null
    }

    private fun resolveSoundAssetPath(soundName: String?): String {
        val clean = soundName?.lowercase()?.trim() ?: ""
        return when {
            clean.contains("slay") -> "flutter_assets/assets/sounds/ringtone-slay.ogg"
            clean.contains("kid") || clean.contains("that-one") || clean.contains("br") -> "flutter_assets/assets/sounds/ringtone-that-one-br-kid.ogg"
            clean.contains("kompa") -> "flutter_assets/assets/sounds/ringtone-kompa.ogg"
            clean.contains("santa") || clean.contains("fe") -> "flutter_assets/assets/sounds/ringtone-santa-fe.ogg"
            clean.contains("dan") -> "flutter_assets/assets/sounds/ringtone-dan-da-dan.ogg"
            clean.startsWith("assets/") -> "flutter_assets/$clean"
            clean.startsWith("flutter_assets/") -> clean
            else -> "flutter_assets/assets/sounds/ringtone-dan-da-dan.ogg"
        }
    }

    private fun copyAssetToCache(context: Context, assetPath: String): File? {
        return try {
            val file = File(context.cacheDir, "current_native_alarm_sound.ogg")
            context.assets.open(assetPath).use { input ->
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
}
