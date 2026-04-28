import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/// 5분마다 각 컬렉션 카운트를 집계해 app_meta/stats 단일 문서를 갱신.
/// 홈 HeroStatsSection 카운터의 데이터 소스.
export const updateAppStats = functions.pubsub
  .schedule("every 5 minutes")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();

    // 각 카운트는 count() aggregation 으로 집계 (low cost).
    const [
      usersAgg,
      petitionsAgg,
      eventsAgg,
      postsAgg,
      commentsAgg,
      signaturesAgg,
    ] = await Promise.all([
      db.collection("users").count().get(),
      db
        .collection("petitions")
        .where("status", "==", "active")
        .count()
        .get(),
      _eventsThisMonthCount(db),
      db
        .collection("posts")
        .where("isDeleted", "==", false)
        .count()
        .get(),
      db.collectionGroup("comments").count().get(),
      db.collectionGroup("signatures").count().get(),
    ]);

    await db.doc("app_meta/stats").set(
      {
        memberCount: usersAgg.data().count,
        activePetitions: petitionsAgg.data().count,
        monthlyEvents: eventsAgg,
        totalPosts: postsAgg.data().count,
        totalComments: commentsAgg.data().count,
        totalSignatures: signaturesAgg.data().count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    functions.logger.info(
      `[updateAppStats] members=${usersAgg.data().count} ` +
        `activePetitions=${petitionsAgg.data().count} ` +
        `monthlyEvents=${eventsAgg}`
    );
  });

async function _eventsThisMonthCount(
  db: admin.firestore.Firestore
): Promise<number> {
  const now = new Date();
  const utcMs = now.getTime();
  const kstNow = new Date(utcMs + 9 * 60 * 60 * 1000);
  const startKst = new Date(
    Date.UTC(kstNow.getUTCFullYear(), kstNow.getUTCMonth(), 1, 0, 0, 0, 0)
  );
  const endKst = new Date(
    Date.UTC(kstNow.getUTCFullYear(), kstNow.getUTCMonth() + 1, 1, 0, 0, 0, 0)
  );
  const startUtc = new Date(startKst.getTime() - 9 * 60 * 60 * 1000);
  const endUtc = new Date(endKst.getTime() - 9 * 60 * 60 * 1000);

  const agg = await db
    .collection("events")
    .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(startUtc))
    .where("eventDate", "<", admin.firestore.Timestamp.fromDate(endUtc))
    .count()
    .get();
  return agg.data().count;
}
