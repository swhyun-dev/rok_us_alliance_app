# FIRESTORE_SCHEMA.md — 한미동맹단 앱 DB 설계도

> 이 문서는 한미동맹단 앱의 Firestore 데이터베이스 구조를 정의합니다.
> 모든 컬렉션·필드·Security Rules·인덱스·Cloud Functions 트리거를 포함합니다.
> Firestore 작업 시작 전 반드시 이 문서를 참조하세요.

**버전**: 1.0
**작성일**: 2026-04
**참조 문서**: CLAUDE.md (Section 12)

---

## 📚 목차

1. 컬렉션 전체 맵
2. 컬렉션 상세 (12개)
3. Security Rules 전체 코드
4. 복합 인덱스 (Composite Indexes)
5. Cloud Functions 트리거 매핑
6. 마이그레이션 스크립트 가이드
7. 데이터 타입 컨벤션

---

## 1. 컬렉션 전체 맵

```
firestore/
│
├── users/{uid}                   사용자 프로필
│
├── admins/{uid}                  관리자 (기존 유지)
│
├── events/{eventId}              행사·집회
│   └── (서브컬렉션 없음)
│
├── posts/{postId}                피드 게시글
│   └── comments/{commentId}      댓글
│
├── petitions/{petitionId}        청원
│   └── signatures/{uid}          서명 (uid를 문서ID로)
│
├── point_logs/{logId}            점수 적립 이력
│
├── check_ins/{checkInId}         행사 체크인 기록
│
├── reports/{reportId}            신고 (게시글·댓글·사용자)
│
├── notifications/{notifId}       사용자별 알림 이력
│
├── event_codes/{code}            행사 체크인 6자리 코드 (단기 유효)
│
├── daily_check_ins/{uid_date}    일일 체크인 (uid_YYYY-MM-DD를 문서ID로)
│
└── app_meta/                     앱 메타데이터
    ├── stats                     홈 통계 (5분마다 갱신)
    └── policies                  등급·점수 정책
```

**총 12개 컬렉션 + 2개 서브컬렉션 + 2개 메타 문서**

---

## 2. 컬렉션 상세

### 2-1. `users/{uid}` — 사용자 프로필

```typescript
interface User {
  // ━━━ 식별자 ━━━
  uid: string;                  // Firebase Auth UID (문서ID와 동일)
  provider: 'apple' | 'kakao' | 'naver' | 'google';
  providerUserId: string;        // 각 OAuth의 고유 ID
  
  // ━━━ 프로필 ━━━
  email: string | null;          // 일부 프로바이더는 미제공
  nickname: string;              // 앱 내 표시명 (2~12자)
  profileImageUrl: string | null;
  
  // ━━━ 등급·점수 (클라이언트 변경 불가) ━━━
  level: 1 | 2 | 3 | 4 | 5;     // 1=새내기, 5=동지
  points: number;                // 누적 점수 (음수 불가)
  
  // ━━━ 약관 ━━━
  consentedTerms: boolean;
  consentedPrivacy: boolean;
  consentedAt: Timestamp;
  termsVersion: string;          // 'v1.0' 등 (약관 갱신 추적)
  
  // ━━━ 시간 ━━━
  createdAt: Timestamp;
  lastSignedInAt: Timestamp;
  lastCheckInAt: Timestamp | null;     // 마지막 일일 체크인
  consecutiveCheckInDays: number;       // 연속 체크인 일수
  
  // ━━━ 디바이스 ━━━
  deviceToken: string | null;    // FCM 토큰
  platform: 'ios' | 'android' | null;
  appVersion: string | null;
  
  // ━━━ 권한·상태 ━━━
  isAdmin: boolean;              // false 기본 (admins 컬렉션과 별개)
  isBanned: boolean;
  bannedReason: string | null;
  bannedUntil: Timestamp | null;
  
  // ━━━ 통계 (Cloud Function 자동 갱신) ━━━
  stats: {
    postsCount: number;
    commentsCount: number;
    likesReceivedCount: number;
    petitionsSignedCount: number;
    eventsAttendedCount: number;
  };
  
  // ━━━ 추천인 ━━━
  referralCode: string;          // 자동 생성 (8자, 본인 코드)
  referredBy: string | null;     // 추천인 referralCode
}
```

**필수 필드**: uid, provider, providerUserId, nickname, level, points, consentedTerms, consentedPrivacy, createdAt

**기본값**:
```javascript
{
  level: 1,
  points: 0,
  consecutiveCheckInDays: 0,
  isAdmin: false,
  isBanned: false,
  stats: { postsCount: 0, commentsCount: 0, likesReceivedCount: 0, petitionsSignedCount: 0, eventsAttendedCount: 0 }
}
```

