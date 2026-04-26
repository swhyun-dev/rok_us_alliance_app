# CLAUDE.md — 한미동맹단 앱 (ROK_US Alliance App)

> 이 파일은 Claude Code가 `rok_us_alliance_app` 프로젝트를 이해하고 작업할 때 참조하는 **단일 진실 소스(Single Source of Truth)**입니다.
> 코드를 수정하기 전에 반드시 이 문서 전체를 읽으세요.
>
> **v3.0 통합 노트 (2026.04)**:
> - v1.0 / v2.0 (React Native + Supabase 계획) 폐기
> - 실제 코드는 Flutter + Firebase로 진행 중
> - v2.0의 UX 명세(범프탭바·홈리뉴얼·청원탭·실시간피드)는 그대로 계승
> - 카페 매칭 제거, 다중 소셜 로그인 추가, 등급 시스템 신규 도입

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **앱 이름** | 한미동맹단 (ROK_US Alliance) |
| **운영 주체** | 대표님 (개인 또는 사업자) |
| **단체 관계** | 한미동맹단 명칭·로고 사용 허락받음, 단체는 응원·협력 (운영 무관) |
| **목적** | 보수 시민의 행동·소통·집결을 돕는 모바일 플랫폼 |
| **플랫폼** | iOS + Android (Flutter) |
| **타겟** | 한미동맹단 지지자 + 일반 보수 성향 시민 |
| **주요 차별점** | 활동 점수 기반 등급 시스템 + 실시간 피드 + 청원 통합 + 디지털 회원증 |
| **수익 모델** | 광고(AdMob) + 향후 커머스·프리미엄 멤버십 |
| **현재 상태** | UI 80% / 백엔드 0% — 백엔드 연동 후 출시 |
| **출시 목표** | 6~7주 후 (앱스토어 제출 기준) |

---

## 2. 기술 스택 (실제)

```
프레임워크         Flutter 3.8+ / Dart
패키지 관리       pub
상태관리         ValueNotifier + StreamBuilder (Flutter 기본)
백엔드           Firebase
  ├─ Auth        Firebase Authentication
  ├─ DB          Cloud Firestore
  ├─ Storage     Firebase Storage (이미지)
  ├─ Functions   Cloud Functions (점수 적립·관리자 작업)
  ├─ Messaging   Firebase Cloud Messaging (푸시)
  └─ App Check   App Check (봇·치팅 방지)

디자인           Material 3 + 자체 AppColors 토큰 (다크 + 라이트 혼합)
아이콘           material icons (Cupertino 보조)
폰트             Pretendard (한글) + Bebas Neue (숫자/영문 헤드라인)
로컬 저장        shared_preferences (자동 로그인 등 최소만)
URL/공유        url_launcher, share_plus
유튜브 임베드    youtube_player_iframe (브리핑 영상용)

소셜 로그인 (4종)
  ├─ Apple       sign_in_with_apple (iOS 심사 필수)
  ├─ Kakao       kakao_flutter_sdk_user
  ├─ Naver       flutter_naver_login
  └─ Google      google_sign_in

QR & 카드
  ├─ QR 생성     qr_flutter
  ├─ QR 스캔     mobile_scanner
  ├─ 화면 캡처    screenshot
  └─ 밝기 제어    screen_brightness

분석/모니터링
  ├─ Analytics   firebase_analytics
  └─ Crashlytics firebase_crashlytics
```

---

## 3. 디자인 시스템

### 3-1. 컬러 토큰 (`lib/app/theme/app_colors.dart`)

기존 코드의 라이트 베이스 + v2의 다크 액센트 + 등급 컬러를 통합:

```dart
class AppColors {
  // ━━━ Brand Primary ━━━
  static const navy = Color(0xFF15233F);           // 신뢰·권위
  static const royalBlue = Color(0xFF2E50A5);      // 활성·링크
  static const accentRed = Color(0xFFD93030);      // 액센트·긴급·CTA
  static const accentRedBg = Color(0x26D93030);    // accentRed 15%

  // ━━━ Backgrounds ━━━
  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAFAFC);        // 앱 전체 배경
  static const softBlue = Color(0xFFF5F8FE);       // 카드 배경
  static const bgUrgent = Color(0xFFFFF1F2);       // 긴급 알림 카드
  static const bgDark = Color(0xFF0D1117);         // 멤버십 카드 등 다크 영역

  // ━━━ Text ━━━
  static const textPrimary = Color(0xFF1A1F2E);
  static const textSecondary = Color(0xFF5C6478);
  static const textMuted = Color(0xFF8C93A8);
  static const textOnDark = Color(0xFFF0F0F0);

  // ━━━ Border ━━━
  static const border = Color(0xFFE3E7F0);
  static const borderStrong = Color(0xFFCDD3E0);

  // ━━━ Semantic ━━━
  static const infoBlue = Color(0xFF378ADD);
  static const infoBlueBg = Color(0x26378ADD);
  static const success = Color(0xFF639922);
  static const successBg = Color(0x26639922);
  static const warning = Color(0xFFBA7517);
  static const warningBg = Color(0x26BA7517);

  // ━━━ Hero Gradient ━━━
  static const heroGradient = LinearGradient(
    colors: [navy, royalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ━━━ Grade (등급별 색상) ━━━
  static const gradeLv1 = Color(0xFF8C93A8);  // 새내기 - 회색
  static const gradeLv2 = Color(0xFF378ADD);  // 시민 - 파랑
  static const gradeLv3 = Color(0xFF639922);  // 활동가 - 녹색
  static const gradeLv4 = Color(0xFFC9A84C);  // 핵심 - 골드
  static const gradeLv5 = Color(0xFF7F77DD);  // 동지 - 퍼플
}
```

### 3-2. 카테고리별 색상 매핑

```dart
class CategoryColors {
  // 피드/청원 카테고리 → 좌측 색상 바, 뱃지 색
  static const Map<String, Color> map = {
    'urgent':   AppColors.accentRed,      // 긴급
    'policy':   AppColors.infoBlue,        // 정책
    'network':  AppColors.success,         // 네트워크
    'event':    AppColors.warning,         // 행사
    'petition': AppColors.gradeLv5,        // 청원
  };
}
```

### 3-3. 타이포그래피

| 용도 | 폰트 | 크기 | Weight |
|------|------|------|--------|
| 앱 브랜드 로고 | Bebas Neue | 28px | w400 |
| 화면 제목 | Pretendard | 25px | w900 |
| 섹션 제목 | Pretendard | 18px | w800 |
| 카드 제목 | Pretendard | 16px | w700 |
| 본문 | Pretendard | 14px | w400~600 |
| 캡션 | Pretendard | 13px | w500 |
| 마이크로 | Pretendard | 11~12px | w500 |
| **통계 카운터** | Bebas Neue | 32px | w400 |
| **퍼센트 숫자** | Bebas Neue | 16px | w400 |
| QR 회원번호 | JetBrains Mono | 12px | w500 |
| 등급 배지 | Pretendard | 10~12px | w700 |

