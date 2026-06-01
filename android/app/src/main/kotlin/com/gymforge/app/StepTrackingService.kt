package com.gymforge.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Foreground service — counts daily steps and refreshes the home widget.
 *
 * Reliability stack:
 *  1. Runs as a FOREGROUND service (shown notification = OS won't kill it)
 *  2. Returns START_STICKY → auto-restarted by OS after kills
 *  3. Re-registers sensor in onStartCommand (not just onCreate)
 *  4. Holds a PARTIAL_WAKE_LOCK so the CPU stays awake for sensor events
 *     even when the screen is off (this is the fix for "stops after a while")
 *  5. Watchdog alarm every 15 min via WatchdogReceiver as belt-and-suspenders
 */
class StepTrackingService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    private var initialSteps: Int = -1

    // ── Widget refresh debounce ───────────────────────────────────────────────
    // Android rate-limits AppWidgetManager.updateAppWidget(). Calling it on
    // every sensor event (potentially 100s of times/min) causes the OS to
    // silently drop updates, making the widget face go stale.
    // We only push a widget refresh every 50 steps OR every 60 seconds.
    private var lastWidgetUpdateSteps: Int = -1
    private var lastWidgetUpdateTime:  Long = 0L
    private val kWidgetStepInterval = 50       // refresh every 50 steps
    private val kWidgetTimeIntervalMs = 60_000L // refresh at least every 60s
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_ID = "step_tracking_channel"
        const val NOTIF_ID   = 1001
        const val PREFS_NAME = "HomeWidgetPreferences"
        const val KEY_STEPS  = "steps"

        fun start(context: Context) {
            val intent = Intent(context, StepTrackingService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            scheduleWatchdog(context)
        }

        fun scheduleWatchdog(context: Context) {
            try {
                val am    = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val pi    = PendingIntent.getBroadcast(
                    context, 99,
                    Intent(context, WatchdogReceiver::class.java)
                        .setAction("com.gymforge.app.WATCHDOG"),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                am.cancel(pi)
                val trigger = System.currentTimeMillis() + 10 * 60 * 1000L
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
                } else {
                    am.setInexactRepeating(
                        AlarmManager.RTC_WAKEUP, trigger, 10 * 60 * 1000L, pi)
                }
            } catch (_: Exception) {}
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification(currentSteps()))

        // Acquire a partial wake lock so the CPU doesn't sleep between sensor events.
        // Without this, Android Doze mode prevents sensor callbacks after ~few minutes
        // of screen-off — which is exactly the "stops counting" symptom.
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "GymForge::StepCounterLock"
        ).also { it.acquire(12 * 60 * 60 * 1000L) } // max 12h, auto-releases

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor    = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Re-register sensor (handles sticky restarts cleanly)
        stepSensor?.let {
            sensorManager.unregisterListener(this, it)
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }
        // Re-acquire wake lock if it expired (max 12h each time)
        if (wakeLock?.isHeld == false) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "GymForge::StepCounterLock"
            ).also { it.acquire(12 * 60 * 60 * 1000L) }
        }
        scheduleWatchdog(this)
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_STEP_COUNTER) return
        val totalSteps = event.values[0].toInt()

        val prefs     = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today     = todayDateString()
        val savedDate = prefs.getString("step_offset_date", "")

        if (savedDate != today) {
            // New day — reset baseline
            initialSteps = totalSteps
            lastWidgetUpdateSteps = 0
            lastWidgetUpdateTime  = System.currentTimeMillis()
            prefs.edit()
                .putInt("step_sensor_offset", initialSteps)
                .putString("step_offset_date", today)
                .putInt(KEY_STEPS, 0)
                .putInt("water_ml", 0)
                .putInt("score", 0)
                .apply()
            GymForgeWidget.updateAll(this) // always update on day reset
            return
        }

        if (initialSteps < 0) {
            initialSteps = prefs.getInt("step_sensor_offset", totalSteps)
            if (initialSteps < 0) initialSteps = totalSteps
        }

        val todaySteps = (totalSteps - initialSteps).coerceAtLeast(0)
        val water      = prefs.getInt("water_ml", 0)
        val sv         = (todaySteps / 10000.0 * 40).toInt().coerceAtMost(40)
        val wv         = (water      / 3000.0  * 30).toInt().coerceAtMost(30)

        prefs.edit()
            .putInt(KEY_STEPS, todaySteps)
            .putInt("score",   sv + wv)
            .apply()

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(todaySteps))

        // Debounce: only update widget every 50 steps OR every 60 seconds.
        // This prevents Android from rate-limiting / silently dropping widget updates.
        val now         = System.currentTimeMillis()
        val stepsDelta  = todaySteps - lastWidgetUpdateSteps
        val timeDelta   = now - lastWidgetUpdateTime
        if (stepsDelta >= kWidgetStepInterval || timeDelta >= kWidgetTimeIntervalMs) {
            lastWidgetUpdateSteps = todaySteps
            lastWidgetUpdateTime  = now
            GymForgeWidget.updateAll(this)
        }
    }

    private fun currentSteps() =
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getInt(KEY_STEPS, 0)

    private fun todayDateString(): String {
        val c = java.util.Calendar.getInstance()
        return "%04d-%02d-%02d".format(
            c.get(java.util.Calendar.YEAR),
            c.get(java.util.Calendar.MONTH) + 1,
            c.get(java.util.Calendar.DAY_OF_MONTH)
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        if (::sensorManager.isInitialized) sensorManager.unregisterListener(this)
        wakeLock?.let { if (it.isHeld) it.release() }
        scheduleWatchdog(this)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(steps: Int): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("GymForge Active")
            .setContentText("Steps today: $steps")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pi)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID, "Step Tracking", NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Tracks your daily steps in the background"
                setShowBadge(false)
            }
            (getSystemService(NotificationManager::class.java)).createNotificationChannel(ch)
        }
    }
}