// lib/shared/services/profile_image_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// 프로필 사진 선택·업로드·users.profileImageUrl 갱신을 담당.
class ProfileImageService {
  ProfileImageService._();

  static final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 1장 선택. 사용자 취소 시 null.
  /// maxWidth/imageQuality 로 업로드 전 자동 압축.
  static Future<File?> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// 선택한 이미지를 Firebase Storage 에 업로드하고
  /// download URL 을 반환. users/{uid}.profileImageUrl 도 갱신.
  ///
  /// Throws FirebaseAuthException if not signed in,
  /// FirebaseException if storage write fails.
  static Future<String> uploadAndPersist(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: '로그인 후 이용해주세요.',
      );
    }
    final uid = user.uid;

    final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=86400',
    );

    await ref.putFile(file, metadata);
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImageUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }
}
