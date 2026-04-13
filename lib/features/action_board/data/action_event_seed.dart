// lib/features/action_board/data/action_event_seed.dart
import '../domain/action_event.dart';

class ActionEventSeed {
  static final List<ActionEvent> events = [
    ActionEvent(
      id: 'pt-20260411',
      status: '중요 공지',
      title: '평택 미군기지 앞 집결 안내',
      startAt: DateTime(2026, 4, 11, 13, 0),
      locationName: '평택 미군기지(캠프 험프리스) K6 사거리',
      locationQuery: '평택 미군기지 캠프 험프리스 K6 사거리',
      slogans: [
        'MAGA WITH ROK',
        'WE GO TOGETHER',
        'SAVE KOREA',
      ],
      items: [
        '반투명 우산(흰우산)',
      ],
      description:
      '어떤 당이든 함께 모여 주세요. 우리에겐 한미동맹이 필요합니다. 질서와 배려를 지키고, 시비와 논쟁은 피해주세요.',
      type: '집회',
    ),
    ActionEvent(
      id: 'weekly-20260418',
      status: '정기 일정',
      title: '주간 행동 공유 모임',
      startAt: DateTime(2026, 4, 18, 15, 0),
      locationName: '온라인 브리핑 / 추후 공지',
      locationQuery: '온라인 브리핑',
      slogans: [
        'WE GO TOGETHER',
      ],
      items: [
        '핵심 공지 확인',
        '공유할 포스터 준비',
      ],
      description: '이번 주 행동 계획과 공유 포인트를 정리하는 온라인 모임입니다.',
      type: '모임',
    ),
    ActionEvent(
      id: 'mission-20260425',
      status: '중요 일정',
      title: '슬로건 / 포스터 공유 주간',
      startAt: DateTime(2026, 4, 25, 9, 0),
      locationName: '앱 내 미션 진행',
      locationQuery: '앱 내 미션 진행',
      slogans: [
        'MAGA WITH ROK',
        'SAVE KOREA',
      ],
      items: [
        '포스터 공유',
        '댓글 참여',
        '지인 초대',
      ],
      description: '앱 내 행동 미션을 중심으로 콘텐츠를 확산하는 주간 일정입니다.',
      type: '중요 일정',
    ),
  ];
}