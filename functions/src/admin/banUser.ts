import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface BanUserData {
  uid?: string;
  reason?: string;
  bannedUntil?: number; // epoch ms; null = 영구
}

/// 관리자가 사용자를 차단. users.isBanned/bannedReason/bannedUntil 갱신.
/// rules 의 isNotBanned() 가 다음 쓰기 동작부터 차단을 강제.
export const banUser = functions.https.onCall(
  async (data: BanUserData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const target = data.uid?.trim();
    const reason = data.reason?.trim();

    if (!target || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid / reason 모두 필요합니다."
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

    if (target === adminUid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "자기 자신은 차단할 수 없습니다."
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

    await userRef.update({
      isBanned: true,
      bannedReason: reason,
      bannedUntil: data.bannedUntil
        ? admin.firestore.Timestamp.fromMillis(data.bannedUntil)
        : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 차단 알림 (당사자에게)
    await db.collection("notifications").add({
      uid: target,
      type: "admin_message",
      title: "계정이 일시 차단되었습니다",
      body: `사유: ${reason}`,
      imageUrl: null,
      routeName: null,
      routeParams: null,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      readAt: null,
      fcmSent: false,
      fcmMessageId: null,
    });

    return { success: true };
  }
);

interface UnbanUserData {
  uid?: string;
}

/// 차단 해제.
export const unbanUser = functions.https.onCall(
  async (data: UnbanUserData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const target = data.uid?.trim();
    if (!target) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid 가 필요합니다."
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
    await db.collection("users").doc(target).update({
      isBanned: false,
      bannedReason: null,
      bannedUntil: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true };
  }
);
