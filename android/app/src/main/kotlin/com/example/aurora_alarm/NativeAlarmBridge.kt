package com.example.aurora_alarm

import android.os.Handler
import android.os.Looper

/**
 * In-memory bridge facilitating communication between native Android activities
 * (such as AlarmRingingActivity) and MainActivity / Flutter's aurora_alarm/native MethodChannel.
 */
object NativeAlarmBridge {

    interface AlarmEventListener {
        fun onAlarmDismissed(alarmId: Int)
        fun onAlarmSnoozed(alarmId: Int, snoozeMinutes: Int)
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var listener: AlarmEventListener? = null

    fun setListener(listener: AlarmEventListener?) {
        this.listener = listener
    }

    fun notifyAlarmDismissed(alarmId: Int) {
        mainHandler.post {
            listener?.onAlarmDismissed(alarmId)
        }
    }

    fun notifyAlarmSnoozed(alarmId: Int, snoozeMinutes: Int = 10) {
        mainHandler.post {
            listener?.onAlarmSnoozed(alarmId, snoozeMinutes)
        }
    }
}