**제약사항**:
- nickname: 2~12자, 중복 불가 (Cloud Function에서 검증)
- referralCode: 영숫자 8자, 자동 생성, 중복 불가
- email은 nullable이지만 가능하면 수집

---

### 2-2. `admins/{uid}` — 관리자

```typescript
interface Admin {
  uid: string;                   // Firebase Auth UID
  email: string;
  role: 'super' | 'moderator' | 'editor';
  createdAt: Timestamp;
  createdBy: string;             // super 관리자 uid
  permissions: {
    canEditEvents: boolean;
    canEditPetitions: boolean;
    canBanUsers: boolean;
    canDeletePosts: boolean;
    canAdjustPoints: boolean;
  };
}
```

**기존 코드와의 호환**:
- `admin_auth_store.dart`에서 이 컬렉션 read만 함
- 신규 필드(`role`, `permissions`)는 점진 추가
- 1차 출시: `role: 'super'`만 사용

---

### 2-3. `events/{eventId}` — 행사·집회

```typescript
interface Event {
  // ━━━ 식별자 ━━━
  id: string;                    // 자동 생성 (문서ID와 동일)
  
  // ━━━ 기본 정보 ━━━
  title: string;                 // 행사명
  description: string;           // 상세 설명 (마크다운 가능)
  category: 'rally' | 'meeting' | 'online' | 'cultural' | 'other';
  
  // ━━━ 시간·장소 ━━━
  eventDate: Timestamp;          // 행사 시작 시각
  endDate: Timestamp | null;     // 종료 시각 (선택)
  location: string;              // "광화문 광장" 등
  locationDetail: string | null; // "이순신 동상 앞" 등
  geoPoint: GeoPoint | null;     // 위도·경도 (선택, 길찾기용)
  
  // ━━━ 참여 ━━━
  maxAttendees: number | null;   // 인원 제한 (null = 무제한)
  currentAttendees: number;      // 현재 신청 수 (Cloud Function 갱신)
  pointsReward: number;          // 체크인 시 적립 포인트 (기본 100)
  requiresCheckIn: boolean;      // 체크인 필요 여부
  
  // ━━━ 콘텐츠 ━━━
  imageUrls: string[];           // 포스터·홍보 이미지
  externalUrl: string | null;    // 외부 링크 (네이버 카페 등)
  
  // ━━━ 상태 ━━━
  status: 'upcoming' | 'ongoing' | 'completed' | 'cancelled';
  isFeatured: boolean;           // 홈 상단 노출 여부
  
  // ━━━ 메타 ━━━
  createdBy: string;             // 관리자 uid
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**자동 갱신**:
- `currentAttendees`: check_ins 컬렉션 카운트로 Cloud Function이 갱신
- `status`: eventDate 기준 매시간 스케줄러가 갱신

---

### 2-4. `posts/{postId}` — 피드 게시글

```typescript
interface Post {
  id: string;
  
  // ━━━ 작성자 ━━━
  authorId: string;              // users.uid
  authorNickname: string;        // 비정규화 (작성 시점 닉네임 캐시)
  authorLevel: number;           // 비정규화 (작성 시점 등급)
  
  // ━━━ 콘텐츠 ━━━
  title: string;                 // 1~50자
  content: string;               // 1~2000자, 마크다운 가능
  category: 'urgent' | 'policy' | 'network' | 'event' | 'general';
  imageUrls: string[];           // 최대 5장
  
  // ━━━ 플래그 ━━━
  isUrgent: boolean;             // 긴급 알림용 (관리자만 true 설정)
  isPinned: boolean;             // 상단 고정
  isDeleted: boolean;            // soft delete
  
  // ━━━ 카운트 (Cloud Function 갱신) ━━━
  viewCount: number;
  likeCount: number;
  commentCount: number;
  shareCount: number;
  
  // ━━━ 시간 ━━━
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**서브컬렉션**: `posts/{postId}/comments/{commentId}`

---

### 2-5. `posts/{postId}/comments/{commentId}` — 댓글

```typescript
interface Comment {
  id: string;
  postId: string;                // 부모 post id (편의용)
  
  authorId: string;
  authorNickname: string;
  authorLevel: number;
  
  content: string;               // 1~500자
  parentCommentId: string | null;  // 대댓글 (1단계만 허용)
  
  isDeleted: boolean;
  likeCount: number;
  
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

---

### 2-6. `petitions/{petitionId}` — 청원

```typescript
interface Petition {
  id: string;
  
