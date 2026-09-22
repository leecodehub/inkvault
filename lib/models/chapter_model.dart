class ChapterModel {
  final String id;
  final String chapterNumber;
  final String title;
  final String releaseDate;
  final int pageCount;
  final bool isLocked;
  final int coinCost;

  ChapterModel({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.releaseDate,
    required this.pageCount,
    this.isLocked = false,
    this.coinCost = 0,
  });

  /// Builds a chapter from a MangaDex `/manga/{id}/feed` data object.
  ///
  /// The [id] here is the real MangaDex chapter UUID, which is required later
  /// by the `/at-home/server/{id}` endpoint to resolve the page images.
  factory ChapterModel.fromMangaDexJson(Map<String, dynamic> json) {
    final Map<String, dynamic> attributes =
        Map<String, dynamic>.from(json['attributes'] ?? {});

    final String chapterNumber = attributes['chapter']?.toString() ?? '';
    final String rawTitle = attributes['title']?.toString().trim() ?? '';

    return ChapterModel(
      id: json['id']?.toString() ?? '',
      chapterNumber: chapterNumber.isEmpty ? 'Oneshot' : chapterNumber,
      title: rawTitle.isEmpty
          ? (chapterNumber.isEmpty ? 'Oneshot' : 'Chapter $chapterNumber')
          : rawTitle,
      releaseDate: _formatReleaseDate(
        attributes['publishAt'] ?? attributes['readableAt'],
      ),
      pageCount: attributes['pages'] is int ? attributes['pages'] as int : 0,
    );
  }

  ChapterModel copyWith({
    String? id,
    String? chapterNumber,
    String? title,
    String? releaseDate,
    int? pageCount,
    bool? isLocked,
    int? coinCost,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      releaseDate: releaseDate ?? this.releaseDate,
      pageCount: pageCount ?? this.pageCount,
      isLocked: isLocked ?? this.isLocked,
      coinCost: coinCost ?? this.coinCost,
    );
  }

  static String _formatReleaseDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final DateTime? parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return '';

    final Duration diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inDays >= 30) {
      final int months = (diff.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }
    if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inMinutes >= 1) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    }
    return 'Just now';
  }
}
