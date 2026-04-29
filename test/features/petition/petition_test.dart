import 'package:flutter_test/flutter_test.dart';
import 'package:rok_us_alliance_app/features/petition/domain/petition.dart';

Petition _make({
  int targetCount = 100,
  int currentCount = 0,
  DateTime? deadline,
  String status = 'active',
}) {
  return Petition(
    id: 'p-1',
    title: '테스트 청원',
    description: '내용',
    category: 'security',
    targetCount: targetCount,
    currentCount: currentCount,
    startDate: DateTime(2026, 1, 1),
    deadline: deadline ?? DateTime(2026, 12, 31),
    status: status,
  );
}

void main() {
  group('Petition.progress', () {
    test('0/100 = 0%', () {
      expect(_make().progressPercent, 0);
    });

    test('25/100 = 25%', () {
      expect(_make(currentCount: 25).progressPercent, 25);
    });

    test('150/100 은 100% 로 클램프', () {
      expect(_make(currentCount: 150).progressPercent, 100);
    });

    test('targetCount=0 이어도 NaN 없이 0 반환', () {
      expect(_make(targetCount: 0).progressPercent, 0);
    });
  });

  group('Petition.ddayLabel', () {
    test('미래 7일+버퍼 이면 D-7', () {
      // Duration.inDays 가 정수 절단이라 두 번째 DateTime.now() 호출
      // 사이의 흐른 시간이 inDays 를 6 으로 떨어뜨릴 수 있어 1시간 버퍼.
      final petition = _make(
        deadline: DateTime.now().add(const Duration(days: 7, hours: 1)),
      );
      expect(petition.ddayLabel, 'D-7');
    });

    test('당일이면 D-DAY', () {
      final now = DateTime.now();
      final petition = _make(
        deadline: DateTime(now.year, now.month, now.day, 23, 59),
      );
      expect(petition.ddayLabel, 'D-DAY');
    });

    test('마감 지난 경우 종료', () {
      final petition = _make(
        deadline: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(petition.ddayLabel, '종료');
    });

    test('status=completed 면 deadline 과 무관하게 종료 라벨', () {
      final petition = _make(
        status: 'completed',
        deadline: DateTime.now().add(const Duration(days: 100)),
      );
      expect(petition.ddayLabel, '종료');
    });
  });

  group('Petition.isActive', () {
    test('status=active 면 true', () {
      expect(_make().isActive, isTrue);
    });

    test('completed 면 false', () {
      expect(_make(status: 'completed').isActive, isFalse);
    });

    test('expired 면 false', () {
      expect(_make(status: 'expired').isActive, isFalse);
    });
  });
}
