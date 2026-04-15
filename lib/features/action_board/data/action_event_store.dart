// lib/features/action_board/data/action_event_store.dart
import 'package:flutter/foundation.dart';

import '../domain/action_event.dart';

class ActionEventStore {
  ActionEventStore._();

  static final ValueNotifier<List<ActionEvent>> notifier =
  ValueNotifier<List<ActionEvent>>([
    ActionEvent(
      id: 'evt-001',
      status: '긴급 공지',
      type: '집회',
      title: '한미동맹단 광화문 자유집회 / YOON FREE / CCP OUT',
      startAt: DateTime(2026, 4, 18, 14, 0),
      locationName: '서울 광화문 광장',
      locationQuery: '서울 광화문 광장',
      slogans: const [
        'YOON FREE',
        'CCP OUT',
        'WE GO TOGETHER',
        'SAVE KOREA',
      ],
      items: const [
        '태극기',
        '성조기',
        '반투명 우산',
        '보조배터리',
      ],
      description:
      '한미동맹의 가치를 지키고 자유대한민국 회복을 위한 광화문 집회입니다. 현장 질서 유지와 비폭력 원칙을 지켜주시고, 주변에 널리 공유해주세요.',
    ),
    ActionEvent(
      id: 'evt-002',
      status: '중요 공지',
      type: '집회',
      title: '평택 미군기지 앞 집결 / 한미동맹단 결집 행동',
      startAt: DateTime(2026, 4, 20, 13, 30),
      locationName: '평택 캠프 험프리스 인근',
      locationQuery: '평택 캠프 험프리스',
      slogans: const [
        'MAGA WITH ROK',
        'WE GO TOGETHER',
        'SAVE KOREA',
      ],
      items: const [
        '흰 우산',
        '태극기',
        '성조기',
        '생수',
      ],
      description:
      '평택 미군기지 인근 집결 행동입니다. 한미동맹 상징성을 살린 현장 행동으로, 질서와 배려를 최우선으로 해주시기 바랍니다.',
    ),
    ActionEvent(
      id: 'evt-003',
      status: '정기 일정',
      type: '모임',
      title: '서울 북부 지역모임 / 윤통복귀 전략 브리핑',
      startAt: DateTime(2026, 4, 22, 19, 0),
      locationName: '서울 노원구 지역 모임장',
      locationQuery: '서울 노원구',
      slogans: const [
        '윤통복귀',
        '자유대한민국',
      ],
      items: const [
        '필기도구',
        '모임자료',
      ],
      description:
      '서울 북부 지역 중심 네트워크 모임입니다. 최근 이슈 브리핑과 향후 오프라인 행동 연결을 논의합니다.',
    ),
    ActionEvent(
      id: 'evt-004',
      status: '중요 일정',
      type: '중요 일정',
      title: 'YOON FREE 온라인 집중 공유의 날',
      startAt: DateTime(2026, 4, 23, 20, 0),
      locationName: '온라인 / 전국 동시',
      locationQuery: '대한민국',
      slogans: const [
        'YOON FREE',
        'FREE KOREA',
      ],
      items: const [
        '공유용 이미지',
        '유튜브 링크',
        '해시태그 문구',
      ],
      description:
      '전국 동시 온라인 공유 행동입니다. 유튜브, 카페, 커뮤니티, SNS 등에 지정 문구와 이미지를 확산시키는 날입니다.',
    ),
    ActionEvent(
      id: 'evt-005',
      status: '정기 일정',
      type: '모임',
      title: '부산 지역모임 / 한미동맹단 오프라인 간담회',
      startAt: DateTime(2026, 4, 25, 18, 30),
      locationName: '부산 서면 모임 공간',
      locationQuery: '부산 서면',
      slogans: const [
        'SAVE KOREA',
        'WE GO TOGETHER',
      ],
      items: const [
        '명찰',
        '모임 공지문',
      ],
      description:
      '부산/경남권 지지자 네트워크 확장을 위한 간담회입니다. 신규 참여자 환영, 지역 활동 연결 중심입니다.',
    ),
    ActionEvent(
      id: 'evt-006',
      status: '긴급 공지',
      type: '집회',
      title: '윤통복귀 촉구 서울역 집중 집회',
      startAt: DateTime(2026, 4, 27, 17, 0),
      locationName: '서울역 광장',
      locationQuery: '서울역 광장',
      slogans: const [
        '윤통복귀',
        'YOON FREE',
        'SAVE KOREA',
      ],
      items: const [
        '태극기',
        '피켓',
        '우비',
      ],
      description:
      '윤통복귀와 자유민주 질서 회복을 촉구하는 서울역 집중 집회입니다. 퇴근 시간대 집중 확산을 목표로 합니다.',
    ),
    ActionEvent(
      id: 'evt-007',
      status: '정기 일정',
      type: '모임',
      title: '경기 남부 차량공유/현장동행 사전 모임',
      startAt: DateTime(2026, 4, 29, 20, 0),
      locationName: '수원 인계동 모임장',
      locationQuery: '수원 인계동',
      slogans: const [
        'WE GO TOGETHER',
      ],
      items: const [
        '차량 정보',
        '연락처',
      ],
      description:
      '집회 현장 이동을 위한 차량공유/동행 연결 모임입니다. 초행길 참여자들을 돕기 위한 실무 중심 모임입니다.',
    ),
    ActionEvent(
      id: 'evt-008',
      status: '중요 일정',
      type: '중요 일정',
      title: 'CCP OUT 전국 동시 피켓 인증 캠페인',
      startAt: DateTime(2026, 5, 1, 12, 0),
      locationName: '전국 주요 거점',
      locationQuery: '대한민국',
      slogans: const [
        'CCP OUT',
        'SAVE KOREA',
      ],
      items: const [
        '피켓',
        '인증사진',
      ],
      description:
      '전국 주요 거점에서 동시 피켓 인증을 진행하는 캠페인입니다. 인증샷을 커뮤니티에 올려 확산하는 방식입니다.',
    ),
    ActionEvent(
      id: 'evt-009',
      status: '정기 일정',
      type: '모임',
      title: '미국 유학생/교포 온라인 연대 모임',
      startAt: DateTime(2026, 5, 3, 10, 0),
      locationName: 'Zoom 온라인 미팅',
      locationQuery: 'Zoom meeting',
      slogans: const [
        'MAGA WITH ROK',
        'WE GO TOGETHER',
      ],
      items: const [
        '줌 링크',
        '브리핑 자료',
      ],
      description:
      '미국 내 지지자, 유학생, 교포 네트워크를 연결하는 온라인 미팅입니다. 한미동맹 메시지 확산 전략을 공유합니다.',
    ),
    ActionEvent(
      id: 'evt-010',
      status: '긴급 공지',
      type: '집회',
      title: '여의도 자유행동 / SAVE KOREA 대집결',
      startAt: DateTime(2026, 5, 5, 15, 0),
      locationName: '여의도공원 인근',
      locationQuery: '여의도공원',
      slogans: const [
        'SAVE KOREA',
        'YOON FREE',
        'CCP OUT',
      ],
      items: const [
        '태극기',
        '성조기',
        '피켓',
        '간식',
      ],
      description:
      '여의도 중심 대규모 자유행동 집회입니다. 집결/공유/확산을 동시에 만드는 상징 집회로 기획된 일정입니다.',
    ),
  ]);

  static List<ActionEvent> get events => notifier.value;

  static void startListening() {}

  static Future<void> add(ActionEvent event) async {
    notifier.value = [event, ...notifier.value]..sort(
          (a, b) => a.startAt.compareTo(b.startAt),
    );
  }

  static Future<void> update(ActionEvent event) async {
    notifier.value = notifier.value
        .map((e) => e.id == event.id ? event : e)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  static Future<void> remove(String id) async {
    notifier.value = notifier.value.where((e) => e.id != id).toList();
  }

  static ActionEvent? findById(String id) {
    try {
      return notifier.value.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}