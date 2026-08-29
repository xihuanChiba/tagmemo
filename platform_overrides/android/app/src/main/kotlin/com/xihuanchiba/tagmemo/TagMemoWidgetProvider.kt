package com.xihuanchiba.tagmemo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class TagMemoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id -> update(context, appWidgetManager, id) }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE).edit()
        appWidgetIds.forEach { editor.remove("filter_$it") }
        editor.apply()
    }

    companion object {
        fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val filter = prefs.getString("filter_$widgetId", "all") ?: "all"
            val title = when {
                filter == "pinned" -> "固定したメモ"
                filter.startsWith("label:") -> filter.removePrefix("label:")
                else -> "すべてのメモ"
            }
            val views = RemoteViews(context.packageName, R.layout.tagmemo_widget).apply {
                setTextViewText(R.id.widget_title, title)
                val serviceIntent = Intent(context, TagMemoWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    putExtra("filter", filter)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.widget_list, serviceIntent)
                setEmptyView(R.id.widget_list, R.id.widget_empty)

                val openIntent = Intent(context, MainActivity::class.java)
                val openPending = PendingIntent.getActivity(
                    context,
                    widgetId,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                setOnClickPendingIntent(R.id.widget_header, openPending)

                val itemTemplate = Intent(context, MainActivity::class.java)
                val itemPending = PendingIntent.getActivity(
                    context,
                    widgetId + 10000,
                    itemTemplate,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                setPendingIntentTemplate(R.id.widget_list, itemPending)
            }
            manager.updateAppWidget(widgetId, views)
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }
}
