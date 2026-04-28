// lib/features/petition/data/petition_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/petition.dart';

class PetitionStore {
  PetitionStore._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('petitions');

  /// 필터별 청원 리스트 구독.
  /// 진행중: status=active orderBy deadline asc
  /// 인기: status=active orderBy currentCount desc
  /// 신규: status=active orderBy createdAt desc
  /// 완료: status=completed orderBy completedAt desc (없으면 createdAt)
  static Stream<List<Petition>> watchAll(
    PetitionFilter filter, {
    int limit = 30,
  }) {
    Query<Map<String, dynamic>> q = _col;
    switch (filter) {
      case PetitionFilter.active:
        q = q
            .where('status', isEqualTo: 'active')
            .orderBy('deadline', descending: false);
        break;
      case PetitionFilter.popular:
        q = q
            .where('status', isEqualTo: 'active')
            .orderBy('currentCount', descending: true);
        break;
      case PetitionFilter.newest:
        q = q
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true);
        break;
      case PetitionFilter.completed:
        q = q
            .where('status', isEqualTo: 'completed')
            .orderBy('createdAt', descending: true);
        break;
    }
    return q.limit(limit).snapshots().map(
          (snap) => snap.docs.map(Petition.fromFirestore).toList(),
        );
  }

  /// isFeatured 청원 + currentCount desc (홈 HotPetitionSection 용).
  static Stream<List<Petition>> watchFeatured({int limit = 3}) {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('currentCount', descending: true)
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

  /// 사용자가 해당 청원에 서명했는지 1회 확인.
  static Future<bool> hasSigned({
    required String petitionId,
    required String uid,
  }) async {
    final doc = await _col.doc(petitionId).collection('signatures').doc(uid).get();
    return doc.exists;
  }

  static Stream<int> watchSignatureCount(String petitionId) {
    return _col
        .doc(petitionId)
        .collection('signatures')
        .snapshots()
        .map((snap) => snap.size);
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