### 3-4. 레이아웃 규칙

```
기본 수평 패딩:    16px
카드 border-radius: 24px (히어로/큰 카드) / 16px (일반)
버튼 border-radius: 12px (일반) / 999px (Pill)
하단 탭 높이:      60px + safe area
카드 내부 패딩:    18~22px (큰 카드) / 14px (작은 카드)
섹션 간격:         12~16px
통계 카운터 간격:  가로 3분할 균등 + border-right 구분선
```

### 3-5. 카드 컴포넌트 기본 스타일

```dart
// lib/shared/widgets/app_card.dart
Container(
decoration: BoxDecoration(
color: AppColors.softBlue,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: AppColors.border, width: 0.5),
),
padding: EdgeInsets.all(14),
)
```

---

## 4. 화면 구조 (Screen Map)

### 4-1. 전체 라우팅 트리

```
앱 진입
├── SplashPage                   ✅ 완성 (애니메이션 풍부)
└── 분기
    ├── 비로그인 → AuthFlow
    │   ├── LoginPage             🟡 4 소셜 로그인으로 리팩토링
    │   ├── TermsAgreementPage    🆕 약관 동의
    │   ├── NicknameSetupPage     🆕 닉네임 설정
    │   └── SignupCompletePage    🟡 카페 매칭 제거, 환영 화면으로
    │
    └── 로그인 → HomePage (5탭 + 중앙 범프)
        ├── Tab 1: 피드 (FeedPage)              🟡 실시간 강화
        ├── Tab 2: 청원 (PetitionPage)           🆕 신규 탭
        ├── Tab 3: 홈 [중앙 범프] (HomeMainPage) 🟡 전면 리뉴얼
        ├── Tab 4: 일정 (CalendarPage)           ✅ 유지
        └── Tab 5: 마이 (MyPage)                 🟡 카페 의존 제거
```

### 4-2. 탭별 상세 화면 트리

```
Tab 1: 피드
├── FeedPage
│   ├── 상단: LIVE 인디케이터 + 검색
│   ├── 세그먼트 바: 전체 / 긴급 / 정책 / 네트워크 / 행사
│   └── FeedList (Firestore Stream)
└── FeedDetailPage (댓글 포함)

Tab 2: 청원
├── PetitionPage
│   ├── 상단: 글쓰기 (관리자만)
│   ├── 세그먼트 바: 진행중 / 인기 / 신규 / 완료
│   └── PetitionList
└── PetitionDetailPage (서명·진행률)

Tab 3: 홈 [중앙 범프 - accentRed 원형]
└── HomeMainPage (전면 리뉴얼 — Section 6 참조)
    ├── HeroStatsSection (가입회원/진행청원/이번달행사 카운터)
    ├── QuickActionGrid (행동동원/일정관리/청원서명)
    ├── BreakingAlertCard (긴급 알림, 조건부)
    ├── LiveFeedPreview (실시간 피드 TOP 3)
    ├── HotPetitionSection (인기 청원 TOP 3)
    └── UpcomingEventCard (다음 행사 D-day)

Tab 4: 일정
├── CalendarPage
│   ├── CalendarView (월 캘린더)
│   └── EventListView
└── EventDetailPage (행사 상세 + 참여 신청)

Tab 5: 마이
├── MyPage
│   ├── ProfileCard (프로필 + 등급 배지)
│   ├── StatsGrid (참여행사/서명/점수)
│   └── 메뉴 리스트
├── MembershipCardPage      🆕 디지털 회원증 (Phase 6)
├── PointHistoryPage        🆕 점수 적립 이력
├── LevelGuidePage          🆕 등급 시스템 안내
├── PetitionHistoryPage     🆕 서명 이력
├── NotificationPage        🆕 알림 목록
├── SettingsPage            🆕 설정
├── TermsPage               🆕 약관 보기
├── PrivacyPage             🆕 개인정보 보기
└── ContactPage             🆕 문의·신고

별도 진입
├── AdminLoginPage          ✅ Firebase Auth 그대로
└── AdminDashboardPage      🆕 (앱 출시 후 결정)

🔴 삭제 대상 (Week 5)
├── MissionPage             정의만, 호출 없음
├── MeetupPage              정의만, 호출 없음
├── BriefingPage            정의만, 호출 없음
└── SearchPage              정의만, 호출 없음
```

---

## 5. 하단 탭바 디자인 명세 (★ v2 계승)

### 5-1. 범프업(Bump-Up) 탭바 구조

```
탭 순서: 피드 | 청원 | [홈-중앙 범프] | 일정 | 마이
```

```dart
// lib/shared/widgets/bump_bottom_nav.dart

// 전체 탭바 높이
const double TAB_BAR_HEIGHT = 60; // + SafeArea bottom

// 중앙 홈 버튼 스펙
class CenterButton {
  static const double size = 58;          // 원형 지름
  static const double elevation = 20;     // 탭바 상단에서 돌출 높이
  static const Color bgColor = AppColors.accentRed;
  static const IconData iconData = Icons.home_filled;
  static const double iconSize = 26;
  static const Color iconColor = Colors.white;
}

// 범프 cutout (CustomPainter로 구현)
const double CUTOUT_RADIUS = 36; // 버튼보다 약간 큰 반경

// 탭바 배경
const Color TAB_BG = Colors.white;
const Color CUTOUT_BG = AppColors.surface; // 앱 배경과 동일해야 seamless
```

### 5-2. 탭바 CustomPainter 구현 가이드

```dart
// 탭바 배경에 중앙 오목 홈을 CustomPainter로 그림
// Path를 사용해서 베지어 곡선으로 부드러운 컷아웃 생성

class BumpBottomNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(mid - CUTOUT_RADIUS - 15, 0)
      ..quadraticBezierTo(
        mid - CUTOUT_RADIUS, 0,
        mid - CUTOUT_RADIUS, CUTOUT_RADIUS * 0.4,
      )
      ..quadraticBezierTo(
        mid, -CUTOUT_RADIUS * 0.8,
        mid + CUTOUT_RADIUS, CUTOUT_RADIUS * 0.4,
      )
      ..quadraticBezierTo(
        mid + CUTOUT_RADIUS, 0,
        mid + CUTOUT_RADIUS + 15, 0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 8, false);
    canvas.drawPath(path, Paint()..color = TAB_BG);
  }
}
```

### 5-3. 탭 아이콘 & 레이블

| 탭 | 아이콘 (비활성) | 아이콘 (활성) | 레이블 | 활성 색상 |
|---|---|---|---|---|
| 피드 | `Icons.article_outlined` | `Icons.article` | 피드 | accentRed |
| 청원 | `Icons.edit_outlined` | `Icons.edit` | 청원 | accentRed |
| 홈 (중앙) | `Icons.home_filled` | `Icons.home_filled` | (없음) | white |
| 일정 | `Icons.calendar_today_outlined` | `Icons.calendar_today` | 일정 | accentRed |
| 마이 | `Icons.person_outline` | `Icons.person` | 마이 | accentRed |

