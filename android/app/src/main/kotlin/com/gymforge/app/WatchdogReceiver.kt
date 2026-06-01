package com.gymforge.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fired by AlarmManager every 10 minutes.
 * Restarts StepTrackingService if Android killed it,
 * and re-schedules the next alarm so the watchdog chain continues.
 */
class WatchdogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        StepTrackingService.start(context)
        StepTrackingService.scheduleWatchdog(context)
    }
}