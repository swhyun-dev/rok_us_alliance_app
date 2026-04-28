// lib/features/petition/domain/petition.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 청원 도메인 모델 (FIRESTORE_SCHEMA Section 2-6).
class Petition {
  const Petition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.currentCount,
    required this.startDate,
    required this.deadline,
    required this.status,
    this.imageUrls = const [],
    this.completedAt,
    this.isFeatured = false,
    this.createdBy = 'system',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category; // security/economy/education/media/judicial/other
  final List<String> imageUrls;
  final int targetCount;
  final int currentCount;
  final DateTime startDate;
  final DateTime deadline;
  final DateTime? completedAt;
  final String status; // active/completed/expired
  final bool isFeatured;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get progress {
    if (targetCount <= 0) return 0;
    return (currentCount / targetCount).clamp(0, 1).toDouble();
  }

  int get progressPercent => (progress * 100).round();

  /// 'D-DAY' / 'D-7' / '종료' 등.
  String get ddayLabel {
    final diff = deadline.difference(DateTime.now()).inDays;
    if (status == 'completed' || status == 'expired') return '종료';
    if (diff == 0) return 'D-DAY';
    if (diff < 0) return '종료';
    return 'D-$diff';
  }

  bool get isActive => status == 'active';

  Petition copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? imageUrls,
    int? targetCount,
    int? currentCount,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? completedAt,
    String? status,
    bool? isFeatured,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Petition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'startDate': Timestamp.fromDate(startDate),
      'deadline': Timestamp.fromDate(deadline),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
      'isFeatured': isFeatured,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Petition.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};
    DateTime? read(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return null;
    }

    return Petition(
      id: doc.id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'other') as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      targetCount: (map['targetCount'] ?? 0) as int,
      currentCount: (map['currentCount'] ?? 0) as int,
      startDate: read(map['startDate']) ?? DateTime.now(),
      deadline: read(map['deadline']) ??
          DateTime.now().add(const Duration(days: 30)),
      completedAt: read(map['completedAt']),
      status: (map['status'] ?? 'active') as String,
      isFeatured: (map['isFeatured'] ?? false) as bool,
      createdBy: (map['createdBy'] ?? 'system') as String,
      createdAt: read(map['createdAt']),
      updatedAt: read(map['updatedAt']),
    );
  }
}

enum PetitionFilter { active, popular, newest, completed }
