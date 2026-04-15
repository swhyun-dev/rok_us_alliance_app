// lib/features/auth/domain/app_user.dart
class AppUser {
  const AppUser({
    required this.provider,
    required this.providerUserId,
    required this.naverNickname,
    required this.name,
    required this.phoneNumber,
    required this.cafeNickname,
    required this.phoneVerified,
    required this.cafeMatched,
    required this.createdAt,
    required this.updatedAt,
  });

  final String provider;
  final String providerUserId;
  final String naverNickname;
  final String name;
  final String phoneNumber;
  final String cafeNickname;
  final bool phoneVerified;
  final bool cafeMatched;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get normalizedCafeNickname => normalizeNickname(cafeNickname);

  AppUser copyWith({
    String? provider,
    String? providerUserId,
    String? naverNickname,
    String? name,
    String? phoneNumber,
    String? cafeNickname,
    bool? phoneVerified,
    bool? cafeMatched,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      provider: provider ?? this.provider,
      providerUserId: providerUserId ?? this.providerUserId,
      naverNickname: naverNickname ?? this.naverNickname,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cafeNickname: cafeNickname ?? this.cafeNickname,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      cafeMatched: cafeMatched ?? this.cafeMatched,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'providerUserId': providerUserId,
      'naverNickname': naverNickname,
      'name': name,
      'phoneNumber': phoneNumber,
      'cafeNickname': cafeNickname,
      'phoneVerified': phoneVerified,
      'cafeMatched': cafeMatched,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      provider: (map['provider'] ?? 'naver') as String,
      providerUserId: (map['providerUserId'] ?? '') as String,
      naverNickname: (map['naverNickname'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? '') as String,
      cafeNickname: (map['cafeNickname'] ?? '') as String,
      phoneVerified: (map['phoneVerified'] ?? false) as bool,
      cafeMatched: (map['cafeMatched'] ?? false) as bool,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '') as String) ??
          DateTime.now(),
    );
  }

  static String normalizeNickname(String value) {
    return value.trim().replaceAll(' ', '').toLowerCase();
  }
}