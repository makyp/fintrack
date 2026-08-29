package app.fimakyp.finanzas;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.view.View;
import android.widget.RemoteViews;

public class FimakypWidgetProvider extends AppWidgetProvider {

    // home_widget stores data under this preferences name
    private static final String PREFS_NAME = "HomeWidgetPreferences";

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int widgetId : appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId);
        }
    }

    static void updateWidget(Context context, AppWidgetManager appWidgetManager, int widgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.fimakyp_widget);

        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String expenses  = prefs.getString("widget_expenses",     "$ 0");
        String date      = prefs.getString("widget_date",         "");
        String topCat    = prefs.getString("widget_top_category", "");
        String hasData   = prefs.getString("widget_has_data",     "0");

        views.setTextViewText(R.id.widget_date,         date);
        views.setTextViewText(R.id.widget_expenses,     expenses);
        views.setTextViewText(R.id.widget_top_category, topCat);

        // Show content or empty state based on whether there are expenses today
        boolean showContent = "1".equals(hasData);
        views.setViewVisibility(R.id.widget_content, showContent ? View.VISIBLE : View.GONE);
        views.setViewVisibility(R.id.widget_empty,   showContent ? View.GONE   : View.VISIBLE);

        // Tap anywhere opens the app
        Intent launchIntent = new Intent(context, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_content, pendingIntent);
        views.setOnClickPendingIntent(R.id.widget_empty,   pendingIntent);

        appWidgetManager.updateAppWidget(widgetId, views);
    }
}
