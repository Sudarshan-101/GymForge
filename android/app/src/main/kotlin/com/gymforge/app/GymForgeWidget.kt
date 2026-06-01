package com.gymforge.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class GymForgeWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_ADD_WATER = "com.gymforge.app.ADD_WATER"
        const val PREFS_NAME       = "HomeWidgetPreferences"
        private val DAY_LETTERS    = arrayOf("M","T","W","T","F","S","S")
        private val DAY_IDS = intArrayOf(
            R.id.widget_day1, R.id.widget_day2, R.id.widget_day3,
            R.id.widget_day4, R.id.widget_day5, R.id.widget_day6,
            R.id.widget_day7
        )

        fun updateAll(context: Context) {
            try {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(ComponentName(context, GymForgeWidget::class.java))
                mgr.updateAppWidget(ids, buildViews(context))
            } catch (_: Exception) {}
        }

        fun showTick(context: Context) {
            try {
                val mgr   = AppWidgetManager.getInstance(context)
                val ids   = mgr.getAppWidgetIds(ComponentName(context, GymForgeWidget::class.java))
                val views = buildViews(context)
                views.setTextViewText(R.id.widget_water_btn, "Added!")
                views.setInt(R.id.widget_water_btn, "setTextColor", 0xFF4CAF50.toInt())
                mgr.updateAppWidget(ids, views)
            } catch (_: Exception) {}
        }

        fun buildViews(context: Context): RemoteViews {
            val prefs      = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val steps      = prefs.getInt("steps",    0)
            val waterMl    = prefs.getInt("water_ml", 0)
            val streak     = prefs.getInt("streak",   0)
            val checkinStr = prefs.getString("week_checkins","0,0,0,0,0,0,0") ?: "0,0,0,0,0,0,0"
            val checkins   = checkinStr.split(",").map { it.trim() == "1" }

            val views = RemoteViews(context.packageName, R.layout.gymforge_widget)

            // Steps
            val fmt = NumberFormat.getIntegerInstance(Locale.getDefault())
            views.setTextViewText(R.id.widget_steps, fmt.format(steps.toLong()))

            // Distance + calories
            views.setTextViewText(R.id.widget_distance,
                String.format(Locale.getDefault(), "%.2f km", steps * 0.000762))
            views.setTextViewText(R.id.widget_calories, "${(steps * 0.04).toInt()} kcal")

            // Date
            views.setTextViewText(R.id.widget_date,
                SimpleDateFormat("EEE, d MMM", Locale.getDefault()).format(Date()))

            // Streak
            views.setTextViewText(R.id.widget_streak, "${streak}d streak")

            // Day circles Mon=0..Sun=6
            val dow      = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
            val todayIdx = (dow + 5) % 7
            for (i in 0..6) {
                val id      = DAY_IDS[i]
                val checked = if (i < checkins.size) checkins[i] else false
                val isToday = i == todayIdx
                val label: String; val textColor: Int; val bgColor: Int
                when {
                    checked -> { label = "v"; textColor = 0xFFFFFFFF.toInt(); bgColor = 0xFF2A7A2A.toInt() }
                    isToday -> { label = DAY_LETTERS[i]; textColor = 0xFF4CAF50.toInt(); bgColor = 0xFF1A3A5A.toInt() }
                    else    -> { label = DAY_LETTERS[i]; textColor = 0xFF445566.toInt(); bgColor = 0xFF2A3347.toInt() }
                }
                views.setTextViewText(id, label)
                views.setInt(id, "setTextColor",      textColor)
                views.setInt(id, "setBackgroundColor", bgColor)
            }

            // Water button
            val waterText = if (waterMl >= 1000)
                String.format("%.1f L", waterMl / 1000.0) else "$waterMl ml  \uD83D\uDCA7"
            views.setTextViewText(R.id.widget_water_btn, "+250ml")
            views.setInt(R.id.widget_water_btn, "setTextColor", 0xFF7AAAD4.toInt())

            val intent = Intent(context, WaterBroadcastReceiver::class.java)
                .setAction(ACTION_ADD_WATER)
            val pi = PendingIntent.getBroadcast(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_water_btn, pi)

            return views
        }
    }

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            try { mgr.updateAppWidget(id, buildViews(context)) }
            catch (_: Exception) {}
        }
    }

    override fun onEnabled(context: Context) = updateAll(context)
}

// ── WaterBroadcastReceiver — in same file (required for widget to add correctly) ──
class WaterBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            if (intent?.action != GymForgeWidget.ACTION_ADD_WATER) return
            val prefs   = context.getSharedPreferences(GymForgeWidget.PREFS_NAME, Context.MODE_PRIVATE)
            val current = prefs.getInt("water_ml", 0)
            prefs.edit().putInt("water_ml", current + 250).apply()
            GymForgeWidget.showTick(context)
            Handler(Looper.getMainLooper()).postDelayed({ GymForgeWidget.updateAll(context) }, 2000)
        } catch (_: Exception) {}
    }
}