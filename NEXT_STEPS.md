# NEXT_STEPS.md — Claude Code 작업 큐

> 이 문서는 Claude Code가 실제로 작업할 때 사용하는 **스프린트 티켓 모음**입니다.
> 각 작업은 30분~3시간 단위로 쪼개져 있고, 시작 프롬프트가 그대로 포함되어 있습니다.
> 위에서부터 순서대로 진행하세요.

**전제 문서**:
- `CLAUDE.md` v3.0 (전체 프로젝트 가이드)
- `FIRESTORE_SCHEMA.md` (DB 설계도)
- `OWNER_TODO.md` (대표님 외부 신청)

**총 작업 수**: 51개
**예상 기간**: 6주 (1주 = 약 8~9개 작업)

---

## 📚 사용 방법

### 작업 단위 구조

```
□ [W1.1] 작업명
   상태:        [ 대기 / 진행 / 완료 / 보류 ]
   예상 시간:   [ 30m / 1h / 2h / 3h ]
   브랜치:      [ feat/xxx ]
   종속성:      [ 선행 작업 번호 ]
   파일:        [ 수정할 파일 목록 ]
   완료 기준:   [ 명확한 검증 항목 ]
   
   [Claude Code 프롬프트]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   여기 그대로 복붙하면 됨
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 진행 표시

- `□` 대기
- `🔄` 진행 중
- `✅` 완료
- `⏸️` 보류
- `❌` 취소

---

## 🗓️ Week 1 — 인증 시스템 재구축 (8개 작업)

> **선행 조건**: 대표님 OWNER_TODO.md의 외부 신청(Apple/Google/Kakao/Naver) 시작
> **브랜치**: `feat/auth-multi-social`

---

### □ [W1.0] 작업 환경 준비

**상태**: 대기 | **예상**: 30m | **종속성**: 없음

**완료 기준**:
- ✅ Git 브랜치 생성
- ✅ pubspec.yaml 의존성 추가
- ✅ flutter pub get 성공

**Claude Code 프롬프트**:
```
CLAUDE.md와 NEXT_STEPS.md를 읽고 Week 1 작업을 시작하겠습니다.

먼저 작업 환경을 준비합니다:

1. 새 브랜치 생성:
   git checkout -b feat/auth-multi-social

2. pubspec.yaml에 다음 의존성 추가:
   - kakao_flutter_sdk_user: ^1.9.6
   - sign_in_with_apple: ^6.1.4
   - google_sign_in: ^6.2.2
   - cloud_functions: ^5.5.0
   
3. flutter pub get 실행

4. firebase_core, firebase_auth, cloud_firestore 버전이 최신인지 확인

5. lib/firebase_options.dart 가 최신인지 확인 (필요 시 flutterfire configure 안내만, 실행은 대표님께)

각 단계 결과를 보고해주세요.
```

---

### □ [W1.1] 카페 매칭 코드 제거

**상태**: 대기 | **예상**: 1.5h | **종속성**: W1.0

**파일**:
- `lib/features/auth/domain/app_user.dart`
- `lib/features/auth/data/auth_store.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/signup_complete_page.dart`
- `lib/features/profile/presentation/profile_page.dart` (또는 my_page.dart)

**완료 기준**:
- ✅ 다음 필드 0개: cafeNickname, cafeMatched, phoneNumber, phoneVerified, isVerified
- ✅ flutter analyze 경고 0
- ✅ 앱 빌드 성공

**Claude Code 프롬프트**:
```
CLAUDE.md Section 9-3 (AppUser 모델 v3)을 기준으로 카페 매칭 코드를 완전히 제거합니다.

목표: 다음 필드들을 모든 코드베이스에서 제거
  - cafeNickname
  - cafeMatched  
  - phoneNumber
  - phoneVerified
  - isVerified (등급 시스템으로 대체)

작업 순서:
1. lib/features/auth/domain/app_user.dart
   - 위 필드 제거
   - CLAUDE.md Section 9-3 기준으로 신규 필드 골격만 추가 (level, points 등)
   - 단, 신규 필드 로직은 W1.4에서 구현하므로 여기선 필드만

2. lib/features/auth/data/auth_store.dart
   - pendingProfile 관련 코드 제거
   - 카페 매칭 관련 메서드 제거

3. lib/features/auth/presentation/signup_complete_page.dart
   - 카페 닉네임 입력 다이얼로그 제거
   - 일단 단순한 환영 화면으로 변경 (W1.7에서 재설계)

4. lib/features/profile/presentation/profile_page.dart (또는 my_page.dart)
   - "카페 닉네임 수정" 다이얼로그 제거
   - "카페 매칭 대기 중" 등 카피 제거
   - _resolveGrade 함수의 카페 의존 부분 제거 (임시로 항상 lv1 반환)

5. lib/features/auth/presentation/login_page.dart
   - "네이버 카페 매칭" 카피 제거
   - 일단 네이버 로그인만 유지 (W1.2에서 다중 로그인 추가)

검증:
  - grep -r "cafeNickname\|cafeMatched\|phoneVerified" lib/ → 0건
  - flutter analyze → 경고 0
  - flutter run으로 앱 시작 + 로그인 + 홈 진입 확인

완료 후 git commit -m "refactor: remove cafe matching system"
```

---

### □ [W1.2] Apple 로그인 서비스 구현

**상태**: 대기 | **예상**: 2h | **종속성**: W1.1

**파일**:
- `lib/features/auth/data/apple_auth_service.dart` (신규)
- `ios/Runner/Runner.entitlements` (수정)
- `ios/Runner/Info.plist` (수정)

**완료 기준**:
- ✅ iOS 시뮬레이터에서 Apple 로그인 시 Firebase Auth UID 획득
- ✅ Android에서는 비활성화 (Apple은 iOS 전용 권장)

**Claude Code 프롬프트**:
```
Apple Sign In 서비스를 구현합니다. iOS 심사 필수 항목입니다.

CLAUDE.md Section 9-1 (로그인 4종) 참조.

작업:

1. lib/features/auth/data/apple_auth_service.dart 생성
   - signInWithApple() 메서드
   - sign_in_with_apple 패키지 사용
   - 받은 ID Token으로 Firebase Auth signInWithCredential
   - 에러 처리 (취소·실패)
   - Platform.isIOS 체크 추가 (iOS 외 환경 차단)

2. ios/Runner/Runner.entitlements 확인·수정
   - com.apple.developer.applesignin 항목 추가
   - 기존 파일이 없으면 생성

3. ios/Runner/Info.plist 확인 (특별 추가 사항 없음, 일반 Apple Sign In 처리)

4. 사용 예시 주석 추가:
   ```dart
   // 사용 예시 (login_page.dart에서):
   // final user = await AppleAuthService.signInWithApple();
   ```

5. iOS 시뮬레이터로 테스트:
    - 로그인 페이지에 임시 버튼 추가 (W1.6에서 본격 UI)
    - Apple ID 로그인 시도
    - Firebase Console > Authentication에서 사용자 추가됐는지 확인

⚠️ 주의:
- Apple Developer 계정에 Sign in with Apple 활성화 되어있어야 함
- 미활성화 시 대표님께 OWNER_TODO.md 항목 1번 진행 안내

완료 후 git commit -m "feat: add Apple Sign In service"
```

---

### □ [W1.3] Google 로그인 서비스 구현

**상태**: 대기 | **예상**: 1h | **종속성**: W1.0

**파일**:
- `lib/features/auth/data/google_auth_service.dart` (신규)
- `android/app/build.gradle.kts` (SHA-1 등록 필요)
- `ios/Runner/Info.plist` (URL Schemes)

**완료 기준**:
- ✅ Android에서 Google 계정으로 Firebase Auth 로그인 성공

**Claude Code 프롬프트**:
```
Google 로그인 서비스를 구현합니다.

작업:

1. lib/features/auth/data/google_auth_service.dart 생성
    - signInWithGoogle() 메서드
    - google_sign_in 패키지 사용
    - GoogleSignInAuthentication 받아서 GoogleAuthProvider.credential 생성
    - Firebase Auth signInWithCredential
    - 에러 처리 (사용자 취소·네트워크·기기)

2. iOS 설정 확인:
    - GoogleService-Info.plist에서 REVERSED_CLIENT_ID 확인
    - ios/Runner/Info.plist에 URL Scheme 추가
      <key>CFBundleURLTypes</key>
      <array>
      <dict>
      <key>CFBundleURLSchemes</key>
      <array>
      <string>(REVERSED_CLIENT_ID 값)</string>
      </array>
      </dict>
      </array>

