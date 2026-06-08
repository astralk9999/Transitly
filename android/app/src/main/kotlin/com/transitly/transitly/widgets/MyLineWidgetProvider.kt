package com.transitly.transitly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.transitly.transitly.MainActivity
import com.transitly.transitly.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import org.json.JSONArray

class MyLineWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val accentColor = loadAccentColor(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_my_line)

            val routeCode = widgetData.getString("widget_my_line", null)

            if (routeCode == null) {
                views.setTextViewText(R.id.widget_line_code, "--")
                views.setTextViewText(R.id.widget_line_status, "Configura tu línea favorita")
                views.setTextViewText(R.id.widget_line_updated, "Toca para abrir Transitly")
                views.setTextViewText(R.id.widget_time_1, "--:--")
                views.setTextViewText(R.id.widget_time_2, "--:--")
                views.setTextViewText(R.id.widget_time_3, "--:--")
                tintBadge(views, R.id.widget_line_code, Color.parseColor("#977DDF"))
            } else {
                val jsonKey = "line_status_$routeCode"
                val jsonStr = widgetData.getString(jsonKey, null)

                views.setTextViewText(R.id.widget_line_code, routeCode)

                if (jsonStr != null) {
                    try {
                        val data = JSONObject(jsonStr)
                        val status = data.optString("status", "Sin datos")
                        val summary = data.optString("summary", "")
                        val updatedLabel = data.optString("updatedLabel", "")
                        views.setTextViewText(R.id.widget_line_status, status)
                        // Resumen de próximas + última actualización, para que se
                        // vea la frescura del dato.
                        val footer = if (updatedLabel.isNotEmpty()) {
                            if (summary.isNotEmpty()) "$summary  ·  act. $updatedLabel"
                            else "Actualizado $updatedLabel"
                        } else {
                            summary
                        }
                        views.setTextViewText(R.id.widget_line_updated, footer)

                        val upcoming = data.optJSONArray("upcoming")
                        populateTimes(views, upcoming)
                    } catch (e: Exception) {
                        views.setTextViewText(R.id.widget_line_status, "Error")
                        views.setTextViewText(R.id.widget_line_updated, "Reintenta en la app")
                        views.setTextViewText(R.id.widget_time_1, "--:--")
                        views.setTextViewText(R.id.widget_time_2, "--:--")
                        views.setTextViewText(R.id.widget_time_3, "--:--")
                    }
                } else {
                    views.setTextViewText(R.id.widget_line_status, "Cargando...")
                    views.setTextViewText(R.id.widget_line_updated, "Toca para recargar")
                    views.setTextViewText(R.id.widget_time_1, "--:--")
                    views.setTextViewText(R.id.widget_time_2, "--:--")
                    views.setTextViewText(R.id.widget_time_3, "--:--")
                }
                tintBadge(views, R.id.widget_line_code, accentColor)
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

    private fun populateTimes(views: RemoteViews, upcoming: JSONArray?) {
        val times = arrayOf(R.id.widget_time_1, R.id.widget_time_2, R.id.widget_time_3)

        for (i in times.indices) {
            if (upcoming != null && i < upcoming.length()) {
                try {
                    val item = upcoming.getJSONObject(i)
                    val time = item.optString("time", "--:--")
                    views.setTextViewText(times[i], time)
                    views.setViewVisibility(times[i], View.VISIBLE)
                } catch (e: Exception) {
                    views.setTextViewText(times[i], "--:--")
                    views.setViewVisibility(times[i], View.VISIBLE)
                }
            } else {
                views.setViewVisibility(times[i], View.GONE)
            }
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
        // The route code is inside a FrameLayout with widget_route_badge_bg.
        // We tint the badge container by setting its background color.
        // For the line_code text, we already have it as a child of the FrameLayout.
    }
}
