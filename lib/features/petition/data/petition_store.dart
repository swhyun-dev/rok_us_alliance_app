// lib/features/petition/data/petition_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/petition.dart';

class PetitionStore {
  PetitionStore._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('petitions');

  /// 상위 [tab] (국민청원/입법법안) + 하위 [status] (진행중/완료) 필터.
  /// active 는 deadline asc, completed 는 completedAt desc.
  static Stream<List<Petition>> watchByTab({
    required PetitionTab tab,
    required PetitionStatusFilter status,
    int limit = 30,
  }) {
    final typeName = tab == PetitionTab.legislativeBill
        ? PetitionType.legislativeBill.name
        : PetitionType.nationalPetition.name;

    Query<Map<String, dynamic>> q =
        _col.where('type', isEqualTo: typeName);

    switch (status) {
      case PetitionStatusFilter.active:
        q = q
            .where('status', isEqualTo: 'active')
            .orderBy('deadline', descending: false);
        break;
      case PetitionStatusFilter.completed:
        q = q
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true);
        break;
    }
    return q.limit(limit).snapshots().map(
          (snap) => snap.docs.map(Petition.fromFirestore).toList(),
        );
  }

  /// 탭바 옆 카운트 표시용. type+status 일치하는 doc 갯수만 반환.
  /// 첫 페이지 30 건만 화면에 그리지만 카운트는 전체를 보여주기 위해 별도 쿼리.
  static Stream<int> watchCount({
    required PetitionTab tab,
    required PetitionStatusFilter status,
  }) {
    final typeName = tab == PetitionTab.legislativeBill
        ? PetitionType.legislativeBill.name
        : PetitionType.nationalPetition.name;

    final statusValue = status == PetitionStatusFilter.active
        ? 'active'
        : 'completed';

    return _col
        .where('type', isEqualTo: typeName)
        .where('status', isEqualTo: statusValue)
        .snapshots()
        .map((snap) => snap.size);
  }

  /// 홈 HotPetitionSection — 진행중 전체에서 isFeatured 우선·신규순 limit.
  static Stream<List<Petition>> watchFeatured({int limit = 3}) {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('isFeatured', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Petition.fromFirestore).toList());
  }

  static Stream<Petition?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Petition.fromFirestore(doc);
    });
  }

  /// referenceNumber 가 이미 등록되어 있는지 검사 (중복 방지).
  /// type 별로 분리해서 검사 — 청원번호와 의안번호는 네임스페이스가 다를 수 있음.
  static Future<bool> isReferenceTaken({
    required PetitionType type,
    required String referenceNumber,
  }) async {
    final ref = referenceNumber.trim();
    if (ref.isEmpty) return false;
    final snap = await _col
        .where('type', isEqualTo: type.name)
        .where('referenceNumber', isEqualTo: ref)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// 관리자만 (rules에서 isAdmin 검증).
  static Future<String> add(Petition petition) async {
    final ref = _col.doc();
    final draft = petition.copyWith(id: ref.id);
    await ref.set(draft.toMap());
    return ref.id;
  }

  static Future<void> update(String id, Map<String, dynamic> changes) async {
    await _col.doc(id).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
