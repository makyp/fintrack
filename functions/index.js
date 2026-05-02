// ─────────────────────────────────────────────────────────────────────────────
// Fimakyp – Cloud Functions (Firebase Blaze plan required to deploy)
//
// Todo lo que estaba aquí ha sido migrado al cliente Flutter:
//
//  onTransactionCreated   → BadgeService.onTransactionAdded() en el cliente
//  onGoalCreated          → BadgeService en el cliente
//  onGoalUpdated          → BadgeService en el cliente
//  onRecurringCreated     → BadgeService en el cliente
//  onBadgeCreated         → in-app notifications (NotificationsCubit) ✅ ya funciona
//                           push FCM ❌ PENDIENTE – requiere Blaze
//
//  processRecurringTransactions → AppStartupService._processRecurring() ✅
//  sendDueDateNotifications     → LocalNotificationService.scheduleDueDateAlerts() ✅
//  creditHighYieldInterest      → AppStartupService._creditInterest() ✅
//
// ─── PENDIENTE (solo necesita Blaze) ─────────────────────────────────────────
//
//  Push FCM al ganar un logro  → requiere onBadgeCreated + Firebase Messaging
//
// Para activarlo cuando tengas Blaze:
//   1. firebase use --add fintrack-6b6d4
//   2. Descomentar el bloque de abajo
//   3. firebase deploy --only functions --project fintrack-6b6d4
//
// ─────────────────────────────────────────────────────────────────────────────

/*
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

const BADGE_LABELS = {
  first_tx:       { title: "🏅 ¡Primer registro!", body: "Registraste tu primera transacción." },
  tx_10:          { title: "🔥 ¡10 transacciones!", body: "Llevas 10 movimientos registrados." },
  tx_50:          { title: "💪 ¡50 transacciones!", body: "¡Eres constante! 50 movimientos registrados." },
  tx_100:         { title: "🎖️ ¡100 transacciones!", body: "Leyenda. 100 transacciones en FinTrack." },
  streak_3:       { title: "🔥 Racha de 3 días", body: "¡3 días seguidos registrando! Sigue así." },
  streak_7:       { title: "⚡ Racha de 7 días", body: "¡Una semana sin fallar! Increíble." },
  streak_30:      { title: "🏆 Racha de 30 días", body: "¡30 días consecutivos! Eres imparable." },
  first_goal:     { title: "🎯 Primera meta", body: "Creaste tu primera meta de ahorro." },
  goal_completed: { title: "✅ Meta cumplida", body: "¡Alcanzaste una meta de ahorro!" },
  first_recurring:{ title: "🔄 Primer recurrente", body: "Configuraste tu primer pago recurrente." },
};

exports.onBadgeCreated = onDocumentCreated(
  { document: "users/{userId}/badges/{badgeId}", region: "us-central1" },
  async (event) => {
    const { userId, badgeId } = event.params;
    const label = BADGE_LABELS[badgeId];
    if (!label) return;

    const tokensSnap = await db.collection("users").doc(userId)
      .collection("fcm_tokens").get();
    const tokens = tokensSnap.docs.map((d) => d.id).filter(Boolean);
    if (tokens.length === 0) return;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: label.title, body: label.body },
      data: { type: "badge", badgeId },
      android: { notification: { channelId: "badges" } },
      apns: { payload: { aps: { sound: "default" } } },
    });
  }
);
*/
