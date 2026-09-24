package com.widgetboard.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.widgetboard.R

/**
 * Simple static preview provider. Real updates are triggered from Flutter via
 * SharedPreferences + `AppWidgetManager`.
 */
class WidgetBoardProvider : AppWidgetProvider() {

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
        val note = prefs.getString("widget_note", "miss u 💛") ?: "miss u 💛"
        val ts = prefs.getString("last_note_ts", "just now") ?: "just now"
        val mgr = context.getSystemService(Context.APPWIDGET_SERVICE) as AppWidgetManager
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, WidgetBoardProvider::class.java))
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_board)
            views.setTextViewText(R.id.widgetMessage, note)
            views.setTextViewText(R.id.widgetUpdated, ts)
            // Tap widget -> open app
            val pi = context.packageManager.getPackageInfo(context.packageName, 0)
            val pending = PendingIntent.getActivity(
                context, 0,
                Intent(context, Class.forName(pi.applicationInfo.className)),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pending)
            mgr.updateAppWidget(id, views)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences("flutter", Context.MODE_PRIVATE)
        val note = prefs.getString("widget_note", "miss u 💛") ?: "miss u 💛"
        val ts = prefs.getString("last_note_ts", "just now") ?: "just now"
        val views = RemoteViews(context.packageName, R.layout.widget_board)
        views.setTextViewText(R.id.widgetMessage, note)
        views.setTextViewText(R.id.widgetUpdated, ts)
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
