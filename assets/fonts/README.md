# 폰트 자산 슬롯

이 폴더는 앱에서 사용하는 폰트 파일을 두는 자리입니다.
**현재는 비어 있으며**, 코드는 시스템 기본 폰트로 동작합니다.

CLAUDE.md Section 3-3 에 명시된 폰트는 다음과 같습니다.

## 1. Pretendard (한글 본문)

- 라이선스: SIL Open Font License 1.1 (상업적 사용 가능)
- 다운로드: https://github.com/orioncactus/pretendard/releases
- 필요한 파일:
  - `Pretendard-Regular.otf`
  - `Pretendard-Medium.otf`
  - `Pretendard-Bold.otf`
  - `Pretendard-Black.otf` (선택)
- 배치: `assets/fonts/Pretendard-{Weight}.otf`

## 2. Bebas Neue (숫자·영문 헤드라인)

- 라이선스: SIL Open Font License 1.1 (상업적 사용 가능)
- 다운로드: https://fonts.google.com/specimen/Bebas+Neue
- 필요한 파일: `BebasNeue-Regular.ttf`
- 배치: `assets/fonts/BebasNeue-Regular.ttf`

## 3. JetBrains Mono (QR 회원번호 등 monospace 영역, 선택)

- 라이선스: SIL Open Font License 1.1
- 다운로드: https://www.jetbrains.com/lp/mono/
- 필요한 파일: `JetBrainsMono-Regular.ttf`
- 배치: `assets/fonts/JetBrainsMono-Regular.ttf`

## 폰트 파일 배치 후 해야 할 일

1. 위 파일들을 이 폴더에 복사
2. `pubspec.yaml` 의 `flutter:` 섹션에 다음을 추가:

   ```yaml
   flutter:
     fonts:
       - family: Pretendard
         fonts:
           - asset: assets/fonts/Pretendard-Regular.otf
           - asset: assets/fonts/Pretendard-Medium.otf
             weight: 500
           - asset: assets/fonts/Pretendard-Bold.otf
             weight: 700
       - family: BebasNeue
         fonts:
           - asset: assets/fonts/BebasNeue-Regular.ttf
   ```

3. `app_theme.dart` 또는 사용처에서 `fontFamily: 'Pretendard'` / `'BebasNeue'` 로 참조
4. `flutter clean && flutter pub get` 으로 자산 재등록
5. 라이선스 고지 페이지(약관 또는 SettingsPage > 오픈소스 라이선스) 에 SIL OFL 표기 누락 여부 확인

> 본 작업은 owner-side 작업으로 OWNER_SETUP.md 에서 가이드합니다.
