// scripts/migrate_events.dart
//
// events 컬렉션에 초기 시드 10건을 일회성 업로드한다.
//
// 실행 (관리자 권한으로 한 번만):
//   flutter run -t scripts/migrate_events.dart -d <device-or-platform>
//
// 두 번 실행하면 중복 데이터가 생긴다. 실행 후 즉시 본 파일을
// _migrated.dart 로 이름을 바꾸거나 .gitignore 처리할 것.
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

import "package:rok_us_alliance_app/firebase_options.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const _MigrationApp());
}

class _MigrationApp extends StatefulWidget {
  const _MigrationApp();

  @override
  State<_MigrationApp> createState() => _MigrationAppState();
}

class _MigrationAppState extends State<_MigrationApp> {
  String _status = "준비됨. 화면을 탭해 시작하세요.";
  bool _running = false;
  bool _done = false;

  Future<void> _run() async {
    if (_running || _done) return;
    setState(() {
      _running = true;
      _status = "업로드 중...";
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final seed in _eventSeed) {
        final ref = firestore.collection("events").doc();
        batch.set(ref, {
          "id": ref.id,
          "title": seed["title"],
          "description": seed["description"],
          "category": seed["category"],
          "eventDate": Timestamp.fromDate(seed["startAt"] as DateTime),
          "endDate": null,
          "location": seed["locationName"],
          "locationDetail": null,
          "geoPoint": null,
          "maxAttendees": null,
          "currentAttendees": 0,
          "pointsReward": 100,
          "requiresCheckIn": true,
          "imageUrls": const <String>[],
          "externalUrl": null,
          "status": _resolveStatus(seed["startAt"] as DateTime),
          "isFeatured": seed["isFeatured"] ?? false,
          "createdBy": "system",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          // UI 보조 필드 (스키마 외)
          "priorityLabel": seed["status"],
          "type": seed["type"],
          "locationQuery": seed["locationQuery"],
          "slogans": seed["slogans"],
          "items": seed["items"],
        });
      }

      await batch.commit();

      setState(() {
        _running = false;
        _done = true;
        _status = "완료. ${_eventSeed.length}건 업로드됨. 본 파일 보존 후 다시 실행하지 말 것.";
      });
    } catch (e) {
      setState(() {
        _running = false;
        _status = "실패: $e";
      });
    }
  }

