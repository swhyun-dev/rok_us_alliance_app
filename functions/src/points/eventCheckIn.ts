import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const CHECK_IN_REWARD = 100;

interface EventCheckInData {
  code?: string;
}

interface EventCheckInResult {
  pointsAwarded: number;
  eventId: string;
  eventTitle: string;
}

/// 사용자가 6자리 코드를 입력해 행사 체크인.
/// 트랜잭션:
///   1) event_codes/{code} 검증 (활성 + 미만료 + 행사 매칭)
///   2) check_ins/{uid_eventId} 신규 생성 (이미 있으면 already-exists 거절)
///   3) point_logs +100P / users.points / stats.eventsAttendedCount
///   4) event_codes.usedCount += 1
export const eventCheckIn = functions.https.onCall(
  async (data: EventCheckInData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const uid = context.auth.uid;
    const code = data.code?.trim();
    if (!code || !/^\d{6}$/.test(code)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "6자리 숫자 코드를 입력해주세요."
      );
    }

    const db = admin.firestore();
    const codeRef = db.collection("event_codes").doc(code);
    const userRef = db.collection("users").doc(uid);

    let eventId = "";
    let eventTitle = "";

    await db.runTransaction(async (tx) => {
      const codeSnap = await tx.get(codeRef);
      if (!codeSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "유효하지 않은 코드입니다."
        );
      }
      const codeData = codeSnap.data() ?? {};
      if (codeData.isActive !== true) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "이미 종료된 코드입니다."
        );
      }
      const expiresAt =
        (codeData.expiresAt as admin.firestore.Timestamp | undefined)?.toMillis();
      if (!expiresAt || expiresAt < Date.now()) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "만료된 코드입니다."
        );
      }

      eventId = codeData.eventId as string;
      const eventRef = db.collection("events").doc(eventId);
      const eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "행사 정보를 찾을 수 없습니다."
        );
      }
      eventTitle = (eventSnap.data()?.title as string | undefined) ?? "";

      const checkInRef = db.collection("check_ins").doc(`${uid}_${eventId}`);
      const existing = await tx.get(checkInRef);
      if (existing.exists) {
        throw new functions.https.HttpsError(
          "already-exists",
          "이미 체크인한 행사입니다."
        );
      }

      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "가입을 마치지 않은 사용자입니다."
        );
      }
      const user = userSnap.data() ?? {};
      if (user.isBanned === true) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "차단된 사용자는 체크인할 수 없습니다."
        );
      }

      // 1) check_ins
      tx.set(checkInRef, {
        id: checkInRef.id,
        uid,
        eventId,
        method: "code",
        codeUsed: code,
        pointsAwarded: CHECK_IN_REWARD,
        giftReceived: false,
        checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
        location: null,
        ipAddress: null,
        uidNickname: user.nickname ?? "",
        eventTitle,
      });

      // 2) point_logs + users.points
      const logRef = db.collection("point_logs").doc();
      tx.set(logRef, {
        id: logRef.id,
        uid,
        type: "event_check_in",
        amount: CHECK_IN_REWARD,
        refId: eventId,
        refType: "event",
        pointsAfter: null,
        levelAfter: null,
        levelChanged: false,
        description: `+${CHECK_IN_REWARD}P 행사 체크인 — ${eventTitle}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        adjustedBy: null,
        adjustReason: null,
      });
      tx.update(userRef, {
        points: admin.firestore.FieldValue.increment(CHECK_IN_REWARD),
        "stats.eventsAttendedCount":
            admin.firestore.FieldValue.increment(1),
      });

      // 3) event_codes.usedCount
      tx.update(codeRef, {
        usedCount: admin.firestore.FieldValue.increment(1),
      });
    });

    const result: EventCheckInResult = {
      pointsAwarded: CHECK_IN_REWARD,
      eventId,
      eventTitle,
    };
    return result;
  }
);
