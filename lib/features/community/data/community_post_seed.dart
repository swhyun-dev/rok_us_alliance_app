// lib/features/community/data/community_post_seed.dart
import '../domain/community_post.dart';

class CommunityPostSeed {
  static final List<CommunityPost> posts = [
    CommunityPost(
      id: 'post-001',
      boardType: CommunityBoardType.free,
      title: '윤통복귀를 바라는 분들 / 결국 행동이 중요하다고 느낍니다',
      content:
      '방송과 기사만 보는 것으로 끝나지 않고, 실제 행동으로 이어져야 분위기가 바뀐다고 생각합니다. 주변에도 한 명씩 더 알리고 같이 움직였으면 좋겠습니다.',
      author: '자유수호',
      region: '전국',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      commentCount: 3,
      likeCount: 31,
      isPinned: true,
      isPopular: true,
      viewCount: 1060,
      saveCount: 1,
      tags: const ['윤통복귀', '행동', '자유'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
      authorBadge: '인증 20회',
      authorDescription: '자유를 지키기 위한 생각과 행동을 함께 나누고 싶습니다.',
      comments: [
        CommunityComment(
          id: 'c-001',
          author: '나라사랑',
          content: '맞습니다. 행동으로 이어져야 진짜 힘이 생깁니다.',
          createdAt: DateTime.now(),
          likeCount: 2,
        ),
      ],
    ),
    CommunityPost(
      id: 'post-002',
      boardType: CommunityBoardType.free,
      title: 'YOON FREE 문구 주변에 공유해보신 분 있나요?',
      content:
      '카톡 단톡방이든 밴드든 한 번쯤은 직접 공유해봐야 분위기가 달라지는 것 같습니다. 저는 생각보다 반응이 괜찮았습니다.',
      author: 'YoonAgain',
      region: '전국',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      commentCount: 5,
      likeCount: 14,
      viewCount: 230,
      tags: const ['YOON FREE', '공유'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80',
    ),
    CommunityPost(
      id: 'post-003',
      boardType: CommunityBoardType.free,
      title: 'CCP OUT 피켓 문구는 짧고 강한 게 좋을까요?',
      content:
      '너무 길면 멀리서 안 보이고, 너무 짧으면 의미가 약한 것 같아서 고민입니다. 혹시 좋은 문구 있으시면 공유 부탁드립니다.',
      author: 'SaveKorea',
      region: '전국',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      commentCount: 4,
      likeCount: 11,
      viewCount: 188,
      tags: const ['CCP OUT', '피켓'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=1200&q=80',
    ),
    CommunityPost(
      id: 'post-004',
      boardType: CommunityBoardType.meetup,
      title: '서울 사전모임 / 광화문 가실 분들 같이 움직여요',
      content:
      '서울 출발하실 분들끼리 사전 집결해서 같이 이동하면 훨씬 수월할 것 같습니다. 초행길인 분들도 같이 합류하시면 좋겠습니다.',
      author: '서울자유',
      region: '서울',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      commentCount: 6,
      likeCount: 18,
      viewCount: 210,
      tags: const ['서울', '광화문', '집결'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=1200&q=80',
    ),
    CommunityPost(
      id: 'post-005',
      boardType: CommunityBoardType.meetup,
      title: '평택 현장 가실 분들 / 준비물 다시 한번 체크해요',
      content:
      '평택 쪽으로 가시는 분들은 반투명 우산, 물, 보조배터리 정도는 꼭 챙기면 좋겠습니다. 처음 가시는 분들은 여유 있게 도착해 주세요.',
      author: 'WEGO',
      region: '경기/평택',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      commentCount: 8,
      likeCount: 22,
      viewCount: 240,
      tags: const ['평택', '준비물'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=80',
    ),
    CommunityPost(
      id: 'post-006',
      boardType: CommunityBoardType.meetup,
      title: '부산 지역모임 / 오프라인 간담회 참여하실 분',
      content:
      '부산/경남권 분들끼리 먼저 연결되면 현장 행동이나 자료 공유도 훨씬 편해질 것 같습니다. 참석 가능하신 분 댓글 부탁드립니다.',
      author: '부산연대',
      region: '부산',
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      commentCount: 2,
      likeCount: 9,
      viewCount: 121,
      tags: const ['부산', '간담회'],
      thumbnailUrl:
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
    ),
    CommunityPost(
      id: 'post-007',
      boardType: CommunityBoardType.resource,
      title: 'YOON FREE 공유용 영상 링크 정리',
      content:
      '지인들에게 바로 전달하기 좋은 영상 링크를 정리했습니다. 설명 문구와 같이 퍼가시면 좋습니다.',
      author: '자유대한',
      region: '온라인',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      commentCount: 3,
      likeCount: 9,
      resourceType: CommunityResourceType.youtube,
      resourceLabel: '추천 영상',
      resourceUrl: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
      viewCount: 510,
      tags: const ['YOON FREE', '유튜브', '공유'],
      authorBadge: '자료공유',
      authorDescription: '영상 자료를 모아서 공유합니다.',
    ),
    CommunityPost(
      id: 'post-008',
      boardType: CommunityBoardType.resource,
      title: '한미동맹단 현장 사진 공유합니다',
      content:
      '현장 분위기 참고하실 수 있게 사진 공유합니다. 추가 사진 있으신 분들은 댓글이나 새 글로 이어서 올려주세요.',
      author: '현장기록',
      region: '온라인',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      commentCount: 4,
      likeCount: 15,
      resourceType: CommunityResourceType.image,
      resourceLabel: '현장 이미지',
      resourceUrl:
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
      viewCount: 330,
      tags: const ['현장', '사진'],
      authorBadge: '현장기록',
      authorDescription: '현장 기록용 사진과 분위기를 공유합니다.',
    ),
    CommunityPost(
      id: 'post-009',
      boardType: CommunityBoardType.resource,
      title: 'CCP OUT 피켓 문구 파일 공유',
      content:
      '집회 현장에서 바로 사용할 수 있는 CCP OUT 피켓 문구 파일입니다. 수정해서 출력하셔도 됩니다.',
      author: '자료모음',
      region: '온라인',
      createdAt: DateTime.now().subtract(const Duration(hours: 11)),
      commentCount: 1,
      likeCount: 12,
      resourceType: CommunityResourceType.file,
      resourceLabel: 'CCP_OUT_피켓문구.pdf',
      resourceUrl: 'https://example.com/ccp-out-file.pdf',
      thumbnailUrl:
      'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=1200&q=80',
      viewCount: 142,
      tags: const ['CCP OUT', '피켓', '파일'],
    ),
    CommunityPost(
      id: 'post-010',
      boardType: CommunityBoardType.resource,
      title: '윤통복귀 관련 참고 사이트 링크',
      content:
      '윤통복귀 관련해서 정리된 참고 사이트 링크입니다. 신규 참여자들에게 설명할 때 참고용으로 쓰기 좋습니다.',
      author: '정리왕',
      region: '온라인',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      commentCount: 2,
      likeCount: 8,
      resourceType: CommunityResourceType.url,
      resourceLabel: '참고 링크 모음',
      resourceUrl: 'https://example.com/yoon-free-links',
      thumbnailUrl:
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=1200&q=80',
      viewCount: 95,
      tags: const ['윤통복귀', '링크', '자료'],
    ),
  ];
}