  static String _resolveStatus(DateTime startAt) {
    return DateTime.now().isBefore(startAt) ? "upcoming" : "completed";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "events seed",
      home: Scaffold(
        appBar: AppBar(title: const Text("events seed migration")),
        body: GestureDetector(
          onTap: _run,
          child: Container(
            color: Colors.white,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (!_done && !_running)
                  const Text(
                    "탭하여 시작",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _eventSeed = [
  {
    "status": "긴급 공지",
    "type": "집회",
    "category": "rally",
    "title": "한미동맹단 광화문 시민 행동의 날",
    "startAt": DateTime(2026, 4, 18, 14, 0),
    "locationName": "서울 광화문 광장",
    "locationQuery": "서울 광화문 광장",
    "slogans": ["한미동맹 강화", "WE GO TOGETHER", "자유민주 회복"],
    "items": ["태극기", "성조기", "반투명 우산", "보조배터리"],
    "description":
        "한미동맹의 가치를 지키고 자유민주 질서 회복을 응원하는 광화문 시민 행동의 날입니다. 현장 질서 유지와 비폭력 원칙을 지켜주시고, 주변에 널리 공유해주세요.",
    "isFeatured": true,
  },
  {
    "status": "중요 공지",
    "type": "집회",
    "category": "rally",
    "title": "평택 미군기지 앞 집결 / 한미동맹 응원 행동",
    "startAt": DateTime(2026, 4, 20, 13, 30),
    "locationName": "평택 캠프 험프리스 인근",
    "locationQuery": "평택 캠프 험프리스",
    "slogans": ["한미동맹 강화", "WE GO TOGETHER", "자유민주 회복"],
    "items": ["흰 우산", "태극기", "성조기", "생수"],
    "description":
        "평택 미군기지 인근 집결 행동입니다. 한미동맹 상징성을 살린 현장 행동으로, 질서와 배려를 최우선으로 해주시기 바랍니다.",
  },
  {
    "status": "정기 일정",
    "type": "모임",
    "category": "meeting",
    "title": "서울 북부 지역 네트워크 모임",
    "startAt": DateTime(2026, 4, 22, 19, 0),
    "locationName": "서울 노원구 지역 모임장",
    "locationQuery": "서울 노원구",
    "slogans": ["자유민주 회복", "시민 연대"],
    "items": ["필기도구", "모임자료"],
    "description": "서울 북부 지역 중심 네트워크 모임입니다. 최근 이슈 브리핑과 향후 오프라인 행동 연결을 논의합니다.",
  },
  {
    "status": "중요 일정",
    "type": "중요 일정",
    "category": "online",
    "title": "한미동맹 가치 온라인 공유의 날",
    "startAt": DateTime(2026, 4, 23, 20, 0),
    "locationName": "온라인 / 전국 동시",
    "locationQuery": "대한민국",
    "slogans": ["한미동맹 강화", "자유민주 회복"],
    "items": ["공유용 이미지", "유튜브 링크", "해시태그 문구"],
    "description":
        "전국 동시 온라인 공유 행동입니다. 한미동맹의 가치와 자유민주 질서의 의미를 SNS·커뮤니티에 함께 알리는 날입니다.",
  },
  {
    "status": "정기 일정",
    "type": "모임",
    "category": "meeting",
    "title": "부산 지역 네트워크 간담회",
    "startAt": DateTime(2026, 4, 25, 18, 30),
    "locationName": "부산 서면 모임 공간",
    "locationQuery": "부산 서면",
    "slogans": ["시민 연대", "WE GO TOGETHER"],
    "items": ["명찰", "모임 공지문"],
    "description": "부산/경남권 지지자 네트워크 확장을 위한 간담회입니다. 신규 참여자 환영, 지역 활동 연결 중심입니다.",
  },
  {
    "status": "긴급 공지",
    "type": "집회",
    "category": "rally",
    "title": "공정한 정치 회복을 위한 서울역 시민 행동",
    "startAt": DateTime(2026, 4, 27, 17, 0),
    "locationName": "서울역 광장",
    "locationQuery": "서울역 광장",
    "slogans": ["자유민주 회복", "공정한 정치", "시민 연대"],
    "items": ["태극기", "피켓", "우비"],
    "description": "자유민주 질서 회복을 응원하는 서울역 시민 행동입니다. 퇴근 시간대 집중 확산을 목표로 합니다.",
    "isFeatured": true,
  },
  {
    "status": "정기 일정",
    "type": "모임",
    "category": "meeting",
    "title": "경기 남부 차량공유/현장동행 사전 모임",
    "startAt": DateTime(2026, 4, 29, 20, 0),
    "locationName": "수원 인계동 모임장",
    "locationQuery": "수원 인계동",
    "slogans": ["WE GO TOGETHER"],
    "items": ["차량 정보", "연락처"],
    "description": "집회 현장 이동을 위한 차량공유/동행 연결 모임입니다. 초행길 참여자들을 돕기 위한 실무 중심 모임입니다.",
  },
  {
    "status": "중요 일정",
    "type": "중요 일정",
    "category": "cultural",
    "title": "한미동맹 강화 전국 동시 피켓 캠페인",
    "startAt": DateTime(2026, 5, 1, 12, 0),
    "locationName": "전국 주요 거점",
    "locationQuery": "대한민국",
    "slogans": ["한미동맹 강화", "자유민주 회복"],
    "items": ["피켓", "인증사진"],
    "description": "전국 주요 거점에서 동시 피켓 인증을 진행하는 캠페인입니다. 인증샷을 커뮤니티에 올려 확산하는 방식입니다.",
  },
  {
    "status": "정기 일정",
    "type": "모임",
    "category": "online",
    "title": "미국 유학생·교포 온라인 연대 모임",
    "startAt": DateTime(2026, 5, 3, 10, 0),
    "locationName": "Zoom 온라인 미팅",
    "locationQuery": "Zoom meeting",
    "slogans": ["한미동맹 강화", "WE GO TOGETHER"],
    "items": ["줌 링크", "브리핑 자료"],
    "description": "미국 내 지지자, 유학생, 교포 네트워크를 연결하는 온라인 미팅입니다. 한미동맹 메시지 확산 전략을 공유합니다.",
  },
  {
    "status": "긴급 공지",
    "type": "집회",
    "category": "rally",
    "title": "여의도 자유민주 시민 대집결",
    "startAt": DateTime(2026, 5, 5, 15, 0),
    "locationName": "여의도공원 인근",
    "locationQuery": "여의도공원",
    "slogans": ["자유민주 회복", "한미동맹 강화", "시민 연대"],
    "items": ["태극기", "성조기", "피켓", "간식"],
    "description": "여의도 중심 대규모 시민 행동입니다. 집결·공유·확산을 동시에 만드는 상징 행사로 기획됐습니다.",
    "isFeatured": true,
  },
];

