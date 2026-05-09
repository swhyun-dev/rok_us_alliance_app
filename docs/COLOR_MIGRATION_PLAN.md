# Color Migration Plan

> 다음 세션 작업용 메모. 본 세션(브랜드 산출물 통합 + 멤버십 카드)에서는 색상 마이그레이션을 보류했습니다.

## 배경

브랜드 산출물 통합 시 `lib/` 전수조사한 결과, 하드코딩된 색상이 광범위하게 분포해 한 세션 내 처리 시 디자인 의사결정 품질이 떨어진다고 판단해 분리.

## 영향 범위 (조사 시점 기준)

- `Color(0x...)` hex 리터럴: **87** 개 / 17 파일
- `Colors.xxx` 머터리얼: **271** 개 / 48 파일
- 그 중 `Colors.transparent` (수용 가능): 15 개 / 12 파일
- **순수 마이그레이션 대상: 약 296 occurrences / 약 45 파일**

## 마이그레이션 제외 (그대로 둠)

| 파일 | 사유 |
|---|---|
| `lib/app/theme/app_colors.dart` | 라이트 팔레트 소스 |
| `lib/theme/colors.dart` | 다크 브랜드 팔레트 소스 |
| `lib/screens/splash_screen.dart` | 브랜드 키트 |
| `lib/widgets/membership_card.dart` | 브랜드 키트 |
| `lib/widgets/alliance_emblem.dart` | 브랜드 키트 |

## 확장 필요 토큰 (`lib/app/theme/app_colors.dart`)

`community_post_detail_page.dart` 에서 발견된 unique 색상이 기존 팔레트에 없음. 의미론적(역할 기반) 이름으로 추가 필요.

발견된 hex 후보 (역할은 사용 맥락 확인 후 결정):
```
0xFFE9EEF8, 0xFFFDE9EA, 0xFFE1E3E8, 0xFFFFEAD7, 0xFFD57A1F,
0xFFF7F8FA, 0xFFF2F2F2, 0xFFF5F6F8, 0xFFEAECEF, 0xFFF4F5F7,
0xFFF8F9FB
```

추가 후보 토큰 이름 (잠정):
- `chipBg`, `chipBorder` — 카테고리·태그 칩
- `mutedSurface`, `divider` — 회색 표면 / 디바이더
- `warningTint`, `warningText` — `0xFFFFEAD7` (배경) / `0xFFD57A1F` (전경)
- 그 외 `community_post_detail_page.dart` 검토 중 발견되는 것들

> ⚠️ 토큰명은 색상값 기반(`gray100`)이 아니라 **역할 기반**으로. 화면별 사용 맥락을 보고 의미를 정한 뒤 이름 짓기.

## 작업 순서

1. **팔레트 확장**: `app_colors.dart`에 누락 토큰 추가 (커밋 1)
2. **그룹별 마이그레이션** (각각 별도 커밋):
   - `home_*` 묶음
   - `auth_*` 묶음
   - `community_*` 묶음
   - `membership_*` 묶음
   - `calendar_*` 묶음
   - 그 외 (settings, profile, notifications, reports, action_board, petition, feed, shared, app/widgets 등)
3. **app_theme.dart 검토**: `scaffoldBackgroundColor` (`0xFFF2F5FB`), `inputDecorationTheme.fillColor` (`0xFFF8FAFF`) 토큰화. Colors.white/black 다수는 Material 기본 동작 그대로 둘지 결정.

## 마이그레이션 규칙

- ✅ 기존 라이트 팔레트(`lib/app/theme/app_colors.dart`) 기준으로 통일
- ✅ 토큰명은 의미론적 (역할 기반)
- ✅ `Colors.transparent` 는 그대로 둠 (수용 가능 패턴)
- ✅ 그룹별 커밋으로 롤백 포인트 확보
- ❌ 시각적 변화 발생할 수 있는 근사 매핑 금지 — 정확 매핑 안 되면 토큰 추가 후 진행
- ❌ 브랜드 키트(`lib/theme/colors.dart`, `lib/screens/splash_screen.dart`, `lib/widgets/{membership_card,alliance_emblem}.dart`) 건드리지 말 것

## 영향 큰 파일 우선순위 (Colors.* 기준 상위)

| 파일 | Colors.* | Color hex |
|---|---:|---:|
| `lib/features/profile/presentation/profile_page.dart` | 23 | 2 |
| `lib/features/membership/presentation/membership_card_modal.dart` | 17 | 1 |
| `lib/features/auth/presentation/login_page.dart` | 15 | 3 |
| `lib/features/action_board/presentation/action_board_page.dart` | 14 | 1 |
| `lib/app/widgets/alliance_app_bar.dart` | 14 | 1 |
| `lib/features/calendar/presentation/calendar_page.dart` | 12 | 0 |
| `lib/features/community/presentation/community_post_detail_page.dart` | 12 | **16** |
| `lib/features/membership/presentation/membership_card_page.dart` | 11 | 2 |

`community_post_detail_page.dart` 가 hex 리터럴이 가장 많고 unique 색상이 집중돼 있어 토큰 확장 작업의 시작점이 되어야 함.

## 기존 화면 색상 베이스 정책

- 일반 화면: `lib/app/theme/app_colors.dart` (라이트, `koreanRed`/`koreanBlue`/`softBlue` 등)
- 브랜드 임팩트 영역(스플래시·회원증·QR 풀화면 등): `lib/theme/colors.dart` (다크, `bgPrimary`/`accentRed`/`flagKr*` 등)

두 팔레트 동시 import 필요 시 alias 사용:
```dart
import 'package:rok_us_alliance_app/app/theme/app_colors.dart';
import 'package:rok_us_alliance_app/theme/colors.dart' as brand;
```
