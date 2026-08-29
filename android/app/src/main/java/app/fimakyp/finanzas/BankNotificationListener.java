package app.fimakyp.finanzas;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Reads the notifications the banking apps post and queues the ones that look
 * like a movement, so the app can offer them as ready-made drafts.
 *
 * This is the cheapest thing there is to automatic capture: the bank already
 * tells the phone about every purchase. There is no aggregation API involved,
 * no cost per user, and nothing leaves the device — the queue is written to
 * the same SharedPreferences file the Flutter side reads.
 *
 * Nothing is ever booked from here. The queue only feeds a screen where the
 * user confirms each movement in the normal form.
 */
public class BankNotificationListener extends NotificationListenerService {

    private static final String TAG = "BankNotifications";

    /** Flutter's shared_preferences file, and its key prefix. */
    private static final String PREFS = "FlutterSharedPreferences";
    private static final String KEY_QUEUE = "flutter.bank_notifications_queue";
    private static final String KEY_ENABLED = "flutter.bank_notifications_enabled";
    private static final String KEY_MUTED = "flutter.bank_notifications_muted";

    /**
     * Cap on the queue. If the app is not opened for a while the oldest ones
     * are dropped: a purchase from three weeks ago is not worth keeping around,
     * and an unbounded list in preferences is a bug waiting to happen.
     */
    private static final int MAX_QUEUED = 100;

    /** An amount written the way banks write it: a currency mark, then digits. */
    private static final Pattern AMOUNT = Pattern.compile(
            "(?:\\$|us\\$|cop|usd|eur|mxn|pen|clp|ars|brl|s/|€|por)\\s*[\\d][\\d.,]*",
            Pattern.CASE_INSENSITIVE);

    /** Mirrors BankNotificationParser: same words, same reasons. */
    private static final String[] MOVEMENT_HINTS = {
            "compra", "pago", "pagaste", "retiro", "retiraste", "enviaste",
            "transferencia", "transferiste", "debito", "cargo", "consumo",
            "avance", "recibiste", "consignacion", "consignaron", "abono",
            "deposito", "depositaron", "devolucion", "reembolso", "te enviaron",
    };

    private static final String[] IGNORE_HINTS = {
            "saldo", "cupo disponible", "codigo", "clave", "otp", "token",
            "promocion", "aprovecha", "felicidades", "sorteo", "cuota de manejo",
            "proximo pago", "vence", "recuerda pagar", "extracto", "intento de",
            "rechazada", "declinada", "no autorizada",
    };

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        try {
            if (sbn == null || sbn.getPackageName() == null) return;
            // Our own reminders are not bank movements.
            if (getPackageName().equals(sbn.getPackageName())) return;

            SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
            if (!prefs.getBoolean(KEY_ENABLED, false)) return;
            if (isMuted(prefs, sbn.getPackageName())) return;

            Bundle extras = sbn.getNotification() == null
                    ? null : sbn.getNotification().extras;
            if (extras == null) return;

            String title = text(extras.getCharSequence("android.title"));
            String body = text(extras.getCharSequence("android.text"));
            if (body.isEmpty()) {
                body = text(extras.getCharSequence("android.bigText"));
            }
            if (body.isEmpty() && title.isEmpty()) return;

            String full = (title + ". " + body).trim();
            if (!looksLikeMovement(full)) return;

            enqueue(prefs, sbn.getPackageName(), title, body, sbn.getPostTime());
        } catch (Exception e) {
            // A listener that crashes gets killed by the system and stops
            // receiving anything — never let one bad notification do that.
            Log.w(TAG, "No se pudo procesar la notificación", e);
        }
    }

    private boolean isMuted(SharedPreferences prefs, String packageName) {
        String muted = prefs.getString(KEY_MUTED, "");
        if (muted == null || muted.isEmpty()) return false;
        for (String entry : muted.split(",")) {
            if (entry.trim().equals(packageName)) return true;
        }
        return false;
    }

    /** Cheap prefilter: an amount, a movement word, and no boilerplate. */
    private boolean looksLikeMovement(String raw) {
        String normalized = normalize(raw);
        for (String hint : IGNORE_HINTS) {
            if (normalized.contains(hint)) return false;
        }
        if (!AMOUNT.matcher(raw).find()) return false;
        for (String hint : MOVEMENT_HINTS) {
            if (normalized.contains(hint)) return true;
        }
        return false;
    }

    private void enqueue(SharedPreferences prefs, String packageName,
                         String title, String body, long postedAt) throws Exception {
        String stored = prefs.getString(KEY_QUEUE, "[]");
        JSONArray queue;
        try {
            queue = new JSONArray(stored == null ? "[]" : stored);
        } catch (Exception e) {
            queue = new JSONArray();
        }

        JSONObject item = new JSONObject();
        item.put("package", packageName);
        item.put("title", title);
        item.put("text", body);
        item.put("postedAt", postedAt);

        // The same purchase often arrives twice (the bank posts an update);
        // keep one.
        String fingerprint = fingerprintOf(packageName, title, body);
        JSONArray next = new JSONArray();
        next.put(item);
        for (int i = 0; i < queue.length() && next.length() < MAX_QUEUED; i++) {
            JSONObject old = queue.optJSONObject(i);
            if (old == null) continue;
            String oldPrint = fingerprintOf(
                    old.optString("package"), old.optString("title"),
                    old.optString("text"));
            if (oldPrint.equals(fingerprint)) continue;
            next.put(old);
        }

        prefs.edit().putString(KEY_QUEUE, next.toString()).apply();
    }

    private static String fingerprintOf(String packageName, String title, String body) {
        return packageName + "|" + normalize(title + ". " + body);
    }

    private static String text(CharSequence value) {
        return value == null ? "" : value.toString().trim();
    }

    private static String normalize(String s) {
        return s.toLowerCase(new Locale("es"))
                .replace('á', 'a').replace('é', 'e').replace('í', 'i')
                .replace('ó', 'o').replace('ú', 'u').replace('ñ', 'n');
    }
}
