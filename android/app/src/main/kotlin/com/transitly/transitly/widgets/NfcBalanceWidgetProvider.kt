package com.transitly.transitly.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.transitly.transitly.MainActivity
import com.transitly.transitly.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class NfcBalanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_nfc_balance)

            val balance = widgetData.getString("nfc_balance_v1", null)

            if (balance == null) {
                views.setTextViewText(R.id.widget_nfc_label, "SALDO")
                views.setTextViewText(R.id.widget_nfc_amount, "--,-- €")
                views.setTextViewText(R.id.widget_nfc_updated, "Escanea tu tarjeta en la app")
            } else {
                try {
                    val data = JSONObject(balance)
                    val amount = data.optDouble("balance", 0.0)
                    val scannedAt = data.optLong("scannedAt", 0)
                    views.setTextViewText(R.id.widget_nfc_label, "SALDO")
                    views.setTextViewText(R.id.widget_nfc_amount, String.format("%.2f €", amount))

                    val ageMs = System.currentTimeMillis() - (scannedAt * 1000)
                    val ageHours = ageMs / (1000 * 60 * 60)
                    val ageText = when {
                        ageHours < 1 -> "Actualizado: ahora"
                        ageHours < 24 -> "Actualizado: hace ${ageHours}h"
                        ageHours < 720 -> "Actualizado: hace ${ageHours / 24}d"
                        else -> "Actualizado: hace >30d"
                    }
                    if (ageHours > 720) {
                        views.setTextViewText(R.id.widget_nfc_label, "DESACTUALIZADO")
                    }
                    views.setTextViewText(R.id.widget_nfc_updated, ageText)
                } catch (e: Exception) {
                    views.setTextViewText(R.id.widget_nfc_label, "ERROR")
                    views.setTextViewText(R.id.widget_nfc_amount, "--,-- €")
                    views.setTextViewText(R.id.widget_nfc_updated, "Reintenta en la app")
                }
            }

            val intent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("transitly://home/tarjeta"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
