import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const AUTO_HIDE_THRESHOLD = 5;

/// reports/{reportId} 가 생성되면:
/// 1) 같은 (targetType, targetId) 의 신고 수를 카운트.
/// 2) 5건 이상이면 콘텐츠를 isDeleted=true 로 자동 숨김 + reports.action
///    필드들을 일괄 'content_removed' 로 갱신 + 신고자들에게 처리 알림.
/// 3) 임계 미만이면 행동 없음 — 운영자 검토 큐에 그대로 둠.
export const onReportCreated = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snap, _context) => {
    const data = snap.data() ?? {};
    const targetType = data.targetType as string | undefined;
    const targetId = data.targetId as string | undefined;
    if (!targetType || !targetId) return;

    const db = admin.firestore();

    const sameTargetSnap = await db
      .collection("reports")
      .where("targetType", "==", targetType)
      .where("targetId", "==", targetId)
      .get();

    const totalCount = sameTargetSnap.size;
    if (totalCount < AUTO_HIDE_THRESHOLD) return;

    // 이미 처리된 신고가 있으면 추가 처리 안 함 (자동 처리 1회만).
    const alreadyHandled = sameTargetSnap.docs.some(
      (d) => d.data().status !== "pending"
    );
    if (alreadyHandled) return;

    // 1) 콘텐츠 자동 숨김 (post / comment / petition 만; user 신고는 ban
    //    같은 자동 조치 보류 — 관리자 수동 처리)
    let contentRefPath: string | null = null;
    if (targetType === "post") {
      contentRefPath = `posts/${targetId}`;
    } else if (targetType === "comment") {
      // 댓글은 부모 postId 가 targetSnapshot 에 들어 있어야 함.
      const postId = data.targetSnapshot?.postId as string | undefined;
      if (postId) contentRefPath = `posts/${postId}/comments/${targetId}`;
    } else if (targetType === "petition") {
      contentRefPath = `petitions/${targetId}`;
    }

    const batch = db.batch();
    if (contentRefPath) {
      batch.update(db.doc(contentRefPath), {
        isDeleted: true,
        autoHiddenAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // 2) 모든 관련 reports 일괄 처리 표시
    for (const doc of sameTargetSnap.docs) {
      batch.update(doc.ref, {
        status: "resolved",
        resolvedBy: "system",
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        resolution: `${AUTO_HIDE_THRESHOLD}건 누적으로 자동 숨김 처리`,
        action: "content_removed",
      });
    }

    // 3) 신고자들에게 처리 알림
    const notifiedReporterIds = new Set<string>();
    for (const doc of sameTargetSnap.docs) {
      const reporterId = doc.data().reporterId as string | undefined;
      if (!reporterId || notifiedReporterIds.has(reporterId)) continue;
      notifiedReporterIds.add(reporterId);

      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        id: notifRef.id,
        uid: reporterId,
        type: "admin_message",
        title: "신고하신 콘텐츠가 처리되었습니다",
        body: `${AUTO_HIDE_THRESHOLD}건 이상 신고가 누적되어 자동 숨김 조치됐습니다.`,
        imageUrl: null,
        routeName: null,
        routeParams: null,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readAt: null,
        fcmSent: false,
        fcmMessageId: null,
      });
    }

    await batch.commit();

    functions.logger.info(
      `자동 숨김 — ${targetType}/${targetId} (${totalCount}건 누적)`
    );
  });
