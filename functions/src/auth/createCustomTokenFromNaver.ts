import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

interface NaverMeResponse {
  resultcode: string;
  message: string;
  response: {
    id: string;
    nickname?: string;
    name?: string;
    email?: string;
    profile_image?: string;
  };
}

export const createCustomTokenFromNaver = functions.https.onCall(
  async (data: { naverAccessToken?: string }) => {
    const { naverAccessToken } = data;
    if (!naverAccessToken) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'naverAccessToken required'
      );
    }

    let payload: NaverMeResponse;
    try {
      const response = await axios.get<NaverMeResponse>(
        'https://openapi.naver.com/v1/nid/me',
        { headers: { Authorization: `Bearer ${naverAccessToken}` } }
      );
      payload = response.data;
    } catch (error) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Naver access token validation failed'
      );
    }

    if (payload.resultcode !== '00' || !payload.response?.id) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        `Naver profile fetch failed (resultcode=${payload.resultcode})`
      );
    }

    const naverId = payload.response.id;
    const uid = `naver:${naverId}`;
    const customToken = await admin.auth().createCustomToken(uid, {
      provider: 'naver',
      providerUserId: naverId,
    });

    return { customToken };
  }
);
