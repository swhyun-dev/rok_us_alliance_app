import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/// users/{uid} 문서가 생성될 때 한 번 실행.
/// - point_logs 에 welcome 로그
/// - users.points 를 0 → 50
/// - notifications 에 환영 알림
/// 모두 단일 batch 로 원자성 보장.
export const onUserCreated = functions.firestore
  .document("users/{uid}")
  .onCreate(async (snap, context) => {
    const uid = context.params.uid as string;
    const user = snap.data() ?? {};
    const db = admin.firestore();

    const batch = db.batch();

    const logRef = db.collection("point_logs").doc();
    batch.set(logRef, {
      id: logRef.id,
      uid,
      type: "welcome",
      amount: 50,
      refId: null,
      refType: null,
      pointsAfter: 50,
      levelAfter: 1,
      levelChanged: false,
      description: "한미동맹단 가입을 환영합니다! +50P",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      adjustedBy: null,
      adjustReason: null,
    });

    batch.update(snap.ref, {
      points: 50,
    });

    const notifRef = db.collection("notifications").doc();
    batch.set(notifRef, {
      id: notifRef.id,
      uid,
      type: "point_awarded",
      title: "+50P 환영 보너스",
      body: "한미동맹단 가입을 환영합니다!",
      imageUrl: null,
      routeName: "/profile/points",
      routeParams: null,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      readAt: null,
      fcmSent: false,
      fcmMessageId: null,
    });

    await batch.commit();

    // 추천인이 있으면 별도 처리(추천인 +200P)는 W3.x onReferralComplete 로 분리.
    if (user.referredBy) {
      functions.logger.info(
        `referredBy=${user.referredBy} 추천 보상은 onReferralComplete 에서 처리`
      );
    }
  });
