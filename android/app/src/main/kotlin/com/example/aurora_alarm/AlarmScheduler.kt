package com.example.aurora_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Native Alarm Scheduler utilizing Android's AlarmManager.setAlarmClock().
 * Guarantees exact, high-priority alarm triggering exempt from Doze mode,
 * showing the system clock icon in the status bar.
 */
class AlarmScheduler(private val context: Context) {

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    companion object {
        private const val TAG = "AlarmScheduler"
        const val ACTION_ALARM_TRIGGER = "com.aurora.alarm.ACTION_ALARM_TRIGGER"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_SOUND = "sound"
        const val EXTRA_VIBRATE = "vibrate"
        const val EXTRA_MISSION = "mission"
        const val EXTRA_TRIGGER_TIME = "trigger_time"
        const val EXTRA_SNOOZE_MINUTES = "snooze_minutes"
    }

    /**
     * Checks whether the app has permission to schedule exact alarms (Android 12+ / API 31+).
     */
    fun canScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    /**
     * Schedules an exact alarm using AlarmManager.setAlarmClock().
     *
     * @param id Unique identifier of the alarm.
     * @param triggerTimeMillis Exact timestamp in milliseconds when the alarm should ring.
     * @param title Display title for the alarm.
     * @param sound Built-in sound asset identifier.
     * @param vibrate Whether vibration is enabled.
     * @param mission Wake-up challenge type (math, shake, none).
     * @param snoozeMinutes Duration in minutes for snoozing.
     * @return true if scheduling succeeded, false otherwise.
     */
    fun scheduleAlarm(
        id: Int,
        triggerTimeMillis: Long,
        title: String? = null,
        sound: String? = null,
        vibrate: Boolean = true,
        mission: String? = null,
        snoozeMinutes: Int = 5
    ): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !canScheduleExactAlarms()) {
                Log.w(TAG, "Cannot schedule exact alarm #$id: SCHEDULE_EXACT_ALARM permission not granted")
                return false
            }

            // 1. Intent fired to AlarmReceiver when the alarm time arrives
            val receiverIntent = Intent(context, AlarmReceiver::class.java).apply {
                action = ACTION_ALARM_TRIGGER
                putExtra(EXTRA_ALARM_ID, id)
                putExtra(EXTRA_TITLE, title ?: "Aurora Alarme")
                putExtra(EXTRA_SOUND, sound ?: "dan-da-dan")
                putExtra(EXTRA_VIBRATE, vibrate)
                putExtra(EXTRA_MISSION, mission ?: "none")
                putExtra(EXTRA_TRIGGER_TIME, triggerTimeMillis)
                putExtra(EXTRA_SNOOZE_MINUTES, snoozeMinutes)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                receiverIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 2. PendingIntent used by the system UI when the user taps on the alarm clock in the lockscreen/status bar
            val showIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("payload", id.toString())
                putExtra(EXTRA_ALARM_ID, id)
            }

            val showPendingIntent = PendingIntent.getActivity(
                context,
                id,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 3. Register the alarm clock with AlarmManager
            val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerTimeMillis, showPendingIntent)
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)

            Log.d(TAG, "Alarm #$id successfully scheduled via setAlarmClock() for epoch: $triggerTimeMillis")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm #$id via setAlarmClock(): ${e.message}", e)
            false
        }
    }

    /**
     * Cancels an existing scheduled alarm by its ID.
     */
    fun cancelAlarm(id: Int): Boolean {
        return try {
            val receiverIntent = Intent(context, AlarmReceiver::class.java).apply {
                action = ACTION_ALARM_TRIGGER
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                receiverIntent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                Log.d(TAG, "Alarm #$id cancelled successfully in AlarmManager")
            } else {
                Log.d(TAG, "Alarm #$id had no active PendingIntent registered")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel alarm #$id: ${e.message}", e)
            false
        }
    }

    /**
     * Cancels all scheduled alarms for a given list of IDs.
     */
    fun cancelAllAlarms(ids: List<Int>? = null): Boolean {
        return try {
            ids?.forEach { cancelAlarm(it) }
            Log.d(TAG, "cancelAllAlarms executed for ${ids?.size ?: 0} alarms")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel all alarms: ${e.message}", e)
            false
        }
    }
}
