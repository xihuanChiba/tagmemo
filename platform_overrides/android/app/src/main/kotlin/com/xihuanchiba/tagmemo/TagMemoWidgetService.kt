package com.xihuanchiba.tagmemo

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class TagMemoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NotesFactory(applicationContext, intent.getStringExtra("filter") ?: "all")
    }
}

private class NotesFactory(
    private val context: Context,
    private val filter: String,
) : RemoteViewsService.RemoteViewsFactory {
    private var notes: List<JSONObject> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val raw = context
            .getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            .getString(MainActivity.NOTES_KEY, "[]") ?: "[]"
        val array = runCatching { JSONArray(raw) }.getOrElse { JSONArray() }
        notes = buildList {
            for (index in 0 until array.length()) {
                val note = array.optJSONObject(index) ?: continue
                val include = when {
                    filter == "pinned" -> note.optBoolean("pinned")
                    filter.startsWith("label:") -> hasLabel(note, filter.removePrefix("label:"))
                    else -> true
                }
                if (include) add(note)
            }
        }.sortedByDescending { it.optLong("updatedAt") }
    }

    private fun hasLabel(note: JSONObject, target: String): Boolean {
        val labels = note.optJSONArray("labels") ?: return false
        for (index in 0 until labels.length()) {
            if (labels.optString(index) == target) return true
        }
        return false
    }

    override fun onDestroy() {
        notes = emptyList()
    }

    override fun getCount(): Int = notes.size

    override fun getViewAt(position: Int): RemoteViews? {
        val note = notes.getOrNull(position) ?: return null
        val title = note.optString("title").ifBlank { "無題" }
        val body = note.optString("body")
        return RemoteViews(context.packageName, R.layout.tagmemo_widget_item).apply {
            setTextViewText(R.id.widget_item_title, title)
            setTextViewText(R.id.widget_item_body, body)
            setInt(R.id.widget_item_root, "setBackgroundColor", note.optInt("color", 0xFFFFF8B8.toInt()))
            val fillIn = Intent().apply {
                data = Uri.parse("tagmemo://note/${note.optString("id")}")
            }
            setOnClickFillInIntent(R.id.widget_item_root, fillIn)
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long =
        notes.getOrNull(position)?.optString("id")?.hashCode()?.toLong() ?: position.toLong()
    override fun hasStableIds(): Boolean = true
}
