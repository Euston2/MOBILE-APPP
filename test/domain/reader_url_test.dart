import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/usecases/reader_url.dart';

void main() {
  group('canonicalizeReaderUrl', () {
    test('removes trackers, fragments and a trailing slash', () {
      expect(
        canonicalizeReaderUrl(
          'https://www.Example.com/story/?utm_source=newsletter&id=7&ref=home#top',
        ),
        'https://example.com/story?id=7',
      );
    });

    test('keeps meaningful query parameters and the scheme', () {
      expect(
        canonicalizeReaderUrl('http://example.com/a?page=2&sort=new'),
        'http://example.com/a?page=2&sort=new',
      );
    });

    test('rejects social, non-web and relative URLs', () {
      expect(canonicalizeReaderUrl('https://www.instagram.com/p/123'), isNull);
      expect(canonicalizeReaderUrl('https://youtu.be/abc'), isNull);
      expect(canonicalizeReaderUrl('mailto:hello@example.com'), isNull);
      expect(canonicalizeReaderUrl('/relative'), isNull);
      expect(canonicalizeReaderUrl('   '), isNull);
    });
  });

  test('article IDs are stable and URL-specific', () {
    const first = 'https://example.com/story';
    const second = 'https://example.com/another-story';

    expect(readerArticleId(first), readerArticleId(first));
    expect(readerArticleId(first), isNot(readerArticleId(second)));
    expect(readerArticleId(first), hasLength(8));
  });

  test('host allowlist includes subdomains but not lookalikes', () {
    expect(
      isReaderHostAllowed(
        Uri.parse('https://news.example.com/article'),
        'example.com',
      ),
      isTrue,
    );
    expect(
      isReaderHostAllowed(Uri.parse('https://example.com'), 'www.example.com'),
      isTrue,
    );
    expect(
      isReaderHostAllowed(
        Uri.parse('https://evil-example.com/article'),
        'example.com',
      ),
      isFalse,
    );
  });

  test('social host matching covers subdomains', () {
    expect(isSocialReaderHost('m.facebook.com'), isTrue);
    expect(isSocialReaderHost('example.com'), isFalse);
  });
}
