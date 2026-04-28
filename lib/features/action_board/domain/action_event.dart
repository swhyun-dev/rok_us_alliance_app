// lib/features/action_board/domain/action_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 행사·집회 도메인 모델.
///
/// v3 Firestore events 컬렉션 스키마(FIRESTORE_SCHEMA.md Section 2-3)와
/// 기존 v2 UI 필드(status 라벨·type·slogans·items 등)를 함께 보존하는 하이브리드.
/// UI 코드는 기존 필드(status/type/slogans/items)를 그대로 사용하고,
/// Firestore 쓰기 시 v3 키(eventDate/location/lifecycleStatus 등)를 추가로 출력.
class ActionEvent {
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
    this.category = 'other',
    this.endAt,
    this.locationDetail,
    this.maxAttendees,
    this.currentAttendees = 0,
    this.pointsReward = 100,
    this.requiresCheckIn = true,
    this.imageUrls = const [],
    this.externalUrl,
    this.isFeatured = false,
    this.createdBy = 'system',
    this.createdAt,
    this.updatedAt,
  });

  // ━━━ v2 UI 필드 (기존 화면 호환) ━━━
  final String id;
  final String status; // UI 라벨: 긴급 공지 / 중요 공지 / 정기 일정 / 중요 일정
  final String title;
  final DateTime startAt; // = eventDate
  final String locationName; // = location
  final String locationQuery;
  final List<String> slogans;
  final List<String> items;
  final String description;
  final String type; // 집회 / 모임 / 중요 일정

  // ━━━ v3 스키마 추가 필드 ━━━
  final String category; // rally / meeting / online / cultural / other
  final DateTime? endAt;
  final String? locationDetail;
  final int? maxAttendees;
  final int currentAttendees;
  final int pointsReward;
  final bool requiresCheckIn;
  final List<String> imageUrls;
  final String? externalUrl;
  final bool isFeatured;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// startAt 기준 lifecycle 산출. 스케줄러로 재계산되기 전까지의 클라이언트 추정.
  String get lifecycleStatus {
    final now = DateTime.now();
    if (now.isBefore(startAt)) return 'upcoming';
    final ended = endAt ?? startAt.add(const Duration(hours: 4));
    if (now.isBefore(ended)) return 'ongoing';
    return 'completed';
  }

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
'''
        .trim();
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
    String? category,
    DateTime? endAt,
    String? locationDetail,
    int? maxAttendees,
    int? currentAttendees,
    int? pointsReward,
    bool? requiresCheckIn,
    List<String>? imageUrls,
    String? externalUrl,
    bool? isFeatured,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      category: category ?? this.category,
      endAt: endAt ?? this.endAt,
      locationDetail: locationDetail ?? this.locationDetail,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      pointsReward: pointsReward ?? this.pointsReward,
      requiresCheckIn: requiresCheckIn ?? this.requiresCheckIn,
      imageUrls: imageUrls ?? this.imageUrls,
      externalUrl: externalUrl ?? this.externalUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore set 시 사용하는 직렬화. v3 스키마 필드 + UI 보조 필드를 함께 출력.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      // v3: eventDate / endDate / location / locationDetail
      'eventDate': Timestamp.fromDate(startAt),
      'endDate': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'location': locationName,
      'locationDetail': locationDetail,
      'geoPoint': null,
      'maxAttendees': maxAttendees,
      'currentAttendees': currentAttendees,
      'pointsReward': pointsReward,
      'requiresCheckIn': requiresCheckIn,
      'imageUrls': imageUrls,
      'externalUrl': externalUrl,
      // v3: lifecycle status
      'status': lifecycleStatus,
      'isFeatured': isFeatured,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // v2 UI 보조 필드 (스키마에 없지만 UI 표시용)
      'priorityLabel': status,
      'type': type,
      'locationQuery': locationQuery,
      'slogans': slogans,
      'items': items,
    };
  }

  factory ActionEvent.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};
    return ActionEvent.fromMap(doc.id, map);
  }

  factory ActionEvent.fromMap(String id, Map<String, dynamic> map) {
    final eventDate = _readTimestamp(map['eventDate'] ?? map['startAt']);
    final endDate = _readTimestamp(map['endDate'] ?? map['endAt']);
    final created = _readTimestamp(map['createdAt']);
    final updated = _readTimestamp(map['updatedAt']);

    return ActionEvent(
      id: id,
      status: (map['priorityLabel'] ?? map['status'] ?? '중요 공지') as String,
      title: (map['title'] ?? '') as String,
      startAt: eventDate ?? DateTime.now(),
      locationName: (map['location'] ?? map['locationName'] ?? '') as String,
      locationQuery: (map['locationQuery'] ?? '') as String,
      slogans: List<String>.from(map['slogans'] ?? const []),
      items: List<String>.from(map['items'] ?? const []),
      description: (map['description'] ?? '') as String,
      type: (map['type'] ?? '집회') as String,
      category: (map['category'] ?? 'other') as String,
      endAt: endDate,
      locationDetail: map['locationDetail'] as String?,
      maxAttendees: map['maxAttendees'] as int?,
      currentAttendees: (map['currentAttendees'] ?? 0) as int,
      pointsReward: (map['pointsReward'] ?? 100) as int,
      requiresCheckIn: (map['requiresCheckIn'] ?? true) as bool,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      externalUrl: map['externalUrl'] as String?,
      isFeatured: (map['isFeatured'] ?? false) as bool,
      createdBy: (map['createdBy'] ?? 'system') as String,
      createdAt: created,
      updatedAt: updated,
    );
  }

  static DateTime? _readTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
