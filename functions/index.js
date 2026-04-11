const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function nextDueDate(date, frequency) {
  const d = date.toDate();
  switch (frequency) {
    case "daily":   d.setDate(d.getDate() + 1); break;
    case "weekly":  d.setDate(d.getDate() + 7); break;
    case "biweekly":d.setDate(d.getDate() + 14); break;
    case "monthly": d.setMonth(d.getMonth() + 1); break;
    case "yearly":  d.setFullYear(d.getFullYear() + 1); break;
  }
  return Timestamp.fromDate(d);
}

function startOfDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

// ─── UC-24: Actualizar racha al crear transacción ─────────────────────────────
exports.onTransactionCreated = onDocumentCreated(
  { document: "users/{userId}/transactions/{txId}", region: "us-central1" },
  async (event) => {
    const userId = event.params.userId;
    const userRef = db.collection("users").doc(userId);

    const userSnap = await userRef.get();
    const data = userSnap.data() || {};

    const today = startOfDay(new Date());
    const lastActivity = data.lastActivityDate?.toDate();
    const lastDay = lastActivity ? startOfDay(lastActivity) : null;

    let currentStreak = data.currentStreak || 0;
    const longestStreak = data.longestStreak || 0;
    const txCount = (data.txCount || 0) + 1;

    if (!lastDay) {
      currentStreak = 1;
    } else {
      const diffDays = Math.round((today - lastDay) / 86400000);
      if (diffDays === 0) {
        // Same day — don't change streak, but still count tx
      } else if (diffDays === 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    }

    const newLongest = Math.max(longestStreak, currentStreak);

    const batch = db.batch();
    batch.set(userRef, {
      currentStreak,
      longestStreak: newLongest,
      lastActivityDate: Timestamp.fromDate(today),
      txCount,
    }, { merge: true });

    // ── Badge evaluation ──────────────────────────────────────────────────
    const badgesCol = userRef.collection("badges");
    const badgeCriteria = [
      { id: "first_tx",   met: txCount >= 1 },
      { id: "tx_10",      met: txCount >= 10 },
      { id: "tx_50",      met: txCount >= 50 },
      { id: "tx_100",     met: txCount >= 100 },
      { id: "streak_3",   met: currentStreak >= 3 },
      { id: "streak_7",   met: currentStreak >= 7 },
      { id: "streak_30",  met: currentStreak >= 30 },
    ];

    for (const badge of badgeCriteria) {
      if (!badge.met) continue;
      const badgeRef = badgesCol.doc(badge.id);
      const snap = await badgeRef.get();
      if (!snap.exists) {
        batch.set(badgeRef, { badgeId: badge.id, earnedAt: Timestamp.now() });
      }
    }

    await batch.commit();
    console.log(`onTransactionCreated: userId=${userId} streak=${currentStreak} txCount=${txCount}`);
  }
);

// ─── UC-24: Badge al crear meta ───────────────────────────────────────────────
exports.onGoalCreated = onDocumentCreated(
  { document: "users/{userId}/goals/{goalId}", region: "us-central1" },
  async (event) => {
    const userId = event.params.userId;
    const badgeRef = db.collection("users").doc(userId)
      .collection("badges").doc("first_goal");
    const snap = await badgeRef.get();
    if (!snap.exists) {
      await badgeRef.set({ badgeId: "first_goal", earnedAt: Timestamp.now() });
      console.log(`onGoalCreated: awarded first_goal to ${userId}`);
    }
  }
);

// ─── UC-24: Badge al completar meta ──────────────────────────────────────────
exports.onGoalUpdated = onDocumentUpdated(
  { document: "users/{userId}/goals/{goalId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.isCompleted || !after.isCompleted) return;

    const userId = event.params.userId;
    const badgeRef = db.collection("users").doc(userId)
      .collection("badges").doc("goal_completed");
    const snap = await badgeRef.get();
    if (!snap.exists) {
      await badgeRef.set({ badgeId: "goal_completed", earnedAt: Timestamp.now() });
      console.log(`onGoalUpdated: awarded goal_completed to ${userId}`);
    }
  }
);

// ─── UC-24: Badge al crear transacción recurrente ─────────────────────────────
exports.onRecurringCreated = onDocumentCreated(
  { document: "users/{userId}/recurring_transactions/{rtId}", region: "us-central1" },
  async (event) => {
    const userId = event.params.userId;
    const badgeRef = db.collection("users").doc(userId)
      .collection("badges").doc("first_recurring");
    const snap = await badgeRef.get();
    if (!snap.exists) {
      await badgeRef.set({ badgeId: "first_recurring", earnedAt: Timestamp.now() });
      console.log(`onRecurringCreated: awarded first_recurring to ${userId}`);
    }
  }
);

// ─── UC-25/26: Notificación push al ganar un logro ───────────────────────────
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

    // Write in-app notification
    await db.collection("users").doc(userId)
      .collection("notifications").add({
        title: label.title,
        body: label.body,
        type: "badge",
        data: { badgeId },
        read: false,
        createdAt: Timestamp.now(),
      });

    // Push notification
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

    console.log(`onBadgeCreated: sent badge=${badgeId} to userId=${userId}`);
  }
);