3. Android 설정 확인:
    - android/app/google-services.json 에 OAuth Client ID가 포함되어 있어야 함
    - 없으면 Firebase Console > Authentication > Sign-in method > Google 활성화 후
      debug SHA-1을 Firebase Console에 등록 필요 (대표님께 안내)

4. 테스트:
    - Android 에뮬레이터에서 Google 계정 로그인 시도
    - Firebase Console에서 사용자 확인

⚠️ SHA-1 안 등록되어 있으면 ApiException 10 에러 발생.
대표님이 안 하셨으면 다음 명령 안내:
cd android && ./gradlew signingReport
출력의 SHA1을 Firebase Console > 프로젝트 설정 > 일반 > SHA-1 추가

완료 후 git commit -m "feat: add Google Sign In service"
```

---

### □ [W1.4] Kakao 로그인 서비스 구현

**상태**: 대기 | **예상**: 2h | **종속성**: W1.0

**파일**:
- `lib/features/auth/data/kakao_auth_service.dart` (신규)
- `lib/main.dart` (Kakao SDK 초기화)
- `android/app/src/main/AndroidManifest.xml` (Kakao Activity)
- `ios/Runner/Info.plist` (URL Schemes)
- `functions/src/auth/createCustomTokenFromKakao.ts` (신규)

**완료 기준**:
- ✅ 카카오 로그인 → Cloud Function → Firebase Custom Token → signInWithCustomToken 성공

**Claude Code 프롬프트**:
```
카카오 로그인을 구현합니다. Firebase Auth는 Kakao를 직접 지원하지 않으므로
Cloud Function을 경유한 Custom Token 방식을 사용합니다.

준비 사항 확인:
- 대표님 OWNER_TODO.md의 Kakao Developers 등록 완료 필요
- Native App Key, REST API Key 발급 받았는지 확인
- 안 되어 있으면 다음 단계 보류 안내

작업:

1. lib/main.dart - Kakao SDK 초기화
   import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

   void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   KakaoSdk.init(nativeAppKey: '<KAKAO_NATIVE_APP_KEY>');
   await Firebase.initializeApp(...);
   runApp(...);
   }

   ⚠️ 키는 환경변수 또는 const 값으로. 일단 const로 시작하고 W4 출시 직전에 분리.

2. lib/features/auth/data/kakao_auth_service.dart 생성
    - signInWithKakao() 메서드
    - 1단계: 카카오톡 설치 여부 확인 → loginWithKakaoTalk() 또는 loginWithKakaoAccount()
    - 2단계: 받은 OAuthToken을 Cloud Function 'createCustomTokenFromKakao'에 전달
    - 3단계: Cloud Function이 반환한 Custom Token으로 Firebase signInWithCustomToken
    - 에러 처리 (사용자 취소·네트워크)

3. Android 설정 (android/app/src/main/AndroidManifest.xml):
   <activity
   android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
   android:exported="true">
   <intent-filter android:label="flutter_web_auth">
   <action android:name="android.intent.action.VIEW" />
   <category android:name="android.intent.category.DEFAULT" />
   <category android:name="android.intent.category.BROWSABLE" />
   <data android:scheme="kakao<KAKAO_NATIVE_APP_KEY>" android:host="oauth"/>
   </intent-filter>
   </activity>

4. iOS 설정 (ios/Runner/Info.plist):
   <key>LSApplicationQueriesSchemes</key>
   <array>
   <string>kakaokompassauth</string>
   <string>kakaolink</string>
   </array>
   <key>CFBundleURLTypes</key>
   <array>
   <dict>
   <key>CFBundleURLSchemes</key>
   <array>
   <string>kakao<KAKAO_NATIVE_APP_KEY></string>
   </array>
   </dict>
   </array>

5. Cloud Function 작성:
   functions/src/auth/createCustomTokenFromKakao.ts

   ```typescript
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import axios from 'axios';
   
   export const createCustomTokenFromKakao = functions.https.onCall(async (data, context) => {
     const { kakaoAccessToken } = data;
     if (!kakaoAccessToken) {
       throw new functions.https.HttpsError('invalid-argument', 'kakaoAccessToken required');
     }
     
     // 카카오 사용자 정보 조회
     const kakaoUser = await axios.get('https://kapi.kakao.com/v2/user/me', {
       headers: { Authorization: `Bearer ${kakaoAccessToken}` }
     });
     
     const kakaoId = kakaoUser.data.id;
     const uid = `kakao:${kakaoId}`;
     
     // Firebase Custom Token 발급
     const customToken = await admin.auth().createCustomToken(uid, {
       provider: 'kakao',
       providerUserId: String(kakaoId),
     });
     
     return { customToken };
   });
   ```

6. functions/package.json에 axios 추가, 배포

7. 테스트:
    - 안드로이드/iOS에서 카카오 로그인 시도
    - Firebase Console에서 kakao:xxx UID 확인

⚠️ 안 됐을 때 디버깅:
- Cloud Function 로그: firebase functions:log
- 카카오 SDK 로그: KakaoSdk.init 호출 시 logLevel: KakaoLogLevel.v 설정

완료 후 git commit -m "feat: add Kakao Sign In with Custom Token"
```

---

### □ [W1.5] Naver 로그인 Cloud Function 연동

**상태**: 대기 | **예상**: 1.5h | **종속성**: W1.0

**파일**:
- `lib/features/auth/data/naver_auth_service.dart` (수정)
- `functions/src/auth/createCustomTokenFromNaver.ts` (신규)

**완료 기준**:
- ✅ 네이버 로그인 후 Firebase Auth UID 획득

**Claude Code 프롬프트**:
```
기존 네이버 로그인 코드를 Firebase Custom Token 방식으로 업그레이드합니다.

기존 코드:
- lib/features/auth/data/naver_auth_service.dart
- 현재는 네이버 로그인만 하고 SharedPreferences에 저장

목표:
- 네이버 로그인 후 Cloud Function으로 Custom Token 받기
- signInWithCustomToken으로 Firebase 인증

작업:

1. functions/src/auth/createCustomTokenFromNaver.ts 작성
   (W1.4의 Kakao와 동일 패턴)
    - 네이버 사용자 정보 API: https://openapi.naver.com/v1/nid/me
    - uid 형식: `naver:${naverUserId}`

2. lib/features/auth/data/naver_auth_service.dart 수정
    - 기존 signInWithNaver() 유지
    - 네이버 로그인 성공 후 받은 access_token을
      Cloud Function 'createCustomTokenFromNaver'에 전달
    - Custom Token으로 FirebaseAuth.signInWithCustomToken
    - SharedPreferences 저장 코드는 제거 (Firebase Auth가 자동 관리)

3. 카페 매칭 관련 코드는 W1.1에서 제거됐으므로 추가 작업 없음

4. 테스트:
    - 네이버 로그인 → Firebase UID 획득
    - 앱 재시작 후 자동 로그인 유지 확인

완료 후 git commit -m "feat: integrate Naver login with Firebase Custom Token"
```

---

### □ [W1.6] 로그인 페이지 UI 4 버튼 통합

**상태**: 대기 | **예상**: 2h | **종속성**: W1.2 ~ W1.5

**파일**:
- `lib/features/auth/presentation/login_page.dart`

**완료 기준**:
- ✅ 4개 버튼 (Apple은 iOS만) 표시
- ✅ 각 버튼 클릭 시 해당 OAuth 플로우 동작
- ✅ 로딩 상태·에러 표시

**Claude Code 프롬프트**:
```
로그인 페이지를 4가지 소셜 로그인 버튼으로 재구성합니다.

CLAUDE.md Section 9-2 (인증 흐름) 참조.

작업:

