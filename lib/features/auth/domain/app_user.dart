// lib/features/auth/domain/app_user.dart
class AppUser {
  const AppUser({
    required this.provider,
    required this.providerUserId,
    required this.nickname,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.profileImageUrl,
    this.level = 1,
    this.points = 0,
    this.consentedTerms = false,
    this.consentedPrivacy = false,
    this.consentedAt,
    this.lastSignedInAt,
    this.isAdmin = false,
    this.isBanned = false,
  });

  final String provider;
  final String providerUserId;
  final String nickname;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? email;
  final String? profileImageUrl;
  final int level;
  final int points;
  final bool consentedTerms;
  final bool consentedPrivacy;
  final DateTime? consentedAt;
  final DateTime? lastSignedInAt;
  final bool isAdmin;
  final bool isBanned;

  AppUser copyWith({
    String? provider,
    String? providerUserId,
    String? nickname,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? profileImageUrl,
    int? level,
    int? points,
    bool? consentedTerms,
    bool? consentedPrivacy,
    DateTime? consentedAt,
    DateTime? lastSignedInAt,
    bool? isAdmin,
    bool? isBanned,
  }) {
    return AppUser(
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      nickname: nickname ?? this.nickname,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      level: level ?? this.level,
      points: points ?? this.points,
      consentedTerms: consentedTerms ?? this.consentedTerms,
      consentedPrivacy: consentedPrivacy ?? this.consentedPrivacy,
      consentedAt: consentedAt ?? this.consentedAt,
      lastSignedInAt: lastSignedInAt ?? this.lastSignedInAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'providerUserId': providerUserId,
      'nickname': nickname,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'email': email,
      'profileImageUrl': profileImageUrl,
      'level': level,
      'points': points,
      'consentedTerms': consentedTerms,
      'consentedPrivacy': consentedPrivacy,
      'consentedAt': consentedAt?.toIso8601String(),
      'lastSignedInAt': lastSignedInAt?.toIso8601String(),
      'isAdmin': isAdmin,
      'isBanned': isBanned,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    // 'naverNickname' 은 v2 잔재 키. 기존 캐시 호환을 위해 fallback 으로만 둔다.
    final legacyNickname = map['naverNickname'];
    return AppUser(
      provider: (map['provider'] ?? 'naver') as String,
      providerUserId: (map['providerUserId'] ?? '') as String,
      nickname: (map['nickname'] ?? legacyNickname ?? '') as String,
      name: (map['name'] ?? '') as String,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '') as String) ??
          DateTime.now(),
      email: map['email'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      level: (map['level'] ?? 1) as int,
      points: (map['points'] ?? 0) as int,
      consentedTerms: (map['consentedTerms'] ?? false) as bool,
      consentedPrivacy: (map['consentedPrivacy'] ?? false) as bool,
      consentedAt: DateTime.tryParse((map['consentedAt'] ?? '') as String),
      lastSignedInAt:
          DateTime.tryParse((map['lastSignedInAt'] ?? '') as String),
      isAdmin: (map['isAdmin'] ?? false) as bool,
      isBanned: (map['isBanned'] ?? false) as bool,
    );
  }
}
