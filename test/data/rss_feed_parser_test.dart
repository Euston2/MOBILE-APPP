import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/data/reader/rss_feed_client.dart';

void main() {
  final longText = List.filled(250, 'word').join(' ');

  test('keeps RSS content:encoded and parses the publication date', () {
    final xml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
     xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>Example</title>
    <link>https://example.com</link>
    <description>Example feed</description>
    <item>
      <title>First</title>
      <link>https://example.com/first</link>
      <description>&lt;p&gt;Short summary&lt;/p&gt;</description>
      <pubDate>Tue, 12 Nov 2026 10:00:00 GMT</pubDate>
      <content:encoded><![CDATA[<p>$longText</p>]]></content:encoded>
    </item>
    <item>
      <title>Second</title>
      <link>https://example.com/second</link>
      <description>Another summary</description>
    </item>
  </channel>
</rss>
''';

    final result = const RssFeedParser().parse(xml, etag: '"v1"');

    expect(result.etag, '"v1"');
    expect(result.items, hasLength(2));
    final first = result.items.first;
    expect(first.title, 'First');
    expect(first.url, 'https://example.com/first');
    expect(first.excerpt, 'Short summary');
    expect(first.contentHtml, contains('word word'));
    expect(first.publishedAt, isNotNull);
    expect(first.publishedAt!.toUtc().year, 2026);

    final second = result.items.last;
    expect(second.contentHtml, isNull);
  });

  test('parses Atom links and ISO dates', () {
    final xml =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Example Atom</title>
  <link href="https://example.com"/>
  <entry>
    <title>Atom post</title>
    <link rel="alternate" href="https://example.com/atom-post"/>
    <published>2026-11-12T10:00:00Z</published>
    <summary>Atom summary</summary>
    <content type="html"><![CDATA[<p>$longText</p>]]></content>
  </entry>
</feed>
''';

    final result = const RssFeedParser().parse(xml);

    expect(result.items, hasLength(1));
    final item = result.items.single;
    expect(item.url, 'https://example.com/atom-post');
    expect(item.excerpt, 'Atom summary');
    expect(item.contentHtml, isNotNull);
    expect(item.publishedAt, DateTime.utc(2026, 11, 12, 10));
  });

  test('respects the item limit', () {
    final xml = '''
<rss version="2.0">
  <channel>
    <title>Example</title>
    <link>https://example.com</link>
    <description>Example</description>
    <item><title>One</title><link>https://example.com/one</link><description>One</description></item>
    <item><title>Two</title><link>https://example.com/two</link><description>Two</description></item>
  </channel>
</rss>
''';

    final result = const RssFeedParser().parse(xml, limit: 1);

    expect(result.items.single.title, 'One');
  });

  test('rejects XML that is not a feed', () {
    expect(
      () => const RssFeedParser().parse('<root><item /></root>'),
      throwsFormatException,
    );
  });
}
