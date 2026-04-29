import 'package:flutter_test/flutter_test.dart';
import 'package:rok_us_alliance_app/features/auth/domain/app_user.dart';

void main() {
  group('AppUser', () {
    test('toMap → fromMap 라운드트립으로 모든 필드를 보존', () {
      final now = DateTime(2026, 4, 30, 12, 0);
      final original = AppUser(
        provider: 'naver',
        providerUserId: 'naver-123',
        nickname: '테스트유저',
        name: '홍길동',
        email: 'hong@example.com',
        profileImageUrl: 'https://img/me.png',
        createdAt: now,
        updatedAt: now,
        consentedAt: now,
        lastSignedInAt: now,
        level: 3,
        points: 670,
        consentedTerms: true,
        consentedPrivacy: true,
        isAdmin: true,
        isBanned: false,
      );

      final restored = AppUser.fromMap(original.toMap());

      expect(restored.provider, 'naver');
      expect(restored.providerUserId, 'naver-123');
      expect(restored.nickname, '테스트유저');
      expect(restored.name, '홍길동');
      expect(restored.email, 'hong@example.com');
      expect(restored.profileImageUrl, 'https://img/me.png');
      expect(restored.level, 3);
      expect(restored.points, 670);
      expect(restored.consentedTerms, isTrue);
      expect(restored.consentedPrivacy, isTrue);
      expect(restored.isAdmin, isTrue);
      expect(restored.isBanned, isFalse);
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
      expect(restored.consentedAt, now);
      expect(restored.lastSignedInAt, now);
    });

    test("naverNickname 레거시 키도 nickname 으로 읽힌다", () {
      final map = {
        'provider': 'naver',
        'providerUserId': 'old-1',
        'naverNickname': '구버전유저',
        'name': '홍길동',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final user = AppUser.fromMap(map);

      expect(user.nickname, '구버전유저');
    });

    test('새 nickname 키가 우선', () {
      final map = {
        'provider': 'naver',
        'providerUserId': 'new-1',
        'nickname': '신버전유저',
        'naverNickname': '구버전유저',
        'name': '홍길동',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final user = AppUser.fromMap(map);

      expect(user.nickname, '신버전유저');
    });

    test('빈 map 으로 fromMap 호출 시 안전한 기본값', () {
      final user = AppUser.fromMap(<String, dynamic>{});

      expect(user.provider, 'naver');
      expect(user.providerUserId, '');
      expect(user.nickname, '');
      expect(user.name, '');
      expect(user.level, 1);
      expect(user.points, 0);
      expect(user.consentedTerms, isFalse);
      expect(user.isAdmin, isFalse);
    });

    test('copyWith 는 지정 필드만 변경', () {
      final original = AppUser(
        provider: 'kakao',
        providerUserId: 'k-1',
        nickname: 'before',
        name: '이름',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        level: 1,
        points: 50,
      );

      final updated = original.copyWith(level: 2, points: 150);

      expect(updated.level, 2);
      expect(updated.points, 150);
      expect(updated.nickname, 'before');
      expect(updated.provider, 'kakao');
    });
  });
}