### 5-4. 미읽 알림 뱃지

```dart
// 탭 아이콘 우상단에 빨간 dot 뱃지
// 피드: 새 긴급 피드 있을 때
// 청원: 새 청원 등록됐을 때
// 마이: 미읽 알림 있을 때

Positioned(
top: -2, right: -4,
child: Container(
width: 8, height: 8,
decoration: BoxDecoration(
color: AppColors.accentRed,
shape: BoxShape.circle,
border: Border.all(color: TAB_BG, width: 1.5),
),
),
)
```

---

## 6. 홈 화면 상세 명세 (★ v2 계승 + 리팩토링)

### 6-1. HeroStatsSection — 통계 카운터

```
┌─────────────────────────────────────────────┐
│  우리의 목소리로                              │
│  대한민국을 바꾼다          [알림벨 아이콘]   │
│                                             │
│  보수 시민 네트워크의 새로운 플랫폼.           │
│  일정, 청원, 커뮤니티를 한 곳에서 관리하세요.  │
│                                             │
│  ┌──────────┬──────────┬──────────┐         │
│  │  128K    │   342    │   89     │         │
│  │ 가입회원  │진행중청원 │이번달행사 │         │
│  └──────────┴──────────┴──────────┘         │
└─────────────────────────────────────────────┘
```

**카운트업 애니메이션 스펙:**

```dart
// lib/features/home/widgets/hero_stats_section.dart

class StatItem {
  final String key;        // 'memberCount' | 'activePetitions' | 'monthlyEvents'
  final String label;
  final int targetValue;
  final String? suffix;    // 'K' 등
}

// 구현: AnimationController + easeOutQuart 커브
// 진입 시 0 → 실제값 카운트업 (1500ms)

class CountUpText extends StatefulWidget {
  final int target;
  final Duration duration;
// ...
}

// 데이터 소스: app_meta/stats 문서 (Firestore)
// {
//   memberCount: 12831,         (Cloud Function 5분마다 집계)
//   activePetitions: 342,
//   monthlyEvents: 89,
//   updatedAt: timestamp
// }
//
// 단위 처리: 10000 이상이면 (value/1000).toStringAsFixed(0) + 'K'
```

**스타일:**
```
통계 숫자: Bebas Neue 32px, textPrimary
레이블:    Pretendard 11px, textMuted, w500
구분선:    border-right 1px, borderStrong
배경:      softBlue, borderRadius 16, padding 16
```

### 6-2. QuickActionGrid — 퀵 액션

```
┌──────────────┬──────────────┬──────────────┐
│  📢           │  📅           │  ✍️           │
│  행동 동원    │  일정 관리   │  청원 서명   │
│  참여하기 →  │  확인하기 →  │  서명하기 →  │
└──────────────┴──────────────┴──────────────┘
```

> v1의 4버튼(내카드 포함) → v2의 3버튼으로 (내카드는 마이탭으로)

```dart
const quickActions = [
  {
    icon: Icons.campaign,
    title: '행동 동원',
    subtitle: '지역 집회 및 캠페인 참여',
    cta: '참여하기',
    routeName: '/feed',
    filterTag: 'urgent',
    bgColor: AppColors.accentRedBg,
    iconColor: AppColors.accentRed,
  },
  {
    icon: Icons.calendar_today,
    title: '일정 관리',
    subtitle: '전국 행사 일정 한눈에',
    cta: '확인하기',
    routeName: '/calendar',
    bgColor: AppColors.infoBlueBg,
    iconColor: AppColors.infoBlue,
  },
  {
    icon: Icons.edit,
    title: '청원 서명',
    subtitle: '진행 중인 청원에 참여',
    cta: '서명하기',
    routeName: '/petition',
    bgColor: AppColors.successBg,
    iconColor: AppColors.success,
  },
];
```

### 6-3. LiveFeedPreview — 실시간 피드 프리뷰

```dart
// lib/features/home/widgets/live_feed_preview.dart

// Firestore Realtime: posts 컬렉션 구독 (홈에서도 연결)
// 새 글 감지 시 → 목록 상단에 슬라이드인 애니메이션
// 최대 3개만 표시 (더보기 → 피드 탭으로 이동)

// 피드 아이템 좌측: 카테고리 색상 바 (4px width)
// 피드 아이템 내용: 제목 2줄, 시간 상대값 (10분 전, 1시간 전)
// 피드 아이템 하단: 공유 N | 댓글 N | 좋아요 N

// 실시간 느낌 강화:
// - 섹션 헤더 우측에 "● LIVE" 빨간 점 + 텍스트 (점멸 1500ms)
// - 새 글 진입 시 상단에서 슬라이드다운 (AnimatedList)
// - 시간 표시: 방금 전 / N분 전 / N시간 전 (1분마다 갱신)

class LiveIndicator extends StatefulWidget {
  // 빨간 점 0.8 ↔ 1.0 opacity 반복 (1500ms 주기)
}
```

### 6-4. HotPetitionSection — 인기 청원 TOP 3

```
┌─────────────────────────────────────────────┐
│  인기 청원              [전체보기 →]          │
│                                             │
│  국방예산 증액          ████████░░  82%      │
│  교육 자유화 법안        ██████░░░░  67%      │
│  언론 자유 보호법        █████░░░░░  54%      │
└─────────────────────────────────────────────┘
```

```dart
// lib/features/home/widgets/hot_petition_section.dart

// 쿼리: petitions where status='active' orderBy currentCount desc limit 3

// 진행률 바 색상 로직
Color getProgressColor(double percent) {
  if (percent >= 80) return AppColors.accentRed;
  if (percent >= 50) return AppColors.warning;
  return AppColors.infoBlue;
}

// 퍼센트 숫자: Bebas Neue 16px
// 탭 이동: "전체보기" 누르면 PetitionPage로
```

### 6-5. BreakingAlertCard — 긴급 알림

```dart
// posts where isUrgent=true, orderBy createdAt desc limit 1
// 없으면 렌더링 안 함 (조건부)

// 스타일:
// 배경: bgUrgent (#FFF1F2 라이트 / #1C0A0D 다크)
// 좌측 붉은 세로선 4px border
// "긴급" 뱃지 accentRed
// 여러 개일 경우 3초마다 자동 carousel
```

### 6-6. UpcomingEventCard — 다음 행사 D-day

```dart
// events where eventDate >= now() orderBy eventDate asc limit 1

// D-day 표시 (큰 숫자):
//   D-DAY: today
//   D-N:   N일 남음
//   종료:  지난 행사

// 카드 우측: 행사 제목·장소·시간
// 카드 하단: "참여 신청" 버튼 또는 "참여 완료" 뱃지
```

---

## 7. 피드 화면 상세 명세 (★ v2 계승)

### 7-1. 화면 구조

