import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const PETITION_REWARD = 50;

interface SignPetitionData {
  petitionId?: string;
}

interface SignPetitionResult {
  pointsAwarded: number;
  currentCount: number;
  milestoneReached: number | null; // 50 / 100 / null
}

/// 청원 서명 호출형 함수.
/// 트랜잭션:
///   1) signatures/{uid} 신규 생성 (이미 있으면 already-exists 거절)
///   2) petition.currentCount += 1
///   3) point_logs +50P / users.points +=50 / stats.petitionsSignedCount +=1
///   4) 50% / 100% 마일스톤 도달 시 notifications 추가 (작성자 식별 어려워
///      서명자 본인에게 마일스톤 알림 — 운영 정책상 단순화)
///
/// 반환: { pointsAwarded, currentCount, milestoneReached }
export const signPetition = functions.https.onCall(
  async (data: SignPetitionData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const uid = context.auth.uid;
    const petitionId = data.petitionId;
    if (!petitionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "petitionId required"
      );
    }

    const db = admin.firestore();
    const petitionRef = db.collection("petitions").doc(petitionId);
    const sigRef = petitionRef.collection("signatures").doc(uid);
    const userRef = db.collection("users").doc(uid);

    let milestoneReached: number | null = null;
    let nextCount = 0;

    await db.runTransaction(async (tx) => {
      const petitionSnap = await tx.get(petitionRef);
      if (!petitionSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "청원을 찾을 수 없습니다."
        );
      }
      const petition = petitionSnap.data() ?? {};
      if (petition.status !== "active") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "이미 종료된 청원입니다."
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
          "차단된 사용자는 서명할 수 없습니다."
        );
      }

      const existing = await tx.get(sigRef);
      if (existing.exists) {
        throw new functions.https.HttpsError(
          "already-exists",
          "이미 서명한 청원입니다."
        );
      }

      const targetCount = (petition.targetCount as number | undefined) ?? 0;
      const currentCount =
        (petition.currentCount as number | undefined) ?? 0;
      nextCount = currentCount + 1;

      // 마일스톤 결정 (이전엔 미달, 이번 서명으로 도달).
      if (targetCount > 0) {
        const prevPct = (currentCount / targetCount) * 100;
        const nextPct = (nextCount / targetCount) * 100;
        if (prevPct < 100 && nextPct >= 100) milestoneReached = 100;
        else if (prevPct < 50 && nextPct >= 50) milestoneReached = 50;
      }

      // 1) signatures/{uid}
      tx.set(sigRef, {
        uid,
        petitionId,
        signedAt: admin.firestore.FieldValue.serverTimestamp(),
        pointsAwarded: PETITION_REWARD,
        signerNickname: user.nickname ?? "",
        signerLevel: user.level ?? 1,
      });

      // 2) petition.currentCount
      const updates: Record<string, unknown> = {
        currentCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (milestoneReached === 100) {
        updates.status = "completed";
        updates.completedAt = admin.firestore.FieldValue.serverTimestamp();
      }
      tx.update(petitionRef, updates);

      // 3) point_logs / users.points / stats
      const logRef = db.collection("point_logs").doc();
      tx.set(logRef, {
        id: logRef.id,
        uid,
        type: "petition_sign",
        amount: PETITION_REWARD,
        refId: petitionId,
        refType: "petition",
        pointsAfter: null,
        levelAfter: null,
        levelChanged: false,
        description: `+${PETITION_REWARD}P 청원 서명`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        adjustedBy: null,
        adjustReason: null,
      });
      tx.update(userRef, {
        points: admin.firestore.FieldValue.increment(PETITION_REWARD),
        "stats.petitionsSignedCount": admin.firestore.FieldValue.increment(1),
      });

      // 4) 마일스톤 알림 (서명한 본인)
      if (milestoneReached !== null) {
        const notifRef = db.collection("notifications").doc();
        tx.set(notifRef, {
          id: notifRef.id,
          uid,
          type: "petition_milestone",
          title: `청원 ${milestoneReached}% 달성`,
          body: `방금 서명한 청원이 ${milestoneReached}% 에 도달했습니다.`,
          imageUrl: null,
          routeName: "/petition",
          routeParams: { petitionId },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          readAt: null,
          fcmSent: false,
          fcmMessageId: null,
        });
      }
    });

    const result: SignPetitionResult = {
      pointsAwarded: PETITION_REWARD,
      currentCount: nextCount,
      milestoneReached,
    };
    return result;
  }
);
