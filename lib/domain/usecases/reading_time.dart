/// Average adult reading speed used for the estimate.
const int readerWordsPerMinute = 220;

final _tagPattern = RegExp(r'<[^>]*>');
final _whitespacePattern = RegExp(r'\s+');
final _entityPattern = RegExp(r'&[a-zA-Z]+;|&#\d+;');

/// Estimates a minimum-one-minute read from HTML or plain text.
int estimateReadingMinutes(String? text) {
  final plain = (text ?? '')
      .replaceAll(_tagPattern, ' ')
      .replaceAll(_entityPattern, ' ')
      .replaceAll(_whitespacePattern, ' ')
      .trim();
  if (plain.isEmpty) return 1;

  final words = plain.split(' ').where((word) => word.isNotEmpty).length;
  final minutes = (words / readerWordsPerMinute).ceil();
  return minutes < 1 ? 1 : minutes;
}

/// Plain text preview used when a feed only provides HTML.
String plainTextPreview(String? html, {int maxCharacters = 320}) {
  final plain = (html ?? '')
      .replaceAll(_tagPattern, ' ')
      .replaceAll(_entityPattern, ' ')
      .replaceAll(_whitespacePattern, ' ')
      .trim();
  if (plain.length <= maxCharacters) return plain;
  return '${plain.substring(0, maxCharacters).trimRight()}…';
}
