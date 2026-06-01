package com.gymforge.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts StepTrackingService after the device reboots.
 * Also handles Vivo/OPPO/Xiaomi quick-boot intents.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            action == "android.intent.action.MY_PACKAGE_REPLACED") {
            StepTrackingService.start(context)
        }
    }
}