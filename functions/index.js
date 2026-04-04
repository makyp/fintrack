const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Calcula la siguiente fecha según la frecuencia */
function nextDueDate(date, frequency) {
  const d = date.toDate();
  switch (frequency) {
    case "daily":
      d.setDate(d.getDate() + 1);
      break;
    case "weekly":
      d.setDate(d.getDate() + 7);
      break;
    case "biweekly":
      d.setDate(d.getDate() + 14);
      break;
    case "monthly":
      d.setMonth(d.getMonth() + 1);
      break;
    case "yearly":
      d.setFullYear(d.getFullYear() + 1);
      break;
  }
  return Timestamp.fromDate(d);
}

function startOfDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

// ─── UC-16: Procesar transacciones recurrentes (00:05 UTC diario) ─────────────
exports.processRecurringTransactions = onSchedule(
  { schedule: "5 0 * * *", timeZone: "UTC", region: "us-central1" },
  async () => {
    const today = startOfDay(new Date());
    const todayTs = Timestamp.fromDate(today);

    const usersSnap = await db.collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const userId = userDoc.id;
      const col = db
        .collection("users")
        .doc(userId)
        .collection("recurring_transactions");

      const rtsSnap = await col
        .where("isActive", "==", true)
        .where("nextDueDate", "<=", todayTs)
        .get();

      if (rtsSnap.empty) continue;

      const batch = db.batch();

      for (const rtDoc of rtsSnap.docs) {
        const rt = rtDoc.data();

        // Crear la transacción
        const txRef = db
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .doc();

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

        // Actualizar el saldo de la cuenta
        const accountRef = db
          .collection("users")
          .doc(userId)
          .collection("accounts")
          .doc(rt.accountId);
        const delta =
          rt.type === "expense"
            ? -rt.amount
            : rt.type === "income"
            ? rt.amount
            : -rt.amount;
        batch.update(accountRef, {
          balance: require("firebase-admin/firestore").FieldValue.increment(delta),
        });

        // Avanzar nextDueDate
        const next = nextDueDate(rt.nextDueDate, rt.frequency);
        const shouldDeactivate =
          rt.endDate && next.toDate() > rt.endDate.toDate();
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

      const rtsSnap = await db
        .collection("users")
        .doc(userId)
        .collection("recurring_transactions")
        .where("isActive", "==", true)
        .where("nextDueDate", ">=", start)
        .where("nextDueDate", "<", end)
        .get();

      if (rtsSnap.empty) continue;

      // Obtener tokens FCM del usuario
      const tokensSnap = await db
        .collection("users")
        .doc(userId)
        .collection("fcm_tokens")
        .get();
      const tokens = tokensSnap.docs.map((d) => d.id);
      if (tokens.length === 0) continue;

      for (const rtDoc of rtsSnap.docs) {
        const rt = rtDoc.data();
        const label =
          rt.type === "expense" ? "Gasto recurrente" : "Ingreso recurrente";

        await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: `${label} próximo a vencer`,
            body: `"${rt.description}" vence en 3 días — $${rt.amount.toLocaleString()}`,
          },
          data: { recurringId: rtDoc.id, type: rt.type },
        });
      }
    }

    console.log("sendDueDateNotifications: done");
  }
);
