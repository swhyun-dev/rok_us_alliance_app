import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

interface KakaoUserResponse {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
      profile_image_url?: string;
    };
  };
}

export const createCustomTokenFromKakao = functions.https.onCall(
  async (data: { kakaoAccessToken?: string }) => {
    const { kakaoAccessToken } = data;
    if (!kakaoAccessToken) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'kakaoAccessToken required'
      );
    }

    let kakaoUser: KakaoUserResponse;
    try {
      const response = await axios.get<KakaoUserResponse>(
        'https://kapi.kakao.com/v2/user/me',
        { headers: { Authorization: `Bearer ${kakaoAccessToken}` } }
      );
      kakaoUser = response.data;
    } catch (error) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Kakao access token validation failed'
      );
    }

    const kakaoId = kakaoUser.id;
    if (!kakaoId) {
      throw new functions.https.HttpsError(
        'internal',
        'Kakao user id missing in response'
      );
    }

    const uid = `kakao:${kakaoId}`;
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: 'kakao',
      providerUserId: String(kakaoId),
    });

    return { customToken };
  }
);
