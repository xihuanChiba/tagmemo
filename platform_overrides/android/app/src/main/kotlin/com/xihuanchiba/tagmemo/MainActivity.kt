package com.xihuanchiba.tagmemo

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "tagmemo/widget"
        const val PREFS_NAME = "tagmemo_widget"
        const val NOTES_KEY = "notes"
        const val LABELS_KEY = "labels"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "updateWidget") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val notes = call.argument<String>("notes") ?: "[]"
                val labels = call.argument<String>("labels") ?: "[]"
                getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                    .edit()
                    .putString(NOTES_KEY, notes)
                    .putString(LABELS_KEY, labels)
                    .apply()
                refreshWidgets()
                result.success(null)
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun refreshWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, TagMemoWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
        val updateIntent = Intent(this, TagMemoWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        sendBroadcast(updateIntent)
    }
}