  // ━━━ 콘텐츠 ━━━
  title: string;                 // 1~80자
  description: string;           // 1~3000자
  category: 'security' | 'economy' | 'education' | 'media' | 'judicial' | 'other';
  imageUrls: string[];
  
  // ━━━ 목표·진행 ━━━
  targetCount: number;           // 목표 서명 수
  currentCount: number;          // 현재 서명 수 (Cloud Function 갱신)
  
  // ━━━ 시간 ━━━
  startDate: Timestamp;
  deadline: Timestamp;
  completedAt: Timestamp | null; // 목표 달성 시점
  
  // ━━━ 상태 ━━━
  status: 'active' | 'completed' | 'expired';
  isFeatured: boolean;
  
  // ━━━ 메타 ━━━
  createdBy: string;             // 관리자 uid
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**서브컬렉션**: `petitions/{petitionId}/signatures/{uid}` — 서명 시 uid를 문서ID로 사용 → 중복 자동 방지

---

### 2-7. `petitions/{petitionId}/signatures/{uid}` — 서명

```typescript
interface PetitionSignature {
  uid: string;                   // 서명자 uid (문서ID와 동일)
  petitionId: string;            // 부모 petition id
  signedAt: Timestamp;
  pointsAwarded: number;         // 적립 포인트 (기본 50)
  
  // 비정규화
  signerNickname: string;
  signerLevel: number;
}
```

**중복 방지**: 문서ID = uid이므로 같은 사용자가 두 번 서명 시 덮어쓰기. Security Rules에서 update 차단.

---

### 2-8. `point_logs/{logId}` — 점수 적립 이력

```typescript
interface PointLog {
  id: string;
  uid: string;                   // 사용자
  
  type: 
    | 'welcome'                  // 가입 환영 +50
    | 'daily_check_in'           // 일일 체크인 +10
    | 'post_create'              // 게시글 +30
    | 'comment_create'           // 댓글 +5
    | 'like_received'            // 좋아요 받음 +2
    | 'share'                    // 공유 +20
    | 'petition_sign'            // 청원 서명 +50
    | 'event_check_in'           // 행사 체크인 +100
    | 'referral_complete'        // 친구 초대 +200
    | 'admin_adjust'             // 관리자 조정 (양/음수)
    | 'consecutive_bonus';       // 연속 체크인 보너스
  
  amount: number;                // 음수 가능 (admin_adjust)
  refId: string | null;          // 관련 문서 ID (postId, eventId 등)
  refType: string | null;        // 'post' | 'comment' | 'event' 등
  
  // 적립 후 상태
  pointsAfter: number;           // 적립 후 누적 점수
  levelAfter: number;            // 적립 후 등급
  levelChanged: boolean;         // 등급 변동 여부
  
  // 메타
  description: string;           // 사용자에게 보여줄 메시지
  createdAt: Timestamp;
  
  // 관리자 조정 시
  adjustedBy: string | null;     // 관리자 uid
  adjustReason: string | null;
}
```

**중요**: 클라이언트는 절대 쓰기 불가. Cloud Functions만.

---

### 2-9. `check_ins/{checkInId}` — 행사 체크인

```typescript
interface CheckIn {
  id: string;
  uid: string;                   // 참여자
  eventId: string;               // 행사
  
  method: 'code' | 'qr' | 'manual';  // 체크인 방식
  codeUsed: string | null;       // 사용된 6자리 코드 (method='code'일 때)
  
  pointsAwarded: number;
  giftReceived: boolean;
  
  checkedInAt: Timestamp;
  
  // GeoPoint (선택, 어뷰징 방지)
  location: GeoPoint | null;
  ipAddress: string | null;      // Cloud Function에서 기록
  
  // 비정규화
  uidNickname: string;
  eventTitle: string;
}
```

**중복 방지**: 문서ID 형식 `${uid}_${eventId}` → unique 보장

---

### 2-10. `reports/{reportId}` — 신고

```typescript
interface Report {
  id: string;
  
  // ━━━ 신고자 ━━━
  reporterId: string;
  reporterNickname: string;
  
  // ━━━ 신고 대상 ━━━
  targetType: 'post' | 'comment' | 'user' | 'petition';
  targetId: string;
  targetSnapshot: object;        // 신고 시점 콘텐츠 스냅샷 (악용 방지)
  
  // ━━━ 사유 ━━━
  reason: 
    | 'spam'                     // 스팸·광고
    | 'hate_speech'              // 혐오 발언
    | 'misinformation'           // 허위정보
    | 'harassment'               // 괴롭힘
    | 'inappropriate'            // 부적절한 콘텐츠
    | 'illegal'                  // 불법 콘텐츠
    | 'other';
  description: string | null;    // 추가 설명
  
  // ━━━ 처리 ━━━
  status: 'pending' | 'reviewing' | 'resolved' | 'dismissed';
  resolvedBy: string | null;     // 처리한 관리자 uid
  resolvedAt: Timestamp | null;
  resolution: string | null;     // 처리 결과
  action: 'none' | 'warning' | 'content_removed' | 'user_banned' | null;
  
  createdAt: Timestamp;
}
```

**Cloud Function 트리거**:
- `onReportCreated`: 같은 대상 5건 이상이면 자동 숨김 처리
- `scheduledReportCleanup`: 24시간 미처리 시 관리자 알림

---

### 2-11. `notifications/{notifId}` — 알림 이력

```typescript
interface Notification {
  id: string;
  uid: string;                   // 수신자
  
  type: 
    | 'point_awarded'            // 점수 적립
    | 'level_up'                 // 등급 승급
    | 'comment_received'         // 내 글에 댓글
    | 'like_received'            // 좋아요 받음
    | 'event_reminder'           // 행사 D-1
    | 'petition_milestone'       // 청원 50%/100% 달성
    | 'urgent_alert'             // 긴급 알림 (전체 푸시)
    | 'admin_message';           // 관리자 알림
  
  title: string;
  body: string;
  imageUrl: string | null;
  
  // 딥링크
  routeName: string | null;      // '/post' 등
  routeParams: object | null;    // { postId: 'xxx' }
  
  isRead: boolean;
  createdAt: Timestamp;
  readAt: Timestamp | null;
  
  // FCM 발송 결과
  fcmSent: boolean;
  fcmMessageId: string | null;
}
```

---

### 2-12. `event_codes/{code}` — 행사 체크인 코드

```typescript
interface EventCode {
  code: string;                  // 6자리 숫자 (문서ID와 동일)
  eventId: string;
  createdBy: string;             // 관리자 uid
  createdAt: Timestamp;
  expiresAt: Timestamp;          // 발급 후 10분
  usedCount: number;             // 사용된 횟수 (중복 사용 방지 X, 횟수만 추적)
  isActive: boolean;
}
```

**자동 만료**: TTL Policy 설정 (Firestore Time-To-Live)

---

### 2-13. `daily_check_ins/{uid_YYYY-MM-DD}` — 일일 체크인

```typescript
interface DailyCheckIn {
  uid: string;
  date: string;                  // 'YYYY-MM-DD' (KST 기준)
  pointsAwarded: number;         // 기본 10, 연속 보너스 별도
  consecutiveDays: number;       // 연속 체크인 일수
  bonusAwarded: boolean;         // 3일/7일 보너스 지급 여부
  checkedInAt: Timestamp;
}
```

**중복 방지**: 문서ID = `${uid}_${date}` → 하루 1번만 가능

---

### 2-14. `app_meta/stats` — 홈 통계 (단일 문서)

```typescript
interface AppStats {
  memberCount: number;           // 가입회원
  activePetitions: number;       // 진행중 청원
  monthlyEvents: number;         // 이번달 행사
  totalPosts: number;
  totalComments: number;
  totalSignatures: number;
  
  updatedAt: Timestamp;          // 5분마다 갱신
}
```

**갱신**: `updateAppStats` Cloud Function이 5분마다 스케줄 실행

---

### 2-15. `app_meta/policies` — 정책 (단일 문서)

```typescript
interface AppPolicies {
  // 등급 정책
  levels: {
    [level: number]: {
      name: string;              // '새내기', '시민', ...
      minPoints: number;
      color: string;             // '#8C93A8' 등
      description: string;
    }
  };
  
  // 점수 정책
  pointRules: {
    [type: string]: {
      amount: number;
      dailyLimit: number | null; // null = 무제한
      description: string;
    }
  };
  
  // 약관 버전
  termsVersion: string;
  privacyVersion: string;
  termsUpdatedAt: Timestamp;
  
  // 기능 토글 (긴급 차단용)
  features: {
    petitionEnabled: boolean;
    eventCheckInEnabled: boolean;
    referralEnabled: boolean;
    membershipCardEnabled: boolean;
  };
}
```

**클라이언트 활용**: 앱 시작 시 한 번 fetch → 메모리에 캐시. 점수·등급 안내 화면에서 표시.

---

## 3. Security Rules 전체 코드

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 헬퍼 함수
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isSignedIn() && 
             exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }
    
