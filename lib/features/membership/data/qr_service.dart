// lib/features/membership/data/qr_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/member.dart';

const _qrSecret = 'rok_us_alliance_qr_secret_2026';
const _ttlSeconds = 300; // 5분
const _cacheKey = 'qr_token_cache_v1';
const _cacheExpireKey = 'qr_token_expire_v1';
const _cacheTtlSeconds = 86400; // 24h 오프라인 캐시

class QrPayload {
  const QrPayload({
    required this.memberId,
    required this.grade,
    required this.iat,
    required this.exp,
  });

  final String memberId;
  final String grade;
  final int iat;
  final int exp;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'grade': grade,
        'iat': iat,
        'exp': exp,
      };

  factory QrPayload.fromMap(Map<String, dynamic> map) => QrPayload(
        memberId: map['memberId'] as String,
        grade: map['grade'] as String,
        iat: map['iat'] as int,
        exp: map['exp'] as int,
      );
}

class QrService {
  QrService._();

  // 오프라인 캐시에서 유효한 토큰 반환 (없으면 null)
  static Future<String?> cachedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_cacheKey);
      final expireAt = prefs.getInt(_cacheExpireKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (token != null && now < expireAt) return token;
    } catch (_) {}
    return null;
  }

  // 토큰을 24h 캐시에 저장
  static Future<void> _cacheToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expireAt =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + _cacheTtlSeconds;
      await prefs.setString(_cacheKey, token);
      await prefs.setInt(_cacheExpireKey, expireAt);
    } catch (_) {}
  }

  // QR 토큰 생성: base64(payload).hmac
  static String generate(Member member) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = QrPayload(
      memberId: member.uid,
      grade: member.grade.code,
      iat: now,
      exp: now + _ttlSeconds,
    );

    final payloadJson = jsonEncode(payload.toMap());
    final payloadB64 = base64Url.encode(utf8.encode(payloadJson));
    final sig = _sign(payloadB64);
    final token = '$payloadB64.$sig';

    _cacheToken(token);
    return token;
  }

  // QR 토큰 검증 및 파싱
  static QrPayload? verify(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;

      final payloadB64 = parts[0];
      final sig = parts[1];

      if (_sign(payloadB64) != sig) return null;

      final payloadJson = utf8.decode(base64Url.decode(payloadB64));
      final map = jsonDecode(payloadJson) as Map<String, dynamic>;
      final payload = QrPayload.fromMap(map);

      if (payload.isExpired) return null;
      return payload;
    } catch (_) {
      return null;
    }
  }

  static String _sign(String data) {
    final key = utf8.encode(_qrSecret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  // 남은 유효 시간(초) 계산
  static int remainingSeconds(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return 0;
      final payloadJson = utf8.decode(base64Url.decode(parts[0]));
      final map = jsonDecode(payloadJson) as Map<String, dynamic>;
      final exp = map['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = exp - now;
      return remaining < 0 ? 0 : remaining;
    } catch (_) {
      return 0;
    }
  }
}
