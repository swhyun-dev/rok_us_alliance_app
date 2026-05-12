import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const BASE_REWARD = 10;
const BONUS_3DAY = 30; // 3일 연속
const BONUS_7DAY = 70; // 7일 연속

interface DailyCheckInResult {
  status: "checked_in" | "already_checked";
  pointsAwarded: number;
  bonusAwarded: number;
  consecutiveDays: number;
  // [DEBUG] 점수 적립 미스터리 추적용. 안정화되면 제거.
  debug?: {
    uid: string;
    dateStr: string;
    todayPath: string;
    todayExisted: boolean;
    userExisted: boolean;
    txCompletedBranch: "early_return" | "new_write" | "none";
    projectId: string;
  };
}

/// 사용자가 오늘 체크인했는지 검사하고 신규면 +10P (연속 3/7일 보너스 별도).
/// daily_check_ins/{uid_YYYY-MM-DD} 문서 ID 로 KST 기준 하루 1회 보장.
export const dailyCheckIn = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const uid = context.auth.uid;

    const dateStr = todayKstString();
    const yesterdayStr = yesterdayKstString();

    functions.logger.info(
      `[dailyCheckIn] called uid=${uid} dateStr=${dateStr}`
    );

    const db = admin.firestore();
    const docRef = db.collection("daily_check_ins").doc(`${uid}_${dateStr}`);
    const yesterdayRef = db
      .collection("daily_check_ins")
      .doc(`${uid}_${yesterdayStr}`);
    const userRef = db.collection("users").doc(uid);

    const result: DailyCheckInResult = {
      status: "already_checked",
      pointsAwarded: 0,
      bonusAwarded: 0,
      consecutiveDays: 0,
      debug: {
        uid,
        dateStr,
        todayPath: docRef.path,
        todayExisted: false,
        userExisted: false,
        txCompletedBranch: "none",
        projectId: process.env.GCLOUD_PROJECT || "unknown",
      },
    };

    await db.runTransaction(async (tx) => {
      const today = await tx.get(docRef);
      functions.logger.info(
        `[dailyCheckIn] tx.today.exists=${today.exists} ` +
          `path=${docRef.path}`
      );
      if (result.debug) result.debug.todayExisted = today.exists;
      if (today.exists) {
        const data = today.data() ?? {};
        result.consecutiveDays =
          (data.consecutiveDays as number | undefined) ?? 0;
        if (result.debug) result.debug.txCompletedBranch = "early_return";
        return;
      }

      const userSnap = await tx.get(userRef);
      functions.logger.info(
        `[dailyCheckIn] tx.user.exists=${userSnap.exists} ` +
          `path=${userRef.path}`
      );
      if (result.debug) result.debug.userExisted = userSnap.exists;
      if (!userSnap.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "가입을 마치지 않은 사용자입니다."
        );
      }

      const yesterday = await tx.get(yesterdayRef);
      const consecutive = yesterday.exists
        ? ((yesterday.data()?.consecutiveDays as number | undefined) ?? 0) + 1
        : 1;

      let bonus = 0;
      if (consecutive % 7 === 0) bonus = BONUS_7DAY;
      else if (consecutive % 3 === 0) bonus = BONUS_3DAY;

      const total = BASE_REWARD + bonus;

      tx.set(docRef, {
        uid,
        date: dateStr,
        pointsAwarded: total,
        consecutiveDays: consecutive,
        bonusAwarded: bonus > 0,
        checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const logRef = db.collection("point_logs").doc();
      tx.set(logRef, {
        id: logRef.id,
        uid,
        type: bonus > 0 ? "consecutive_bonus" : "daily_check_in",
        amount: total,
        refId: dateStr,
        refType: "daily_check_in",
        pointsAfter: null,
        levelAfter: null,
        levelChanged: false,
        description: bonus > 0
          ? `+${total}P 연속 ${consecutive}일 체크인 보너스`
          : `+${BASE_REWARD}P 일일 체크인`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        adjustedBy: null,
        adjustReason: null,
      });

      tx.update(userRef, {
        points: admin.firestore.FieldValue.increment(total),
        lastCheckInAt: admin.firestore.FieldValue.serverTimestamp(),
        consecutiveCheckInDays: consecutive,
      });

      result.status = "checked_in";
      result.pointsAwarded = BASE_REWARD;
      result.bonusAwarded = bonus;
      result.consecutiveDays = consecutive;
      if (result.debug) result.debug.txCompletedBranch = "new_write";

      functions.logger.info(
        `[dailyCheckIn] tx.writes prepared total=${total} ` +
          `consecutive=${consecutive} bonus=${bonus}`
      );
    });

    functions.logger.info(
      `[dailyCheckIn] tx.commit OK status=${result.status} ` +
        `points=${result.pointsAwarded} days=${result.consecutiveDays}`
    );

    return result;
  }
);

function todayKstString(): string {
  return _kstDateString(0);
}

function yesterdayKstString(): string {
  return _kstDateString(-1);
}

function _kstDateString(deltaDays: number): string {
  const utcMs = Date.now();
  const kstMs = utcMs + 9 * 60 * 60 * 1000 + deltaDays * 24 * 60 * 60 * 1000;
  const d = new Date(kstMs);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
