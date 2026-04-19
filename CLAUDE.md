# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> 코드 작업 전 이 파일 전체를 반드시 읽으세요. 실제 코드베이스 기준으로 작성된 단일 진실 소스입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | ROK-US Alliance |
| 목적 | 한미동맹단 공식 모바일 앱 — 디지털 멤버십 카드, QR 현장 참여, 커뮤니티·행동 공지 통합 플랫폼 |
| 플랫폼 | iOS / Android / Web (Flutter) |
| 타겟 | 보수 시민 네트워크 정회원 및 지지자 |

---

## 2. 기술 스택

```
프레임워크     Flutter (Dart) — Material 3
상태관리       ValueNotifier + ValueListenableBuilder (외부 패키지 없음)
로컬 저장      SharedPreferences
백엔드/DB      Firebase (Firestore + Firebase Auth)
인증           Naver OAuth (flutter_naver_login) + Firebase Email/Password (관리자 전용)
동영상         youtube_player_iframe
공유           share_plus
URL            url_launcher
린트           flutter_lints
```

---

## 3. 디자인 시스템

### 3-1. 색상 토큰 (`lib/app/theme/app_colors.dart`)

```dart
// 주요 팔레트 — 태극기 + 성조기
darkNavy      #050D1F   앱 AppBar·히어로 배경
navy          #0B1F5C   보조 딥 네이비
koreanRed     #CD2E3A   액센트 레드 (집회·긴급)
koreanBlue    #003478   주 색상 (버튼·선택·뱃지)
gold          #C8A84B   Gold 등급·완료 상태

// 배경
background    #F2F5FB   Scaffold 배경
softBlue      #EAF0FF   파란 계열 카드 배경
softRed       #FFEEEE   빨간 계열 카드 배경

// 텍스트·경계선
textPrimary   #111111
textSecondary #5F6773
border        #E3E8F2

// 그라디언트
shieldGradient       koreanRed → koreanBlue (대각선) — 방패 아이콘, 섹션 바
flagAccentGradient   koreanRed → white → koreanBlue (수평) — 플래그 스트라이프
heroGradient         darkNavy → #0A1830 (수직) — 히어로 카드
```

**규칙: 색상 하드코딩 금지. 반드시 `AppColors.*` 토큰 사용.**

### 3-2. 공통 위젯 (`lib/app/widgets/`)

| 파일 | 용도 |
|------|------|
| `alliance_app_bar.dart` | 앱 전체 공용 AppBar. `AllianceAppBar.main()` / `AllianceAppBar.sub()` |
| `alliance_loading_indicator.dart` | 태극 ↔ 성조기 별 교차 애니메이션 로딩. `AllianceLoadingIndicator(size)` / `AllianceLoadingOverlay(message)` |

새 페이지를 만들 때 AppBar는 반드시 이 두 팩토리를 사용한다.

### 3-3. 테마 (`lib/app/theme/app_theme.dart`)

Material 3 기반. AppBarTheme·NavigationBarTheme·FilledButtonTheme·CardTheme·InputDecorationTheme 모두 중앙 설정됨. 개별 위젯에서 재정의하지 않는다.

---

## 4. 파일 구조

