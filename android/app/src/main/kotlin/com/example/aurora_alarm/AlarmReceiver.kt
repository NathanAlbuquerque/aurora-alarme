package com.example.aurora_alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * BroadcastReceiver responsible for receiving exact alarm triggers from AlarmManager.setAlarmClock().
 * Runs natively in Android even when the app is completely closed or screen is locked.
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ALARM_ID, 1)
        val title = intent.getStringExtra(AlarmScheduler.EXTRA_TITLE) ?: "Aurora Alarme"
        val sound = intent.getStringExtra(AlarmScheduler.EXTRA_SOUND) ?: "dan-da-dan"
        val vibrate = intent.getBooleanExtra(AlarmScheduler.EXTRA_VIBRATE, true)
        val mission = intent.getStringExtra(AlarmScheduler.EXTRA_MISSION) ?: "none"
        val snoozeMinutes = intent.getIntExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, 5)

        Log.d(TAG, "Native AlarmReceiver triggered for alarm #$alarmId ('$title')")

        // 1. Acquire temporary partial WakeLock to keep CPU alive during transition
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "aurora_alarm:AlarmReceiverWakeLock"
            )
            wakeLock?.acquire(3 * 60 * 1000L /* 3 minutes */)
            Log.d(TAG, "Acquired partial WakeLock in AlarmReceiver")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock in AlarmReceiver: ${e.message}")
        }

        // 2. Launch AlarmRingingActivity (prepared full-screen native activity)
        try {
            val ringingIntent = Intent(context, AlarmRingingActivity::class.java).apply {
                action = "com.aurora.alarm.RING_NATIVE"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra(AlarmScheduler.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmScheduler.EXTRA_TITLE, title)
                putExtra(AlarmScheduler.EXTRA_SOUND, sound)
                putExtra(AlarmScheduler.EXTRA_VIBRATE, vibrate)
                putExtra(AlarmScheduler.EXTRA_MISSION, mission)
                putExtra(AlarmScheduler.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
                putExtra("payload", alarmId.toString())
            }
            context.startActivity(ringingIntent)
            Log.d(TAG, "AlarmRingingActivity started successfully from AlarmReceiver for alarm #$alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AlarmRingingActivity from AlarmReceiver: ${e.message}", e)
        }
    }
}
