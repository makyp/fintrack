package com.example.fintrack;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.app.PendingIntent;
import android.content.Intent;

import es.antonborri.home_widget.HomeWidgetPlugin;

public class FimakypWidgetProvider extends AppWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int widgetId : appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId);
        }
    }

    static void updateWidget(Context context, AppWidgetManager appWidgetManager, int widgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.fimakyp_widget);

        // Read data saved by Flutter via home_widget (stored in SharedPreferences)
        SharedPreferences prefs = HomeWidgetPlugin.getData(context);
        String expenses  = prefs.getString("widget_expenses",     "$ 0");
        String income    = prefs.getString("widget_income",       "$ 0");
        String date      = prefs.getString("widget_date",         "");
        String topCat    = prefs.getString("widget_top_category", "Sin movimientos hoy");

        views.setTextViewText(R.id.widget_expenses,     expenses);
        views.setTextViewText(R.id.widget_income,       income);
        views.setTextViewText(R.id.widget_date,         date);
        views.setTextViewText(R.id.widget_top_category, topCat);

        // Tap opens the app
        Intent launchIntent = new Intent(context, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_expenses, pendingIntent);
        views.setOnClickPendingIntent(R.id.widget_income,   pendingIntent);

        appWidgetManager.updateAppWidget(widgetId, views);
    }
}
