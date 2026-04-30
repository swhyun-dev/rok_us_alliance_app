// lib/features/petition/domain/petition.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 청원 타입.
/// - nationalPetition: 국회 국민동의청원 (외부 서명, robots.txt 차단 → 수동 등록)
/// - legislativeBill: 입법예고 법안 (pal.assembly.go.kr 자동 매칭 가능)
enum PetitionType { nationalPetition, legislativeBill }

/// 입법법안에서 우리 앱이 권장하는 입장.
/// - support: 지지 법안 (찬성 의견 권장)
/// - oppose: 주목 법안 (반대 의견 권장)
/// - neutral: 입장 표기 없음 (국민청원 기본값)
enum PetitionStance { support, oppose, neutral }

/// 청원·법안 도메인 모델 (외부 큐레이션 v2).
/// 자체 서명은 더 이상 사용하지 않음 — currentCount 는 외부 표기용 또는 0.
class Petition {
  const Petition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.deadline,
    required this.status,
    this.type = PetitionType.nationalPetition,
    this.stance = PetitionStance.neutral,
    this.externalUrl = '',
    this.sourceUrl = '',
    this.referenceNumber = '',
    this.progressStatus = '',
    this.progressUpdatedAt,
    this.targetCount = 0,
    this.currentCount = 0,
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

  /// 외부 서명/의견 URL — 카드의 메인 CTA 가 여기로 이동.
  final String externalUrl;

  /// 큐레이터(vforkorea 등) URL. UI 노출 안 해도 됨.
  final String sourceUrl;

  /// 청원번호(국민청원) 또는 의안번호(입법법안). 중복 등록 방지에 사용.
  final String referenceNumber;

  final PetitionType type;
  final PetitionStance stance;

  /// 외부에서 가져온 진행 현황 텍스트 (예: "위원회 심사", "본회의 상정 대기").
  final String progressStatus;
  final DateTime? progressUpdatedAt;

  /// 표시용. 0 이면 카드에서 진행률 바 숨김.
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
  bool get hasProgressBar => targetCount > 0;

  /// 'D-DAY' / 'D-7' / '종료' 등.
  String get ddayLabel {
    final diff = deadline.difference(DateTime.now()).inDays;
    if (status == 'completed' || status == 'expired') return '종료';
    if (diff == 0) return 'D-DAY';
    if (diff < 0) return '종료';
    return 'D-$diff';
  }

  bool get isActive => status == 'active';
  bool get isLegislativeBill => type == PetitionType.legislativeBill;
  bool get isNationalPetition => type == PetitionType.nationalPetition;

  String get stanceLabel {
    switch (stance) {
      case PetitionStance.support:
        return '지지 법안';
      case PetitionStance.oppose:
        return '주목 법안';
      case PetitionStance.neutral:
        return '';
    }
  }

  /// 카드 CTA 라벨.
  String get ctaLabel {
    if (isLegislativeBill) {
      return '국회 입법예고에서 의견 등록';
    }
    return '국회 청원사이트에서 서명';
  }

  Petition copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? imageUrls,
    String? externalUrl,
    String? sourceUrl,
    String? referenceNumber,
    PetitionType? type,
    PetitionStance? stance,
    String? progressStatus,
    DateTime? progressUpdatedAt,
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
      externalUrl: externalUrl ?? this.externalUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      type: type ?? this.type,
      stance: stance ?? this.stance,
      progressStatus: progressStatus ?? this.progressStatus,
      progressUpdatedAt: progressUpdatedAt ?? this.progressUpdatedAt,
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
      'externalUrl': externalUrl,
      'sourceUrl': sourceUrl,
      'referenceNumber': referenceNumber,
      'type': type.name,
      'stance': stance.name,
      'progressStatus': progressStatus,
      'progressUpdatedAt': progressUpdatedAt != null
          ? Timestamp.fromDate(progressUpdatedAt!)
          : null,
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

    final typeName = (map['type'] ?? 'nationalPetition') as String;
    final type = PetitionType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => PetitionType.nationalPetition,
    );
    final stanceName = (map['stance'] ?? 'neutral') as String;
    final stance = PetitionStance.values.firstWhere(
      (e) => e.name == stanceName,
      orElse: () => PetitionStance.neutral,
    );

    return Petition(
      id: doc.id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'other') as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      externalUrl: (map['externalUrl'] ?? '') as String,
      sourceUrl: (map['sourceUrl'] ?? '') as String,
      referenceNumber: (map['referenceNumber'] ?? '') as String,
      type: type,
      stance: stance,
      progressStatus: (map['progressStatus'] ?? '') as String,
      progressUpdatedAt: read(map['progressUpdatedAt']),
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

/// 상위 분류: 국민청원 / 입법법안.
/// 하위 상태 필터(active/completed) 와 별개.
enum PetitionTab { nationalPetition, legislativeBill }

/// 하위 상태 필터.
enum PetitionStatusFilter { active, completed }

/// 구버전 호환용 — Hot petition 등에서 사용.
@Deprecated('Use PetitionTab + PetitionStatusFilter')
enum PetitionFilter { active, popular, newest, completed }
