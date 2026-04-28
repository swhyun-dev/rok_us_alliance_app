import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import { startOfTodayKst } from "../shared/time";

const COMMENT_DAILY_LIMIT = 10;
const COMMENT_REWARD = 5;

/// posts/{postId}/comments/{commentId} 생성 시:
/// 1) post.commentCount += 1
/// 2) 댓글 작성자에게 +5P (일일 한도 10회)
/// 3) 한도 초과 시 카운트만 증가 (사일런트 스킵)
export const onCommentCreated = functions.firestore
  .document("posts/{postId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId as string;
    const commentId = context.params.commentId as string;
    const data = snap.data() ?? {};
    const authorId = data.authorId as string | undefined;

    const db = admin.firestore();
    const postRef = db.collection("posts").doc(postId);

    if (!authorId) {
      // authorId 누락 시에도 카운트는 증가 (시드/관리자 일괄 작성 방어).
      await postRef.update({
        commentCount: admin.firestore.FieldValue.increment(1),
      });
      return;
    }

    // 일일 한도 체크 (KST 기준 자정).
    const start = startOfTodayKst();
    const logs = await db
      .collection("point_logs")
      .where("uid", "==", authorId)
      .where("type", "==", "comment_create")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(start))
      .limit(COMMENT_DAILY_LIMIT)
      .get();

    const overLimit = logs.size >= COMMENT_DAILY_LIMIT;

    const batch = db.batch();
    batch.update(postRef, {
      commentCount: admin.firestore.FieldValue.increment(1),
    });

    if (!overLimit) {
      const logRef = db.collection("point_logs").doc();
      batch.set(logRef, {
        id: logRef.id,
        uid: authorId,
        type: "comment_create",
        amount: COMMENT_REWARD,
        refId: commentId,
        refType: "comment",
        pointsAfter: null,
        levelAfter: null,
        levelChanged: false,
        description: `+${COMMENT_REWARD}P 댓글 작성`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        adjustedBy: null,
        adjustReason: null,
      });

      const userRef = db.collection("users").doc(authorId);
      batch.update(userRef, {
        points: admin.firestore.FieldValue.increment(COMMENT_REWARD),
        "stats.commentsCount": admin.firestore.FieldValue.increment(1),
      });
    }

    await batch.commit();

    if (overLimit) {
      functions.logger.info(
        `댓글 일일 한도 초과 — uid=${authorId}, 카운트만 증가`
      );
    }
  });

