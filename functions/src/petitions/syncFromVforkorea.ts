import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

/**
 * vforkorea.com 에서 청원/입법법안 리스트를 받아 Firestore petitions 컬렉션에
 * upsert. 도메인 모델과의 호환을 유지해 기존 PetitionPage 가 그대로 동작한다.
 *
 * 데이터 소스 (협의 완료):
 *  - 국민동의청원: POST https://vforkorea.com/api2/won/getList.php
 *  - 입법예정법안: POST https://vforkorea.com/api2/assembly/getList.php
 *
 * doc id 안정 전략:
 *  - 국민청원:   np_{petitId}      (국회 청원 ID 기준)
 *  - 입법법안:   lb_{id}           (국회 의안 ID PRC_xxx 기준)
 *
 *  → 동일 청원이 매번 새 doc 으로 생성되지 않고 update.
 */

const WON_URL = "https://vforkorea.com/api2/won/getList.php";
const ASSEMBLY_URL = "https://vforkorea.com/api2/assembly/getList.php";
const COMMON_HEADERS = {
  "User-Agent": "Mozilla/5.0 (compatible; rok-us-alliance-app/1.0)",
  "X-Requested-With": "XMLHttpRequest",
  Referer: "https://vforkorea.com/",
};

interface SyncReport {
  nationalPetitionsUpserted: number;
  legislativeBillsUpserted: number;
  errors: string[];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// vforkorea won (국민동의청원) raw response
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
interface VforWonItem {
  idx: string;
  petitSj: string;        // 제목
  petitId: string;        // 국회 청원 ID
  petitRealmNm: string;   // 분야
  AIshort: string;        // AI 요약
  AI: string;
  agreCo: string;         // 동의자 수
  comment: string;
  agreBeginDe: string;    // "YYYY-MM-DD HH:mm:ss"
  agreEndDe: string;
  creatDt: string;
  lastupdate: string;
  regdate: string;
  gubun: string;
  category: string;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// vforkorea assembly (입법예정법안) raw response
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
interface VforAssemItem {
  idx: string;
  id: string;             // PRC_xxx 의안 ID
  title: string;
  end_date: string;       // "YYYY-MM-DD"
  parties: string;        // "국민의힘:10"
  opinion_count: string;
  danger: string;
  proposer_type: string;
  countN: string;         // 반대 의견
  countY: string;         // 찬성 의견
  short: string;          // AI 요약
  positive: string;
  nagative: string;
  notice_period: string;  // "YYYY-MM-DD~YYYY-MM-DD"
  hidden_intent: string;
  AI_good: string;
  AI_bad: string;
  partyType: string;
  partyCnt: string;
  regdate: string;
  lastupdate: string;
}

interface VforEnvelope<T> {
  data: T[];
  total: number;
  main_total?: number;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 매핑 helpers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/** "YYYY-MM-DD HH:mm:ss" 또는 "YYYY-MM-DD" 를 KST Date 로. */
function parseKstDate(raw: string): Date {
  if (!raw) return new Date();
  const t = raw.trim().replace(" ", "T");
  // 이미 timezone 없으니 KST(+09:00) 명시
  const iso = t.length <= 10 ? `${t}T00:00:00+09:00` : `${t}+09:00`;
  const d = new Date(iso);
  return isNaN(d.getTime()) ? new Date() : d;
}

/** vforkorea 청원 카테고리 코드 → 우리 앱 카테고리 (security/economy/education/media/judicial/other). */
function mapWonCategory(realm: string, vforCategoryCode: string): string {
  // realm 텍스트 우선, 없으면 코드.
  const realmLower = (realm || "").toLowerCase();
  if (realmLower.includes("외교") || realmLower.includes("국방") ||
      realmLower.includes("안보") || realmLower.includes("통일")) {
    return "security";
  }
  if (realmLower.includes("재정") || realmLower.includes("세제") ||
      realmLower.includes("금융") || realmLower.includes("예산") ||
      realmLower.includes("산업") || realmLower.includes("경제")) {
    return "economy";
  }
  if (realmLower.includes("교육")) return "education";
  if (realmLower.includes("언론") || realmLower.includes("방송")) return "media";
  if (realmLower.includes("사법") || realmLower.includes("법무") ||
      realmLower.includes("선거") || realmLower.includes("국회")) {
    return "judicial";
  }

  // realm 없으면 vforkorea category 코드로 fallback (1=부정선거 등)
  switch (vforCategoryCode) {
    case "1": return "judicial";   // 부정선거 관련
    case "2": return "security";   // 반국가세력
    case "3": return "security";   // 중국 관련
    case "4": return "judicial";   // 악법 반대
    case "5": return "other";      // 애국청원
    default:  return "other";
  }
}

/** AI 점수로 입법법안 stance 추정. */
function inferStance(aiGoodStr: string, aiBadStr: string): "support" | "oppose" | "neutral" {
  const good = parseInt(aiGoodStr || "0", 10) || 0;
  const bad = parseInt(aiBadStr || "0", 10) || 0;
  if (bad >= 70) return "oppose";
  if (good >= 70) return "support";
  return "neutral";
}

/** 동의자 수가 5만 이상이면 본회의 회부 — 외부 표기용 target. */
function petitionTarget(): number {
  return 50000;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// fetch helpers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function fetchWonList(): Promise<VforWonItem[]> {
  const res = await axios.post<VforEnvelope<VforWonItem>>(WON_URL, "", {
    headers: COMMON_HEADERS,
    timeout: 15000,
  });
  return res.data?.data ?? [];
}

async function fetchAssemblyList(): Promise<VforAssemItem[]> {
  const res = await axios.post<VforEnvelope<VforAssemItem>>(ASSEMBLY_URL, "", {
    headers: COMMON_HEADERS,
    timeout: 15000,
  });
  return res.data?.data ?? [];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// upsert helpers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function upsertWonItems(items: VforWonItem[]): Promise<number> {
  const db = admin.firestore();
  let upserted = 0;

  // 한 번에 500 까지 묶을 수 있지만 여유 있게 100 단위.
  const chunks = chunk(items, 100);
  for (const chunkItems of chunks) {
    const batch = db.batch();
    for (const it of chunkItems) {
      if (!it.petitId) continue;
      const docId = `np_${it.petitId}`;
      const ref = db.collection("petitions").doc(docId);

      const startDate = parseKstDate(it.agreBeginDe);
      const deadline = parseKstDate(it.agreEndDe);
      const now = new Date();
      const status = deadline.getTime() < now.getTime() ? "expired" : "active";

      const externalUrl =
        `https://petitions.assembly.go.kr/proceed/onGoingDetail/${it.petitId}`;

      batch.set(ref, {
        id: docId,
        title: it.petitSj || "",
        description: it.AIshort || "",
        category: mapWonCategory(it.petitRealmNm, it.category),
        imageUrls: [],
        externalUrl,
        sourceUrl: "https://vforkorea.com/won/",
        referenceNumber: it.petitId,
        type: "nationalPetition",
        stance: "neutral",
        progressStatus: it.petitRealmNm || "",
        progressUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        targetCount: petitionTarget(),
        currentCount: parseInt(it.agreCo || "0", 10) || 0,
        startDate: admin.firestore.Timestamp.fromDate(startDate),
        deadline: admin.firestore.Timestamp.fromDate(deadline),
        completedAt: null,
        status,
        isFeatured: false,
        createdBy: "vforkorea_sync",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      upserted++;
    }
    await batch.commit();
  }
  return upserted;
}

async function upsertAssemblyItems(items: VforAssemItem[]): Promise<number> {
  const db = admin.firestore();
  let upserted = 0;

  const chunks = chunk(items, 100);
  for (const chunkItems of chunks) {
    const batch = db.batch();
    for (const it of chunkItems) {
      if (!it.id) continue;
      const docId = `lb_${it.id}`;
      const ref = db.collection("petitions").doc(docId);

      // notice_period: "2026-04-29~2026-05-08"
      const periodParts = (it.notice_period || "").split("~");
      const startDate = periodParts[0]
        ? parseKstDate(periodParts[0])
        : parseKstDate(it.regdate);
      const deadline = periodParts[1]
        ? parseKstDate(periodParts[1])
        : parseKstDate(it.end_date);
      const now = new Date();
      const status = deadline.getTime() < now.getTime() ? "expired" : "active";

      const externalUrl =
        `https://pal.assembly.go.kr/napal/lgsltpa/lgsltpaOngoing/view.do?lgsltPaId=${it.id}`;

      // description: AI short + 발의 정당 정보
      const partyInfo = it.parties ? ` (${it.parties} ${it.partyCnt}인)` : "";
      const description = `${(it.short || "").trim()}${partyInfo}`;

      batch.set(ref, {
        id: docId,
        title: it.title || "",
        description,
        category: "judicial",  // 법안은 일괄 judicial
        imageUrls: [],
        externalUrl,
        sourceUrl: "https://vforkorea.com/assem/",
        referenceNumber: it.id,
        type: "legislativeBill",
        stance: inferStance(it.AI_good, it.AI_bad),
        progressStatus: "입법예고 진행 중",
        progressUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        targetCount: 0,  // 법안은 진행률 바 미사용
        currentCount: parseInt(it.opinion_count || "0", 10) || 0,
        startDate: admin.firestore.Timestamp.fromDate(startDate),
        deadline: admin.firestore.Timestamp.fromDate(deadline),
        completedAt: null,
        status,
        isFeatured: false,
        createdBy: "vforkorea_sync",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      upserted++;
    }
    await batch.commit();
  }
  return upserted;
}

function chunk<T>(arr: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 코어 동작
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function runSync(): Promise<SyncReport> {
  const report: SyncReport = {
    nationalPetitionsUpserted: 0,
    legislativeBillsUpserted: 0,
    errors: [],
  };

  try {
    const wonItems = await fetchWonList();
    report.nationalPetitionsUpserted = await upsertWonItems(wonItems);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    report.errors.push(`won: ${msg}`);
    functions.logger.error("syncFromVforkorea won 실패:", e);
  }

  try {
    const assemItems = await fetchAssemblyList();
    report.legislativeBillsUpserted = await upsertAssemblyItems(assemItems);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    report.errors.push(`assembly: ${msg}`);
    functions.logger.error("syncFromVforkorea assembly 실패:", e);
  }

  functions.logger.info("syncFromVforkorea 완료:", report);
  return report;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Exports
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/** 매시간 정각에 vforkorea 데이터를 동기화. KST 기준 운영. */
export const syncFromVforkoreaScheduled = functions
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .pubsub.schedule("0 * * * *")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    await runSync();
    return null;
  });

/** 관리자가 즉시 한 번 동기화 실행. 검증·초기 시드용. */
export const syncFromVforkoreaNow = functions
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminDoc = await admin
      .firestore()
      .collection("admins")
      .doc(context.auth.uid)
      .get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "관리자만 호출할 수 있습니다."
      );
    }
    return runSync();
  });