// ─── UC-16: Procesar transacciones recurrentes (00:05 UTC diario) ─────────────
exports.processRecurringTransactions = onSchedule(
  { schedule: "5 0 * * *", timeZone: "UTC", region: "us-central1" },
  async () => {
    const today = startOfDay(new Date());
    const todayTs = Timestamp.fromDate(today);

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const col = db.collection("users").doc(userId)
        .collection("recurring_transactions");

      const rtsSnap = await col
        .where("isActive", "==", true)
        .where("nextDueDate", "<=", todayTs)
        .get();

      if (rtsSnap.empty) continue;

      const batch = db.batch();

      for (const rtDoc of rtsSnap.docs) {
        const rt = rtDoc.data();

        const txRef = db.collection("users").doc(userId)
          .collection("transactions").doc();

        const tx = {
          userId,
          amount: rt.amount,
          type: rt.type,
          category: rt.category,
          accountId: rt.accountId,
          description: rt.description,
          date: todayTs,
          isRecurring: true,
          tags: [],
          createdAt: Timestamp.now(),
        };
        if (rt.toAccountId) tx.toAccountId = rt.toAccountId;
        batch.set(txRef, tx);

        const accountRef = db.collection("users").doc(userId)
          .collection("accounts").doc(rt.accountId);
        const delta = rt.type === "expense" ? -rt.amount
          : rt.type === "income" ? rt.amount : -rt.amount;
        batch.update(accountRef, {
          balance: require("firebase-admin/firestore").FieldValue.increment(delta),
        });

        const next = nextDueDate(rt.nextDueDate, rt.frequency);
        const shouldDeactivate = rt.endDate && next.toDate() > rt.endDate.toDate();
        batch.update(rtDoc.ref, {
          nextDueDate: next,
          isActive: !shouldDeactivate,
        });
      }

      await batch.commit();
    }

    console.log("processRecurringTransactions: done");
  }
);

// ─── UC-17: Notificaciones 3 días antes del vencimiento (09:00 UTC diario) ────
exports.sendDueDateNotifications = onSchedule(
  { schedule: "0 9 * * *", timeZone: "UTC", region: "us-central1" },
  async () => {
    const in3 = new Date();
    in3.setDate(in3.getDate() + 3);
    const start = Timestamp.fromDate(startOfDay(in3));
    const end = Timestamp.fromDate(
      new Date(in3.getFullYear(), in3.getMonth(), in3.getDate() + 1)
    );

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;

      const rtsSnap = await db.collection("users").doc(userId)
        .collection("recurring_transactions")
        .where("isActive", "==", true)
        .where("nextDueDate", ">=", start)
        .where("nextDueDate", "<", end)
        .get();

      if (rtsSnap.empty) continue;

      const tokensSnap = await db.collection("users").doc(userId)
        .collection("fcm_tokens").get();
      const tokens = tokensSnap.docs.map((d) => d.id);
      if (tokens.length === 0) continue;

      for (const rtDoc of rtsSnap.docs) {
        const rt = rtDoc.data();
        const label = rt.type === "expense" ? "Gasto recurrente" : "Ingreso recurrente";
        const title = `${label} próximo a vencer`;
        const body = `"${rt.description}" vence en 3 días — $${rt.amount.toLocaleString()}`;

        // In-app notification
        await db.collection("users").doc(userId)
          .collection("notifications").add({
            title,
            body,
            type: "recurring",
            data: { recurringId: rtDoc.id, rtType: rt.type },
            read: false,
            createdAt: Timestamp.now(),
          });

        // Push notification
        await getMessaging().sendEachForMulticast({
          tokens,
          notification: { title, body },
          data: { recurringId: rtDoc.id, type: rt.type },
        });
      }
    }

    console.log("sendDueDateNotifications: done");
  }
);

// ─── Alto rendimiento: acreditar interés diario (00:01 UTC) ───────────────────
// Calcula interés diario = saldo * (tasaEA / 365) y crea una transacción
// de tipo ingreso en la cuenta de alto rendimiento una vez al día.
exports.creditHighYieldInterest = onSchedule(
  { schedule: "1 0 * * *", timeZone: "UTC", region: "us-central1" },
  async () => {
    const { FieldValue } = require("firebase-admin/firestore");
    const today = startOfDay(new Date());
    const todayTs = Timestamp.fromDate(today);

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const accountsSnap = await db
        .collection("users").doc(userId)
        .collection("accounts")
        .where("type", "==", "highYield")
        .where("isArchived", "==", false)
        .get();

      if (accountsSnap.empty) continue;

      const batch = db.batch();

      for (const accDoc of accountsSnap.docs) {
        const acc = accDoc.data();
        const annualRate = acc.interestRate;
        if (!annualRate || annualRate <= 0) continue;

        const balance = acc.balance || 0;
        if (balance <= 0) continue;

        // Interés diario = saldo * (tasa EA / 365)
        const dailyInterest = Math.round(balance * (annualRate / 365));
        if (dailyInterest < 1) continue;

        // Crear transacción de ingreso
        const txRef = db
          .collection("users").doc(userId)
          .collection("transactions").doc();

        batch.set(txRef, {
          userId,
          amount: dailyInterest,
          type: "income",
          category: "investment",
          accountId: accDoc.id,
          description: `Interés diario 🏆 ${acc.name}`,
          date: todayTs,
          isRecurring: false,
          tags: ["interes", "alto-rendimiento"],
          createdAt: Timestamp.now(),
        });

        // Actualizar saldo de la cuenta
        batch.update(accDoc.ref, {
          balance: FieldValue.increment(dailyInterest),
        });
      }

      await batch.commit();
    }

    console.log("creditHighYieldInterest: done");
  }
);
