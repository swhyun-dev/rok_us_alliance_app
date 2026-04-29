import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/// notifications/{notifId} 가 새로 생성될 때마다 해당 uid 의 deviceToken 으로
/// FCM 메시지를 발송. 발송 결과는 notifications 문서에 fcmSent/fcmMessageId
/// 로 기록.
///
/// 토큰이 없거나 발송이 실패해도 silently skip — 알림 doc 자체는 인앱
/// 센터에서 그대로 표시된다.
export const dispatchNotificationOnCreate = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, _context) => {
    const data = snap.data() ?? {};
    const uid = data.uid as string | undefined;
    if (!uid) return;

    const db = admin.firestore();
    const userSnap = await db.collection("users").doc(uid).get();
    if (!userSnap.exists) return;

    const token = userSnap.data()?.deviceToken as string | undefined;
    if (!token || token.trim().length === 0) {
      await snap.ref.update({ fcmSent: false, fcmMessageId: null });
      return;
    }

    const message = _buildMessage(snap.id, token, data);

    try {
      const messageId = await admin.messaging().send(message);
      await snap.ref.update({
        fcmSent: true,
        fcmMessageId: messageId,
      });
    } catch (e) {
      functions.logger.warn(
        `FCM 발송 실패 — uid=${uid}, notifId=${snap.id}`,
        e
      );

      // 무효 토큰은 사용자 문서에서 제거해 다음 알림 발송 비용을 줄인다.
      const code = (e as { code?: string } | undefined)?.code ?? "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        await db.collection("users").doc(uid).update({
          deviceToken: admin.firestore.FieldValue.delete(),
        });
      }

      await snap.ref.update({ fcmSent: false, fcmMessageId: null });
    }
  });

function _buildMessage(
  notifId: string,
  token: string,
  data: admin.firestore.DocumentData
): admin.messaging.Message {
  const title = (data.title as string | undefined) ?? "한미동맹단";
  const body = (data.body as string | undefined) ?? "";
  const routeName = data.routeName as string | undefined;
  const routeParamsRaw = data.routeParams as Record<string, unknown> | undefined;

  const routeParams: Record<string, string> = {};
  if (routeParamsRaw) {
    for (const [k, v] of Object.entries(routeParamsRaw)) {
      routeParams[k] = String(v);
    }
  }

  return {
    token,
    notification: { title, body },
    data: {
      notificationId: notifId,
      type: (data.type as string | undefined) ?? "",
      routeName: routeName ?? "",
      ...routeParams,
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
    android: {
      priority: "high",
      notification: {
        channelId: "default",
        sound: "default",
      },
    },
  };
}