```
lib/
├── main.dart                          Firebase 초기화 → ROKUSAllianceApp 실행
├── firebase_options.dart              FlutterFire CLI 자동 생성 (수정 금지)
│
├── app/
│   ├── app.dart                       MaterialApp 루트, 라우팅 진입점
│   ├── theme/
│   │   ├── app_colors.dart            색상 토큰 (단일 진실 소스)
│   │   └── app_theme.dart             Material 3 테마 전체 설정
│   └── widgets/
│       ├── alliance_app_bar.dart      공용 AppBar
│       └── alliance_loading_indicator.dart  커스텀 로딩 인디케이터
│
└── features/                          피처별 레이어드 구조
    ├── auth/
    │   ├── data/
    │   │   ├── auth_store.dart        일반 유저 상태 (ValueNotifier<AuthState>)
    │   │   ├── admin_auth_store.dart  관리자 상태 (Firebase Auth 기반)
    │   │   └── naver_auth_service.dart  네이버 OAuth 래퍼
    │   ├── domain/
    │   │   └── app_user.dart          일반 유저 모델
    │   └── presentation/
    │       ├── login_page.dart
    │       ├── signup_complete_page.dart
    │       └── admin_login_page.dart
    │
    ├── splash/presentation/splash_page.dart
    ├── home/presentation/home_page.dart         바텀탭 5개 탭 컨테이너
    ├── briefing/presentation/briefing_page.dart
    ├── calendar/presentation/calendar_page.dart
    ├── meetup/presentation/meetup_page.dart
    ├── mission/presentation/mission_page.dart   StatefulWidget — 완료 상태 추적
    ├── profile/presentation/profile_page.dart
    ├── search/
    │   ├── data/search_history_store.dart
    │   └── presentation/search_page.dart
    ├── action_board/
    │   ├── data/
    │   │   ├── action_event_store.dart  ValueNotifier<List<ActionEvent>> (로컬 시드)
    │   │   └── action_event_seed.dart
    │   ├── domain/action_event.dart     Firestore 직렬화 포함
    │   └── presentation/
    │       ├── action_board_page.dart
    │       ├── action_event_form_page.dart   관리자 공지 등록
    │       └── action_notice_detail_page.dart
    └── community/
        ├── data/
        │   ├── community_post_store.dart
        │   └── community_post_seed.dart
        ├── domain/community_post.dart
        └── presentation/
            ├── community_page.dart
            ├── community_board_page.dart
            ├── community_post_detail_page.dart
            └── community_post_form_page.dart
```

---

## 5. 라우팅 & 네비게이션

Named route 없음. 전부 `Navigator.push(MaterialPageRoute(...))` 사용.

```
앱 진입
└── SplashPage
    ├── (미로그인) → LoginPage → SignupCompletePage → HomePage
    └── (로그인됨) → HomePage

HomePage (BottomNavigationBar, 5탭)
├── Tab 0: BriefingPage      오늘의 이슈 브리핑
├── Tab 1: ActionBoardPage   행동 공지 게시판
├── Tab 2: CommunityPage     커뮤니티
├── Tab 3: CalendarPage      일정 캘린더
└── Tab 4: ProfilePage       마이페이지

ActionBoardPage → ActionNoticeDetailPage
ActionBoardPage (관리자) → ActionEventFormPage
CommunityPage → CommunityBoardPage → CommunityPostDetailPage
CommunityPostDetailPage → CommunityPostFormPage (수정)
```

---

## 6. 상태 관리 패턴

외부 패키지(Provider, Riverpod, BLoC 등) 없음. 순수 `ValueNotifier` 사용.

```dart
// 스토어: 정적 클래스 + static ValueNotifier
class SomeStore {
  SomeStore._();
  static final ValueNotifier<SomeState> notifier = ValueNotifier(SomeState.initial());
  static SomeState get state => notifier.value;
}

// 위젯: ValueListenableBuilder로 구독
ValueListenableBuilder<SomeState>(
  valueListenable: SomeStore.notifier,
  builder: (context, state, _) { ... },
)
```

### 현재 스토어 목록

| 스토어 | 타입 | 영속성 | 백엔드 |
|--------|------|--------|--------|
| `AuthStore` | `ValueNotifier<AuthState>` | SharedPreferences | Naver OAuth |
| `AdminAuthStore` | `ValueNotifier<AdminAuthState>` | Firebase Auth 세션 | Firestore `admins` 컬렉션 |
| `ActionEventStore` | `ValueNotifier<List<ActionEvent>>` | 없음 (로컬 시드) | (예정: Firestore `action_events`) |
| `CommunityPostStore` | `ValueNotifier<List<CommunityPost>>` | 없음 (로컬 시드) | (예정: Firestore `posts`) |
| `SearchHistoryStore` | `ValueNotifier<List<String>>` | 없음 | — |

---

## 7. 인증 구조

### 7-1. 일반 유저 인증 (Naver OAuth)

```
flutter_naver_login → NaverAuthService.signIn()
  → NaverProfileDraft (임시 보관)
  → SignupCompletePage (닉네임·전화 입력)
  → AuthStore.completeSignup()
  → AppUser (SharedPreferences 저장)
```

- `AppUser`는 Firebase 계정 없음. Naver providerUserId 기반으로 식별.
- 세션 복원: 앱 시작 시 `AuthStore.initialize()` → SharedPreferences에서 읽어옴.
- `AuthStore.debugSignInForDesignPreview()`: 실제 Naver 없이 목업 유저로 로그인 (개발용).

### 7-2. 관리자 인증 (Firebase Email/Password)

