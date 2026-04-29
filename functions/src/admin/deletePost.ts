import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface DeletePostData {
  postId?: string;
  hard?: boolean; // true 면 hard delete; 기본 soft delete (isDeleted=true)
}

/// 관리자가 게시글을 강제 삭제. 기본은 soft delete (isDeleted=true) 로
/// 감사 추적 보존. hard 옵션을 명시한 경우에만 실제 문서 삭제.
export const deletePost = functions.https.onCall(
  async (data: DeletePostData, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }
    const adminUid = context.auth.uid;
    const postId = data.postId?.trim();
    if (!postId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "postId 가 필요합니다."
      );
    }

    const db = admin.firestore();
    const adminDoc = await db.collection("admins").doc(adminUid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "관리자만 수행할 수 있습니다."
      );
    }

    const postRef = db.collection("posts").doc(postId);
    if (data.hard === true) {
      await postRef.delete();
    } else {
      await postRef.update({
        isDeleted: true,
        adminDeletedBy: adminUid,
        adminDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true, hard: data.hard === true };
  }
);
