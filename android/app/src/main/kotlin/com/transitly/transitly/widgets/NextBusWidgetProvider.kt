package com.transitly.transitly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import com.transitly.transitly.MainActivity
import com.transitly.transitly.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import org.json.JSONArray

class NextBusWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val accentColor = loadAccentColor(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_next_bus)

            val favLine = widgetData.getString("widget_fav_line", null)

            if (favLine == null) {
                views.setTextViewText(R.id.widget_route_code, "--")
                views.setTextViewText(R.id.widget_next_time, "Configura tu viaje")
                views.setTextViewText(R.id.widget_stop_name, "Toca para abrir Transitly")
                views.setTextViewText(R.id.widget_summary, "")
                tintBadge(views, R.id.widget_badge_container, Color.parseColor("#977DDF"))
            } else {
                val jsonKey = "next_bus_$favLine"
                val jsonStr = widgetData.getString(jsonKey, null)

                if (jsonStr != null) {
                    try {
                        val data = JSONObject(jsonStr)
                        val time = data.optString("time", "?")
                        val stop = data.optString("stop", "?")
                        views.setTextViewText(R.id.widget_route_code, favLine)
                        views.setTextViewText(R.id.widget_next_time, time)
                        views.setTextViewText(R.id.widget_stop_name, stop)

                        val source = data.optString("source", "")
                        if (source.isNotEmpty()) {
                            views.setTextViewText(R.id.widget_summary, "Fuente: $source")
                        } else {
                            views.setTextViewText(R.id.widget_summary, "")
                        }
                    } catch (e: Exception) {
                        views.setTextViewText(R.id.widget_route_code, favLine)
                        views.setTextViewText(R.id.widget_next_time, "Sin datos")
                        views.setTextViewText(R.id.widget_stop_name, "Actualiza en la app")
                        views.setTextViewText(R.id.widget_summary, "")
                    }
                } else {
                    views.setTextViewText(R.id.widget_route_code, favLine)
                    views.setTextViewText(R.id.widget_next_time, "Cargando...")
                    views.setTextViewText(R.id.widget_stop_name, "Toca para recargar")
                    views.setTextViewText(R.id.widget_summary, "")
                }
                tintBadge(views, R.id.widget_badge_container, accentColor)
            }

            val intent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("transitly://home/inicio"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun loadAccentColor(widgetData: SharedPreferences): Int {
        return try {
            val themeJson = widgetData.getString("theme_v1", null)
            if (themeJson != null) {
                val theme = JSONObject(themeJson)
                val accentHex = theme.optString("accent", "#977DDF")
                Color.parseColor(accentHex)
            } else {
                Color.parseColor("#977DDF")
            }
        } catch (e: Exception) {
            Color.parseColor("#977DDF")
        }
    }

    private fun tintBadge(views: RemoteViews, viewId: Int, color: Int) {
        views.setInt(viewId, "setBackgroundColor", color)
    }
}
