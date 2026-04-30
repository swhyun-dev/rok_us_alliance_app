# 앱 아이콘 자산 슬롯

CLAUDE.md Section 14 (파일 구조) 에 따라 출시 빌드에는 다음 자산이 필요합니다.
**현재 폴더에는 placeholder 가 없으므로**, owner 가 직접 배치해야 합니다.

## 필요한 파일

### 1. 마스터 아이콘 — `app_icon.png`

- 크기: 1024 × 1024 px
- 포맷: PNG, 알파 없음(불투명 배경)
- 디자인 가이드:
  - 한미동맹단 상징 (대한민국·미국 국기 모티브 + 방패형 실루엣)
  - 외곽 60px 안쪽으로만 핵심 요소 배치 (iOS rounded corner 안전 영역)
  - 텍스트 사용 시 짧은 약자만 (예: ROK·US 이니셜)
- 배치: `assets/images/app_icon.png`

### 2. 적응형 아이콘 (Android, 선택)

- `app_icon_foreground.png` — 432 × 432 px, 투명 배경, 가운데 264 × 264 영역만 보임
- `app_icon_background.png` — 432 × 432 px 단색 또는 그라디언트

## 자동 생성 절차 (권장)

`flutter_launcher_icons` 패키지로 모든 플랫폼별 사이즈를 한 번에 생성합니다.

1. `dev_dependencies` 에 `flutter_launcher_icons: ^0.14.1` 추가
2. `pubspec.yaml` 루트에 다음 추가:

   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/images/app_icon.png"
     adaptive_icon_background: "#0B1F5C"
     adaptive_icon_foreground: "assets/images/app_icon_foreground.png"
     remove_alpha_ios: true
   ```

3. 실행:

   ```bash
   flutter pub get
   dart run flutter_launcher_icons
   ```

4. 생성 확인:
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`

## 스토어 자료 (별도)

스토어 제출에는 **추가 스크린샷**이 필요합니다 (앱 아이콘과 별개).
`OWNER_SETUP.md` 의 "스토어 자료" 섹션 참조.

> 본 작업은 owner-side 작업으로 OWNER_SETUP.md 에서 가이드합니다.