```
AdminLoginPage → AdminAuthStore.signIn(email, password)
  → Firebase Auth 로그인
  → Firestore admins/{uid} 문서 존재 여부 확인
  → isAdmin = true/false
```

- `AdminAuthStore.startListening()`: `main.dart` 또는 앱 초기화 시점에 호출 필요.
- 관리자만 `ActionEventFormPage`(공지 등록) 접근 가능.

---

## 8. Firebase 연동 구조

### Firestore 컬렉션

| 컬렉션 | 용도 | 읽기 주체 | 쓰기 주체 |
|--------|------|-----------|-----------|
| `admins` | 관리자 UID 목록 | AdminAuthStore | Firebase Console (수동) |
| `action_events` | 행동 공지 이벤트 | ActionEventStore (예정) | 관리자 앱 |

> 현재 `ActionEventStore`는 로컬 시드 데이터 사용. Firestore 실시간 연동은 Phase 4에서 진행.

### ActionEvent Firestore 필드 매핑

```dart
// ActionEvent.toMap() / ActionEvent.fromFirestore()
'status'        → String   (긴급 공지 / 중요 공지 / 정기 일정 / 중요 일정)
'type'          → String   (집회 / 모임 / 중요 일정)
'title'         → String
'startAt'       → Timestamp
'locationName'  → String
'locationQuery' → String   (지도 검색용)
'slogans'       → List<String>
'items'         → List<String>   (준비물)
'description'   → String
```

---

## 9. 개발 명령어

```bash
flutter run                              # 연결된 기기/에뮬레이터 실행
flutter run -d chrome --web-port 4567   # 크롬 실행 (포트 충돌 시 번호 변경)
flutter build apk --release             # Android APK 빌드
flutter build ios                       # iOS 빌드
flutter analyze                         # 린트 검사
flutter test                            # 전체 테스트
flutter test test/path/to_test.dart     # 단일 테스트
```

---

## 10. 개발 규칙

### 반드시 지킬 것

```
✅ 색상은 AppColors.* 토큰만 사용
✅ 새 페이지의 AppBar는 AllianceAppBar.main() 또는 AllianceAppBar.sub() 사용
✅ 로딩 UI는 AllianceLoadingIndicator / AllianceLoadingOverlay 사용
✅ 상태 관리는 ValueNotifier 패턴 유지 (외부 패키지 추가 금지)
✅ Firestore 쿼리는 Store 레이어(data/)에서만 처리
✅ 인증 플로우(AuthStore, AdminAuthStore) 임의 변경 금지
```

### 하면 안 되는 것

```
❌ 색상 하드코딩 (#FFFFFF, Color(0xFF...) 직접 입력 — AppColors에 없는 경우 토큰 추가 후 사용)
❌ 화면 위젯에 비즈니스 로직 직접 작성 (Store/Service 레이어 분리)
❌ firebase_options.dart 수동 수정
❌ ActionEventStore·CommunityPostStore의 로컬 시드 데이터를 프로덕션 데이터로 오해하고 수정
```

---

## 11. 구현 로드맵 (Phase 계획)

> **규칙:** Phase 순서 준수. Phase 1–3은 완료됨. Phase 4부터 시작.
> **절대 금지:** Phase 4 이전에 인증·라우팅·기존 기능 로직 변경.

### ✅ Phase 1 — 디자인 시스템 (완료)

```
lib/app/theme/app_colors.dart   색상 토큰
lib/app/theme/app_theme.dart    Material 3 테마
```

### ✅ Phase 2 — 공통 위젯 (완료)

```
lib/app/widgets/alliance_app_bar.dart
lib/app/widgets/alliance_loading_indicator.dart
```

### ✅ Phase 3 — 전체 UI 리디자인 (완료)

```
splash, login, home, briefing, action_board,
community, calendar, meetup, mission, profile, search
— 모든 화면 태극기·성조기 아이덴티티로 리디자인 완료
```

---

### 🔜 Phase 4 — 한미동맹단증 & QR 시스템 (다음 단계)

**목표:** 정회원 디지털 신분증 + QR 기반 행사 현장 참여 처리

