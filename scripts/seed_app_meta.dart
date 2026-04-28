// scripts/seed_app_meta.dart
//
// app_meta/policies (등급·점수 정책 + 약관 버전 + 기능 토글) 와
// app_meta/stats (홈 통계 초기 0) 두 단일 문서를 일회성으로 생성한다.
//
// 실행:
//   flutter run -t scripts/seed_app_meta.dart -d <device-or-platform>
//
// 두 번 실행해도 set 이라 같은 값으로 덮어써짐. 그러나 stats는 이후
// updateAppStats Cloud Function (W4.2) 이 5분마다 갱신하므로 본 스크립트
// 재실행은 stats 카운터를 0으로 되돌릴 수 있음. 주의.
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

import "package:rok_us_alliance_app/firebase_options.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const _SeedApp());
}

class _SeedApp extends StatefulWidget {
  const _SeedApp();

  @override
  State<_SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<_SeedApp> {
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

      await firestore.doc("app_meta/policies").set(_policies);

      await firestore.doc("app_meta/stats").set({
        "memberCount": 0,
        "activePetitions": 0,
        "monthlyEvents": 0,
        "totalPosts": 0,
        "totalComments": 0,
        "totalSignatures": 0,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        _running = false;
        _done = true;
        _status = "완료. policies / stats 작성됨.";
      });
    } catch (e) {
      setState(() {
        _running = false;
        _status = "실패: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "app_meta seed",
      home: Scaffold(
        appBar: AppBar(title: const Text("app_meta seed")),
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

const Map<String, dynamic> _policies = {
  "levels": {
    "1": {
      "name": "새내기",
      "minPoints": 0,
      "color": "#8C93A8",
      "description": "한미동맹단 가입을 환영합니다",
    },
    "2": {
      "name": "시민",
      "minPoints": 100,
      "color": "#378ADD",
      "description": "활동을 시작한 시민",
    },
    "3": {
      "name": "활동가",
      "minPoints": 500,
      "color": "#639922",
      "description": "꾸준히 활동하는 시민",
    },
    "4": {
      "name": "핵심",
      "minPoints": 2000,
      "color": "#C9A84C",
      "description": "핵심 멤버",
    },
    "5": {
      "name": "동지",
      "minPoints": 5000,
      "color": "#7F77DD",
      "description": "같은 배를 탄 동지",
    },
  },
  "pointRules": {
    "welcome": {
      "amount": 50,
      "dailyLimit": null,
      "description": "가입 환영",
    },
    "daily_check_in": {
      "amount": 10,
      "dailyLimit": 1,
      "description": "일일 체크인",
    },
    "post_create": {
      "amount": 30,
      "dailyLimit": 3,
      "description": "게시글 작성",
    },
    "comment_create": {
      "amount": 5,
      "dailyLimit": 10,
      "description": "댓글 작성",
    },
    "like_received": {
      "amount": 2,
      "dailyLimit": 50,
      "description": "좋아요 받음",
    },
    "share": {
      "amount": 20,
      "dailyLimit": 5,
      "description": "공유하기",
    },
    "petition_sign": {
      "amount": 50,
      "dailyLimit": null,
      "description": "청원 서명",
    },
    "event_check_in": {
      "amount": 100,
      "dailyLimit": null,
      "description": "행사 체크인",
    },
    "referral_complete": {
      "amount": 200,
      "dailyLimit": null,
      "description": "친구 초대",
    },
  },
  "termsVersion": "v1.0",
  "privacyVersion": "v1.0",
  "features": {
    "petitionEnabled": true,
    "eventCheckInEnabled": true,
    "referralEnabled": true,
    "membershipCardEnabled": false,
  },
};
