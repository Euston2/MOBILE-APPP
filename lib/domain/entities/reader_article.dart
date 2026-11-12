/// One cached article, as rendered by the Reader.
class ReaderArticle {
  const ReaderArticle({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.url,
    required this.excerpt,
    required this.readingMinutes,
    required this.fetchedAt,
    this.contentHtml,
    this.publishedAt,
    this.isRead = false,
    this.isBookmarked = false,
    this.pickDate,
    this.pickRank,
  });

  final String id;
  final String sourceId;
  final String sourceName;
  final String title;
  final String url;
  final String excerpt;
  final String? contentHtml;
  final int readingMinutes;
  final DateTime? publishedAt;
  final DateTime fetchedAt;
  final bool isRead;
  final bool isBookmarked;
  final String? pickDate;
  final int? pickRank;

  bool get hasFullContent => (contentHtml ?? '').trim().isNotEmpty;

  bool get hasExcerpt => excerpt.trim().isNotEmpty;

  ReaderArticle copyWith({
    String? title,
    String? sourceName,
    String? excerpt,
    String? contentHtml,
    int? readingMinutes,
    DateTime? publishedAt,
    DateTime? fetchedAt,
    bool? isRead,
    bool? isBookmarked,
    String? pickDate,
    int? pickRank,
    bool clearPick = false,
  }) {
    return ReaderArticle(
      id: id,
      sourceId: sourceId,
      sourceName: sourceName ?? this.sourceName,
      title: title ?? this.title,
      url: url,
      excerpt: excerpt ?? this.excerpt,
      contentHtml: contentHtml ?? this.contentHtml,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      publishedAt: publishedAt ?? this.publishedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isRead: isRead ?? this.isRead,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      pickDate: clearPick ? null : pickDate ?? this.pickDate,
      pickRank: clearPick ? null : pickRank ?? this.pickRank,
    );
  }

  @override
  String toString() =>
      'ReaderArticle($id, ${sourceName.trim()}, ${title.trim()})';
}
