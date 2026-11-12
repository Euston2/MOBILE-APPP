import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/reading_time.dart';

void main() {
  test('returns at least one minute for empty content', () {
    expect(estimateReadingMinutes(''), 1);
    expect(estimateReadingMinutes(null), 1);
  });

  test('counts words after stripping HTML tags', () {
    final words = List.filled(220, 'word').join(' ');
    expect(estimateReadingMinutes('<p>$words</p>'), 1);
    expect(estimateReadingMinutes('<p>$words extra</p>'), 2);
    expect(estimateReadingMinutes('<p>one</p><p>two</p>'), 1);
  });

  test('plain text preview strips tags, entities and whitespace', () {
    expect(
      plainTextPreview('<p>Hello&nbsp; <strong>there</strong></p>'),
      'Hello there',
    );
    expect(plainTextPreview('one two three', maxCharacters: 7), 'one two…');
  });
}
