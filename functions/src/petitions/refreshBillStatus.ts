import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { fetchBillSummary } from "./fetchBillFromAssembly";

/**
 * 매일 새벽 3시 KST 에 모든 active 입법법안의 progressStatus 를 갱신.
 * 한 번에 최대 50건만 처리 (rate limit 방지).
 *
 * 변경이 있으면 progressStatus + progressUpdatedAt 만 patch.
 * 의안번호가 비어 있으면 skip.
 */
export const refreshBillStatus = functions
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .pubsub.schedule("0 3 * * *")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const snap = await db
      .collection("petitions")
      .where("type", "==", "legislativeBill")
      .where("status", "==", "active")
      .limit(50)
      .get();

    if (snap.empty) {
      functions.logger.info("refreshBillStatus: 갱신할 입법법안 없음");
      return null;
    }

    let updated = 0;
    let skipped = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const billNumber = (data.referenceNumber as string | undefined)?.trim();
      if (!billNumber) {
        skipped++;
        continue;
      }
      try {
        const result = await fetchBillSummary(billNumber);
        const oldStatus = (data.progressStatus as string | undefined) ?? "";
        if (result.progressStatus && result.progressStatus !== oldStatus) {
          await doc.ref.update({
            progressStatus: result.progressStatus,
            progressUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          updated++;
        }
        // 사이트 부담 줄이기 위해 호출 사이 짧은 간격
        await new Promise((r) => setTimeout(r, 500));
      } catch (err) {
        functions.logger.warn("refreshBillStatus: 개별 항목 실패", {
          id: doc.id,
          billNumber,
          err,
        });
      }
    }

    functions.logger.info("refreshBillStatus 완료", {
      total: snap.size,
      updated,
      skipped,
    });
    return null;
  });
