import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as cheerio from "cheerio";

interface FetchBillData {
  billNumber?: string;
}

/**
 * 관리자가 의안번호를 입력하면 국회 입법예고 사이트(pal.assembly.go.kr)에서
 * 제목·진행상태·상세 URL 을 가져와 폼에 자동 채워준다.
 *
 * robots.txt 가 검색엔진 3종(Googlebot/Yeti/Daumoa) 일부 경로만 차단하고
 * 그 외는 모두 허용. 일반 봇으로 fetch 가능.
 *
 * 사이트 구조 변경에 약하므로:
 *  - 실패해도 throw 대신 빈 결과 반환 → 관리자가 수동 입력 가능
 *  - selector 는 보수적으로 (제목 후보 여러 곳 시도)
 *
 * 호출자: 관리자 권한 필요. 일반 사용자에게는 거의 의미 없는 함수.
 */
export const fetchBillFromAssembly = functions.https.onCall(
  async (data: FetchBillData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const adminDoc = await admin
      .firestore()
      .collection("admins")
      .doc(adminUid)
      .get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "관리자만 호출할 수 있습니다."
      );
    }

    const billNumber = data.billNumber?.trim();
    if (!billNumber) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "billNumber 가 필요합니다."
      );
    }

    return fetchBillSummary(billNumber);
  }
);

/**
 * 의안번호로 국회 입법예고 페이지를 조회하고 요약 정보를 반환.
 * 외부 모듈에서도 재사용 (refreshBillStatus 스케줄러).
 */
export async function fetchBillSummary(billNumber: string): Promise<{
  title: string;
  progressStatus: string;
  externalUrl: string;
}> {
  const searchUrl =
    "https://pal.assembly.go.kr/napal/lgsltpa/lgsltpaOngoing/list.do" +
    `?searchVal=${encodeURIComponent(billNumber)}`;

  try {
    const res = await axios.get(searchUrl, {
      timeout: 10000,
      headers: {
        "User-Agent":
          "Mozilla/5.0 (compatible; RokUsAllianceBot/1.0; +https://rokus-alliance.com/bot)",
        "Accept-Language": "ko-KR,ko;q=0.9,en;q=0.8",
      },
      validateStatus: (s) => s < 500,
    });
    if (res.status !== 200) {
      return { title: "", progressStatus: "", externalUrl: searchUrl };
    }

    const $ = cheerio.load(res.data);

    // 제목 후보: 보수적으로 여러 selector 시도. 사이트 구조가 바뀌면 첫 .title
    // 이나 첫 a 태그를 fallback 으로 사용.
    let title = "";
    const titleCandidates = [
      "table tbody tr td a",
      ".tit a",
      ".title a",
      "a.subject",
    ];
    for (const sel of titleCandidates) {
      const el = $(sel).first();
      if (el.length > 0) {
        const txt = el.text().trim();
        if (txt) {
          title = txt;
          break;
        }
      }
    }

    // 진행 상태 후보
    let progressStatus = "";
    const statusCandidates = [
      "table tbody tr td.status",
      ".state",
      ".progress",
      "td:contains('심사')",
    ];
    for (const sel of statusCandidates) {
      const el = $(sel).first();
      if (el.length > 0) {
        const txt = el.text().trim();
        if (txt && txt.length < 40) {
          progressStatus = txt;
          break;
        }
      }
    }

    // 상세 URL: 첫 a[href] 의 href 가 상대경로면 절대화
    let externalUrl = searchUrl;
    const firstLink = $("table tbody tr td a").first().attr("href");
    if (firstLink) {
      try {
        externalUrl = new URL(firstLink, searchUrl).toString();
      } catch (_) {
        // 파싱 실패 → 검색 URL 유지
      }
    }

    return { title, progressStatus, externalUrl };
  } catch (err) {
    functions.logger.warn("fetchBillSummary failed", { billNumber, err });
    return { title: "", progressStatus: "", externalUrl: searchUrl };
  }
}
