# 폰트 자산

본 폴더는 앱이 사용하는 폰트 파일을 둡니다.

## 현재 배치된 폰트

### Bebas Neue ✅

- 파일: `BebasNeue-Regular.ttf`
- 다운로드: https://fonts.google.com/specimen/Bebas+Neue
- 라이선스: **SIL Open Font License 1.1** — 상업적 사용 자유
- pubspec 등록: `family: BebasNeue` (이미 등록됨)
- 사용처:
  - 스플래시 RPG 텍스트 프레임 (`lib/screens/splash/rpg_text_frame.dart`)
  - 로그인 페이지 "ROK · US" / "ALLIANCE" (`lib/features/auth/presentation/login_page.dart`)
  - 멤버십 카드 헤더 + ACTIVITY POINTS (`lib/widgets/membership_card.dart`)

코드에서 `fontFamily: 'BebasNeue'` 로 참조.

## 향후 추가 예정 (코드에서 실제 사용 시점에 도입)

### Pretendard (한글 본문)

- 다운로드: https://github.com/orioncactus/pretendard/releases
- 권장 weight: Regular / Medium / Bold
- 라이선스: SIL OFL 1.1
- 등록 시 pubspec.yaml 의 fonts 섹션에 family `Pretendard` 추가

### JetBrains Mono (선택, 회원번호 monospace)

- 다운로드: https://www.jetbrains.com/lp/mono/
- 라이선스: SIL OFL 1.1
- 현재는 `fontFamily: 'monospace'` 시스템 fallback 사용 — 통일감 위해 도입 가능

## 라이선스 고지 (Open Source Licenses)

본 앱이 사용하는 폰트 라이선스는 SIL Open Font License 1.1 입니다. 상업적
사용·재배포는 자유이나, 라이선스 사본을 함께 배포해야 합니다.

추후 설정 화면 또는 `assets/legal/open_source_licenses.md` 등에서 다음 형식으로
고지해주세요:

```
- Bebas Neue
  © 2010 The Bebas Neue Project Authors
  https://github.com/dharmatype/Bebas-Neue
  Licensed under SIL Open Font License 1.1
```

`Pretendard`, `JetBrains Mono` 등이 추가되면 위 항목에 같은 형식으로 덧붙입니다.
