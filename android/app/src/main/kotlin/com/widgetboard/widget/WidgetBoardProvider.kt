package com.widgetboard.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import com.widgetboard.R

/**
 * AppWidgetProvider that displays the last 5 shared notes from friends.
 *
 * Notes are stored in SharedPreferences under the key "widget_notes_json".
 * Each entry is a JSON object: { "sender": "...", "body": "...", "timestamp": "..." }
 *
 * The Flutter side pushes updates by writing this key → onReceive() picks them up.
 */
class WidgetBoardProvider : AppWidgetProvider() {

    companion object {
        private const val KEY_NOTES = "widget_notes_json"
        private const val KEY_TS = "last_note_ts"
        private const val MAX_NOTES = 5
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val prefs = context.getSharedPreferences("flutter", Context.MODE_PRIVATE)
        refreshAll(context, prefs)
    }

    private fun refreshAll(context: Context, prefs: android.content.SharedPreferences) {
        val mgr = context.getSystemService(Context.APPWIDGET_SERVICE) as AppWidgetManager
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, WidgetBoardProvider::class.java))
        for (id in ids) {
            updateAppWidgetInternal(context, mgr, id, prefs)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences("flutter", Context.MODE_PRIVATE)
        updateAppWidgetInternal(context, appWidgetManager, widgetId, prefs)
    }

    private fun updateAppWidgetInternal(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        prefs: android.content.SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_board)

        // Load notes
        val json = prefs.getString(KEY_NOTES, "[]") ?: "[]"
        val noteList = parseNotes(json)

        // Show up to MAX_NOTES lines
        for (i in 0 until MAX_NOTES) {
            val tvId = when (i) {
                0 -> R.id.noteRow0
                1 -> R.id.noteRow1
                2 -> R.id.noteRow2
                3 -> R.id.noteRow3
                else -> R.id.noteRow4
            }
            if (i < noteList.size) {
                views.setTextViewText(tvId, noteList[i].formatForWidget())
                views.setViewVisibility(tvId, android.view.View.VISIBLE)
            } else {
                views.setTextViewText(tvId, "")
                views.setViewVisibility(tvId, android.view.View.GONE)
            }
        }

        // Timestamps
        val ts = prefs.getString(KEY_TS, "waiting for notes…") ?: "waiting for notes…"
        views.setTextViewText(R.id.widgetUpdated, ts)

        // Tap to open app
        try {
            val pi = context.packageManager.getPackageInfo(context.packageName, 0)
            val pending = PendingIntent.getActivity(
                context, 0,
                Intent(context, Class.forName(pi.applicationInfo.className)),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pending)
        } catch (e: Exception) {
            // Ignore – widget still renders
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /**
     * Parse notes JSON array. Handles both:
     * - Old format: single string "miss u 💛" (widget_note key)
     * - New format: JSON array [{sender, body, timestamp}, ...]
     */
    private fun parseNotes(jsonString: String): List<NoteLine> {
        val result = mutableListOf<NoteLine>()

        // Try new format first (JSON array)
        try {
            val arr = JSONArray(jsonString)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val sender = obj.optString("sender", "friend")
                val body = obj.optString("body", "")
                result.add(NoteLine(sender = sender, body = body))
            }
            return result
        } catch (_: Exception) {
            // Fall through to legacy format
        }

        // Legacy single-note format
        val body = jsonString.trim()
        if (body.isNotEmpty()) {
            result.add(NoteLine(sender = "friend", body = body))
        }
        return result
    }

    data class NoteLine(val sender: String, val body: String) {
        fun formatForWidget(): String {
            val truncated = if (body.length > 40) "${body.substring(0, 40)}…" else body
            return "$sender — $truncated"
        }
    }
}
