import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import { startOfTodayKst } from "../shared/time";

const LIKE_DAILY_LIMIT = 50;
const LIKE_REWARD = 2;

/// posts/{postId}/likes/{uid} 생성 시:
/// 1) post.likeCount += 1
/// 2) author.stats.likesReceivedCount += 1
/// 3) 좋아요 받은 작성자에게 +2P (자기 글 좋아요 제외, 일일 한도 50회)
export const onLikeReceived = functions.firestore
  .document("posts/{postId}/likes/{likerUid}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId as string;
    const likerUid = context.params.likerUid as string;

    const db = admin.firestore();
    const postRef = db.collection("posts").doc(postId);
    const postSnap = await postRef.get();
    const authorId = postSnap.exists
      ? (postSnap.data()?.authorId as string | undefined)
      : undefined;

    const batch = db.batch();
    batch.update(postRef, {
      likeCount: admin.firestore.FieldValue.increment(1),
    });

    // 자기 글 좋아요는 카운트만 증가, 점수 적립 없음.
    if (!authorId || authorId === likerUid) {
      await batch.commit();
      return;
    }

    const start = startOfTodayKst();
    const todayLogs = await db
      .collection("point_logs")
      .where("uid", "==", authorId)
      .where("type", "==", "like_received")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(start))
      .limit(LIKE_DAILY_LIMIT)
      .get();

    const overLimit = todayLogs.size >= LIKE_DAILY_LIMIT;

    if (!overLimit) {
      const logRef = db.collection("point_logs").doc();
      batch.set(logRef, {
        id: logRef.id,
        uid: authorId,
        type: "like_received",
        amount: LIKE_REWARD,
        refId: postId,
        refType: "post",
        pointsAfter: null,
        levelAfter: null,
        levelChanged: false,
        description: `+${LIKE_REWARD}P 좋아요 받음`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        adjustedBy: null,
        adjustReason: null,
      });

      const userRef = db.collection("users").doc(authorId);
      batch.update(userRef, {
        points: admin.firestore.FieldValue.increment(LIKE_REWARD),
        "stats.likesReceivedCount": admin.firestore.FieldValue.increment(1),
      });
    } else {
      // 한도 초과 — stats 카운트는 유지(누적 추적용).
      const userRef = db.collection("users").doc(authorId);
      batch.update(userRef, {
        "stats.likesReceivedCount": admin.firestore.FieldValue.increment(1),
      });
      functions.logger.info(
        `좋아요 일일 한도(${LIKE_DAILY_LIMIT}) 초과 — uid=${authorId}, 점수 적립 스킵`
      );
    }

    await batch.commit();
    void snap;
  });

/// posts/{postId}/likes/{uid} 삭제(언라이크) 시 likeCount 감소만.
/// 적립된 점수는 회수하지 않음(어뷰징 부담 < 정합성 부담).
export const onLikeRemoved = functions.firestore
  .document("posts/{postId}/likes/{likerUid}")
  .onDelete(async (_snap, context) => {
    const postId = context.params.postId as string;
    const db = admin.firestore();
    await db.collection("posts").doc(postId).update({
      likeCount: admin.firestore.FieldValue.increment(-1),
    });
  });
