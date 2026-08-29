package com.example.fintrack;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    /** Talks to BankNotificationService on the Flutter side. */
    private static final String CHANNEL = "fimakyp/notification_access";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        createNotificationChannel();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "isEnabled":
                            result.success(isNotificationAccessGranted());
                            break;
                        case "openSettings":
                            // There is no runtime permission dialog for this
                            // one: the user has to grant it in system settings.
                            openNotificationAccessSettings();
                            result.success(null);
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    private boolean isNotificationAccessGranted() {
        String enabled = Settings.Secure.getString(
                getContentResolver(), "enabled_notification_listeners");
        if (enabled == null || enabled.isEmpty()) return false;
        ComponentName us = new ComponentName(this, BankNotificationListener.class);
        for (String entry : enabled.split(":")) {
            ComponentName component = ComponentName.unflattenFromString(entry);
            if (component != null && component.equals(us)) return true;
        }
        return false;
    }

    private void openNotificationAccessSettings() {
        Intent intent;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        } else {
            intent = new Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS");
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                "fintrack_default",
                "Fimakyp Notificaciones",
                NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("Recordatorios y alertas de Fimakyp");
            channel.enableVibration(true);
            channel.enableLights(true);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }
}
