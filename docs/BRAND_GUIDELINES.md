# ROK · US Alliance · 브랜드 가이드라인

> 한미동맹단 (ROK_US Alliance) 공식 브랜드 사용 매뉴얼 · v1.0

## 1. 로고 시스템

### 메인 로고
- **`shield_final.svg`** — 방패 형태 메인 엠블럼
- 기본 사용처: 스플래시(소환되는 방패), 마이페이지, 큰 영역
- `AllianceEmblem` 위젯이 이 파일을 참조

### 깃발 SVG (스플래시 애니메이션용)
- **`us_flag_waving.svg`** — 펄럭이는 성조기 (320×260)
- **`kr_flag_waving.svg`** — 펄럭이는 태극기 (정확한 사양 적용)
- **`kr_flag_official.svg`** — 표준 태극기 단독 (참고용)

## 2. 색상 시스템

모든 색상은 `lib/theme/colors.dart`의 `AppColors` 클래스에서만 가져와야 합니다.

### 메인 컬러
| 토큰 | HEX | 용도 |
|---|---|---|
| `bgPrimary` | `#0D1117` | 앱 전체 배경 |
| `bgCard` | `#1C2128` | 카드, 모달 배경 |
| `accentRed` | `#E63946` | 메인 액센트 |
| `textPrimary` | `#F0F0F0` | 본문 텍스트 |
| `textMuted` | `#6B7280` | 부가 정보 |

### 깃발 컬러 (정확한 사양)
| 토큰 | HEX | 용도 |
|---|---|---|
| `flagUsBlue` | `#3C3B6E` | 성조기 청색 (canton) |
| `flagUsRed` | `#B22234` | 성조기 적색 (stripe) |
| `flagKrRed` | `#CD2E3A` | 태극 적색 |
| `flagKrBlue` | `#003478` | 태극 청색 |

### 등급 컬러
| 등급 | 토큰 | HEX |
|---|---|---|
| 일반회원 | `textMuted` | `#6B7280` |
| 정회원 | `accentRed` | `#E63946` |
| Gold | `gradeGold` | `#C9A84C` |
| VIP | `gradeVip` | `#7F77DD` |

## 3. 타이포그래피

| 용도 | 폰트 | 크기 | Weight |
|---|---|---|---|
| 브랜드 로고 (영문) | Bebas Neue | 28-56px | 400 |
| 화면 제목 | Noto Sans KR | 20px | 700 |
| 본문 | Noto Sans KR | 14px | 400 |
| QR 번호 | monospace | 12px | 500 |

## 4. 절대 규칙

- ✅ 모든 색상은 `AppColors` 토큰만 사용
- ✅ 하드코딩된 색상 (`Color(0xFF...)`, `Colors.red`) 절대 금지
- ❌ 태극기 비율·색상 임의 변경 금지
- ❌ 정치 메시지 결합 금지 (브랜드 정체성 보호)

## 5. 산출물 통합 체크리스트

- [ ] `assets/svg/` 폴더에 SVG 4개 배치
- [ ] `lib/theme/colors.dart` 통합
- [ ] `lib/widgets/alliance_emblem.dart` 통합
- [ ] `lib/widgets/membership_card.dart` 통합
- [ ] `lib/screens/splash_screen.dart` 통합
- [ ] `pubspec.yaml`에 `flutter_svg`, `qr_flutter` 의존성 추가
- [ ] `pubspec.yaml`의 assets에 `assets/svg/` 등록
- [ ] Bebas Neue, Noto Sans KR 폰트 다운로드 후 `assets/fonts/`에 배치
- [ ] `flutter pub get` 실행
- [ ] `main.dart`에서 SplashScreen 첫 화면으로 설정
- [ ] 시뮬레이터에서 애니메이션 동작 확인