```
FeedPage
├── 상단 헤더: "실시간 피드" + LIVE 인디케이터 + 검색 아이콘
├── 세그먼트 바: 전체 / 긴급 / 정책 / 네트워크 / 행사
├── FeedList (Firestore Stream)
│   └── FeedItem
│       ├── 카테고리 좌측 색상 바
│       ├── 제목 + 본문 미리보기 (2줄)
│       ├── 시간 (상대값, 1분마다 갱신)
│       └── 공유 / 댓글 / 좋아요 카운트
└── 새 글 알림 토스트 (상단 슬라이드인)
    "새 글이 올라왔습니다 ↑"
```

### 7-2. 실시간 구현

```dart
// lib/features/feed/data/feed_store.dart

class FeedStore {
  static Stream<List<Post>> watchAll({String? category}) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(Post.fromFirestore).toList(),
    );
  }

  // 새 글 감지: docChanges에서 added 이벤트 필터링
  static Stream<Post> watchNewPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .where((snap) => snap.docChanges.any((c) => c.type == DocumentChangeType.added))
        .map((snap) => Post.fromFirestore(snap.docs.first));
  }
}

// 화면에서: 새 글 도착 → 토스트 슬라이드다운 → 2초 후 사라짐
// "새 글 1개 ↑ 탭하여 보기" 형태
```

### 7-3. FeedItem 카드 스타일

```
카테고리별 좌측 색상 바 (4px width):
  긴급     → #D93030  (accentRed)
  정책     → #378ADD  (infoBlue)
  네트워크 → #639922  (success)
  행사     → #BA7517  (warning)
  청원     → #7F77DD  (gradeLv5)

카드 하단 액션바:
  공유 아이콘 + 숫자 | 댓글 아이콘 + 숫자 | 좋아요 + 숫자
```

---

## 8. 청원 화면 상세 명세 (★ v2 계승)

### 8-1. PetitionPage 구조

```
PetitionPage
├── 상단 헤더: "청원" + 글쓰기 아이콘 (관리자만)
├── 세그먼트 바: 진행중 / 인기 / 신규 / 완료
├── PetitionList
│   └── PetitionCard
│       ├── 카테고리 뱃지
│       ├── 제목 + 설명 (2줄)
│       ├── 진행률 바 + 퍼센트
│       ├── 현재서명 / 목표서명 카운트
│       └── D-day 뱃지 + 서명 버튼
└── PetitionDetailPage (push)
```

### 8-2. PetitionCard 컴포넌트

```dart
// lib/features/petition/widgets/petition_card.dart

// 진행률 바 색상 (Section 6-4와 동일 로직)
Color getProgressColor(double percent) {
  if (percent >= 80) return AppColors.accentRed;
  if (percent >= 50) return AppColors.warning;
  return AppColors.infoBlue;
}

// D-day 계산
String getDday(DateTime deadline) {
  final diff = deadline.difference(DateTime.now()).inDays;
  if (diff == 0) return 'D-DAY';
  if (diff < 0) return '종료';
  return 'D-$diff';
}

// 서명 버튼 상태
// - 비로그인: "로그인 후 서명" (비활성)
// - 로그인 + 미서명: "서명하기" (활성, accentRed)
// - 로그인 + 서명완료: "서명완료 ✓" (비활성, success)
//
// ⚠️ v3 변경: "정회원만" 제약 제거됨
//   누구나 서명 가능, 단 점수 적립은 Lv2 이상부터
//   (등급별 차등은 등급 정책 참조)
```

### 8-3. 서명 처리 (Optimistic UI)

```dart
// lib/features/petition/presentation/petition_detail_page.dart

Future<void> handleSign() async {
  // 1. 즉시 UI 업데이트 (Optimistic)
  setState(() {
    petition = petition.copyWith(
      currentCount: petition.currentCount + 1,
      isSigned: true,
    );
  });

  try {
    // 2. Cloud Function 호출 (서버 검증 + 점수 적립)
    final callable = FirebaseFunctions.instance.httpsCallable('signPetition');
    final result = await callable.call({'petitionId': petition.id});

    // 3. 성공 토스트 (점수 적립)
    showToast(
      type: 'success',
      message: '+${result.data['pointsAwarded']}P 적립! 서명 완료',
    );
  } catch (e) {
    // 4. 실패 시 롤백
    setState(() {
      petition = petition.copyWith(
        currentCount: petition.currentCount - 1,
        isSigned: false,
      );
    });
    showToast(type: 'error', message: '서명에 실패했습니다.');
  }
}
```

---

## 9. 인증 시스템 (★ v3 신규)

### 9-1. 로그인 방법 4종

```
1. Sign in with Apple   (iOS 심사 필수)
2. Kakao 로그인         (한국 사용자 핵심)
3. Naver 로그인         (보수 성향 사용자 다수)
4. Google 로그인        (Android 표준)
```

### 9-2. 인증 흐름

```
[로그인 버튼 클릭]
  ↓
[소셜 OAuth 인증]
  ├─ Apple/Google: Firebase Auth 직접 지원
  └─ Kakao/Naver: Cloud Function으로 Custom Token 발급 후 signInWithCustomToken
  ↓
[users/{uid} 컬렉션 확인]
  ├─ 신규 사용자
  │   ├─ TermsAgreementPage (약관 동의)
  │   ├─ NicknameSetupPage (닉네임 입력)
  │   ├─ users 생성 + Cloud Function 환영 보너스 +50P
  │   └─ HomePage 이동
  └─ 기존 사용자
      └─ HomePage 이동
```

### 9-3. AppUser 모델 (v3)

```dart
class AppUser {
  final String uid;
  final String provider;          // 'apple' | 'kakao' | 'naver' | 'google'
  final String providerUserId;
  final String? email;
  final String nickname;
  final String? profileImageUrl;
  final int level;                // 1~5
  final int points;
  final bool consentedTerms;
  final bool consentedPrivacy;
  final DateTime consentedAt;
  final DateTime createdAt;
  final DateTime lastSignedInAt;
  final String? deviceToken;
  final bool isAdmin;
  final bool isBanned;
  final String? bannedReason;

// ⚠️ v2까지 있던 필드들 - 모두 제거됨
//   cafeNickname, cafeMatched, phoneNumber, phoneVerified, isVerified
}
```

---

## 10. 등급·점수 시스템 (★ v3 신규)

### 10-1. 등급 정책

| Lv | 명칭 | 누적 점수 | 색상 | 부여 조건 |
|----|------|----------|------|----------|
| 1 | 새내기 | 0~99 | gradeLv1 | 가입 즉시 |
| 2 | 시민 | 100~499 | gradeLv2 | 100P 누적 |
| 3 | 활동가 | 500~1999 | gradeLv3 | 500P 누적 |
| 4 | 핵심 | 2000~4999 | gradeLv4 | 2000P 누적 |
| 5 | 동지 | 5000+ | gradeLv5 | 5000P 누적 |

