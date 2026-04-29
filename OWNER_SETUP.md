# OWNER_SETUP.md — 대표님 직접 처리 단계별 셋업

> 이 문서는 코드 작업이 모두 끝난 상태에서 **앱이 실제로 동작하게 만들기 위해 대표님이 직접 처리해야 하는 외부 가입·설정·배포 절차**를 순서대로 정리한 체크리스트입니다.
>
> 각 단계는 의존성 순서대로 정렬돼 있고, 완료 후 다음으로 넘어가세요. 🟢 = 즉시 가능 / 🟡 = 비용 발생 / 🔴 = 대기 시간 있음.
>
> **참고 문서**: `OWNER_TODO.md` (가입·계약 큰 그림), `CLAUDE.md` (전체 v3 가이드), `FIRESTORE_SCHEMA.md` (DB 설계도), `NEXT_STEPS.md` (코드 작업 큐).

---

## 📋 한 눈에 보기

| 단계 | 작업 | 비용 | 시간 | 차단 항목 |
|---|---|---|---|---|
| 0 | 환경 — Windows Dev Mode | 0원 | 1분 | flutter 빌드 자체 |
| 1 | Firebase CLI 설치·로그인 | 0원 | 5분 | deploy 전부 |
| 2 | Firestore Rules + Indexes 배포 | 0원 | 10분 | 모든 DB 읽기·쓰기 |
| 3 | Cloud Functions 배포 | 0원 (소규모) | 15분 | 점수·청원·체크인·로그인·푸시 |
| 4 | 시드 데이터 업로드 | 0원 | 5분 | 빈 화면 → 실데이터 |
| 5 | Naver 로그인 검수 (선택) | 0원 | 1주 | 네이버 OAuth |
| 6 | Kakao Developers + Native App Key | 0원 | 30분 | 카카오 OAuth |
| 7 | Android: SHA-1 등록 + google-services.json 갱신 | 0원 | 15분 | 구글 OAuth |
| 8 | Apple Developer Program | $99/년 | 1~3일 승인 | iOS 빌드·Apple 로그인·APNs |
| 9 | iOS: Bundle ID 결정 + GoogleService-Info.plist 발급 + URL Schemes | 0원 | 1시간 | iOS 빌드 일체 |
| 10 | Android 릴리즈 keystore | 0원 | 10분 | 출시 빌드 |
| 11 | iOS APNs 인증서 (FCM 푸시) | 0원 | 15분 | iOS 푸시 |
| 12 | Google Play Console 가입 | $25 일회 | 1~2일 | Android 출시 |
| 13 | App Store Connect 정보 입력 | (포함) | 1시간 | iOS 심사 |
| 14 | 약관 외부 페이지 게시 | 0원 | 30분 | 심사 요건 |

---

## 🟢 0. Windows Developer Mode

**왜**: Flutter가 플러그인 빌드 시 symlink를 만드는데, Windows는 Developer Mode가 켜져 있어야 symlink 생성을 허용합니다. 이게 없으면 `flutter run`이 시작도 안 됩니다.

**방법**:

```powershell
start ms-settings:developers
```

설정 창 → "개발자 모드" 토글 **ON**.

✅ 끝.

---

## 🟢 1. Firebase CLI 설치 + 프로젝트 로그인

**왜**: rules / indexes / functions 배포에 사용. 시드 스크립트 실행에는 불필요(앱 자체로 실행).

**방법**:

```bash
npm install -g firebase-tools
firebase login              # 브라우저로 Google 로그인
firebase use rok-us-alliance-app   # 프로젝트 선택 (이미 .firebaserc에 default 지정됨)
```

**검증**:

```bash
firebase projects:list
# rok-us-alliance-app 가 (current) 라고 표시되는지 확인
```