1. lib/features/auth/presentation/login_page.dart 전면 재작성

   레이아웃:
    - 상단: 한미동맹단 로고 + 슬로건
    - 하단: 4개 로그인 버튼 (Apple은 Platform.isIOS일 때만)
    - 버튼 순서:
        1. Apple (iOS만, 검정 배경 + 흰색 사과 아이콘)
        2. Kakao (#FEE500 배경, 검정 텍스트)
        3. Naver (#03C75A 배경, 흰색 N 아이콘)
        4. Google (흰 배경 테두리, 구글 컬러 G)

2. 각 버튼 처리:
    - tap → 해당 AuthService 호출
    - 진행 중 로딩 인디케이터
    - 성공 시: 신규/기존 분기
        * 신규 사용자 (users 문서 없음) → TermsAgreementPage 이동 (W1.7)
        * 기존 사용자 → HomePage 이동
    - 실패 시: 에러 토스트

3. 신규/기존 사용자 판별 로직:
   ```dart
   final user = await FirebaseAuth.instance.currentUser;
   final doc = await FirebaseFirestore.instance
       .collection('users').doc(user.uid).get();
   if (doc.exists) {
     // 기존 사용자 → 홈
   } else {
     // 신규 사용자 → 약관 동의 화면
   }
   ```

4. 디자인 가이드:
    - CLAUDE.md Section 3 컬러 토큰만 사용
    - 버튼 높이 56px, border-radius 12px
    - 버튼 간격 12px
    - 버튼 텍스트: "Apple로 시작하기" / "카카오로 시작하기" 등

5. 약관 미니 버전:
    - 페이지 하단에 "로그인하면 이용약관 및 개인정보처리방침에 동의합니다" 안내
    - 정식 동의는 W1.7의 TermsAgreementPage에서

완료 후 git commit -m "feat: 4 social login buttons in login page"
```

---

### □ [W1.7] 약관 동의 + 닉네임 설정 페이지

**상태**: 대기 | **예상**: 2h | **종속성**: W1.6

**파일**:
- `lib/features/auth/presentation/terms_agreement_page.dart` (신규)
- `lib/features/auth/presentation/nickname_setup_page.dart` (신규)
- `assets/legal/terms_v1.md` (placeholder)
- `assets/legal/privacy_v1.md` (placeholder)

**완료 기준**:
- ✅ 약관 미동의 시 다음 페이지 진행 불가
- ✅ 닉네임 2~12자 검증
- ✅ 닉네임 중복 검사
- ✅ users 컬렉션에 신규 문서 생성

**Claude Code 프롬프트**:
```
신규 사용자를 위한 가입 플로우 2개 페이지를 만듭니다.

CLAUDE.md Section 9-2 가입 흐름 참조.

작업:

1. lib/features/auth/presentation/terms_agreement_page.dart

   레이아웃:
    - "한미동맹단 가입을 환영합니다" 헤더
    - 약관 동의 체크박스 3개:
      [필수] 이용약관 동의 [보기]
      [필수] 개인정보처리방침 동의 [보기]
      [선택] 마케팅 정보 수신 동의
    - "전체 동의" 토글
    - 하단 "다음" 버튼 (필수 2개 모두 체크 시 활성)

   동작:
    - "보기" 누르면 약관 전체 화면 모달 (assets/legal/*.md 표시)
    - "다음" → NicknameSetupPage로 push
    - 동의 데이터를 NicknameSetupPage에 전달

2. lib/features/auth/presentation/nickname_setup_page.dart

   레이아웃:
    - "어떻게 불러드릴까요?" 헤더
    - 닉네임 입력 필드 (2~12자 카운터)
    - 실시간 검증:
        * 길이 (2~12자)
        * 특수문자 제한 (한글·영문·숫자만)
        * 중복 검사 (debounce 500ms)
    - "한미동맹단 시작하기" 버튼

   동작:
    - 검증 통과 시 users 문서 생성:
      ```dart
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'provider': '...',
        'providerUserId': '...',
        'email': user.email,
        'nickname': nickname,
        'profileImageUrl': null,
        'level': 1,
        'points': 0,
        'consentedTerms': true,
        'consentedPrivacy': true,
        'consentedAt': FieldValue.serverTimestamp(),
        'termsVersion': 'v1.0',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignedInAt': FieldValue.serverTimestamp(),
        'consecutiveCheckInDays': 0,
        'isAdmin': false,
        'isBanned': false,
        'stats': {...},
        'referralCode': _generateReferralCode(),
        'referredBy': null,
      });
      ```
    - 생성 완료 → HomePage로 이동 (replace, 뒤로가기 불가)

3. 닉네임 중복 검사:
    - users 컬렉션에서 nickname == 입력값 쿼리
    - ⚠️ Firestore 쿼리는 비효율적이므로 Cloud Function 호출 권장
    - 1차: 클라이언트 직접 쿼리 (소규모 사용자 OK)
    - 2차: 추후 nickname → uid 매핑 컬렉션 추가 (별도 작업)

4. 약관 placeholder:
    - assets/legal/terms_v1.md 와 privacy_v1.md를 임시 텍스트로 작성
    - 정식 약관은 OWNER_TODO 8번에서 변호사 검토 후 교체

5. pubspec.yaml에 assets 추가:
   assets:
    - assets/legal/

완료 후 git commit -m "feat: terms agreement and nickname setup pages"
```

---

## 🗓️ Week 2 — 백엔드 연동 Firestore (8개 작업)

> **선행 조건**: Week 1 완료
> **브랜치**: `feat/firestore-migration`

---

### □ [W2.0] Firestore Security Rules 배포

**상태**: 대기 | **예상**: 1h | **종속성**: W1.7

**파일**:
- `firestore.rules`

**완료 기준**:
- ✅ Rules 시뮬레이터로 9개 시나리오 통과 (FIRESTORE_SCHEMA.md Section 8)
- ✅ Production 배포 성공

**Claude Code 프롬프트**:
```
Firestore Security Rules를 작성·배포합니다.

FIRESTORE_SCHEMA.md Section 3 전체 코드를 firestore.rules에 작성합니다.

작업:

1. 프로젝트 루트에 firestore.rules 생성
2. FIRESTORE_SCHEMA.md Section 3의 코드 그대로 복사
3. firebase.json에 rules 등록 확인:
   {
   "firestore": {
   "rules": "firestore.rules",
   "indexes": "firestore.indexes.json"
   }
   }

4. Firebase Emulator로 검증:
   firebase emulators:start --only firestore
   별도 시뮬레이터로 Section 8의 9개 시나리오 테스트

5. 시뮬레이터 통과 후 배포:
   firebase deploy --only firestore:rules

⚠️ 배포 전 반드시 시뮬레이터 검증.
실수 시 모든 데이터 접근 차단되어 앱 사용 불가.

완료 후 git commit -m "feat: deploy firestore security rules v1"
```

---

### □ [W2.1] Firestore Composite Indexes 배포

**상태**: 대기 | **예상**: 30m | **종속성**: W2.0

**파일**:
- `firestore.indexes.json`

**Claude Code 프롬프트**:
```
복합 인덱스를 배포합니다.

작업:

1. 프로젝트 루트에 firestore.indexes.json 생성
2. FIRESTORE_SCHEMA.md Section 4의 JSON 그대로 복사
3. 배포: firebase deploy --only firestore:indexes
4. Firebase Console > Firestore > Indexes에서 빌드 진행 확인
   (대규모 컬렉션 아니면 1~5분 내 완료)

완료 후 git commit -m "feat: deploy firestore composite indexes"
```

---

### □ [W2.2] Cloud Functions 프로젝트 초기화

**상태**: 대기 | **예상**: 1h | **종속성**: W2.0

**파일**:
- `functions/` 폴더 구조

**Claude Code 프롬프트**:
```
Cloud Functions 프로젝트를 초기화합니다.

작업:

1. firebase init functions
    - TypeScript 선택
    - ESLint 사용
    - npm install

2. functions/src/ 폴더 구조 생성 (CLAUDE.md Section 13 참조):
   functions/src/
   ├── index.ts
   ├── auth/
   ├── points/
   ├── stats/
   ├── admin/
   └── moderation/

3. functions/src/index.ts에 빈 export만 작성:
   export * from './auth';
   export * from './points';
   export * from './stats';

4. 각 폴더에 index.ts 빈 파일 + 향후 추가될 함수의 stub

5. functions/package.json 의존성 추가:
    - axios (Kakao/Naver API용)
    - firebase-admin
    - firebase-functions

6. 빈 함수 1개 배포 테스트:
   export const ping = functions.https.onCall(() => ({ pong: true }));
   firebase deploy --only functions:ping
   → 배포 성공 확인 후 함수 삭제

완료 후 git commit -m "chore: init cloud functions project"
```

---

### □ [W2.3] Custom Token Cloud Functions 배포

**상태**: 대기 | **예상**: 30m | **종속성**: W2.2, W1.4, W1.5

**파일**:
- `functions/src/auth/createCustomTokenFromKakao.ts` (W1.4에서 작성)
- `functions/src/auth/createCustomTokenFromNaver.ts` (W1.5에서 작성)
- `functions/src/auth/index.ts`

**Claude Code 프롬프트**:
```
W1.4, W1.5에서 작성한 Custom Token 함수를 정식 배포합니다.

작업:

1. functions/src/auth/index.ts에 export 추가:
   export { createCustomTokenFromKakao } from './createCustomTokenFromKakao';
   export { createCustomTokenFromNaver } from './createCustomTokenFromNaver';

2. functions/src/index.ts에 from './auth' 추가

3. 빌드: cd functions && npm run build

4. 배포: firebase deploy --only functions:createCustomTokenFromKakao,functions:createCustomTokenFromNaver

5. 클라이언트에서 카카오·네이버 로그인 재시도하여 토큰 발급 확인

완료 후 git commit -m "feat: deploy custom token cloud functions"
```

---

### □ [W2.4] onUserCreated 트리거 (가입 환영 +50P)

**상태**: 대기 | **예상**: 1h | **종속성**: W2.2

**파일**:
- `functions/src/auth/onUserCreated.ts` (신규)

**Claude Code 프롬프트**:
```
사용자 가입 시 +50P 적립 + referralCode 생성하는 Firestore 트리거를 만듭니다.

CLAUDE.md Section 10-2 (점수 적립 규칙) 참조.

작업:

functions/src/auth/onUserCreated.ts:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onUserCreated = functions.firestore
  .document('users/{uid}')
  .onCreate(async (snap, context) => {
    const uid = context.params.uid;
    const user = snap.data();
    
    const batch = admin.firestore().batch();
    
    // 1. point_logs 추가
    const logRef = admin.firestore().collection('point_logs').doc();
    batch.set(logRef, {
      id: logRef.id,
      uid,
      type: 'welcome',
      amount: 50,
      refId: null,
      refType: null,
      pointsAfter: 50,
      levelAfter: 1,
      levelChanged: false,
      description: '한미동맹단 가입을 환영합니다! +50P',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      adjustedBy: null,
      adjustReason: null,
    });
    
    // 2. users.points 증가
    batch.update(snap.ref, {
      points: 50,
    });
    
    // 3. notifications 추가
    const notifRef = admin.firestore().collection('notifications').doc();
    batch.set(notifRef, {
      id: notifRef.id,
      uid,
      type: 'point_awarded',
      title: '+50P 환영 보너스',
      body: '한미동맹단 가입을 환영합니다!',
      imageUrl: null,
      routeName: '/profile/points',
      routeParams: null,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      readAt: null,
      fcmSent: false,
      fcmMessageId: null,
    });
    
    await batch.commit();
    
    // 4. 추천인 처리 (referredBy 있으면)
    if (user.referredBy) {
      // 별도 작업: 추천인에게 +200P 적립
      // → W3.x에서 onReferralComplete로 분리
    }
  });
```

배포: firebase deploy --only functions:onUserCreated

테스트:
- 새 계정 가입
- users 문서에 points: 50 확인
- point_logs에 welcome 로그 확인
- notifications에 알림 확인

완료 후 git commit -m "feat: onUserCreated trigger - welcome bonus"
```

---

### □ [W2.5] ActionEvent 모델 Firestore 변환

**상태**: 대기 | **예상**: 1.5h | **종속성**: W2.0

**파일**:
- `lib/features/action_board/domain/action_event.dart`
- `lib/features/action_board/data/action_event_store.dart`

**Claude Code 프롬프트**:
```
ActionEvent 모델과 스토어를 Firestore 기반으로 재작성합니다.

CLAUDE.md Section 5-3, FIRESTORE_SCHEMA.md Section 2-3 참조.

작업:

1. lib/features/action_board/domain/action_event.dart 수정
    - 기존 필드 유지 + Firestore 매핑 메서드 추가:
        - factory ActionEvent.fromFirestore(DocumentSnapshot doc)
        - Map<String, dynamic> toMap()
    - DateTime은 Timestamp.toDate() 사용
    - FIRESTORE_SCHEMA.md events 컬렉션 필드 모두 반영

2. lib/features/action_board/data/action_event_store.dart 재작성
    - 기존 ValueNotifier 기반 → Stream 기반으로 변경
    - 메서드:
        * static Stream<List<ActionEvent>> watchAll()
        * static Stream<List<ActionEvent>> watchUpcoming()
        * static Stream<ActionEvent?> watchById(String id)
        * static Future<String> add(ActionEvent event) // 관리자만
        * static Future<void> update(String id, Map<String, dynamic> changes)
        * static Future<void> delete(String id) // 관리자만
    - 시드 데이터 의존 제거

3. 시드 데이터 일회성 업로드 스크립트:
   scripts/migrate_events.dart (FIRESTORE_SCHEMA.md Section 6-2 참조)
    - dart run scripts/migrate_events.dart 로 실행
    - 한 번 실행 후 action_event_seed.dart 파일 보관 (참고용)

⚠️ 주의:
- 기존 ActionEventStore의 ValueNotifier 사용 화면들은 다음 작업(W2.6)에서 변경
- 이 작업에서는 모델·스토어만 교체

완료 후 git commit -m "refactor: migrate ActionEvent to Firestore"
```

---

### □ [W2.6] 행사 관련 화면 Stream 변환

**상태**: 대기 | **예상**: 2h | **종속성**: W2.5

**파일**:
- `lib/features/action_board/presentation/action_board_page.dart`
- `lib/features/action_board/presentation/action_event_form_page.dart`
- `lib/features/action_board/presentation/action_notice_detail_page.dart`
- `lib/features/calendar/presentation/calendar_page.dart`
- `lib/features/home/presentation/home_page.dart` (행사 관련 부분)

**Claude Code 프롬프트**:
```
ActionEventStore가 Stream 기반이 됐으니 사용 화면을 StreamBuilder로 변경합니다.

작업:

1. lib/features/action_board/presentation/action_board_page.dart
    - ValueListenableBuilder → StreamBuilder<List<ActionEvent>>
    - ActionEventStore.watchAll() 구독
    - 로딩/에러 상태 처리

2. lib/features/action_board/presentation/action_event_form_page.dart
    - ActionEventStore.add() / update() 호출
    - 비동기 처리 + 성공/실패 토스트

3. lib/features/action_board/presentation/action_notice_detail_page.dart
    - StreamBuilder<ActionEvent?> watchById(eventId)
    - 실시간 업데이트 반영

4. lib/features/calendar/presentation/calendar_page.dart
    - 마찬가지로 Stream 구독

5. lib/features/home/presentation/home_page.dart
    - 행사 관련 부분 Stream 구독 (UpcomingEventCard 자리)

검증:
- 한 디바이스에서 행사 추가
- 다른 디바이스 (또는 핫 리로드)에서 즉시 반영 확인

⚠️ Stream 구독은 dispose에서 cancel 필수:
StreamSubscription? _sub;
@override
void dispose() { _sub?.cancel(); super.dispose(); }

완료 후 git commit -m "refactor: stream-based event screens"
```

---

### □ [W2.7] 시드 데이터 Firestore 업로드

**상태**: 대기 | **예상**: 30m | **종속성**: W2.5

**파일**:
- `scripts/migrate_events.dart`
- `scripts/seed_app_meta.dart`

**Claude Code 프롬프트**:
```
기존 시드 데이터를 Firestore에 일회성 업로드합니다.

FIRESTORE_SCHEMA.md Section 6 참조.

작업:

1. scripts/migrate_events.dart 작성·실행
    - action_event_seed.dart의 데이터 → events 컬렉션
    - createdBy: 'system' 으로 설정
    - status는 eventDate 기준으로 'upcoming' 결정

2. scripts/seed_app_meta.dart 작성·실행
    - app_meta/policies 문서 생성
    - FIRESTORE_SCHEMA.md Section 6-3 데이터 사용

3. scripts/seed_app_meta.dart 에 stats 초기 문서도 생성:
   await firestore.doc('app_meta/stats').set({
   'memberCount': 0,
   'activePetitions': 0,
   'monthlyEvents': 0,
   'totalPosts': 0,
   'totalComments': 0,
   'totalSignatures': 0,
   'updatedAt': FieldValue.serverTimestamp(),
   });

4. 실행 후 Firebase Console에서 데이터 확인

⚠️ 한 번만 실행. 실수로 두 번 실행 시 중복 데이터 발생.
실행 직후 스크립트 파일 이름을 _migrated.dart 로 변경 추천.

완료 후 git commit -m "chore: seed initial firestore data"
```

---

## 🗓️ Week 3 — 점수 시스템 + 청원 탭 (10개 작업)

> **브랜치**: `feat/point-system`, `feat/petition-tab`

---

### □ [W3.0] Post / CommunityPost Firestore 마이그레이션

**상태**: 대기 | **예상**: 2h | **종속성**: W2.7

**Claude Code 프롬프트**:
```
W2.5와 동일 패턴으로 Post(피드/커뮤니티 게시글)를 Firestore로 변환합니다.

FIRESTORE_SCHEMA.md Section 2-4 참조.

작업:
1. CommunityPost 모델에 fromFirestore/toMap 추가
2. CommunityPostStore Stream 기반 재작성
3. 페이지네이션 (cursor 기반):
    - .limit(20) + .startAfterDocument() 패턴
4. Optimistic UI (작성 즉시 화면 반영, 실패 시 롤백)
5. CommunityBoardPage / CommunityPostDetailPage / CommunityPostFormPage 화면들 StreamBuilder 적용
6. 시드 데이터 → 일회성 업로드 (scripts/migrate_posts.dart)

⚠️ 비정규화 필드 채우기:
- 작성 시점 user의 nickname, level을 authorNickname, authorLevel에 복사
- 작성자 닉네임 변경되어도 기존 글은 옛 닉네임 유지

완료 후 git commit -m "refactor: migrate Post to Firestore"
```

---

### □ [W3.1] Comments 서브컬렉션 + 카운트 트리거

**상태**: 대기 | **예상**: 2h | **종속성**: W3.0

**Claude Code 프롬프트**:
```
댓글을 posts/{id}/comments 서브컬렉션으로 구현합니다.

작업:
1. Comment 모델 (FIRESTORE_SCHEMA.md Section 2-5)
2. CommentStore Stream 기반
3. CommunityPostDetailPage에 댓글 영역 추가
4. Cloud Function: onCommentCreated
    - Post.commentCount += 1
    - 작성자에게 +5P (W3.3에서 통합)
    - 글 작성자에게 알림

완료 후 git commit -m "feat: comments subcollection with counters"
```

---

### □ [W3.2] onPostCreated 점수 적립 트리거 (+30P)

**상태**: 대기 | **예상**: 1.5h | **종속성**: W3.0

**Claude Code 프롬프트**:
```
게시글 작성 시 +30P 적립 트리거를 만듭니다.

CLAUDE.md Section 10-2, 10-3 참조.

functions/src/points/onPostCreated.ts:

```typescript
export const onPostCreated = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const uid = post.authorId;
    
    // 일일 한도 체크 (3개)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todaysPosts = await admin.firestore()
      .collection('point_logs')
      .where('uid', '==', uid)
      .where('type', '==', 'post_create')
      .where('createdAt', '>=', today)
      .count()
      .get();
    
    if (todaysPosts.data().count >= 3) {
      console.log(`Daily limit reached for ${uid}`);
      return;
    }
    
    // 점수 적립 (헬퍼 함수)
    await awardPointsHelper({
      uid,
      type: 'post_create',
      amount: 30,
      refId: snap.id,
      refType: 'post',
      description: '게시글 작성 +30P',
    });
    
    // users.stats.postsCount++
    await admin.firestore().collection('users').doc(uid).update({
      'stats.postsCount': admin.firestore.FieldValue.increment(1),
    });
  });
```

awardPointsHelper는 별도 함수로 functions/src/points/_helpers.ts에 작성:
- point_logs 추가
- users.points += amount
- recalculateLevel 호출 (등급 변동 시)
- notifications 추가

배포 후 게시글 작성 → +30P 토스트 확인.

완료 후 git commit -m "feat: onPostCreated trigger - 30P reward"
```

---

### □ [W3.3] onCommentCreated, onLikeReceived 트리거 (+5P, +2P)

**상태**: 대기 | **예상**: 1.5h | **종속성**: W3.2

**Claude Code 프롬프트**:
```
댓글·좋아요 점수 적립 트리거 추가.

functions/src/points/:
1. onCommentCreated - 일일 10회 한도, +5P
2. onLikeReceived - 일일 50회 한도, +2P
   ⚠️ 좋아요는 별도 likes 서브컬렉션 만들거나
   post.likes 배열로 관리할지 결정 필요
   → posts/{id}/likes/{uid} 서브컬렉션 권장

W3.2의 패턴 그대로 적용.

완료 후 git commit -m "feat: comment and like point triggers"
```

---

### □ [W3.4] recalculateLevel 등급 자동 승급

**상태**: 대기 | **예상**: 1h | **종속성**: W3.2

**Claude Code 프롬프트**:
```
points 변경 시 등급 재계산 + 승급 알림.

functions/src/points/recalculateLevel.ts:

```typescript
export const recalculateLevel = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.points === after.points) return;  // points 안 바뀌면 스킵
    
    const newLevel = calculateLevel(after.points);
    
    if (newLevel !== after.level) {
      await change.after.ref.update({ level: newLevel });
      
      if (newLevel > after.level) {
        // 승급 알림
        await admin.firestore().collection('notifications').add({
          uid: context.params.uid,
          type: 'level_up',
          title: `Lv${newLevel} 승급!`,
          body: getLevelName(newLevel) + ' 등급이 되셨습니다',
          // ...
        });
        
        // FCM 푸시 (W5에서 구현)
      }
    }
  });

function calculateLevel(points: number): number {
  if (points >= 5000) return 5;
  if (points >= 2000) return 4;
  if (points >= 500) return 3;
  if (points >= 100) return 2;
  return 1;
}
```

배포 + 테스트:
- 가입 후 +50P → Lv1 유지 확인
- 게시글 작성 누적 100P 도달 → Lv2 자동 승급 확인

완료 후 git commit -m "feat: auto level recalculation on points change"
```

---

### □ [W3.5] PointLog 화면 (활동 이력)

**상태**: 대기 | **예상**: 1.5h | **종속성**: W3.4

**Claude Code 프롬프트**:
```
사용자가 자기 점수 적립 이력을 볼 수 있는 화면.

CLAUDE.md Section 4-2의 PointHistoryPage 참조.

작업:

1. lib/features/profile/data/point_log_store.dart
    - watchMyLogs() Stream
    - point_logs where uid == myUid orderBy createdAt desc

2. lib/features/profile/presentation/point_history_page.dart
    - 상단: 누적 포인트·등급 카드
    - 본문: 점수 적립 이력 리스트
        * 아이콘 (type별)
        * 제목 (description)
        * 점수 (+30P 등 색상)
        * 시간 (상대값)
    - 무한 스크롤 (cursor pagination)

3. lib/features/profile/presentation/level_guide_page.dart
    - 5단계 등급 카드 표시
    - 각 등급의 혜택·조건
    - 현재 진행도 게이지

4. MyPage에서 위 두 화면으로 진입 동선 추가

완료 후 git commit -m "feat: point history and level guide pages"
```

---

### □ [W3.6] Petition 모델 + 스토어

**상태**: 대기 | **예상**: 1.5h | **종속성**: W2.7

**Claude Code 프롬프트**:
```
청원 시스템 데이터 레이어.

FIRESTORE_SCHEMA.md Section 2-6, 2-7 참조.

작업:

1. lib/features/petition/domain/petition.dart
    - 모델 + fromFirestore + toMap

2. lib/features/petition/data/petition_store.dart
    - watchAll(filter)  // 진행중/인기/신규/완료
    - watchById(id)
    - add(petition) // 관리자만
    - hasSigned(petitionId, uid) // signatures/{uid} 존재 여부

3. 임시 시드 데이터 (관리자 화면 만들기 전):
    - Firebase Console에서 직접 1~2개 청원 추가
    - 또는 scripts/seed_petitions.dart

완료 후 git commit -m "feat: petition data layer"
```

---

### □ [W3.7] PetitionPage + PetitionCard

**상태**: 대기 | **예상**: 2h | **종속성**: W3.6

**Claude Code 프롬프트**:
```
CLAUDE.md Section 8 (청원 화면 명세) 그대로 구현.

작업:

1. lib/features/petition/presentation/widgets/petition_card.dart
    - Section 8-2 명세 그대로
    - 진행률 바 색상 자동 (80%/50%/그 외)
    - D-day 계산 + 뱃지

2. lib/features/petition/presentation/widgets/progress_bar.dart
    - percent prop으로 색상 결정
    - 부드러운 애니메이션 (curve: easeInOut)

3. lib/features/petition/presentation/petition_page.dart
    - 세그먼트 바 (진행중/인기/신규/완료)
    - StreamBuilder로 청원 리스트
    - Pull-to-refresh

완료 후 git commit -m "feat: petition list page with cards"
```

---

### □ [W3.8] PetitionDetailPage + 서명 처리

**상태**: 대기 | **예상**: 2h | **종속성**: W3.7

**Claude Code 프롬프트**:
```
청원 상세 + Optimistic UI 서명.

CLAUDE.md Section 8-3 참조.

작업:

1. lib/features/petition/presentation/petition_detail_page.dart
    - 청원 상세 내용
    - 진행률 바 (실시간)
    - 서명자 수 (실시간)
    - 서명 버튼 (상태별 4가지)

2. Cloud Function: signPetition (호출형)
   functions/src/points/signPetition.ts:
    - 입력: petitionId
    - 검증:
        * 인증 사용자
        * 차단 안된 사용자
        * 이미 서명 안 함 (signatures/{uid} 없음)
        * 청원 active 상태
    - 트랜잭션:
        * signatures/{uid} 생성
        * petitions.currentCount++
        * point_logs 추가 (+50P)
        * users.points += 50
        * users.stats.petitionsSignedCount++
        * 마일스톤 도달 (50%, 100%) → 알림

3. 서명 버튼 처리 (Optimistic UI):
    - 즉시 UI 변경
    - Cloud Function 호출
    - 실패 시 롤백 + 토스트

완료 후 git commit -m "feat: petition detail with signing"
```

---

### □ [W3.9] dailyCheckIn 함수 + 홈 체크인 버튼

**상태**: 대기 | **예상**: 1.5h | **종속성**: W3.4

**Claude Code 프롬프트**:
```
일일 체크인 시스템.

CLAUDE.md Section 10-2 참조.

작업:

1. functions/src/points/dailyCheckIn.ts (호출형)
    - daily_check_ins/{uid_YYYY-MM-DD} 문서 검사
    - 이미 있으면 'already_checked' 반환
    - 없으면 트랜잭션:
        * daily_check_ins 생성
        * point_logs +10P
        * users.points += 10
        * users.lastCheckInAt = now
        * users.consecutiveCheckInDays = 어제 체크인 했으면 +1, 아니면 1
        * 3일/7일 보너스 별도 적립

2. 홈에 체크인 버튼 추가
    - HomeMainPage에 작은 카드형 버튼
    - 오늘 체크인 했으면 "체크 완료 ✓" (비활성)
    - 안 했으면 "출석 +10P" (활성)
    - 연속 체크인 표시

완료 후 git commit -m "feat: daily check-in system"
```

---

## 🗓️ Week 4 — 홈 리뉴얼 + 범프탭바 + 출시 설정 (10개 작업)

> **브랜치**: `feat/home-revamp`, `feat/release-config`

---

### □ [W4.0] 범프탭바 CustomPainter 구현

**상태**: 대기 | **예상**: 2h | **종속성**: W3.9

**Claude Code 프롬프트**:
```
CLAUDE.md Section 5 그대로 범프 탭바 구현.

작업:

1. lib/shared/widgets/bump_bottom_nav_painter.dart
    - CustomPainter 클래스
    - Section 5-2의 Path 코드 그대로 (Flutter 변환)
    - 그림자 처리 (drawShadow)

2. lib/shared/widgets/bump_bottom_nav.dart
    - StatelessWidget
    - 5탭 구조
    - 중앙 버튼: Stack + Positioned (clipBehavior: Clip.none)
    - 미읽 알림 dot 뱃지

테스트:
- iOS/Android 양쪽에서 자연스러운 돌출
- SafeArea 정상 처리

완료 후 git commit -m "feat: bump bottom navigation bar"
```

---

### □ [W4.1] HomePage 5탭 재배치

**상태**: 대기 | **예상**: 1h | **종속성**: W4.0

**Claude Code 프롬프트**:
```
CLAUDE.md Section 4 화면 구조에 맞게 HomePage 탭 재배치.

탭 순서: 피드 | 청원 | 홈(중앙) | 일정 | 마이

작업:

1. lib/features/home/presentation/home_page.dart 재작성
    - 기존 IndexedStack 또는 PageView 유지
    - 5탭 컨텐츠 매핑:
      0: FeedPage
      1: PetitionPage
      2: HomeMainPage (W4.2-4.7에서 만들 것)
      3: CalendarPage
      4: MyPage
    - BumpBottomNav 사용

2. 일단 HomeMainPage는 임시 placeholder (다음 작업에서 채움)

완료 후 git commit -m "feat: 5-tab navigation with bump bar"
```

---

### □ [W4.2] StatsStore + Cloud Function

**상태**: 대기 | **예상**: 1.5h | **종속성**: W4.1

**Claude Code 프롬프트**:
```
홈 통계 카운터를 위한 데이터 레이어.

작업:

1. functions/src/stats/updateAppStats.ts (스케줄러)
    - functions.pubsub.schedule('every 5 minutes')
    - 각 컬렉션 count() 집계
    - app_meta/stats 문서 업데이트

2. lib/features/home/data/stats_store.dart
    - watchStats() Stream
    - app_meta/stats 문서 구독

배포 + 5분 대기 후 stats 갱신 확인.

완료 후 git commit -m "feat: app stats stream + scheduled updater"
```

---

### □ [W4.3] CountUpText 위젯

**상태**: 대기 | **예상**: 1h | **종속성**: W4.2

**Claude Code 프롬프트**:
```
숫자 카운트업 애니메이션 위젯.

CLAUDE.md Section 6-1 참조.

lib/features/home/presentation/widgets/count_up_text.dart:

```dart
class CountUpText extends StatefulWidget {
  final int target;
  final Duration duration;
  final TextStyle? style;
  final String suffix;  // 'K' 등
  
  const CountUpText({
    required this.target,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.suffix = '',
  });
}

class _CountUpTextState extends State<CountUpText> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.target)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }
  
  // ...
}
```

완료 후 git commit -m "feat: count up text widget"
```

---

### □ [W4.4] HeroStatsSection

**상태**: 대기 | **예상**: 1.5h | **종속성**: W4.3

**Claude Code 프롬프트**:
```
홈 상단 통계 카운터 섹션.

CLAUDE.md Section 6-1 그대로.

lib/features/home/presentation/widgets/hero_stats_section.dart:
- 헤더 텍스트
- 3개 통계 카드 (가입회원/진행청원/이번달행사)
- StatsStore 구독
- CountUpText 사용
- K 단위 변환 (10000 이상)

완료 후 git commit -m "feat: hero stats section"
```

---

### □ [W4.5] QuickActionGrid + BreakingAlertCard

**상태**: 대기 | **예상**: 1h | **종속성**: W4.4

**Claude Code 프롬프트**:
```
홈 하위 위젯 2개 구현.

CLAUDE.md Section 6-2, 6-5 참조.

작업:

1. lib/features/home/presentation/widgets/quick_action_grid.dart
    - 3버튼 (행동동원/일정관리/청원서명)
    - 각 버튼 → 해당 탭으로 이동

2. lib/features/home/presentation/widgets/breaking_alert_card.dart
    - posts where isUrgent=true 1개 구독
    - 없으면 SizedBox.shrink()
    - 좌측 빨간 세로선 + 긴급 뱃지

완료 후 git commit -m "feat: quick action grid + breaking alert"
```

---

### □ [W4.6] LiveFeedPreview + LiveIndicator

**상태**: 대기 | **예상**: 1.5h | **종속성**: W4.5

**Claude Code 프롬프트**:
```
실시간 피드 프리뷰.

CLAUDE.md Section 6-3 그대로.

작업:

1. lib/features/home/presentation/widgets/live_indicator.dart
    - 빨간 dot opacity 0.8↔1.0 1500ms 펄스
    - "LIVE" 텍스트

2. lib/features/home/presentation/widgets/live_feed_preview.dart
    - posts orderBy createdAt desc limit 3 구독
    - 새 글 진입 시 슬라이드인 (AnimatedList)
    - 각 아이템: 카테고리 색상 바 + 제목 + 시간
    - "더보기" → 피드 탭

완료 후 git commit -m "feat: live feed preview with indicator"
```

---

### □ [W4.7] HotPetitionSection + UpcomingEventCard

**상태**: 대기 | **예상**: 1h | **종속성**: W4.6

**Claude Code 프롬프트**:
```
나머지 홈 섹션.

CLAUDE.md Section 6-4, 6-6 참조.

작업:

1. hot_petition_section.dart
    - petitions where status=active orderBy currentCount desc limit 3
    - ProgressBar (W3.7과 같은 위젯 재사용)

2. upcoming_event_card.dart
    - events where eventDate >= now() orderBy eventDate asc limit 1
    - D-day 큰 숫자
    - 참여 신청 버튼

3. HomeMainPage 조립:
    - W4.4~W4.7의 모든 위젯 SingleChildScrollView로 배치
    - 순서: HeroStats → QuickAction → BreakingAlert → LiveFeed → HotPetition → UpcomingEvent

완료 후 git commit -m "feat: complete home main page"
```

---

### □ [W4.8] 패키지 ID·Bundle ID 변경

**상태**: 대기 | **예상**: 2h | **종속성**: W4.7

**파일**:
- `android/app/build.gradle.kts`
- `ios/Runner.xcodeproj/project.pbxproj`
- `android/app/google-services.json` (재발급)
- `ios/Runner/GoogleService-Info.plist` (재발급)

**Claude Code 프롬프트**:
```
출시용 패키지 ID·Bundle ID 변경.

CLAUDE.md Section 16-1 (절대 규칙) 주의: 한 번만 변경, 이후 절대 변경 금지.

작업:

1. 결정된 ID 확인 (대표님과 협의):
    - applicationId: com.rokus.alliance (예시)
    - Bundle ID: com.rokus.alliance (동일하게)

2. android/app/build.gradle.kts 수정:
   defaultConfig {
   applicationId = "com.rokus.alliance"
   // ...
   }

3. ios/Runner Bundle ID 변경:
    - Xcode에서 변경 권장 (혹은 .pbxproj 직접 수정)
    - PRODUCT_BUNDLE_IDENTIFIER 항목 검색해서 변경

4. Firebase Console 작업 (대표님 안내):
    - Firebase Console > 프로젝트 설정 > 앱 추가
    - Android 새 패키지명 등록 → google-services.json 재발급
    - iOS 새 Bundle ID 등록 → GoogleService-Info.plist 재발급
    - 새 파일을 프로젝트에 교체

5. flutter clean && flutter pub get

6. 빌드 테스트:
    - flutter build apk --debug
    - flutter build ios --no-codesign

⚠️ 카카오·네이버 SDK도 새 패키지명 등록 필요:
- Kakao Developers > 플랫폼 > Android/iOS 패키지 추가
- Naver Developers > 환경 정보 > Android/iOS 패키지 추가

완료 후 git commit -m "chore: change package id and bundle id"
```

---

### □ [W4.9] 릴리즈 서명 설정

**상태**: 대기 | **예상**: 2h | **종속성**: W4.8

**Claude Code 프롬프트**:
```
출시용 빌드 서명 설정.

작업:

1. Android keystore 생성:
   keytool -genkey -v -keystore ~/.android/rokus-alliance-release.jks \
   -keyalg RSA -keysize 2048 -validity 10000 \
   -alias rokus

   ⚠️ keystore 파일과 비밀번호는 절대 git 커밋 금지
   ⚠️ 분실 시 앱 업데이트 영구 불가

2. android/key.properties 생성 (.gitignore 등록):
   storeFile=/Users/.../rokus-alliance-release.jks
   storePassword=...
   keyAlias=rokus
   keyPassword=...

3. android/app/build.gradle.kts 릴리즈 서명 설정:
    - 기존 signingConfigs.getByName("debug") → release 추가
    - buildTypes.release.signingConfig = signingConfigs.getByName("release")

4. iOS Distribution Certificate:
    - Xcode > Signing & Capabilities
    - Apple Developer 계정으로 자동 설정 (Automatic Signing)
    - Provisioning Profile 자동 발급

5. 빌드 테스트:
    - flutter build appbundle --release
    - flutter build ipa --release

⚠️ keystore 백업 필수 (대표님 OWNER_TODO 추가):
- 외장 하드 또는 클라우드 (1Password, Keeper 등)
- 비밀번호 별도 보관

완료 후 git commit -m "chore: setup release signing"
```

---

## 🗓️ Week 5 — 정리 + 약관 + 멤버십 카드 (8개 작업)

---

### □ [W5.0] 죽은 코드 제거

**상태**: 대기 | **예상**: 1h | **종속성**: W4.9

**Claude Code 프롬프트**:
```
사용 안 되는 코드 정리.

대상:
- lib/features/mission/ 전체 삭제
- lib/features/meetup/ 전체 삭제
- lib/features/briefing/ 전체 삭제
- lib/features/search/ 전체 삭제

추가 정리:
- pubspec.yaml에서 youtube_player_iframe 제거 (briefing에서만 썼음)
- 미사용 import 일괄 정리
- print() / debugPrint() 제거 또는 kDebugMode 가드

검증:
- flutter analyze → 경고 0
- flutter test → 통과
- 앱 빌드 정상

완료 후 git commit -m "chore: remove dead code"
```

---

### □ [W5.1] 약관·개인정보 페이지

**상태**: 대기 | **예상**: 1.5h | **종속성**: W5.0

**Claude Code 프롬프트**:
```
약관 보기 화면.

작업:

1. assets/legal/terms_v1.md 정식 약관 작성 (또는 placeholder 유지)
2. assets/legal/privacy_v1.md 개인정보처리방침 작성
3. lib/features/settings/presentation/terms_page.dart - markdown 렌더링
4. lib/features/settings/presentation/privacy_page.dart - markdown 렌더링
5. flutter_markdown 패키지 추가
6. 외부 약관 페이지 게시 안내 (대표님 OWNER_TODO 8번)

완료 후 git commit -m "feat: terms and privacy pages"
```

---

### □ [W5.2] 푸시 알림 (FCM)

**상태**: 대기 | **예상**: 2h | **종속성**: W5.1

**Claude Code 프롬프트**:
```
FCM 푸시 알림 설정.

작업:

1. firebase_messaging 패키지 추가
2. lib/shared/services/notification_service.dart
    - FCM 토큰 발급 + users.deviceToken 저장
    - 권한 요청 (iOS는 명시적 요청 필요)
    - 포그라운드/백그라운드 메시지 핸들러
3. iOS APNs 설정 (Apple Developer 콘솔)
4. Cloud Function: 알림 트리거 시 FCM 발송
    - notifications 컬렉션 onCreate → FCM 발송
5. 인앱 알림 센터 (NotificationPage)

완료 후 git commit -m "feat: FCM push notifications"
```

---

### □ [W5.3] 멤버십 카드 (선택)

**상태**: 대기 | **예상**: 2h | **종속성**: W5.2

**Claude Code 프롬프트**:
```
디지털 회원증 화면.

CLAUDE.md Section 11 참조.

작업:

1. qr_flutter, screenshot 패키지 추가
2. lib/features/profile/presentation/membership_card_page.dart
    - 카드 디자인 (국기 스트라이프, 이름, 등급, 점수)
    - QR 표시 (단순 ID 인코딩)
    - 화면 밝기 자동 최대 (screen_brightness)
3. 카드 캡처·공유 (screenshot + share_plus)
4. app_meta/policies.features.membershipCardEnabled 토글로 제어

완료 후 git commit -m "feat: membership card page"
```

---

### □ [W5.4] 행사 체크인 6자리 코드

**상태**: 대기 | **예상**: 2h | **종속성**: W5.3

**Claude Code 프롬프트**:
```
CLAUDE.md Section 11-3 참조.

작업:

1. 관리자: 행사 화면에서 "체크인 코드 발급" 버튼
    - Cloud Function: generateEventCode (호출형)
    - event_codes/{code} 생성, 10분 유효
2. 사용자: 행사 상세에서 "참여 코드 입력"
    - Cloud Function: eventCheckIn (호출형)
    - 코드 검증 + check_ins 생성 + +100P
3. EventDetailPage UI 추가

완료 후 git commit -m "feat: event check-in with 6-digit code"
```

---

### □ [W5.5] 정치 표현·시드 데이터 정리

**상태**: 대기 | **예상**: 1h | **종속성**: W5.4

**Claude Code 프롬프트**:
```
Apple 심사 거절 위험 표현 제거.

작업:

1. 시드 데이터 검토 (events, posts):
    - "CCP OUT", "YOON FREE" 등 직접적 정치 키워드 → 톤다운
    - 예: "윤어게인" → "정상화를 위한 행동"
    - 예: "부정선거 척결 집회" → "공정선거를 위한 시민 행동"

2. UI 카피 검토:
    - 광고문구·헤더·소개글 모두
    - "보수" 단어는 OK (가치판단 단어)
    - 특정 정당·정치인 비방 표현 → 제거

3. 시드 데이터 날짜 점검:
    - 미래 날짜로 수정
    - 출시 예상 시점 이후로

완료 후 git commit -m "chore: tone down political expressions for store review"
```

---

### □ [W5.6] 앱 아이콘 + 스플래시 적용

**상태**: 대기 | **예상**: 1h | **종속성**: W5.5

**Claude Code 프롬프트**:
```
대표님이 발주한 앱 아이콘 적용.

작업:

1. flutter_launcher_icons 패키지 사용
   pubspec.yaml:
   flutter_launcher_icons:
   android: true
   ios: true
   image_path: "assets/images/app_icon.png"
   adaptive_icon_background: "#FFFFFF"
   adaptive_icon_foreground: "assets/images/app_icon_foreground.png"

2. flutter pub run flutter_launcher_icons:main

3. 스플래시:
   flutter_native_splash 패키지 사용
   pubspec.yaml:
   flutter_native_splash:
   color: "#15233F"
   image: assets/images/splash_logo.png

4. flutter pub run flutter_native_splash:create

완료 후 git commit -m "chore: app icon and native splash"
```

---

### □ [W5.7] 스토어 등록 자료 준비

**상태**: 대기 | **예상**: 1h | **종속성**: W5.6

**Claude Code 프롬프트**:
```
앱스토어/플레이스토어 등록 자료 준비.

작업:

1. assets/store_assets/ 폴더에 정리:
    - 스크린샷 (대표님이 디자이너 발주, 또는 실기기 캡처)
    - 6.7" iPhone: 1290x2796 5장
    - 5.5" iPhone: 1242x2208 5장
    - Android: 1080x1920 이상 5장

2. docs/store_listing.md 작성:
    - 앱 이름 (한국어/영어)
    - 짧은 설명 (80자)
    - 긴 설명 (4000자, 한국어/영어)
    - 키워드 (한국어 100자)
    - 카테고리 결정 (News 또는 Social Networking 권장)
    - 콘텐츠 등급 (만 12세 또는 17세)

3. docs/release_notes_v1.0.md
    - 첫 출시 노트

⚠️ 한미동맹단 명칭 사용 동의 증빙 자료 준비 (대표님 OWNER_TODO 6번)

완료 후 git commit -m "chore: store listing assets and copy"
```

---

## 🗓️ Week 6 — 베타 + 심사 (7개 작업)

---

### □ [W6.0] flutter analyze + flutter test 통과

**상태**: 대기 | **예상**: 2h | **종속성**: W5.7

**Claude Code 프롬프트**:
```
모든 경고·테스트 통과.

작업:

1. flutter analyze
    - 모든 경고 fix
    - prefer_const_constructors 등 lint 적용

2. flutter test
    - 기본 테스트 작성 (위젯 빌드 테스트)
    - 핵심 비즈니스 로직 테스트 (등급 계산 등)

3. 메모리 릭 점검:
    - StreamSubscription cancel
    - AnimationController dispose
    - TextEditingController dispose

완료 후 git commit -m "chore: pass analyze and tests"
```

---

### □ [W6.1] TestFlight 베타 배포

**상태**: 대기 | **예상**: 2h | **종속성**: W6.0

**Claude Code 프롬프트**:
```
iOS 베타 배포.

작업:

1. flutter build ipa --release
2. Apple Transporter로 업로드 또는 Xcode Archive
3. App Store Connect:
    - TestFlight 그룹 생성 ("내부 테스터")
    - 베타 빌드 등록
    - 초대 이메일 30개 입력
4. 베타 노트 작성

⚠️ 첫 업로드는 24시간 내 처리되지 않을 수 있음

완료 후 git commit -m "chore: testflight beta release"
```

---

### □ [W6.2] Google Play Internal Testing

**상태**: 대기 | **예상**: 1h | **종속성**: W6.0

**Claude Code 프롬프트**:
```
Android 내부 테스트.

작업:

1. flutter build appbundle --release
2. Google Play Console:
    - Internal Testing 트랙 생성
    - aab 업로드
    - 테스터 이메일 30개 입력
3. 테스트 링크 공유

완료 후 git commit -m "chore: play internal testing release"
```

---

### □ [W6.3] 베타 피드백 반영

**상태**: 대기 | **예상**: 8h (가변) | **종속성**: W6.1, W6.2

**Claude Code 프롬프트**:
```
베타 테스터 30명에게 피드백 받고 반영.

수집 채널:
- 카카오톡 단톡방
- 구글 폼
- TestFlight 피드백

분류:
- 🔴 Blocker: 심사 전 반드시 수정
- 🟡 Important: 출시 직후 빠르게 패치
- 🟢 Nice to have: 1.1 버전에 반영

작업:
1. 피드백 정리 (docs/beta_feedback_v1.md)
2. Blocker 수정
3. 새 빌드 → 베타 재배포

완료 후 git commit -m "fix: address beta feedback"
```

---

### □ [W6.4] 약관·정책 외부 게시

**상태**: 대기 | **예상**: 30m | **종속성**: W6.3

**Claude Code 프롬프트**:
```
앱스토어 등록 시 필요한 약관 URL 준비.

작업:

1. 정적 사이트로 약관 게시:
    - GitHub Pages 또는 Notion 공개 페이지
    - terms.html, privacy.html
    - 모바일 친화 레이아웃

2. URL 확정:
    - https://rokus-alliance.com/terms (예시)
    - https://rokus-alliance.com/privacy

3. 앱 내 약관 페이지에서도 외부 URL 링크 추가

⚠️ 대표님 OWNER_TODO 8번 (약관 작성·검토)이 완료되어야 함

완료 후 git commit -m "chore: external terms and privacy pages"
```

---

### □ [W6.5] App Store 심사 제출

**상태**: 대기 | **예상**: 2h | **종속성**: W6.4

**Claude Code 프롬프트**:
```
Apple App Store 심사 제출.

작업:

1. App Store Connect 정보 입력:
    - 앱 이름·부제·설명
    - 키워드·카테고리
    - 스크린샷·아이콘
    - 약관·개인정보 URL
    - 콘텐츠 등급 설문 (만 12세 또는 17세)
    - 데모 계정 정보 (심사관용 - 약관 동의된 테스트 계정)

2. 정치 카테고리 대응:
    - "리뷰 노트" 칸에:
      "본 앱은 한미동맹단 단체의 공식 협력 앱으로, 단체 명칭 사용 허락을 받았습니다.
      [협력 증빙 자료 첨부]
      본 앱은 정치 단체 운영이 아니며, 시민 참여 플랫폼으로 분류됩니다.
      혐오 발언 금지 정책을 명시하며 신고 시스템을 운영합니다."

3. 심사 제출

⚠️ 거절 시 대응 (CLAUDE.md Section 19):
- 단체 협력 증빙
- 약관 명확화
- 카테고리 변경 (Lifestyle → News 등)

완료 후 git commit -m "chore: submitted to app store"
```

---

### □ [W6.6] Google Play 심사 제출

**상태**: 대기 | **예상**: 2h | **종속성**: W6.4

**Claude Code 프롬프트**:
```
Google Play Console 심사 제출.

작업:

1. Production 트랙 생성
2. 정보 입력 (App Store와 동일하되 Google 형식)
3. 데이터 보안 섹션 (수집 데이터 명시):
    - 개인정보: 이메일·닉네임·OAuth ID
    - 위치: 사용 안함 (또는 행사 GPS 사용 시 명시)
    - 메시지: 댓글·게시글
    - 사진: 프로필·게시글 첨부

4. 콘텐츠 등급 설문
5. 타겟 연령
6. 심사 제출

심사 일반: 7일

완료 후 git commit -m "chore: submitted to play store"
```

---

## 🎉 출시 후 작업 (Week 7+)

심사 통과 후 진행할 작업들 (이번 문서 범위 밖):

```
□ 정식 출시 발표
□ 단체 채널 홍보
□ 첫 행사 연계 마케팅
□ 사용자 데이터 분석 (PostHog)
□ 1.1 패치 (베타 피드백 nice-to-have 항목)
□ 관리자 웹 대시보드 (대표님 결정 보류)
□ 추천인 시스템
□ 커머스 모듈
□ 광고 SDK (AdMob)
□ 본격 보수 플랫폼 신규 앱 설계
```

---

## 📊 진행 추적 요약

```
Week 1: 인증 시스템    (8개)  □□□□□□□□
Week 2: Firestore     (8개)  □□□□□□□□
Week 3: 점수+청원     (10개) □□□□□□□□□□
Week 4: 홈+범프+출시  (10개) □□□□□□□□□□
Week 5: 정리+약관    (8개)  □□□□□□□□
Week 6: 베타+심사    (7개)  □□□□□□□

합계 51개
```

---

## 🆘 막힐 때 대응

**디버깅 우선순위**:
1. flutter analyze
2. firebase functions:log
3. Firestore Console > Rules 시뮬레이터
4. CLAUDE.md Section 19 트러블슈팅

**Claude Code에 도움 요청 시**:
```
W[X.Y] 작업 중 [구체적 문제] 발생.
에러 메시지: [전문]
시도한 것: [목록]
관련 파일: [경로]
CLAUDE.md Section [N]을 참고하여 진단·수정해주세요.
```

---

## 변경 이력

| 일자 | 버전 | 변경 |
|------|------|------|
| 2026-04 | 1.0 | 초안 (51개 작업) |

---

*Last updated: 2026-04*
*Version: 1.0*
*Maintained by: 대표님 + Claude*