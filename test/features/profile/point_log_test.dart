import 'package:flutter_test/flutter_test.dart';
import 'package:rok_us_alliance_app/features/profile/domain/point_log.dart';

PointLog _make({
  int amount = 30,
  DateTime? createdAt,
}) {
  return PointLog(
    id: 'l-1',
    uid: 'u-1',
    type: 'post_create',
    amount: amount,
    description: '+30P 게시글 작성',
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  group('PointLog.amountLabel', () {
    test('양수는 + 접두사', () {
      expect(_make(amount: 30).amountLabel, '+30P');
    });

    test('음수는 - 접두사 (파싱 그대로)', () {
      expect(_make(amount: -10).amountLabel, '-10P');
    });

    test('0 도 표기', () {
      expect(_make(amount: 0).amountLabel, '0P');
    });
  });

  group('PointLog.isPositive', () {
    test('+30 → true', () {
      expect(_make(amount: 30).isPositive, isTrue);
    });

    test('-10 → false', () {
      expect(_make(amount: -10).isPositive, isFalse);
    });

    test('0 → false (양수 아님)', () {
      expect(_make(amount: 0).isPositive, isFalse);
    });
  });

  group('PointLog.timeLabel', () {
    test('30초 전이면 "방금 전"', () {
      final log = _make(
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(log.timeLabel, '방금 전');
    });

    test('5분 전이면 "5분 전"', () {
      final log = _make(
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(log.timeLabel, '5분 전');
    });

    test('3시간 전이면 "3시간 전"', () {
      final log = _make(
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(log.timeLabel, '3시간 전');
    });

    test('2일 전이면 "2일 전"', () {
      final log = _make(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(log.timeLabel, '2일 전');
    });

    test('30일 전이면 절대 날짜', () {
      final log = _make(
        createdAt: DateTime(2024, 5, 15),
      );
      expect(log.timeLabel, '2024.05.15');
    });
  });
}
