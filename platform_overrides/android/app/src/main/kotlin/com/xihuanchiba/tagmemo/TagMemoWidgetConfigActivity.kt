package com.xihuanchiba.tagmemo

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import org.json.JSONArray

class TagMemoWidgetConfigActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.tagmemo_widget_config)

        widgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences(MainActivity.PREFS_NAME, MODE_PRIVATE)
        val rawLabels = prefs.getString(MainActivity.LABELS_KEY, "[]") ?: "[]"
        val array = runCatching { JSONArray(rawLabels) }.getOrElse { JSONArray() }
        val labels = buildList {
            for (index in 0 until array.length()) add(array.optString(index))
        }.filter { it.isNotBlank() }
        val display = listOf("すべてのメモ", "固定したメモ") + labels.map { "ラベル: $it" }
        val values = listOf("all", "pinned") + labels.map { "label:$it" }

        val spinner = findViewById<Spinner>(R.id.widget_filter_spinner)
        spinner.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, display)
        findViewById<Button>(R.id.widget_save_button).setOnClickListener {
            prefs.edit().putString("filter_$widgetId", values[spinner.selectedItemPosition]).apply()
            TagMemoWidgetProvider.update(this, AppWidgetManager.getInstance(this), widgetId)
            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId),
            )
            finish()
        }
    }
}
