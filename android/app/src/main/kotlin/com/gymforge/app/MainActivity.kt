package com.gymforge.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity

/**
 * On every app open:
 *  1. Start / restart the step tracking foreground service.
 *  2. Do a one-shot hardware sensor read to catch up ALL steps
 *     missed while the service was killed by the OEM battery manager.
 *     The TYPE_STEP_COUNTER sensor is a hardware counter that never
 *     stops — it accumulates steps since device boot regardless of
 *     whether our service is alive. Reading it here guarantees the
 *     widget and Flutter UI always show accurate steps even if the
 *     service was dead all day.
 */
class MainActivity : FlutterActivity(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    private var syncDone = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Always restart the background service
        StepTrackingService.start(this)
        // One-shot sync to catch up missed steps
        syncStepsNow()
    }

    override fun onResume() {
        super.onResume()
        // Also sync when user returns to app from background
        if (!syncDone) syncStepsNow()
    }

    private fun syncStepsNow() {
        try {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            stepSensor     = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (stepSensor != null) {
                // Request ONE reading — unregister after we get it
                sensorManager.registerListener(this, stepSensor,
                    SensorManager.SENSOR_DELAY_FASTEST)
                // Safety timeout: unregister after 5 seconds if no event
                Handler(Looper.getMainLooper()).postDelayed({
                    try { sensorManager.unregisterListener(this) } catch (_: Exception) {}
                }, 5000)
            }
        } catch (_: Exception) {}
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_STEP_COUNTER) return
        if (syncDone) return
        syncDone = true

        try {
            sensorManager.unregisterListener(this)

            val totalSteps = event.values[0].toInt()
            val prefs      = getSharedPreferences(
                StepTrackingService.PREFS_NAME, Context.MODE_PRIVATE)
            val today      = todayString()
            val savedDate  = prefs.getString("step_offset_date", "")
            val baseline   = prefs.getInt("step_sensor_offset", -1)

            val todaySteps: Int
            if (savedDate != today || baseline < 0) {
                // New day or no baseline — set baseline to current total
                todaySteps = 0
                prefs.edit()
                    .putInt("step_sensor_offset", totalSteps)
                    .putString("step_offset_date", today)
                    .putInt(StepTrackingService.KEY_STEPS, 0)
                    .apply()
            } else {
                // Calculate steps since baseline
                todaySteps = (totalSteps - baseline).coerceAtLeast(0)
                prefs.edit()
                    .putInt(StepTrackingService.KEY_STEPS, todaySteps)
                    .apply()
            }

            // Update widget immediately with real step count
            GymForgeWidget.updateAll(this)

        } catch (_: Exception) {}
    }

    private fun todayString(): String {
        val c = java.util.Calendar.getInstance()
        return "%04d-%02d-%02d".format(
            c.get(java.util.Calendar.YEAR),
            c.get(java.util.Calendar.MONTH) + 1,
            c.get(java.util.Calendar.DAY_OF_MONTH)
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        try { sensorManager.unregisterListener(this) } catch (_: Exception) {}
        super.onDestroy()
    }
}