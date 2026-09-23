// lib/models/manga_model.dart

class MangaModel {
  final String id;
  final String title;
  final String coverUrl;
  final String category;
  final String rating;
  final String chapter;
  final String description;
  final double? ratingValue;
  final int? follows;

  MangaModel({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.category,
    required this.rating,
    required this.chapter,
    this.description = '',
    this.ratingValue,
    this.follows,
  });

  /// Display value for the rating row, e.g. "9.6" or "—" when unknown.
  String get ratingLabel =>
      ratingValue != null ? ratingValue!.toStringAsFixed(1) : rating;

  /// Display value for the follows/bookmarks row, e.g. "141K" or "—".
  String get followsLabel => follows == null ? '—' : compactCount(follows!);

  static String compactCount(int value) {
    if (value >= 1000000) {
      final d = value / 1000000;
      return '${d.toStringAsFixed(d >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final d = value / 1000;
      return '${d.toStringAsFixed(d >= 10 ? 0 : 1)}K';
    }
    return '$value';
  }

  factory MangaModel.fromMangaDexJson(Map<String, dynamic> json) {
    final String id = json['id'] ?? '';
    final attributes = json['attributes'] ?? {};
    final relationships = (json['relationships'] as List?) ?? [];

    String fileName = '';
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art' && rel['attributes'] != null) {
        fileName = rel['attributes']['fileName'] ?? '';
        break;
      }
    }

    final coverUrl = (id.isNotEmpty && fileName.isNotEmpty)
        ? 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg'
        : '';

    final titleMap = attributes['title'] as Map<String, dynamic>? ?? {};
    final title = titleMap['en'] ??
        titleMap['ko'] ??
        titleMap['ja-ro'] ??
        titleMap['ja'] ??
        'Untitled';

    final descMap = attributes['description'] as Map<String, dynamic>? ?? {};
    final description = (descMap['en'] ?? descMap['ko'] ?? '').toString();

    final tags = (attributes['tags'] as List?) ?? [];
    String category = 'MANGA';
    if (tags.isNotEmpty) {
      final firstTagAttr = tags.first['attributes'] ?? {};
      category =
          (firstTagAttr['name']?['en'] ?? 'MANGA').toString().toUpperCase();
    }

    return MangaModel(
      id: id,
      title: title,
      coverUrl: coverUrl,
      category: category,
      rating: '—',
      chapter: 'Ch. 1',
      description: description,
    );
  }

  /// Serialization used to persist bookmarks inside a user's Firestore doc.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'category': category,
      'rating': rating,
      'chapter': chapter,
      'description': description,
      'ratingValue': ratingValue,
      'follows': follows,
    };
  }

  factory MangaModel.fromMap(Map<String, dynamic> map) {
    return MangaModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      coverUrl: map['coverUrl']?.toString() ?? '',
      category: map['category']?.toString() ?? 'MANGA',
      rating: map['rating']?.toString() ?? '—',
      chapter: map['chapter']?.toString() ?? 'Ch. 1',
      description: map['description']?.toString() ?? '',
      ratingValue: (map['ratingValue'] as num?)?.toDouble(),
      follows: (map['follows'] as num?)?.toInt(),
    );
  }

  MangaModel copyWith({
    String? title,
    String? coverUrl,
    String? category,
    String? rating,
    String? chapter,
    String? description,
    double? ratingValue,
    int? follows,
  }) {
    return MangaModel(
      id: id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      chapter: chapter ?? this.chapter,
      description: description ?? this.description,
      ratingValue: ratingValue ?? this.ratingValue,
      follows: follows ?? this.follows,
    );
  }
}
