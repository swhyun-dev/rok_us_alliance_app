import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface AdjustPointsData {
  uid?: string;
  amount?: number;
  reason?: string;
}

/// 관리자가 특정 사용자의 활동 점수를 가감.
/// batch: users.points += amount + point_logs(admin_adjust) 기록.
/// recalculateLevel 트리거가 후속으로 등급 재산출.
export const adjustPoints = functions.https.onCall(
  async (data: AdjustPointsData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const target = data.uid?.trim();
    const amount = data.amount;
    const reason = data.reason?.trim();

    if (!target || amount === undefined || amount === 0 || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid / amount / reason 모두 필요합니다 (amount != 0)."
      );
    }

    const db = admin.firestore();
    const adminDoc = await db.collection("admins").doc(adminUid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "관리자만 수행할 수 있습니다."
      );
    }

    const userRef = db.collection("users").doc(target);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "대상 사용자를 찾을 수 없습니다."
      );
    }

    const batch = db.batch();
    batch.update(userRef, {
      points: admin.firestore.FieldValue.increment(amount),
    });
    const logRef = db.collection("point_logs").doc();
    batch.set(logRef, {
      id: logRef.id,
      uid: target,
      type: "admin_adjust",
      amount,
      refId: null,
      refType: null,
      pointsAfter: null,
      levelAfter: null,
      levelChanged: false,
      description: amount > 0
        ? `+${amount}P 관리자 조정 — ${reason}`
        : `${amount}P 관리자 조정 — ${reason}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      adjustedBy: adminUid,
      adjustReason: reason,
    });
    await batch.commit();

    return { success: true, amount };
  }
);