### 10-2. 점수 적립 규칙

| 행동 | 점수 | 일일 한도 | 적립 위치 |
|------|------|----------|----------|
| 가입 환영 | +50 | 1회 (최초) | onUserCreated |
| 일일 체크인 | +10 | 1회 | dailyCheckIn |
| 게시글 작성 | +30 | 3회 | onPostCreated |
| 댓글 작성 | +5 | 10회 | onCommentCreated |
| 좋아요 받음 | +2 | 50회 | onLikeReceived |
| 공유하기 | +20 | 5회 | sharePost (호출) |
| 청원 서명 | +50 | 청원당 1회 | signPetition |
| 행사 체크인 | +100 | 행사당 1회 | onEventCheckIn |
| 친구 초대 | +200 | 무제한 (가입 성공 시) | onReferralComplete |

### 10-3. 점수 적립 메커니즘

⚠️ **중요**: 점수는 클라이언트가 직접 변경 못함. 반드시 Cloud Functions 경유.

```
사용자 행동 (예: 게시글 작성)
  ↓
[클라이언트] posts.add(...) → Firestore
  ↓
[Cloud Function 트리거] onPostCreated
  ↓
[검증]
  - 일일 한도 체크 (point_logs 조회)
  - 사용자 ban 상태 체크
  - 어뷰징 패턴 체크 (단시간 다중 작성)
  ↓
[배치 쓰기]
  1. point_logs 추가 { uid, type, amount, refId, createdAt }
  2. users/{uid}.points += amount
  3. 등급 변동 시 users/{uid}.level 업데이트
  ↓
[클라이언트 알림]
  - 인앱: "+30P 적립" 토스트
  - 등급 변동 시: 별도 다이얼로그 + 푸시
```

### 10-4. 등급 승급 알림

```dart
// 등급이 올라가면 다이얼로그 표시
showDialog(
context: context,
builder: (_) => GradeUpDialog(
fromLevel: 1,
toLevel: 2,
message: '시민 등급으로 승급하셨습니다!',
rewards: [
'청원 서명 시 +50P 가능',
'커뮤니티 게시글 작성 가능',
],
),
);
```

---

## 11. 디지털 회원증 & QR (Phase 6 - 선택)

### 11-1. 멤버십 카드 UI

```
┌─────────────────────────────────────┐
│ 🇰🇷⬜🇺🇸  [Lv 3 활동가]              │
│                                     │
│  홍길동                              │
│  No. ROK-2026-00847                 │
│  가입일 2026.01.15                   │
│                                     │
│  [QR CODE 32x32]    활동점수 1,240P  │
└─────────────────────────────────────┘
```

### 11-2. QR 1차 출시 사양 (단순)

> v2의 JWT 기반 QR은 1차 출시에서 제외. 2차 업데이트에 추가.

```dart
// 1차 출시: 단순 ID 인코딩 (서명 없음)
// 행사 체크인용 - 운영자가 사용자 QR 스캔 → users/{uid} 조회

class QrPayload {
  final String uid;
  final String nickname;
  final int level;
  final int issuedAt;

  String toBase64() => base64Encode(utf8.encode(jsonEncode(toMap())));
}

// 화면 밝기 자동 최대 (전체화면 모드 시)
ScreenBrightness().setScreenBrightness(1.0);
// 닫을 때 복원
ScreenBrightness().resetScreenBrightness();
```

### 11-3. 행사 체크인 (1차)

QR 스캔 대신 **6자리 숫자 코드 입력** 방식으로 시작:

```
1. 운영자가 행사 관리 페이지에서 6자리 코드 발급 (10분 유효)
2. 참여자가 앱에서 코드 입력 → Cloud Function 검증
3. 중복 체크 + 점수 적립 (+100P)
```

이유: QR JWT 시스템은 보안 검증·만료 처리·오프라인 캐시 등 복잡도 높음. 1차에서는 단순화하고 사용자 데이터 모인 후 정교화.

---

## 12. Firestore 스키마 (요약)

> 자세한 내용은 별도 `FIRESTORE_SCHEMA.md` 참조

```
firestore/
├── users/{uid}                  사용자 프로필 (Section 9-3)
├── admins/{uid}                 관리자 (현재 코드 유지)
├── events/{eventId}             행사·집회
├── posts/{postId}               피드 게시글
│   └── comments/{commentId}     댓글 (subcollection)
├── petitions/{petitionId}       청원
│   └── signatures/{uid}         서명 (subcollection)
├── point_logs/{logId}           점수 적립 이력
├── check_ins/{checkInId}        행사 체크인
├── reports/{reportId}           신고
├── notifications/{notifId}      푸시 알림 이력
└── app_meta/                    앱 메타
    ├── stats                    홈 통계 (5분마다 갱신)
    └── policies                 등급·점수 정책
```

### 12-1. Security Rules 핵심 원칙

```javascript
// ✅ 절대 금지
- 클라이언트가 users.points 직접 변경
- 클라이언트가 users.level 직접 변경
- 클라이언트가 users.isAdmin 변경
- 클라이언트가 point_logs 쓰기

// ✅ 클라이언트 가능
- 본인 users 문서 read/update (보호 필드 제외)
- posts/petitions/comments read (인증 사용자)
- 본인 글 작성/수정/삭제
```

---

## 13. Cloud Functions 구조

```
functions/src/
├── index.ts
│
├── auth/
│   ├── createCustomTokenFromKakao   카카오 → Firebase Custom Token
│   ├── createCustomTokenFromNaver   네이버 → Firebase Custom Token
│   └── onUserCreated                가입 +50P 환영
│
├── points/
│   ├── awardPoints                  점수 적립 (호출 가능)
│   ├── onPostCreated                게시글 +30P
│   ├── onCommentCreated             댓글 +5P
│   ├── onLikeReceived               좋아요 +2P
│   ├── onCheckIn                    행사 체크인 +100P
│   ├── signPetition                 청원 서명 +50P
│   ├── dailyCheckIn                 일일 +10P
│   └── recalculateLevel             등급 재계산 (points 변경 시)
│
├── stats/
│   └── updateAppStats               5분마다 app_meta/stats 갱신
│
├── admin/
│   ├── adjustPoints                 관리자 점수 조정
│   ├── banUser                      사용자 차단
│   └── deletePost                   게시글 강제 삭제
│
└── moderation/
    ├── onReportCreated              신고 처리
    └── scheduledCleanup             24시간 후 미처리 신고 알림
```

---

## 14. 파일 구조 (실제 + TODO)