    function isOwnerOrAdmin(uid) {
      return isOwner(uid) || isAdmin();
    }
    
    function isNotBanned() {
      return isSignedIn() && 
             (!exists(/databases/$(database)/documents/users/$(request.auth.uid)) ||
              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isBanned == false);
    }
    
    // 사용자가 보호 필드를 변경하려고 하는지 체크
    function isChangingProtectedFields() {
      return request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['points', 'level', 'isAdmin', 'isBanned', 'bannedReason', 
                   'bannedUntil', 'stats', 'consecutiveCheckInDays', 'lastCheckInAt',
                   'referralCode', 'createdAt']);
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // users
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /users/{uid} {
      // 본인 또는 관리자만 읽기
      allow read: if isOwner(uid) || isAdmin();
      
      // 본인만 생성 (uid 일치 확인)
      allow create: if isOwner(uid)
                       && request.resource.data.uid == uid
                       && request.resource.data.points == 0
                       && request.resource.data.level == 1
                       && request.resource.data.isAdmin == false
                       && request.resource.data.isBanned == false
                       && request.resource.data.consentedTerms == true
                       && request.resource.data.consentedPrivacy == true;
      
      // 본인만 업데이트 (보호 필드 제외)
      allow update: if isOwner(uid)
                       && !isChangingProtectedFields();
      
      // 삭제 불가 (Cloud Function의 deleteUser만 가능)
      allow delete: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // admins
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /admins/{uid} {
      // 본인만 자신의 admin 문서 읽기 가능 (admin_login_page 동작)
      allow read: if isOwner(uid);
      // 쓰기는 super 관리자 콘솔에서만 (Cloud Function)
      allow write: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // events
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /events/{eventId} {
      // 인증 사용자 모두 읽기 가능
      allow read: if isSignedIn();
      
      // 관리자만 작성·수정·삭제
      allow create, update, delete: if isAdmin();
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // posts
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /posts/{postId} {
      allow read: if isSignedIn();
      
      // 작성: 본인 글, 차단되지 않은 사용자만
      allow create: if isNotBanned()
                       && request.resource.data.authorId == request.auth.uid
                       && request.resource.data.isDeleted == false
                       && request.resource.data.likeCount == 0
                       && request.resource.data.commentCount == 0
                       && request.resource.data.viewCount == 0
                       && request.resource.data.shareCount == 0
                       // 일반 사용자는 isUrgent/isPinned false 강제
                       && (isAdmin() || (
                           request.resource.data.isUrgent == false &&
                           request.resource.data.isPinned == false
                       ));
      
      // 수정: 본인 글 + 카운트 필드 변경 불가, 또는 관리자
      allow update: if isOwnerOrAdmin(resource.data.authorId)
                       && (isAdmin() ||
                           !request.resource.data.diff(resource.data).affectedKeys()
                               .hasAny(['likeCount', 'commentCount', 'viewCount', 'shareCount',
                                        'isUrgent', 'isPinned', 'authorId', 'createdAt']));
      
      // 삭제: 작성자 또는 관리자 (실제로는 isDeleted=true로 update 권장)
      allow delete: if isOwnerOrAdmin(resource.data.authorId);
      
      // 댓글
      match /comments/{commentId} {
        allow read: if isSignedIn();
        
        allow create: if isNotBanned()
                         && request.resource.data.authorId == request.auth.uid
                         && request.resource.data.isDeleted == false
                         && request.resource.data.likeCount == 0;
        
        allow update: if isOwnerOrAdmin(resource.data.authorId)
                         && (isAdmin() ||
                             !request.resource.data.diff(resource.data).affectedKeys()
                                 .hasAny(['likeCount', 'authorId', 'createdAt']));
        
        allow delete: if isOwnerOrAdmin(resource.data.authorId);
      }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // petitions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /petitions/{petitionId} {
      allow read: if isSignedIn();
      allow create, update, delete: if isAdmin();
      
      // 서명: signPetition Cloud Function이 처리하므로 클라이언트 직접 쓰기 불가
      match /signatures/{uid} {
        allow read: if isOwner(uid) || isAdmin();
        allow write: if false;  // Cloud Function만
      }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // point_logs (절대 클라이언트 쓰기 불가)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /point_logs/{logId} {
      // 본인 또는 관리자만 읽기
      allow read: if isOwner(resource.data.uid) || isAdmin();
      // 쓰기는 Cloud Function만
      allow write: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // check_ins
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /check_ins/{checkInId} {
      allow read: if isOwner(resource.data.uid) || isAdmin();
      allow write: if false;  // Cloud Function (eventCheckIn) 만
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // reports
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /reports/{reportId} {
      // 신고자 본인 또는 관리자만 읽기
      allow read: if isOwner(resource.data.reporterId) || isAdmin();
      
      // 작성: 본인 신고만
      allow create: if isNotBanned()
                       && request.resource.data.reporterId == request.auth.uid
                       && request.resource.data.status == 'pending'
                       && request.resource.data.resolvedBy == null;
      
      // 수정·삭제: 관리자만
      allow update, delete: if isAdmin();
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // notifications
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /notifications/{notifId} {
      // 본인 알림만 읽기·읽음 처리
      allow read: if isOwner(resource.data.uid);
      
      // isRead만 변경 가능
      allow update: if isOwner(resource.data.uid)
                       && request.resource.data.diff(resource.data).affectedKeys()
                           .hasOnly(['isRead', 'readAt']);
      
      // 작성·삭제: Cloud Function만
      allow create, delete: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // event_codes (체크인 코드 - 검증만 클라이언트, 발급은 관리자)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /event_codes/{code} {
      // 인증된 사용자가 코드 검증을 위해 읽기 가능
      allow read: if isSignedIn();
      // 발급은 관리자, 사용 처리는 Cloud Function
      allow create: if isAdmin();
      allow update, delete: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // daily_check_ins
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /daily_check_ins/{docId} {
      // 본인 체크인만 읽기 (UI에서 오늘 체크인 여부 확인용)
      allow read: if isSignedIn() && 
                     resource.data.uid == request.auth.uid;
      // 쓰기는 dailyCheckIn Cloud Function만
      allow write: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // app_meta
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /app_meta/{doc} {
      // 인증 사용자 모두 읽기 (홈 통계·정책)
      allow read: if isSignedIn();
      // 쓰기는 Cloud Function 또는 관리자 콘솔
      allow write: if false;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 기타 (기본 차단)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 4. 복합 인덱스 (Composite Indexes)

Firestore는 단일 필드 정렬은 자동, 다중 필드 쿼리는 수동 인덱스 필요.

### 4-1. firestore.indexes.json

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "eventDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isFeatured", "order": "ASCENDING" },
        { "fieldPath": "eventDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isUrgent", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isPinned", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isDeleted", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "authorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "petitions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "currentCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "petitions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "petitions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "deadline", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "petitions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "currentCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "comments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "parentCommentId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "point_logs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "point_logs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "check_ins",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "checkedInAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "check_ins",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "eventId", "order": "ASCENDING" },
        { "fieldPath": "checkedInAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetType", "order": "ASCENDING" },
        { "fieldPath": "targetId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**배포 명령**:
```bash
firebase deploy --only firestore:indexes
```

---

## 5. Cloud Functions 트리거 매핑

각 컬렉션 변경 → 어떤 함수가 트리거되는지:

```
users/{uid}
├── onCreate  → onUserCreated (가입 환영 +50P, referralCode 생성)
└── onUpdate  → onUserUpdate (points 변경 시 level 재계산)

events/{eventId}
└── onCreate  → updateAppStats (홈 통계 갱신)

posts/{postId}
├── onCreate  → onPostCreated (+30P 적립, 작성자 stats.postsCount 증가)
├── onUpdate  → onPostUpdate (콘텐츠 변경 감사 로그)
└── onDelete  → onPostDelete (관련 댓글 일괄 삭제)

posts/{postId}/comments/{commentId}
├── onCreate  → onCommentCreated (+5P, post.commentCount 증가, 알림)
└── onDelete  → onCommentDelete (post.commentCount 감소)

petitions/{petitionId}/signatures/{uid}
└── onCreate  → onPetitionSigned (+50P, petition.currentCount 증가, 마일스톤 알림)

reports/{reportId}
└── onCreate  → onReportCreated (5건 이상 자동 숨김, 관리자 알림)

호출형 (Callable)
├── createCustomTokenFromKakao
├── createCustomTokenFromNaver
├── signPetition
├── eventCheckIn (코드 입력)
├── dailyCheckIn
├── awardPoints (관리자 조정용)
├── banUser (관리자)
├── adjustPoints (관리자)
└── deletePost (관리자, hard delete)

스케줄러
├── updateAppStats        (5분마다)
├── updatePetitionStatus  (1시간마다, deadline 지난 청원 expired)
├── updateEventStatus     (1시간마다, eventDate 지난 행사 completed)
├── cleanupExpiredCodes   (1시간마다, event_codes 만료된 것 삭제)
├── reportCleanupAlert    (24시간마다, 미처리 신고 알림)
└── eventReminderPush     (매일 자정, D-1 행사 푸시 알림)
```

---

## 6. 마이그레이션 스크립트 가이드

기존 메모리 시드 데이터(`action_event_seed.dart`, `community_post_seed.dart`)를 Firestore에 일회성 업로드하는 스크립트.

### 6-1. 위치

```
scripts/
├── migrate_events.dart       시드 → events 컬렉션
├── migrate_posts.dart        시드 → posts 컬렉션
├── seed_app_meta.dart        app_meta/policies 초기 설정
└── README.md                 사용법
```

### 6-2. migrate_events.dart 예시 골격

```dart
// scripts/migrate_events.dart
// 실행: dart run scripts/migrate_events.dart
// 주의: 운영자 권한으로 한 번만 실행

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';
import '../lib/features/action_board/data/action_event_seed.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  for (final event in actionEventSeed) {
    final docRef = firestore.collection('events').doc();
    batch.set(docRef, {
      'id': docRef.id,
      'title': event.title,
      'description': event.description,
      'category': 'rally',  // 적절히 매핑
      'eventDate': Timestamp.fromDate(event.dateTime),
      'location': event.location,
      'maxAttendees': null,
      'currentAttendees': 0,
      'pointsReward': 100,
      'requiresCheckIn': true,
      'imageUrls': [],
      'status': 'upcoming',
      'isFeatured': false,
      'createdBy': 'system',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  await batch.commit();
  print('Migrated ${actionEventSeed.length} events');
}
```

### 6-3. seed_app_meta.dart 예시

```dart
// app_meta/policies 초기 데이터
final policies = {
  'levels': {
    '1': { 'name': '새내기', 'minPoints': 0, 'color': '#8C93A8', 'description': '한미동맹단 가입을 환영합니다' },
    '2': { 'name': '시민', 'minPoints': 100, 'color': '#378ADD', 'description': '활동을 시작한 시민' },
    '3': { 'name': '활동가', 'minPoints': 500, 'color': '#639922', 'description': '꾸준히 활동하는 시민' },
    '4': { 'name': '핵심', 'minPoints': 2000, 'color': '#C9A84C', 'description': '핵심 멤버' },
    '5': { 'name': '동지', 'minPoints': 5000, 'color': '#7F77DD', 'description': '같은 배를 탄 동지' },
  },
  'pointRules': {
    'welcome': { 'amount': 50, 'dailyLimit': null, 'description': '가입 환영' },
    'daily_check_in': { 'amount': 10, 'dailyLimit': 1, 'description': '일일 체크인' },
    'post_create': { 'amount': 30, 'dailyLimit': 3, 'description': '게시글 작성' },
    'comment_create': { 'amount': 5, 'dailyLimit': 10, 'description': '댓글 작성' },
    'like_received': { 'amount': 2, 'dailyLimit': 50, 'description': '좋아요 받음' },
    'share': { 'amount': 20, 'dailyLimit': 5, 'description': '공유하기' },
    'petition_sign': { 'amount': 50, 'dailyLimit': null, 'description': '청원 서명' },
    'event_check_in': { 'amount': 100, 'dailyLimit': null, 'description': '행사 체크인' },
    'referral_complete': { 'amount': 200, 'dailyLimit': null, 'description': '친구 초대' },
  },
  'termsVersion': 'v1.0',
  'privacyVersion': 'v1.0',
  'features': {
    'petitionEnabled': true,
    'eventCheckInEnabled': true,
    'referralEnabled': true,
    'membershipCardEnabled': false,  // Phase 6에 활성화
  },
};
```

---

## 7. 데이터 타입 컨벤션

### 7-1. 시간

```
✅ 모든 시간 필드는 Timestamp 타입
✅ KST(+09:00) 기준이지만 Firestore는 UTC 저장
✅ 클라이언트에서 KST 변환은 .toLocal() 사용 (한국 디바이스 기준)
✅ Cloud Function은 명시적 KST 변환 필요 (TZ='Asia/Seoul')

❌ Date string ("2026-04-27" 등)은 daily_check_ins.date에서만 사용
   (KST 기준 일자 키로 사용)
```

### 7-2. 식별자

```
✅ Firestore 자동 생성 ID (auto-id) 우선 사용
✅ users.uid는 Firebase Auth UID와 동일
✅ daily_check_ins.id = "${uid}_YYYY-MM-DD" (KST 기준)
✅ check_ins.id = "${uid}_${eventId}" (중복 방지)
✅ petitions/{id}/signatures/{uid} 서명 문서ID = uid
```

### 7-3. 카운트·통계

```
✅ 카운트 필드(likeCount 등)는 Cloud Function이 갱신
✅ 클라이언트는 절대 직접 변경 금지
✅ FieldValue.increment(1) 사용 (atomic)
✅ users.stats.* 도 Cloud Function 책임
```

### 7-4. 비정규화 (Denormalization)

성능을 위해 일부 필드는 의도적으로 중복 저장:

```
✅ Post.authorNickname / authorLevel  
   → users 조회 없이 피드 표시 가능
   → 사용자 닉네임 변경 시 onUserUpdate가 최근 N개 글 업데이트

✅ Comment.authorNickname / authorLevel
   → 동일

✅ CheckIn.uidNickname / eventTitle
   → 행사 참여 이력 표시 시 조회 절약

❌ 등급 변경은 빈번하지 않으니 매번 갱신 X
   → 일관성보다 성능 우선
```

### 7-5. Soft Delete

```
✅ posts.isDeleted = true 우선 (감사 추적)
✅ comments.isDeleted = true 우선
❌ Hard delete는 관리자 deletePost Cloud Function만

이유: 신고·법적 분쟁 시 콘텐츠 보존 필요
```

### 7-6. 이미지 URL

```
✅ Firebase Storage 경로:
   posts/{postId}/{filename}
   events/{eventId}/{filename}
   petitions/{petitionId}/{filename}
   users/{uid}/profile.jpg

✅ Firestore 저장: 다운로드 URL (https://firebasestorage.googleapis.com/...)
✅ 클라이언트 업로드 시: Firebase Storage SDK 직접 사용
✅ 권한: Firebase Storage Rules로 별도 관리
```

---

## 8. 테스트 시나리오 체크리스트

Security Rules 배포 전 시뮬레이터에서 검증할 시나리오:

```
✅ 신규 사용자 가입 (users 생성 가능)
✅ 본인 프로필 수정 (닉네임 등)
❌ 본인 points 변경 시도 → 거절
❌ 본인 level 변경 시도 → 거절
❌ 본인 isAdmin: true 시도 → 거절
❌ 다른 사용자 프로필 읽기 → 거절 (관리자 아닌 한)
❌ 다른 사용자 글 작성 (authorId 위조) → 거절

✅ 인증 사용자 events 읽기
❌ 일반 사용자 events 작성 → 거절

✅ 인증 사용자 posts 작성
✅ 본인 글 수정
❌ 본인 글의 likeCount 임의 변경 → 거절
❌ 일반 사용자가 isUrgent: true 작성 → 거절
✅ 관리자가 isUrgent: true 작성 → 허용

❌ 클라이언트가 point_logs 직접 쓰기 → 거절
❌ 클라이언트가 petitions/{id}/signatures 쓰기 → 거절
❌ 차단된 사용자(isBanned)가 글 작성 → 거절

✅ 본인 신고 작성
❌ 다른 사람 신고 위조 (reporterId 변경) → 거절
❌ 신고 status를 resolved로 변경 → 거절 (관리자만)
```

---

## 9. 운영 체크리스트

### 9-1. 일별 모니터링

```
□ Firebase Console > Usage 대시보드
  - read/write 사용량
  - 무료 한도 초과 여부

□ Cloud Functions > Logs
  - 에러 발생 함수 확인
  - 일일 한도 초과 알림

□ Crashlytics
  - 신규 크래시 점검
```

### 9-2. 주별 점검

```
□ point_logs 어뷰징 패턴 분석
  - 동일 IP/기기 다중 계정
  - 짧은 시간 다중 게시글

□ reports 처리 현황
  - 24시간 이상 미처리 건 확인

□ 인덱스 사용량 점검
  - 사용 안 되는 인덱스 제거
```

### 9-3. 월별 점검

```
□ Firestore 비용 분석
  - 무료 한도 → Blaze 플랜 전환 시점

□ 컬렉션 크기 증가 추이
  - notifications: 오래된 알림 정리 (90일 이전 삭제)
  - point_logs: 12개월 이상 압축 또는 BigQuery 이관

□ 등급 분포 분석
  - Lv1 정체 비율
  - 점수 정책 조정 필요 여부
```

---

## 10. 관련 문서

```
CLAUDE.md            전체 프로젝트 가이드 (Section 12 = 본 문서 요약)
NEXT_STEPS.md        Claude Code 작업 큐
OWNER_TODO.md        대표님 직접 처리 항목
```

---

## 변경 이력

| 일자 | 버전 | 변경 내용 |
|------|------|----------|
| 2026.04 | 1.0 | 초안 작성 (Flutter + Firebase 기준) |

---

*Last updated: 2026-04*
*Version: 1.0*
*Maintained by: 대표님 + Claude*