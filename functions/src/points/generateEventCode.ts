import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface GenerateEventCodeData {
  eventId?: string;
}

interface GenerateEventCodeResult {
  code: string;
  expiresAt: number; // epoch ms
}

const CODE_TTL_MS = 10 * 60 * 1000; // 10분

/// 관리자가 행사용 6자리 체크인 코드를 발급. event_codes/{code} 생성.
/// 충돌 시 재시도. context.auth 에 admin claim 또는 admins 컬렉션 멤버십 확인.
export const generateEventCode = functions.https.onCall(
  async (data: GenerateEventCodeData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const eventId = data.eventId;
    if (!eventId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "eventId required"
      );
    }

    const db = admin.firestore();

    // 관리자 권한 확인 — admins/{uid} 문서 존재 여부.
    const adminDoc = await db.collection("admins").doc(adminUid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "관리자만 코드를 발급할 수 있습니다."
      );
    }

    // event 존재 확인.
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (!eventDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "행사를 찾을 수 없습니다."
      );
    }

    // 6자리 코드 생성. 충돌 시 최대 5회 재시도.
    let code = "";
    for (let attempt = 0; attempt < 5; attempt++) {
      const candidate = _generateSixDigitCode();
      const exists = await db
        .collection("event_codes")
        .doc(candidate)
        .get();
      if (!exists.exists) {
        code = candidate;
        break;
      }
    }
    if (!code) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "코드 생성에 실패했습니다. 잠시 후 다시 시도해주세요."
      );
    }

    const expiresAtMs = Date.now() + CODE_TTL_MS;
    await db.collection("event_codes").doc(code).set({
      code,
      eventId,
      createdBy: adminUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMs),
      usedCount: 0,
      isActive: true,
    });

    const result: GenerateEventCodeResult = {
      code,
      expiresAt: expiresAtMs,
    };
    return result;
  }
);

function _generateSixDigitCode(): string {
  const n = Math.floor(Math.random() * 1000000);
  return n.toString().padStart(6, "0");
}