⚠️ Firebase 프로젝트가 아직 만들어져 있지 않으면 먼저 [console.firebase.google.com](https://console.firebase.google.com) 에서 프로젝트 생성 후 ID를 `rok-us-alliance-app`으로 맞추거나, `lib/firebase_options.dart` + `.firebaserc` + `firebase.json` + `android/app/google-services.json`의 projectId를 새 ID로 일괄 교체.

---

## 🟢 2. Firestore Rules + Indexes 배포

**왜**: 코드는 user 문서·posts·petitions 등을 읽고 씁니다. Rules가 없으면 production 모드 프로젝트는 모든 접근을 거절합니다.

**사전 검증** (선택):

```bash
firebase emulators:start --only firestore
# 다른 터미널에서 시뮬레이터 UI(http://127.0.0.1:4000)로
# FIRESTORE_SCHEMA.md Section 8 의 9 시나리오 통과 확인
```

**배포**:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

✅ Firebase Console > Firestore > Indexes 에서 빌드가 1~5분 안에 완료되면 끝.
✅ Storage rules 는 콘솔 > Storage > Rules 탭에서 즉시 반영 확인 가능.

> **참고**: `storage.rules` 는 프로필 사진 업로드(users/{uid}/profile.jpg) 권한을 정의합니다.
> 누락 시 **Storage 업로드가 실패**하므로 반드시 위 명령에 포함해 배포하세요.

---

## 🟢 3. Cloud Functions 빌드·배포

**왜**: 13개 함수가 점수 적립·청원 서명·행사 체크인·일일 체크인·소셜 로그인 Custom Token·푸시 발송·계정 탈퇴 등 핵심 동작을 담당합니다.

**방법**:

```bash
cd functions
npm install               # 첫 1회만 (~3분)
npm run build             # tsc 컴파일 — TS 오류 있으면 여기서 발견
cd ..
firebase deploy --only functions
```

**배포되는 함수 13개**:

| 카테고리 | 함수 | 트리거 |
|---|---|---|
| auth | createCustomTokenFromKakao | onCall (클라) |
| auth | createCustomTokenFromNaver | onCall (클라) |
| auth | onUserCreated | users 문서 onCreate (가입 +50P) |
| points | onPostCreated | posts onCreate (+30P) |
| points | onCommentCreated | comments onCreate (+5P) |
| points | onLikeReceived / onLikeRemoved | posts/{id}/likes onCreate/onDelete (+2P) |
| points | recalculateLevel | users onUpdate (등급 자동 산출) |
| points | signPetition | onCall (+50P) |
| points | dailyCheckIn | onCall (+10P, 연속 보너스) |
| points | eventCheckIn | onCall (+100P) |
| points | generateEventCode | onCall (관리자 6자리 코드 발급) |
| stats | updateAppStats | 5분 스케줄러 |
| notifications | dispatchNotificationOnCreate | notifications onCreate → FCM |
| admin | deleteUserAccount | onCall (계정 탈퇴) |

⚠️ **TS 빌드 오류가 발견되면 직접 수정**하지 마시고 Claude에게 메시지 그대로 전달해주세요. 첫 빌드라 여러 케이스가 한꺼번에 떨어질 수 있어 일괄 수정이 효율적입니다.

⚠️ Cloud Functions는 Blaze(종량제) 플랜 필수. Firebase Console > 사용량 및 결제 > Blaze 업그레이드 (소규모 사용 시 월 $0~$1).

---

## 🟢 4. 시드 데이터 업로드

**왜**: events 10개 + app_meta/policies + app_meta/stats 가 있어야 빈 홈/피드/일정 화면이 채워집니다.

**방법** (각 1회만):

```bash
flutter run -t scripts/migrate_events.dart -d <device>
# 화면 탭 → "완료. 10건 업로드됨" 확인 → 앱 종료

flutter run -t scripts/seed_app_meta.dart -d <device>
# 화면 탭 → "완료" 확인 → 앱 종료
```

⚠️ **두 번 실행 금지**. events는 중복 생성, stats는 0으로 초기화됩니다.

✅ Firebase Console > Firestore > events 에 10개 문서 / app_meta/policies + stats 2개 문서가 생기면 끝.

---

## 🟢 5. Naver Developers 검수 (선택)

**왜**: 기존 v2 시절 등록된 Naver 앱이 있으면 그 키를 그대로 사용 가능. 신규로 만들어야 하면:

**방법**:

1. [developers.naver.com](https://developers.naver.com) 로그인
2. Application > 애플리케이션 등록
3. 사용 API: **네이버 로그인** 체크
4. 환경: Android, iOS
5. 패키지명/Bundle ID는 W4.8(아래 9단계)에서 확정한 후 등록
6. **검수 신청** (비즈니스용 사용 시 필수, 결과 ~1주)
7. Client ID / Client Secret 메모

⚠️ Cloud Functions 의 `createCustomTokenFromNaver` 는 access_token 만 사용해 Naver `/v1/nid/me` API 를 호출하므로 Client Secret 등록은 안 해도 동작. 다만 향후 토큰 refresh 등 확장 시 필요.

---

## 🟢 6. Kakao Developers + Native App Key

**왜**: Kakao 로그인 SDK 초기화에 Native App Key 필요.

**방법**:

1. [developers.kakao.com](https://developers.kakao.com) 카카오 계정으로 로그인
2. 내 애플리케이션 → 추가하기
3. 앱 이름: `한미동맹단`, 회사명: 운영 사업자
4. **앱 설정 → 카카오 로그인 → 활성화 ON**
5. **동의 항목**: 닉네임(필수), 프로필 사진·이메일(선택)
6. **플랫폼 등록** (Android/iOS — W4.8 후 패키지명 확정 후)
7. **앱 키 → Native App Key** 복사 → 메모

빌드 시 키 주입:

```bash
flutter run --dart-define=KAKAO_NATIVE_APP_KEY=<복사한키>
```

**비즈니스 채널 신청** (출시 시 필수): 사업자등록증 첨부, 검수 1~2주.

---

## 🟢 7. Android: SHA-1 등록 + google-services.json 갱신

**왜**: Google Sign-In은 Firebase Console에 SHA-1이 등록돼야 동작합니다(`ApiException 10` 방지).

**방법**:

```bash
cd android
./gradlew signingReport
# 출력의 'SHA1' 값 복사 (debug variant 의 것)
cd ..
```

1. [console.firebase.google.com](https://console.firebase.google.com) → `rok-us-alliance-app` → 프로젝트 설정 → Android 앱
2. **SHA 인증서 지문** 추가 → 위에서 복사한 SHA-1 붙여넣기
3. **Authentication > Sign-in method > Google 활성화** (이메일 한 줄 입력 필요)
4. 같은 페이지 하단 **google-services.json 다운로드**
5. `android/app/google-services.json` 에 덮어쓰기 (기존 oauth_client 빈 배열이 채워짐)

릴리즈 시점엔 release variant SHA-1도 같은 방식으로 추가 (10단계 keystore 생성 후).

---

## 🟡 8. Apple Developer Program 가입

**왜**: iOS 빌드·Sign in with Apple·APNs 푸시·App Store 출시 모두 필수.

**비용**: $99/년 (약 13만원).

**방법**:

1. [developer.apple.com/programs/](https://developer.apple.com/programs/) 가입
2. 결제 (신용카드)
3. 1~3일 내 승인 메일 수신
4. 승인 후 App ID 생성:
   - Certificates, Identifiers & Profiles → Identifiers → +
   - Bundle ID: `com.rokus.alliance` (예시 — 9단계와 동일하게)
   - **Capabilities**: ☑ Sign in with Apple

법인 가입 시 **D-U-N-S 번호** 별도 발급 필요(무료, 5~14일 — [developer.apple.com/support/D-U-N-S/](https://developer.apple.com/support/D-U-N-S/)).

---

## 🟢 9. iOS Bundle ID 결정 + GoogleService-Info.plist + URL Schemes

**왜**: 현재 Bundle ID 가 placeholder `com.example.rokUsAllianceApp`. iOS 빌드를 한 번이라도 하려면 정식 ID 필요.

**방법**:

1. **Bundle ID 결정** (이후 변경 금지): `com.rokus.alliance` 권장
2. Xcode에서 `ios/Runner.xcodeproj` 열기 → Runner > Signing & Capabilities → Bundle Identifier 변경
3. **+ Capability → Sign in with Apple** 추가 (8단계 App ID와 일치)
4. Firebase Console → 프로젝트 설정 → 앱 추가 → iOS → Bundle ID 입력
5. **GoogleService-Info.plist 다운로드** → `ios/Runner/` 에 추가 (Xcode에서 Runner target 에 포함)
6. plist 파일을 텍스트로 열어 `REVERSED_CLIENT_ID` 값 복사
7. `ios/Runner/Info.plist` 의 `CFBundleURLTypes` 배열에 추가:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>(REVERSED_CLIENT_ID 값)</string>
         <string>kakao(KAKAO_NATIVE_APP_KEY)</string>
       </array>
     </dict>
   </array>
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>kakaokompassauth</string>
     <string>kakaolink</string>
   </array>
   ```

8. **Android applicationId** 도 `android/app/build.gradle.kts` 에서 같이 변경 (Bundle ID 와 동일하게)
9. **AndroidManifest.xml** 에 Kakao Activity 추가:

   ```xml
   <activity
       android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
       android:exported="true">
     <intent-filter android:label="flutter_web_auth">
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="kakao(KAKAO_NATIVE_APP_KEY)" android:host="oauth"/>
     </intent-filter>
   </activity>
   ```

10. `flutter clean && flutter pub get` 으로 캐시 정리

11. **Firebase Console** → 기존 placeholder 앱은 삭제하고 새 Bundle ID 로 등록한 앱만 남김. `lib/firebase_options.dart` 도 `flutterfire configure --project=rok-us-alliance-app` 으로 재생성.

⚠️ **Bundle ID/applicationId는 한 번 변경 후 재변경 금지** (Firebase·Kakao·Naver·Apple 모든 키 재발급 필요). 8~9단계는 한 자리에서 한 번에 하세요.

---

## 🟢 10. Android 릴리즈 keystore 생성

**왜**: Google Play Store에 release APK/AAB를 올리려면 서명 필요.

**방법**:

```bash
keytool -genkey -v -keystore $HOME/.android/rokus-alliance-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rokus
# 비밀번호·이름·조직·국가 입력 (CN/Country만 KR이면 OK)
```

`android/key.properties` 생성 (.gitignore에 등록):

```properties
storeFile=/Users/.../rokus-alliance-release.jks
storePassword=...
keyAlias=rokus
keyPassword=...
```

`android/app/build.gradle.kts` 에 release 서명 설정 추가 (별도 안내 가능).

⚠️ **keystore 파일과 비밀번호는 절대 git에 커밋 금지**. 분실 시 앱 업데이트 영구 불가. 1Password 등 안전한 곳에 백업 필수.

릴리즈 빌드용 SHA-1도 따로 추출해 7단계와 같은 방식으로 Firebase Console 에 추가:

```bash
keytool -list -v -keystore $HOME/.android/rokus-alliance-release.jks -alias rokus
```

---

## 🟢 11. iOS APNs 인증서 (FCM 푸시 활성화)

**왜**: FCM은 Android는 별도 설정 없이 동작하지만 iOS는 APNs 인증서가 필요합니다.

**방법** (8단계 Apple Developer + 9단계 GoogleService-Info.plist 완료 후):

1. [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles
2. Identifiers → 8단계에서 만든 App ID 선택 → **Push Notifications** Capability 활성화
3. Keys → +Key → 이름 `FCM Push` → ☑ Apple Push Notifications service (APNs) → Continue → Register
4. **.p8 파일 다운로드** (한 번만 가능, 잘 보관)
5. Key ID, Team ID 메모
6. Firebase Console → 프로젝트 설정 → Cloud Messaging → Apple 앱 구성 → APNs 인증 키 업로드
   - .p8 파일 + Key ID + Team ID 입력

✅ 끝. 이후 `notifications` 컬렉션에 doc이 생기면 자동 푸시.

---

## 🟡 12. Google Play Console 가입

**비용**: $25 일회성 (약 3.3만원).

**방법**:

1. [play.google.com/console/signup](https://play.google.com/console/signup)
2. Google 계정으로 가입 + 결제
3. 24~48시간 승인
4. **개발자 계정 인증** (2024년부터 신분증/사업자등록증 필수)
5. 새 앱 생성:
   - 앱 이름: 한미동맹단
   - 패키지명: 9단계 applicationId 와 동일
   - 카테고리: News 또는 Social Networking 권장 (정치 카테고리 회피)

---

## 🟢 13. App Store Connect 정보 입력 (8단계 후 가능)

**방법**:

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 나의 앱 → +
2. 8단계의 Bundle ID 선택
3. 앱 정보:
   - 한국어/영어 이름·부제·설명·키워드·스크린샷(아래 별도)
   - 카테고리: News 또는 Social Networking 권장
   - 콘텐츠 등급 설문 (만 12세 또는 17세)
   - **데모 계정**: 심사관용 테스트 계정(소셜 로그인 우회를 위한 디버그 로그인 안내 또는 별도 admins/{uid} 권한 부여)
4. **리뷰 노트** 칸:

   ```
   본 앱은 한미동맹단 단체의 공식 협력 앱으로, 단체 명칭 사용
   허락을 받았습니다. [협력 증빙 자료 첨부]
   본 앱은 정치 단체 운영이 아닌 시민 참여 플랫폼으로 분류되며,
   혐오 발언 금지 정책과 신고 시스템을 운영합니다.
   ```

---

## 🟢 14. 약관·개인정보처리방침 외부 페이지 게시

**왜**: App Store / Play Store 등록 시 약관 URL 필수.

**방법**:

1. `assets/legal/terms_v1.md` / `privacy_v1.md` 의 placeholder 텍스트를 정식 약관으로 교체 (변호사 검토 권장)
2. GitHub Pages, Notion 공개 페이지, 또는 자체 도메인에 정적 HTML로 게시:
   - 예: `https://rokus-alliance.com/terms`, `/privacy`
3. App Store Connect / Play Console 의 정책 URL 칸에 입력
4. 앱 내 약관 페이지(`TermsPage`/`PrivacyPage`) 도 외부 URL 링크 추가 가능

---

## ✅ 완료 후 빠른 검증 체크리스트

위 단계 모두 끝났다면 실기기에서 다음을 확인:

```bash
flutter run --dart-define=KAKAO_NATIVE_APP_KEY=<실제키>
```

- [ ] 4개 OAuth 버튼 각각으로 가입 → users/{uid} 생성됨 + +50P 환영 알림 받음
- [ ] 게시글 작성 → +30P 토스트
- [ ] 댓글 작성 → +5P
- [ ] 좋아요 누르고 다시 진입 → 좋아요 상태 유지 + 작성자에게 +2P
- [ ] 청원 서명 → +50P + 진행률 +1
- [ ] 행사 체크인 6자리 코드 입력 → +100P
- [ ] 일일 체크인 → +10P (연속 3일째 +30P 보너스, 7일째 +70P)
- [ ] 100P 누적 → Lv2 시민 승급 알림
- [ ] 종 아이콘 빨간 dot → 알림 목록 페이지에서 일괄 읽음
- [ ] 마이페이지 → 멤버십 카드 → 카드 공유하기 → 카톡으로 PNG 공유
- [ ] 마이페이지 → 계정 탈퇴 → users/{uid} 와 Auth user 모두 사라짐 → LoginPage 회귀

---

## 🆘 막힐 때

| 에러 메시지 | 원인 | 해결 |
|---|---|---|
| `ApiException 10` (Google) | SHA-1 미등록 | 7단계 다시 |
| `Kakao SDK not initialized` | `--dart-define=KAKAO_NATIVE_APP_KEY` 누락 | 6단계의 키로 재실행 |
| `function not found` (CF call) | functions 미배포 | 3단계 |
| Firestore `permission-denied` | rules 미배포 | 2단계 |
| `requires symlink support` | Windows Dev Mode 꺼짐 | 0단계 |
| iOS 빌드 실패 + Apple Sign In 관련 | App ID 에 capability 미활성 | 8단계 |
| FCM iOS 안 옴 | APNs 키 미등록 | 11단계 |

---

## 📦 코드 변경 후 재배포 패턴

코드를 수정한 뒤 다시 deploy해야 할 때:

```bash
# Cloud Functions 만 변경됐으면
cd functions && npm run build && cd ..
firebase deploy --only functions

# Firestore rules 만 변경됐으면
firebase deploy --only firestore:rules

# 인덱스가 추가됐으면
firebase deploy --only firestore:indexes

# 클라이언트만 변경됐으면 deploy 불필요. flutter run 으로 재실행.
```

---

*Last updated: 2026-04-30*
*Version: 1.0*
