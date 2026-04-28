import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface LevelTier {
  level: 1 | 2 | 3 | 4 | 5;
  minPoints: number;
  name: string;
}

const TIERS: LevelTier[] = [
  { level: 1, minPoints: 0, name: "새내기" },
  { level: 2, minPoints: 100, name: "시민" },
  { level: 3, minPoints: 500, name: "활동가" },
  { level: 4, minPoints: 2000, name: "핵심" },
  { level: 5, minPoints: 5000, name: "동지" },
];

function computeLevel(points: number): LevelTier {
  let result = TIERS[0];
  for (const tier of TIERS) {
    if (points >= tier.minPoints) result = tier;
  }
  return result;
}

/// users/{uid} onUpdate. points 변경을 감지해 level 재산출.
/// level 만 바뀐 self-trigger 는 early return — 피드백 루프 방지.
export const recalculateLevel = functions.firestore
  .document("users/{uid}")
  .onUpdate(async (change, context) => {
    const uid = context.params.uid as string;
    const before = change.before.data() ?? {};
    const after = change.after.data() ?? {};

    const beforePoints = (before.points as number | undefined) ?? 0;
    const afterPoints = (after.points as number | undefined) ?? 0;
    if (beforePoints === afterPoints) return;

    const currentLevel = (after.level as number | undefined) ?? 1;
    const newTier = computeLevel(afterPoints);
    if (newTier.level === currentLevel) return;

    const db = admin.firestore();
    const batch = db.batch();

    batch.update(change.after.ref, { level: newTier.level });

    if (newTier.level > currentLevel) {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        id: notifRef.id,
        uid,
        type: "level_up",
        title: `🎖 ${newTier.name} 등급으로 승급`,
        body: `누적 ${afterPoints}P 달성. ${newTier.name} 등급으로 올라갔습니다.`,
        imageUrl: null,
        routeName: "/profile/level",
        routeParams: { fromLevel: currentLevel, toLevel: newTier.level },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readAt: null,
        fcmSent: false,
        fcmMessageId: null,
      });
    }

    await batch.commit();
  });