```
rok_us_alliance_app/
├── CLAUDE.md                        ← 이 파일
├── FIRESTORE_SCHEMA.md             별도 문서
├── NEXT_STEPS.md                   별도 문서
├── pubspec.yaml
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts        ⚠️ applicationId 변경 필요
│   │   └── google-services.json
│   └── ...
│
├── ios/
│   ├── Runner/
│   │   ├── Info.plist              ⚠️ Bundle ID 변경 필요
│   │   └── GoogleService-Info.plist
│   └── ...
│
├── functions/                       🆕 Cloud Functions
│   ├── package.json
│   └── src/
│       ├── index.ts
│       ├── auth/
│       ├── points/
│       ├── stats/
│       ├── admin/
│       └── moderation/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── app/
│   │   ├── app.dart                 라우팅 + 테마
│   │   └── theme/
│   │       ├── app_colors.dart      Section 3-1, 3-2
│   │       └── app_theme.dart       Material 3 테마
│   │
│   ├── features/
│   │   ├── auth/                    🟡 다중 로그인 리팩토링
│   │   │   ├── data/
│   │   │   │   ├── auth_store.dart
│   │   │   │   ├── admin_auth_store.dart      ✅ 유지
│   │   │   │   ├── apple_auth_service.dart    🆕
│   │   │   │   ├── kakao_auth_service.dart    🆕
│   │   │   │   ├── naver_auth_service.dart    🟡 유지
│   │   │   │   └── google_auth_service.dart   🆕
│   │   │   ├── domain/
│   │   │   │   └── app_user.dart              🟡 카페 필드 제거
│   │   │   └── presentation/
│   │   │       ├── login_page.dart            🟡 4 로그인 버튼
│   │   │       ├── terms_agreement_page.dart  🆕
│   │   │       ├── nickname_setup_page.dart   🆕
│   │   │       └── admin_login_page.dart      ✅ 유지
│   │   │
│   │   ├── splash/                  ✅ 유지
│   │   │
│   │   ├── home/                    🟡 전면 리뉴얼 (Section 6)
│   │   │   ├── data/
│   │   │   │   └── stats_store.dart 🆕 app_meta/stats 구독
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── home_page.dart   🟡 탭 컨테이너
│   │   │       ├── home_main_page.dart      🆕 홈 탭 콘텐츠
│   │   │       └── widgets/
│   │   │           ├── hero_stats_section.dart   🆕
│   │   │           ├── count_up_text.dart        🆕
│   │   │           ├── quick_action_grid.dart    🆕
│   │   │           ├── breaking_alert_card.dart  🆕
│   │   │           ├── live_feed_preview.dart    🆕
│   │   │           ├── live_indicator.dart       🆕
│   │   │           ├── hot_petition_section.dart 🆕
│   │   │           └── upcoming_event_card.dart  🆕
│   │   │
│   │   ├── feed/                    🟡 ActionBoard에서 분리·확장
│   │   │   ├── data/
│   │   │   │   └── feed_store.dart           🟡 → Firestore Stream
│   │   │   ├── domain/
│   │   │   │   └── post.dart                 🟡 fromFirestore 추가
│   │   │   └── presentation/
│   │   │       ├── feed_page.dart            🟡 세그먼트바·LIVE
│   │   │       ├── feed_detail_page.dart     🟡
│   │   │       ├── feed_form_page.dart       🟡
│   │   │       └── widgets/
│   │   │           ├── feed_item.dart        🟡
│   │   │           └── new_post_banner.dart  🆕
│   │   │
│   │   ├── petition/                🆕 신규 탭
│   │   │   ├── data/
│   │   │   │   └── petition_store.dart
│   │   │   ├── domain/
│   │   │   │   └── petition.dart
│   │   │   └── presentation/
│   │   │       ├── petition_page.dart
│   │   │       ├── petition_detail_page.dart
│   │   │       ├── petition_form_page.dart   (관리자만)
│   │   │       └── widgets/
│   │   │           ├── petition_card.dart
│   │   │           ├── progress_bar.dart
│   │   │           └── sign_button.dart
│   │   │
│   │   ├── calendar/                🟡 Firestore 연동
│   │   │
│   │   ├── action_board/            🟡 events 컬렉션으로 마이그레이션
│   │   │
│   │   ├── community/               🔴 → feed로 통합 검토
│   │   │
│   │   ├── profile/                 🟡 카페 의존 제거
│   │   │   ├── data/
│   │   │   │   └── point_log_store.dart      🆕
│   │   │   ├── domain/
│   │   │   │   ├── member_grade.dart         🟡 5단계
│   │   │   │   └── point_log.dart            🆕
│   │   │   └── presentation/
│   │   │       ├── my_page.dart              🟡 카페 다이얼로그 제거
│   │   │       ├── point_history_page.dart   🆕
│   │   │       ├── level_guide_page.dart     🆕
│   │   │       ├── membership_card_page.dart 🆕 (Phase 6)
│   │   │       └── widgets/
│   │   │           ├── grade_badge.dart
│   │   │           ├── stats_grid.dart
│   │   │           └── level_progress_bar.dart  🆕
│   │   │
│   │   └── settings/                🆕
│   │       └── presentation/
│   │           ├── settings_page.dart
│   │           ├── terms_page.dart
│   │           ├── privacy_page.dart
│   │           ├── contact_page.dart
│   │           └── notification_page.dart
│   │
│   └── shared/                      🆕
│       ├── widgets/
│       │   ├── app_card.dart
│       │   ├── loading_indicator.dart
│       │   ├── empty_state.dart
│       │   ├── error_view.dart
│       │   ├── point_toast.dart           🆕
│       │   ├── grade_up_dialog.dart       🆕
│       │   ├── bump_bottom_nav.dart       🆕 (Section 5)
│       │   └── bump_bottom_nav_painter.dart 🆕
│       └── utils/
│           ├── date_formatter.dart
│           ├── relative_time.dart         🆕 ("10분 전")
│           └── validators.dart
│
└── assets/
    ├── images/
    │   ├── app_icon.png            🆕 1024x1024
    │   ├── korea_flag.png          ✅
    │   ├── usa_flag.png            ✅
    │   └── maga_with_rok_popup.png ✅
    └── fonts/
        ├── Pretendard-Regular.otf  🆕
        ├── Pretendard-Medium.otf   🆕
        ├── Pretendard-Bold.otf     🆕
        └── BebasNeue-Regular.ttf   🆕
```

---

## 15. 6주 리팩토링 실행 계획

> **규칙**: 각 주차 작업 시작 전 직전 주차 완료 확인. 절대 점프 금지.

### Week 1 — 인증 시스템 재구축

**목표**: 카페 매칭 제거 + 다중 소셜 로그인 4종

```
1.1 카페 매칭 제거 (1.5일)
  □ AppUser에서 cafeNickname/cafeMatched/phoneNumber/phoneVerified 제거
  □ AuthStore 정리
  □ MyPage 카페 닉네임 다이얼로그 제거
  □ LoginPage "카페 매칭" 카피 제거
  □ SignupCompletePage 정리

1.2 다중 소셜 로그인 (3일)
  □ pubspec.yaml: kakao_flutter_sdk_user / google_sign_in / sign_in_with_apple
  □ KakaoAuthService / GoogleAuthService / AppleAuthService 구현
  □ NaverAuthService 유지 + Firebase Custom Token 연동
  □ Cloud Function: createCustomTokenFromKakao
  □ Cloud Function: createCustomTokenFromNaver
  □ LoginPage UI: 4 버튼 (Apple은 iOS만)

1.3 가입 플로우 (1일)
  □ TermsAgreementPage
  □ NicknameSetupPage
  □ users 컬렉션 생성

완료 기준:
  ✅ 4가지 방법으로 로그인 성공
  ✅ users 컬렉션 신규 생성
  ✅ 카페 코드 0줄
```

