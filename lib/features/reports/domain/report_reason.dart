// lib/features/reports/domain/report_reason.dart
enum ReportReason {
  spam('spam', '스팸 · 광고'),
  hateSpeech('hate_speech', '혐오 발언'),
  misinformation('misinformation', '허위 정보'),
  harassment('harassment', '괴롭힘 · 위협'),
  inappropriate('inappropriate', '부적절한 콘텐츠'),
  illegal('illegal', '불법 콘텐츠'),
  other('other', '기타');

  const ReportReason(this.code, this.label);
  final String code;
  final String label;
}

enum ReportTargetType {
  post('post'),
  comment('comment'),
  user('user'),
  petition('petition');

  const ReportTargetType(this.code);
  final String code;
}
