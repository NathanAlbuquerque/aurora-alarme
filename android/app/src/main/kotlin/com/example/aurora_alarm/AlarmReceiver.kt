package com.example.aurora_alarm

import android.app.ActivityOptions
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Native BroadcastReceiver responsible for exact alarm triggers from AlarmManager.setAlarmClock().
 *
 * Responsibilities on trigger:
 * 1. Immediately starts sound playback and rhythmic vibration via NativeAlarmSoundPlayer.
 * 2. Displays a persistent, high-priority full-screen intent notification with "Desligar" and "Soneca" actions.
 * 3. Immediately launches AlarmRingingActivity with NEW_TASK / CLEAR_TOP / REORDER_TO_FRONT flags.
 *
 * Also handles notification action callbacks (ACTION_DISMISS, ACTION_SNOOZE) natively.
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_ALARM_TRIGGER = "com.aurora.alarm.ACTION_ALARM_TRIGGER"
        const val ACTION_DISMISS = "com.aurora.alarm.ACTION_DISMISS"
        const val ACTION_SNOOZE = "com.aurora.alarm.ACTION_SNOOZE"
        const val NOTIFICATION_CHANNEL_ID = "aurora_native_alarm_channel_v2"
        private const val NOTIFICATION_CHANNEL_NAME = "Disparo de Alarme Aurora"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: ACTION_ALARM_TRIGGER
        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, 1)
        val title = intent.getStringExtra(AlarmScheduler.EXTRA_TITLE) ?: "Aurora Alarme"
        val sound = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND) ?: "dan-da-dan"
        val vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)
        val mission = intent.getStringExtra(AlarmScheduler.EXTRA_MISSION) ?: "none"
        val snoozeMinutes = intent.getIntExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, 10)

        Log.d(TAG, "Native AlarmReceiver onReceive: action='$action', alarmId=#$alarmId")

        when (action) {
            ACTION_DISMISS -> {
                handleDismissAction(context, alarmId)
            }
            ACTION_SNOOZE -> {
                handleSnoozeAction(context, alarmId, title, sound, vibrate, mission, snoozeMinutes)
            }
            else -> {
                handleTriggerAction(context, alarmId, title, sound, vibrate, mission, snoozeMinutes)
            }
        }
    }

    private fun handleTriggerAction(
        context: Context,
        alarmId: Int,
        title: String,
        sound: String,
        vibrate: Boolean,
        mission: String,
        snoozeMinutes: Int
    ) {
        // 0. Acquire hardware screen WakeLock to wake up display immediately
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "aurora_alarm:AlarmReceiverScreenWakeLock"
            )
            wakeLock?.setReferenceCounted(false)
            wakeLock?.acquire(60 * 1000L /* 60 seconds */)
            Log.d(TAG, "Acquired screen bright WakeLock in AlarmReceiver")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock in AlarmReceiver: ${e.message}")
        }

        // 1. Iniciar o som imediatamente
        try {
            NativeAlarmSoundPlayer.start(
                context = context,
                alarmId = alarmId,
                soundName = sound,
                vibrate = vibrate
            )
            Log.d(TAG, "Sound and vibration started from AlarmReceiver for alarm #$alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start sound from AlarmReceiver: ${e.message}", e)
        }

        // 2. Mostrar notificação de alta prioridade (fallback e heads-up para tela desbloqueada)
        try {
            showHighPriorityAlarmNotification(
                context = context,
                alarmId = alarmId,
                title = title,
                sound = sound,
                vibrate = vibrate,
                mission = mission,
                snoozeMinutes = snoozeMinutes
            )
            Log.d(TAG, "High-priority notification posted for alarm #$alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to post high-priority notification: ${e.message}", e)
        }

        // 3. Abrir a AlarmRingingActivity imediatamente com as flags mais agressivas possíveis e opções de BAL
        try {
            val ringingIntent = Intent(context, AlarmRingingActivity::class.java).apply {
                this.action = "com.aurora.alarm.RING_NATIVE"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_NO_USER_ACTION
                putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmScheduler.EXTRA_TITLE, title)
                putExtra(AlarmScheduler.EXTRA_SOUND, sound)
                putExtra(AlarmScheduler.EXTRA_VIBRATE, vibrate)
                putExtra(AlarmScheduler.EXTRA_MISSION, mission)
                putExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
                putExtra("payload", alarmId.toString())
            }

            val optionsBundle = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ActivityOptions.makeBasic().apply {
                    setPendingIntentBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                    )
                }.toBundle()
            } else {
                null
            }

            // A. Iniciar diretamente via context.startActivity com options de BAL
            try {
                if (optionsBundle != null) {
                    context.startActivity(ringingIntent, optionsBundle)
                } else {
                    context.startActivity(ringingIntent)
                }
                Log.d(TAG, "AlarmRingingActivity started via context.startActivity for alarm #$alarmId")
            } catch (se: Exception) {
                Log.w(TAG, "context.startActivity warning: ${se.message}")
            }

            // B. Também disparar via PendingIntent com privilégios explícitos de Background Activity Launch (BAL)
            try {
                val directPendingIntent = PendingIntent.getActivity(
                    context,
                    alarmId + 500000,
                    ringingIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    optionsBundle
                )
                if (optionsBundle != null) {
                    directPendingIntent.send(context, 0, null, null, null, null, optionsBundle)
                } else {
                    directPendingIntent.send()
                }
                Log.d(TAG, "directPendingIntent.send executed for alarm #$alarmId")
            } catch (pe: Exception) {
                Log.w(TAG, "directPendingIntent.send warning: ${pe.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch AlarmRingingActivity: ${e.message}", e)
        }
    }

    private fun showHighPriorityAlarmNotification(
        context: Context,
        alarmId: Int,
        title: String,
        sound: String,
        vibrate: Boolean,
        mission: String,
        snoozeMinutes: Int
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Notification Channel with HIGH importance for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                notificationManager.deleteNotificationChannel("aurora_native_alarm_channel")
            } catch (_: Exception) {}

            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificações de alta prioridade para o disparo do alarme"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                setShowBadge(true)
                setBypassDnd(true)
                setSound(null, null) // Audio is handled loopingly by NativeAlarmSoundPlayer
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Full-screen and content Intent pointing to AlarmRingingActivity
        val ringingIntent = Intent(context, AlarmRingingActivity::class.java).apply {
            this.action = "com.aurora.alarm.RING_NATIVE"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION
            putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmScheduler.EXTRA_TITLE, title)
            putExtra(AlarmScheduler.EXTRA_SOUND, sound)
            putExtra(AlarmScheduler.EXTRA_VIBRATE, vibrate)
            putExtra(AlarmScheduler.EXTRA_MISSION, mission)
            putExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
            putExtra("payload", alarmId.toString())
        }

        val optionsBundle = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ActivityOptions.makeBasic().apply {
                setPendingIntentBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                )
            }.toBundle()
        } else {
            null
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            alarmId,
            ringingIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            optionsBundle
        )

        // Action Intent for Dismiss ("Desligar")
        val dismissIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = ACTION_DISMISS
            putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId + 100000,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action Intent for Snooze ("Soneca")
        val snoozeIntent = Intent(context, AlarmReceiver::class.java).apply {
            this.action = ACTION_SNOOZE
            putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmScheduler.EXTRA_TITLE, title)
            putExtra(AlarmScheduler.EXTRA_SOUND, sound)
            putExtra(AlarmScheduler.EXTRA_VIBRATE, vibrate)
            putExtra(AlarmScheduler.EXTRA_MISSION, mission)
            putExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId + 200000,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("Alarme disparando! Toque para abrir.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(0, "Desligar", dismissPendingIntent)
            .addAction(0, "Soneca (${snoozeMinutes}m)", snoozePendingIntent)

        notificationManager.notify(alarmId, notificationBuilder.build())
    }

    private fun handleDismissAction(context: Context, alarmId: Int) {
        Log.d(TAG, "handleDismissAction: user tapped Desligar on notification for alarm #$alarmId")

        // 1. Stop audio and vibration
        NativeAlarmSoundPlayer.stop()

        // 2. Cancel fallback notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(alarmId)

        // 3. Mark alarm as dismissed in shared preferences for Flutter offline sync
        try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("flutter.dismissed_alarm_$alarmId", true)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving dismissed alarm to prefs: ${e.message}")
        }

        // 4. Close AlarmRingingActivity if visible
        AlarmRingingActivity.finishIfActive(alarmId)

        // 5. Notify Flutter
        NativeAlarmBridge.notifyAlarmDismissed(alarmId)
    }

    private fun handleSnoozeAction(
        context: Context,
        alarmId: Int,
        title: String,
        sound: String,
        vibrate: Boolean,
        mission: String,
        snoozeMinutes: Int
    ) {
        Log.d(TAG, "handleSnoozeAction: user tapped Soneca on notification for alarm #$alarmId ($snoozeMinutes min)")

        // 1. Stop current ringing
        NativeAlarmSoundPlayer.stop()

        // 2. Cancel active notification
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(alarmId)

        // 3. Close AlarmRingingActivity if visible
        AlarmRingingActivity.finishIfActive(alarmId)

        // 4. Schedule snooze natively
        val snoozeTimeMillis = System.currentTimeMillis() + (snoozeMinutes * 60 * 1000L)
        val scheduler = AlarmScheduler(context)
        scheduler.scheduleAlarm(
            id = alarmId,
            triggerTimeMillis = snoozeTimeMillis,
            title = title,
            sound = sound,
            vibrate = vibrate,
            mission = mission,
            snoozeMinutes = snoozeMinutes
        )

        // 5. Notify Flutter
        NativeAlarmBridge.notifyAlarmSnoozed(alarmId, snoozeMinutes)
    }
}