```
작업 순서:
  4-1. Firestore 스키마 확장
       members/{uid}         정회원 정보, 등급, 포인트
       events/{id}           행사 + 부스 QR 코드
       attendance/{id}       참여 이력 (member_id + event_id UNIQUE)
       point_history/{id}    포인트 적립/차감 내역

  4-2. MembershipCardPage 신규
       lib/features/membership/presentation/membership_card_page.dart
       - 카드 UI: 국기 스트라이프, 이름, 등급, 회원번호 (ROK-YYYY-NNNNN)
       - QR 코드 표시 (qr_flutter 패키지, 5분 자동 갱신)
       - 활동 점수 표시

  4-3. QR 서비스 레이어
       lib/features/membership/data/qr_service.dart
       - JWT 생성: HMAC-SHA256, payload { memberId, grade, exp: now+300s }
       - JWT 검증 (관리자 앱)
       - SharedPreferences 오프라인 캐시 (24h)

  4-4. QRFullscreenPage
       화면 밝기 최대 (screen_brightness 패키지)
       닫을 때 밝기 복원

  4-5. QRScanPage
       expo-camera 대신 mobile_scanner 패키지 사용
       스캔 성공 → 참여 처리 → 점수 즉시 반영

  4-6. AdminScannerPage
       관리자 계정 전용 스캐너
       회원 QR 스캔 → Firestore attendance 기록

완료 기준:
  ✅ QR 발급 → 스캔 → 참여처리 → 점수적립 흐름 동작
  ✅ 중복 스캔 방지 (Firestore UNIQUE 제약)
  ✅ 오프라인 QR 캐시 동작
  ✅ 5분 만료 후 자동 갱신
```

---

### 🔜 Phase 5 — Firestore 실시간 연동

**목표:** 로컬 시드 데이터를 실제 Firestore로 교체

```
작업 순서:
  5-1. ActionEventStore → Firestore 실시간 스트림 연동
       action_events 컬렉션 StreamSubscription → ValueNotifier 업데이트

  5-2. CommunityPostStore → Firestore 연동
       posts 컬렉션 페이지네이션 (cursor 기반)
       댓글(comments) 서브컬렉션

  5-3. 실시간 피드 카테고리 필터
       category: urgent | policy | network | event | petition

  5-4. 청원 시스템
       lib/features/petition/
       목표 서명 수 진행률 바
       서명 시 +50P 적립, 중복 방지

완료 기준:
  ✅ 관리자가 등록한 공지가 앱에 즉시 반영
  ✅ 커뮤니티 게시글 Firestore 저장/로드
  ✅ 청원 서명 중복 방지
```

---

### 🔜 Phase 6 — 리더보드 & 부가 기능

```
  6-1. LeaderboardPage     전체/지역별 순위, 내 순위 하이라이트
  6-2. ActivityHistoryPage 참여 행사 타임라인 + 포인트 내역
  6-3. 회원증 이미지 저장·공유 (screenshot 패키지 + share_plus)
  6-4. 추천인 코드 시스템
  6-5. 푸시 알림 (firebase_messaging)
       행사 D-day, 청원 목표 달성, 등급 승급
```

---

## 12. 등급 & 포인트 시스템 (Phase 4+ 구현 예정)

| 등급 | 조건 | 혜택 |
|------|------|------|
| 일반회원 | 가입 | 피드 열람, 일정 확인 |
| 정회원 | 운영자 승인 | 한미동맹단증 발급, QR 생성, 행사 참여 |
| Gold | 누적 2,000P | 사은품 우선, 전용 배지 |
| VIP | 누적 5,000P | 굿즈 우선, VIP 라운지 |
| 명예회원 | 운영자 지정 | 전체 혜택 + 특별 배지 |

| 행동 | 점수 |
|------|------|
| 행사 QR 참여 | +150P |
| 집회 참석 | +200P |
| 청원 서명 | +50P |
| 게시글 공유 | +20P (1일 5회 상한) |
| 댓글 작성 | +10P (1일 10회 상한) |
| 신규 회원 추천 | +500P |

---

## 13. 환경 변수

```bash
# google-services.json (android/app/)   Firebase Android 설정 (git 제외)
# GoogleService-Info.plist (ios/Runner/) Firebase iOS 설정 (git 제외)
# lib/firebase_options.dart             FlutterFire CLI 생성 (git 포함 가능)

# Naver 로그인 클라이언트 ID는 android/app/src/main/AndroidManifest.xml 및
# ios/Runner/Info.plist에 직접 설정 (환경변수 아님)
```

---

*Last updated: 2026-04*
*Stack: Flutter + Firebase + Naver OAuth*