### Week 2 — 백엔드 연동 (Firestore)

**목표**: 메모리 → Firestore 전환

```
2.1 Firestore 스키마 적용 (1일)
  □ Security Rules 작성·배포
  □ 인덱스 생성 (events.eventDate, posts.createdAt 등)

2.2 Events 마이그레이션 (1일)
  □ ActionEvent.fromFirestore / toMap
  □ ActionEventStore Stream 기반 재작성
  □ 시드 데이터 → Firestore 일회성 업로드

2.3 Posts 마이그레이션 (2일)
  □ Post 모델·Store Stream화
  □ 페이지네이션 (cursor)
  □ Optimistic UI

2.4 Comments (1일)
  □ comments subcollection
  □ 댓글 카운트 자동 갱신 (Cloud Function)

완료 기준:
  ✅ 사용자 A 작성 → 사용자 B 실시간 표시
  ✅ 앱 재시작 후 데이터 유지
  ✅ 시드 데이터 0개
```

### Week 3 — 점수 시스템 + 청원 탭

**목표**: 진짜 점수 + 청원 신규 탭

```
3.1 Cloud Functions: 점수 적립 엔진 (2일)
  □ awardPoints (호출형)
  □ onUserCreated +50P
  □ onPostCreated +30P (3회/일)
  □ onCommentCreated +5P (10회/일)
  □ onLikeReceived +2P (50회/일)
  □ recalculateLevel 트리거

3.2 청원 시스템 (2일)
  □ Petition 모델·Store
  □ PetitionPage + 세그먼트바
  □ PetitionCard + 진행률 바
  □ PetitionDetailPage + Optimistic UI 서명
  □ Cloud Function: signPetition (+50P)

3.3 활동 이력 화면 (1일)
  □ PointHistoryPage
  □ LevelGuidePage
  □ MyPage 진행도 게이지

완료 기준:
  ✅ 게시글 작성 → +30P 토스트
  ✅ 100P 누적 → Lv2 자동 승급 + 다이얼로그
  ✅ 청원 서명 + 50P 적립
  ✅ 클라이언트 points 변조 불가
```

### Week 4 — 홈 화면 리뉴얼 + 범프탭바 + 출시 설정

**목표**: 시각적 임팩트 + 출시 인프라

```
4.1 범프탭바 구현 (1.5일)
  □ BumpBottomNavPainter (CustomPainter)
  □ BumpBottomNav 위젯
  □ HomePage 5탭 재배치 (피드/청원/홈/일정/마이)
  □ 미읽 알림 dot 뱃지

4.2 홈 화면 리뉴얼 (3일)
  □ StatsStore (app_meta/stats 구독)
  □ Cloud Function: updateAppStats (5분마다)
  □ CountUpText 위젯 (easeOutQuart)
  □ HeroStatsSection
  □ QuickActionGrid (3버튼)
  □ BreakingAlertCard
  □ LiveFeedPreview + LiveIndicator
  □ HotPetitionSection
  □ UpcomingEventCard

4.3 출시 설정 (2일)
  □ applicationId 변경
  □ Bundle ID 변경
  □ Firebase Console 패키지 재등록
  □ Android keystore 생성
  □ iOS Distribution Certificate
  □ Firebase API 제한
  □ App Check 활성화

완료 기준:
  ✅ 범프 버튼 자연스러운 돌출
  ✅ 카운트업 부드러움
  ✅ 실시간 피드 동작
  ✅ 릴리즈 빌드 성공
```

### Week 5 — 약관 + 죽은 코드 정리 + 부가 기능

**목표**: 출시 전 마지막 정리 + 멤버십 카드(선택)

```
5.1 죽은 코드 제거 (1일)
  □ MissionPage / MeetupPage / BriefingPage / SearchPage 삭제
  □ 미사용 의존성 제거
  □ flutter analyze 통과
  □ flutter test 통과

5.2 약관·정책 (1.5일)
  □ assets/legal/terms.md
  □ assets/legal/privacy.md
  □ TermsPage / PrivacyPage 구현
  □ 약관 외부 페이지 게시 (앱스토어용)

5.3 푸시 알림 (1일)
  □ FCM 설정
  □ 알림 권한 요청
  □ NotificationService (토픽 구독)
  □ 인앱 알림 센터

5.4 멤버십 카드 (선택, 1.5일)
  □ MembershipCardPage UI
  □ qr_flutter QR 표시
  □ screenshot 캡처·공유
  □ 행사 체크인 (6자리 코드 방식)

5.5 정치 표현 정리 (0.5일)
  □ "CCP OUT" 등 키워드 점검
  □ 공식 카피 수정
  □ Apple 심사 친화적 톤

5.6 스토어 자료 (1일)
  □ 앱 아이콘 1024x1024
  □ 스크린샷 5종 (한국어·영어)
  □ 앱 설명·키워드

완료 기준:
  ✅ flutter analyze 경고 0
  ✅ 약관 화면 완성
  ✅ 릴리즈 APK/IPA 빌드 성공
```

### Week 6 — 베타 테스트 & 심사 제출

```
6.1 베타 테스트 (3일)
  □ TestFlight 내부 테스트 (10명)
  □ Google Play Internal Testing (10명)
  □ 단체 핵심 회원 30명 배포
  □ 버그 리포트 수집·수정

6.2 심사 제출 (2일)
  □ App Store Connect 정보 입력
  □ Google Play Console 정보 입력
  □ 등급 결정 (만 12세 / 만 17세)
  □ 심사 제출

심사 일반 소요:
  Apple: 1~3일
  Google: 7일

⚠️ 정치 카테고리 거절 시 대응:
  - 단체 협력 증빙 자료 첨부
  - 약관·정책 명확히 게시
  - "혐오 발언 금지" 정책 강조
  - 카테고리: News 또는 Social Networking 권장
```

---

## 16. 개발 규칙 & 컨벤션

### 16-1. 절대 규칙 (MUST)

```
✅ 모든 색상은 lib/app/theme/app_colors.dart 토큰만 사용
✅ Firestore 쓰기 전 Security Rules 시뮬레이터 검증
✅ 점수·등급 변경은 반드시 Cloud Functions 경유
✅ OAuth 시크릿은 Cloud Functions secrets에만
✅ 각 Phase 완료 시 git commit
✅ flutter analyze 경고 0개 유지
✅ Bundle ID·applicationId는 Week 4 변경 후 절대 변경 금지
✅ 청원 서명은 Optimistic UI + 서버 검증 패턴
✅ Realtime Stream은 dispose에서 cancel
```

