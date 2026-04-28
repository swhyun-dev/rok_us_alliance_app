import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import { startOfTodayKst } from "../shared/time";

const POST_DAILY_LIMIT = 3;
const POST_REWARD = 30;

/// posts/{postId} 생성 시 작성자에게 +30P (KST 자정 기준 일일 3회 한도).
/// 한도 초과 시 사일런트 스킵 — point_logs, users.points 미갱신.
export const onPostCreated = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId as string;
    const data = snap.data() ?? {};
    const authorId = data.authorId as string | undefined;

    if (!authorId) {
      functions.logger.warn(
        `posts/${postId} 생성됐지만 authorId 가 비어있어 점수 적립 스킵`
      );
      return;
    }

    if (data.isDeleted === true) {
      // 비정상 케이스 — 생성 즉시 isDeleted=true.
      return;
    }

    const db = admin.firestore();
    const start = startOfTodayKst();

    const todayLogs = await db
      .collection("point_logs")
      .where("uid", "==", authorId)
      .where("type", "==", "post_create")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(start))
      .limit(POST_DAILY_LIMIT)
      .get();

    if (todayLogs.size >= POST_DAILY_LIMIT) {
      functions.logger.info(
        `게시글 일일 한도(${POST_DAILY_LIMIT}) 초과 — uid=${authorId}, post=${postId}`
      );
      return;
    }

    const batch = db.batch();

    const logRef = db.collection("point_logs").doc();
    batch.set(logRef, {
      id: logRef.id,
      uid: authorId,
      type: "post_create",
      amount: POST_REWARD,
      refId: postId,
      refType: "post",
      pointsAfter: null,
      levelAfter: null,
      levelChanged: false,
      description: `+${POST_REWARD}P 게시글 작성`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      adjustedBy: null,
      adjustReason: null,
    });

    const userRef = db.collection("users").doc(authorId);
    batch.update(userRef, {
      points: admin.firestore.FieldValue.increment(POST_REWARD),
      "stats.postsCount": admin.firestore.FieldValue.increment(1),
    });

    await batch.commit();
  });
