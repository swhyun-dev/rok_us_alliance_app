# Future Work

> 본 세션(브랜드 키트 통합 + 멤버십 카드 리디자인 + 로그인 리뉴얼 + 방패 로고 + RPG 스플래시)에서 의도적으로 보류한 작업 모음. 다음 세션 진입 시 이 문서부터 보면 빠르게 컨텍스트 복원 가능.

## 1. 색상 마이그레이션

상세 계획: [`docs/COLOR_MIGRATION_PLAN.md`](./COLOR_MIGRATION_PLAN.md)

요약:
- 영향 범위 약 45개 파일 / 약 280개 하드코딩 색상
- `lib/app/theme/app_colors.dart` (라이트, 일반 화면) 기준으로 정렬
- 브랜드 키트 영역(`lib/screens/splash_screen.dart`, `lib/widgets/membership_card.dart`, `lib/widgets/alliance_emblem.dart`)은 `lib/theme/colors.dart` (다크) 그대로 유지
- `app_colors.dart` 에 chipBg / mutedSurface / warningTint 등 누락 토큰 추가가 선행 필요
- 그룹별 커밋 (home / auth / community / membership / calendar 등) 권장

## 2. 폰트 자산 배치

현재 `assets/fonts/` 는 README 만 있고 실제 폰트 파일 없음. 다음을 배치 후 `pubspec.yaml` 에 등록 필요.

- **Pretendard** (한글 본문) — `Pretendard-{Regular,Medium,Bold}.otf`
- **BebasNeue** (영문 헤드라인) — `BebasNeue-Regular.ttf`
  - 미배치 상태에서 스플래시·로그인·회원증의 "ROK · US ALLIANCE" 영문 타이포가 시스템 sans-serif 로 fallback 중
- (선택) **JetBrainsMono** — 회원번호 monospace

배치 후 라이선스 고지 (SIL OFL) 도 필요 — `assets/fonts/README.md` 의 가이드 참조.

## 3. 스플래시 재진입 시 짧은 버전

현재는 첫 진입이든 재진입이든 동일하게 4.6s 풀 시퀀스 + 5.0s onComplete.

개선:
- `SharedPreferences` 등으로 첫 진입 여부 판단
- 첫 진입: 풀 4.6s 시퀀스
- 재진입: 1~2s fade-in 정도의 짧은 인트로
- 코드 위치: `lib/app/app.dart` 의 `_SplashGate` 또는 `lib/screens/splash_screen.dart` 에 `mode` prop 추가

## 4. 스플래시 사운드 효과

현재 시각 연출만, 무음. 추가 가능 포인트:
- 마법진 등장 (0.5s ~) — 저음의 hum
- 4방향 광선 발사 (1.6s ~) — 칼날 swoosh
- 방패 소환 + 폭발 (2.0~2.4s) — 임팩트 + chime
- 진행바 채워짐 (4.3s ~) — 미세한 UI tick

라이선스·용량·접근성(소리 끄기 옵션) 검토 필요. 패키지: `audioplayers` 또는 `just_audio`.

## 5. 앱 아이콘 풀세트

방패 로고(`assets/svg/shield_final.svg`) 기반 iOS/Android 아이콘 생성:
- iOS: 1024×1024 마스터 + 모든 사이즈 자동 생성 (Xcode `AppIcon.appiconset` 또는 `flutter_launcher_icons` 패키지)
- Android: adaptive icon (foreground·background 분리) — 방패는 foreground, 다크 배경 색상은 background
- App Store / Play Store 등록 시 1024×1024 마스터 아이콘 필요

## 6. QR 시스템 (Phase D)

CLAUDE.md Section 5-1 (1차 출시 단순 ID 인코딩) → 2차 정교화 (JWT 기반):

- JWT payload: uid, level, issuedAt, expiresAt
- 서명 키 보안: Cloud Functions secrets
- 만료·재발급 로직 (이미 부분 구현 — `lib/features/membership/data/qr_service.dart`)
- 행사 체크인 워크플로 — 스캔 → 검증 → 점수 적립

본 세션에서 QR 시스템은 회원증 카드와 연동된 부분만 보존, 나머지는 그대로.

## 7. assets/temp/files/ 정리 ✅ 완료

splash_rpg.html, shield_final_render.png 는 `docs/design-references/` 로 이동.
CLAUDE_CODE_FINAL.md (작업 지시서) 는 commit history 에 결과물이 반영됐으므로 삭제.
`assets/temp/` 폴더 제거 완료.

## 8. 죽은 코드 정리 (Week 5 예정)

CLAUDE.md Section 14 명시:
- `lib/features/splash/presentation/splash_page.dart` — orphan (새 SplashScreen 도입 후 미사용)
- `lib/shared/widgets/alliance_logo.dart` — orphan (사용자 결정으로 보류 중)
- `MissionPage`, `MeetupPage`, `BriefingPage`, `SearchPage` 등 정의만 있고 호출 없음

`flutter analyze` 가 unused 경고를 안 내는 건 import 이 남아있기 때문. 의도적 삭제 단계로 정리 필요.

---

*Last updated: 2026-05-10 (브랜드 통합 배치 종료 시점)*