### 16-2. 금지 사항 (MUST NOT)

```
❌ 클라이언트에서 users.points / level / isAdmin 변경
❌ Firestore Rules 우회한 직접 접근
❌ 하드코딩된 OAuth 시크릿
❌ print/debugPrint를 프로덕션 빌드에 남기기
❌ Phase 1-2 진행 중 다른 Phase 동시 작업
❌ "CCP OUT", "YOON FREE" 등 직접적 정치 표현
❌ Stream 구독 후 dispose 누락 (메모리 릭)
❌ Bundle ID 한 번 결정 후 재변경 (재발급 지옥)
```

### 16-3. 파일 네이밍 (Flutter)

```
화면:   snake_case + _page    (home_page.dart)
서비스: snake_case + _service (kakao_auth_service.dart)
스토어: snake_case + _store   (point_log_store.dart)
모델:   snake_case            (app_user.dart)
위젯:   snake_case            (point_toast.dart)

클래스명: PascalCase (HomePage, KakaoAuthService)
```

### 16-4. Git 브랜치 전략

```
main                       프로덕션 (보호됨)
develop                    개발 통합
feat/auth-multi-social     Week 1 인증 재구축
feat/firestore-events      Week 2 events 마이그레이션
feat/firestore-posts       Week 2 posts 마이그레이션
feat/point-system          Week 3 점수 시스템
feat/petition-tab          Week 3 청원 탭
feat/bump-tab-bar          Week 4 범프탭바
feat/home-revamp           Week 4 홈 리뉴얼
feat/release-config        Week 4 출시 설정
feat/legal-pages           Week 5 약관
feat/membership-card       Week 5 멤버십 카드
fix/[이슈명]               버그 수정
```

---

## 17. 환경 변수 & 시크릿 관리

```bash
# Firebase는 google-services.json / GoogleService-Info.plist 자동 로드
# 별도 환경변수 불필요

# Kakao
KAKAO_NATIVE_APP_KEY=xxxxx       # 네이티브 코드(Android/iOS) 설정
KAKAO_REST_API_KEY=xxxxx         # Cloud Functions에서만

# Naver
NAVER_CLIENT_ID=xxxxx             # 클라이언트 OK
NAVER_CLIENT_SECRET=xxxxx         # Cloud Functions에서만

# Cloud Functions secrets
firebase functions:secrets:set KAKAO_REST_API_KEY
firebase functions:secrets:set NAVER_CLIENT_SECRET

# Apple Sign In
# ios/Runner/Runner.entitlements + Apple Developer Console

# Google Sign In
# google-services.json에 자동 포함 (Android)
# iOS는 GoogleService-Info.plist + Info.plist URL Schemes
```

---

## 18. Claude Code 빠른 시작 프롬프트

### Week 1.1 시작 (카페 매칭 제거)
```
CLAUDE.md를 읽었습니다. Week 1.1을 시작합니다.

목표: 카페 매칭 코드 완전 제거

수정 대상:
  - lib/features/auth/domain/app_user.dart
  - lib/features/auth/data/auth_store.dart
  - lib/features/auth/presentation/login_page.dart
  - lib/features/auth/presentation/signup_complete_page.dart
  - lib/features/profile/presentation/profile_page.dart 또는 my_page.dart

제거할 필드:
  cafeNickname, cafeMatched, phoneNumber, phoneVerified, isVerified

완료 후:
  flutter analyze 통과 확인
  feat/auth-multi-social 브랜치에 커밋
```

### Week 4 범프탭바 시작
```
CLAUDE.md Section 5를 기준으로 범프 탭바를 구현합니다.

생성 파일:
  - lib/shared/widgets/bump_bottom_nav_painter.dart (CustomPainter)
  - lib/shared/widgets/bump_bottom_nav.dart (위젯)

탭 순서: 피드 | 청원 | 홈(중앙) | 일정 | 마이

명세:
  - 탭바 높이 60 + safe area
  - 중앙 버튼 지름 58, accentRed
  - cutout radius 36
  - Section 5-2의 Path 코드 참고

완료 기준:
  - iOS/Android 양쪽에서 자연스러운 돌출
  - 미읽 알림 dot 뱃지 동작
```

### 버그 수정
```
CLAUDE.md를 참고하여 [화면명]의 [문제]를 수정하세요.
원인 분석 → 수정 → 테스트 결과 순으로 보고.
로직/API/인증 코드는 가능한 한 보존.
```

---

## 19. 트러블슈팅 가이드

**1. Firebase 초기화 실패**
```
원인: google-services.json 누락 or applicationId 불일치
해결: Firebase Console에서 패키지명 확인 → 파일 재발급
```

**2. 네이버/카카오 로그인 후 Firebase Auth 실패**
```
원인: Cloud Function (createCustomToken*) 미배포
해결: firebase deploy --only functions:createCustomTokenFromKakao
```

**3. 점수 적립 안 됨**
```
원인: Cloud Function 미배포 or 일일 한도 초과
해결:
  1. firebase functions:log 확인
  2. point_logs 컬렉션 직접 조회로 한도 체크
```

**4. 범프탭바 중앙 버튼 그림자 잘림**
```
원인: Stack의 clipBehavior가 hardEdge
해결: Stack(clipBehavior: Clip.none) 적용
```

**5. 카운트업 끊김**
```
원인: setState 너무 자주 호출
해결: AnimationController + AnimatedBuilder 사용
```

**6. 앱스토어 심사 거절 - "정치 카테고리 부적절"**
```
대응:
  - 단체 협력 증빙 자료 첨부
  - 약관·정책 명확히 게시 (URL 제공)
  - "혐오 발언 금지" 정책 강조
  - 카테고리: News 또는 Social Networking 권장
```

---

## 20. 참고 문서

```
FIRESTORE_SCHEMA.md     데이터베이스 컬렉션 구조 상세
NEXT_STEPS.md           Claude Code 작업 큐 (스프린트별)
OWNER_TODO.md           대표님 직접 처리 항목 (외부 신청 등)
```

---

## 21. 변경 이력

| 일자 | 버전 | 변경 내용 |
|------|------|----------|
| 2025.04 | 1.0 | React Native + Supabase 초안 |
| 2025.04 | 2.0 | UI/UX 리뉴얼 (범프탭바·홈리뉴얼·청원탭·실시간피드) |
| 2026.04 | 3.0 | **Flutter + Firebase 실코드 반영. v2 UX 명세 계승. 카페매칭 제거. 다중로그인. 등급 시스템 도입.** |

---

*Last updated: 2026-04*
*Version: 3.0.0*
*Maintained by: 대표님 + Claude*
*변경 핵심: 실제 기술스택 반영(Flutter+Firebase) / v2 UX 명세 계승 / 카페매칭 폐기 / 4 소셜로그인 / 활동 기반 5단계 등급*