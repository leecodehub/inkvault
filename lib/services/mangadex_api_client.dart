import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chapter_model.dart';
import '../models/manga_model.dart';

class MangaDexApiClient {
  static const Map<String, String> _headers = {
    // Rule requirement: MUST supply a valid custom User-Agent
    'User-Agent': 'InkVaultApp/1.0.0 (contact@inkvault.app)',
    'Accept': 'application/json',
  };

  Future<List<MangaModel>> fetchPopularManga({int limit = 12}) async {
    // Construct Uri using Map with list values for array query parameters
    final Uri url = Uri.https('api.mangadex.org', '/manga', {
      'limit': '$limit',
      'originalLanguage[]': 'ko', // 'ko' filters explicitly for Manhwa
      'order[followedCount]': 'desc',
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
    });

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('MangaDex API Response Code: ${response.statusCode}');
        return [];
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];

      if (data.isEmpty) {
        debugPrint('MangaDex returned 0 results.');
        return [];
      }

      return data
          .map((item) => _mapMangaItem(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('MangaDex Fetch Error: $e');
      return [];
    }
  }

  /// Fetches manhwa with the most recently uploaded chapters.
  ///
  /// Sorted by `latestUploadedChapter` descending, so the first result has the
  /// newest chapter release. Used by the "Latest Chapter Releases" section.
  Future<List<MangaModel>> fetchLatestReleases({int limit = 30}) async {
    final Uri url = Uri.https('api.mangadex.org', '/manga', {
      'limit': '$limit',
      'originalLanguage[]': 'ko',
      'order[latestUploadedChapter]': 'desc',
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
      'hasAvailableChapters': 'true',
    });

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint(
            'MangaDex Latest Releases Response Code: ${response.statusCode}');
        return [];
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];

      return data
          .map((item) => _mapMangaItem(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('MangaDex Latest Releases Error: $e');
      return [];
    }
  }

