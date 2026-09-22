// lib/models/manga_model.dart

class MangaModel {
  final String id;
  final String title;
  final String coverUrl;
  final String category;
  final String rating;
  final String chapter;

  MangaModel({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.category,
    required this.rating,
    required this.chapter,
  });

  factory MangaModel.fromMangaDexJson(Map<String, dynamic> json) {
    final String id = json['id'] ?? '';
    final attributes = json['attributes'] ?? {};
    final relationships = (json['relationships'] as List?) ?? [];

    // 1. Find cover filename from real API relationships payload
    String fileName = '';
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art' && rel['attributes'] != null) {
        fileName = rel['attributes']['fileName'] ?? '';
        break;
      }
    }

    // 2. Build live MangaDex CDN cover URL
    final coverUrl = (id.isNotEmpty && fileName.isNotEmpty)
        ? 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg'
        : '';

    // 3. Extract title dynamically
    final titleMap = attributes['title'] as Map<String, dynamic>? ?? {};
    final title =
        titleMap['en'] ?? titleMap['ja-ro'] ?? titleMap['ja'] ?? 'Untitled';

    // 4. Extract primary tag name dynamically
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
      rating: '4.8',
      chapter: 'Ch. 1',
    );
  }
}
