// lib/features/action_board/domain/action_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActionEvent {
  final String id;
  final String status;
  final String title;
  final DateTime startAt;
  final String locationName;
  final String locationQuery;
  final List<String> slogans;
  final List<String> items;
  final String description;
  final String type;

  const ActionEvent({
    required this.id,
    required this.status,
    required this.title,
    required this.startAt,
    required this.locationName,
    required this.locationQuery,
    required this.slogans,
    required this.items,
    required this.description,
    required this.type,
  });

  String get monthLabel {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[startAt.month - 1];
  }

  String get dayLabel => startAt.day.toString().padLeft(2, '0');

  String get dateTimeText {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[startAt.weekday - 1];
    final minute = startAt.minute.toString().padLeft(2, '0');
    final period = startAt.hour < 12 ? '오전' : '오후';
    final displayHour = startAt.hour == 0
        ? 12
        : startAt.hour > 12
        ? startAt.hour - 12
        : startAt.hour;

    return '${startAt.year}.${startAt.month.toString().padLeft(2, '0')}.${startAt.day.toString().padLeft(2, '0')} '
        '$weekday / $period $displayHour:$minute';
  }

  bool isSameDay(DateTime date) {
    return startAt.year == date.year &&
        startAt.month == date.month &&
        startAt.day == date.day;
  }

  String buildShareText() {
    return '''
$title
일시: $dateTimeText
위치: $locationName
슬로건: ${slogans.join(' / ')}
준비물: ${items.join(', ')}
안내: $description
'''.trim();
  }

  ActionEvent copyWith({
    String? id,
    String? status,
    String? title,
    DateTime? startAt,
    String? locationName,
    String? locationQuery,
    List<String>? slogans,
    List<String>? items,
    String? description,
    String? type,
  }) {
    return ActionEvent(
      id: id ?? this.id,
      status: status ?? this.status,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      locationName: locationName ?? this.locationName,
      locationQuery: locationQuery ?? this.locationQuery,
      slogans: slogans ?? this.slogans,
      items: items ?? this.items,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'title': title,
      'startAt': Timestamp.fromDate(startAt),
      'locationName': locationName,
      'locationQuery': locationQuery,
      'slogans': slogans,
      'items': items,
      'description': description,
      'type': type,
    };
  }

  factory ActionEvent.fromFirestore(
      String id,
      Map<String, dynamic> map,
      ) {
    final rawStartAt = map['startAt'];

    DateTime parsedStartAt;
    if (rawStartAt is Timestamp) {
      parsedStartAt = rawStartAt.toDate();
    } else if (rawStartAt is DateTime) {
      parsedStartAt = rawStartAt;
    } else {
      parsedStartAt = DateTime.now();
    }

    return ActionEvent(
      id: id,
      status: (map['status'] ?? '중요 공지') as String,
      title: (map['title'] ?? '') as String,
      startAt: parsedStartAt,
      locationName: (map['locationName'] ?? '') as String,
      locationQuery: (map['locationQuery'] ?? '') as String,
      slogans: List<String>.from(map['slogans'] ?? const []),
      items: List<String>.from(map['items'] ?? const []),
      description: (map['description'] ?? '') as String,
      type: (map['type'] ?? '집회') as String,
    );
  }
}