  /// Fetches one page of the full manhwa directory using offset pagination.
  ///
  /// Supports optional server-side [title] search and [tagId] genre filtering,
  /// plus order by [orderKey] (e.g. `followedCount`, `rating`, `title`). The
  /// response `total` is returned alongside the items so callers know how many
  /// pages exist. MangaDex caps `limit` at 100.
  Future<({List<MangaModel> items, int total})> fetchDirectoryPage({
    int limit = 50,
    int offset = 0,
    String? title,
    String? tagId,
    String orderKey = 'followedCount',
    bool ascending = false,
  }) async {
    final Map<String, dynamic> params = {
      'limit': '$limit',
      'offset': '$offset',
      'originalLanguage[]': 'ko',
      'order[$orderKey]': ascending ? 'asc' : 'desc',
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
      'hasAvailableChapters': 'true',
    };
    if (title != null && title.isNotEmpty) {
      params['title'] = title;
    }
    if (tagId != null && tagId.isNotEmpty) {
      params['includedTags[]'] = tagId;
    }

    final Uri url = Uri.https('api.mangadex.org', '/manga', params);

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('MangaDex Directory Response Code: ${response.statusCode}');
        return (items: const <MangaModel>[], total: 0);
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      final int total = decoded['total'] is int
          ? decoded['total'] as int
          : (offset + data.length);

      final List<MangaModel> items = data
          .map((item) => _mapMangaItem(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      return (items: items, total: total);
    } catch (e) {
      debugPrint('MangaDex Directory Error: $e');
      return (items: const <MangaModel>[], total: 0);
    }
  }

  /// Fetches all MangaDex tags as a lowercase-name -> UUID map.
  ///
  /// Used to translate display genres (e.g. "Martial Arts") into the tag IDs
  /// that the `/manga` endpoint expects for `includedTags[]`.
  Future<Map<String, String>> fetchTagMap() async {
    final Uri url = Uri.https('api.mangadex.org', '/manga/tag');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('MangaDex Tags Response Code: ${response.statusCode}');
        return {};
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];

      final Map<String, String> tagMap = {};
      for (final tag in data) {
        final String id = tag['id']?.toString() ?? '';
        final String name =
            tag['attributes']?['name']?['en']?.toString() ?? '';
        if (id.isNotEmpty && name.isNotEmpty) {
          tagMap[name.toLowerCase()] = id;
        }
      }

      return tagMap;
    } catch (e) {
      debugPrint('MangaDex Tags Error: $e');
      return {};
    }
  }

  /// Maps a single `/manga` data item into a [MangaModel].
  MangaModel _mapMangaItem(Map<String, dynamic> item) {
    final String id = item['id'] ?? '';
    final attributes = item['attributes'] ?? {};

    // Title Extraction
    final Map<String, dynamic> titleMap =
        Map<String, dynamic>.from(attributes['title'] ?? {});
    final String title = titleMap['en'] ??
        (titleMap.values.isNotEmpty
            ? titleMap.values.first.toString()
            : 'Untitled');

    // Cover Art Relationship Extraction
    final List<dynamic> relationships = item['relationships'] ?? [];
    String fileName = '';

    for (var rel in relationships) {
      if (rel['type'] == 'cover_art' && rel['attributes'] != null) {
        fileName = rel['attributes']['fileName'] ?? '';
        break;
      }
    }

    // Cover URL Construction (256px Thumbnail)
    final String coverUrl = (id.isNotEmpty && fileName.isNotEmpty)
        ? 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg'
        : 'https://placehold.co/256x360?text=No+Cover';

    // Tag / Category Extraction
    String category = 'MANHWA';
    final List<dynamic> tags = attributes['tags'] ?? [];
    if (tags.isNotEmpty) {
      final firstTag = tags.firstWhere(
        (t) => t['attributes']?['name']?['en'] != 'Long Strip',
        orElse: () => tags.first,
      );
      category = (firstTag['attributes']?['name']?['en'] ?? 'MANHWA')
          .toString()
          .toUpperCase();
    }

    final String lastChapter = attributes['lastChapter'] != null &&
            attributes['lastChapter'].toString().isNotEmpty
        ? 'Ch. ${attributes['lastChapter']}'
        : 'New Chapter';

    return MangaModel(
      id: id,
      title: title,
      coverUrl: coverUrl,
      category: category,
      chapter: lastChapter,
      rating: '4.8',
    );
  }

  /// Fetches the English chapter feed for a manga.
  ///
  /// Returns only chapters that are actually hosted on MangaDex (external
  /// chapters such as official publisher links have no readable pages and are
  /// skipped). The returned IDs are real chapter UUIDs suitable for
  /// [fetchChapterImages].
  Future<List<ChapterModel>> fetchChapters(
    String mangaId, {
    int limit = 200,
  }) async {
    final Uri url = Uri.https('api.mangadex.org', '/manga/$mangaId/feed', {
      'limit': '$limit',
      'translatedLanguage[]': 'en',
      'order[chapter]': 'desc',
      'contentRating[]': ['safe', 'suggestive', 'erotica'],
      'includes[]': 'scanlation_group',
    });

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('MangaDex Feed Response Code: ${response.statusCode}');
        return [];
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];

      final List<ChapterModel> chapters = [];
      for (final item in data) {
        final attributes = item['attributes'] ?? {};

        // Skip external / unavailable chapters: they have no at-home pages.
        final bool isExternal =
            (attributes['externalUrl']?.toString().isNotEmpty ?? false);
        final bool isUnavailable = attributes['isUnavailable'] == true;
        if (isExternal || isUnavailable) continue;

        final ChapterModel chapter =
            ChapterModel.fromMangaDexJson(Map<String, dynamic>.from(item));
        if (chapter.id.isEmpty) continue;
        chapters.add(chapter);
      }

      return chapters;
    } catch (e) {
      debugPrint('MangaDex Feed Error: $e');
      return [];
    }
  }

  /// Resolves the actual page image URLs for a chapter.
  ///
  /// MangaDex rotates its image host, so the CDN [baseUrl] returned by
  /// `/at-home/server/{id}` must be used instead of assuming
  /// `uploads.mangadex.org`. Set [dataSaver] to true for the smaller,
  /// compressed JPEG files.
  Future<List<String>> fetchChapterImages(
    String chapterId, {
    bool dataSaver = false,
  }) async {
    final Uri url = Uri.https('api.mangadex.org', '/at-home/server/$chapterId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode != 200) {
        debugPrint('MangaDex At-Home Response Code: ${response.statusCode}');
        return [];
      }

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final String baseUrl = decoded['baseUrl']?.toString() ?? '';
      final Map<String, dynamic> chapter =
          Map<String, dynamic>.from(decoded['chapter'] ?? {});
      final String hash = chapter['hash']?.toString() ?? '';

      final List<dynamic> files =
          (dataSaver ? chapter['dataSaver'] : chapter['data']) as List? ?? [];

      if (baseUrl.isEmpty || hash.isEmpty || files.isEmpty) {
        debugPrint('MangaDex At-Home payload missing data for $chapterId');
        return [];
      }

      final String quality = dataSaver ? 'data-saver' : 'data';
      return files
          .map((file) => '$baseUrl/$quality/$hash/$file')
          .toList(growable: false);
    } catch (e) {
      debugPrint('MangaDex At-Home Error: $e');
      return [];
    }
  }
}
