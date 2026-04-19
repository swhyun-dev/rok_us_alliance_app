// lib/features/membership/domain/member.dart

enum MemberGrade { general, regular, gold, vip, honorary }

extension MemberGradeExt on MemberGrade {
  String get label {
    switch (this) {
      case MemberGrade.general:
        return '일반회원';
      case MemberGrade.regular:
        return '정회원';
      case MemberGrade.gold:
        return 'Gold';
      case MemberGrade.vip:
        return 'VIP';
      case MemberGrade.honorary:
        return '명예회원';
    }
  }

  String get code {
    switch (this) {
      case MemberGrade.general:
        return 'general';
      case MemberGrade.regular:
        return 'regular';
      case MemberGrade.gold:
        return 'gold';
      case MemberGrade.vip:
        return 'vip';
      case MemberGrade.honorary:
        return 'honorary';
    }
  }

  bool get canIssueCard => this != MemberGrade.general;

  static MemberGrade fromCode(String code) {
    switch (code) {
      case 'regular':
        return MemberGrade.regular;
      case 'gold':
        return MemberGrade.gold;
      case 'vip':
        return MemberGrade.vip;
      case 'honorary':
        return MemberGrade.honorary;
      default:
        return MemberGrade.general;
    }
  }

  static MemberGrade fromPoints(int points) {
    if (points >= 5000) return MemberGrade.vip;
    if (points >= 2000) return MemberGrade.gold;
    return MemberGrade.regular;
  }
}

class Member {
  const Member({
    required this.uid,
    required this.name,
    required this.memberNumber,
    required this.branch,
    required this.grade,
    required this.points,
    required this.isVerified,
    required this.joinedAt,
  });

  final String uid;
  final String name;
  final String memberNumber; // ROK-YYYY-NNNNN
  final String branch;
  final MemberGrade grade;
  final int points;
  final bool isVerified;
  final DateTime joinedAt;

  String get joinedDateLabel =>
      '${joinedAt.year}.${joinedAt.month.toString().padLeft(2, '0')}.${joinedAt.day.toString().padLeft(2, '0')}';

  int get pointsToNextGrade {
    if (grade == MemberGrade.regular) return 2000 - points;
    if (grade == MemberGrade.gold) return 5000 - points;
    return 0;
  }

  Member copyWith({
    String? name,
    String? branch,
    MemberGrade? grade,
    int? points,
    bool? isVerified,
  }) {
    return Member(
      uid: uid,
      name: name ?? this.name,
      memberNumber: memberNumber,
      branch: branch ?? this.branch,
      grade: grade ?? this.grade,
      points: points ?? this.points,
      isVerified: isVerified ?? this.isVerified,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'memberNumber': memberNumber,
        'branch': branch,
        'grade': grade.code,
        'points': points,
        'isVerified': isVerified,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
        uid: (map['uid'] ?? '') as String,
        name: (map['name'] ?? '') as String,
        memberNumber: (map['memberNumber'] ?? '') as String,
        branch: (map['branch'] ?? '') as String,
        grade: MemberGradeExt.fromCode((map['grade'] ?? 'general') as String),
        points: (map['points'] ?? 0) as int,
        isVerified: (map['isVerified'] ?? false) as bool,
        joinedAt: DateTime.tryParse((map['joinedAt'] ?? '') as String) ??
            DateTime.now(),
      );

  // 개발용 목업 데이터
  factory Member.mock() => Member(
        uid: 'debug_user',
        name: '홍길동',
        memberNumber: 'ROK-2026-00001',
        branch: '서울',
        grade: MemberGrade.regular,
        points: 1240,
        isVerified: true,
        joinedAt: DateTime(2026, 1, 15),
      );
}
