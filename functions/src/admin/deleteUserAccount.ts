import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface DeleteUserAccountResult {
  success: boolean;
}

/// 본인 계정 탈퇴 호출형 함수.
/// users/{uid} 문서 + Firebase Auth 사용자 삭제.
///
/// point_logs / check_ins / daily_check_ins 등 user 참조 데이터는
/// CLAUDE.md Section 9-1 정책에 따라 90일 보관 후 일괄 정리되도록
/// 별도 scheduled cleanup job 책임 (이번 함수 범위 외).
///
/// 본인 글·댓글은 authorNickname 이 작성 시점 비정규화로 박혀 있으므로
/// 그대로 둔다 — 다른 사용자에게 보이는 작성자 이름은 변경 없음.
export const deleteUserAccount = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const uid = context.auth.uid;
    const db = admin.firestore();

    try {
      await db.collection("users").doc(uid).delete();
    } catch (e) {
      functions.logger.warn(`users/${uid} 삭제 실패`, e);
      // Firestore 삭제 실패해도 Auth 삭제는 시도.
    }

    try {
      await admin.auth().deleteUser(uid);
    } catch (e) {
      const code = (e as { code?: string } | undefined)?.code ?? "";
      if (code === "auth/user-not-found") {
        // 이미 지워진 경우 — 정상 종료.
      } else {
        functions.logger.error(`Auth 사용자 ${uid} 삭제 실패`, e);
        throw new functions.https.HttpsError(
          "internal",
          "계정 삭제 처리 중 오류가 발생했습니다."
        );
      }
    }

    const result: DeleteUserAccountResult = { success: true };
    return result;
  }
);
