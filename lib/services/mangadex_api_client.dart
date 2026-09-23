import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../models/schedule_entry.dart';

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

  /// Searches manhwa by title (used by the navbar search suggestions).
  Future<List<MangaModel>> searchManga(String query, {int limit = 10}) async {
    final Uri url = Uri.https('api.mangadex.org', '/manga', {
      'limit': '$limit',
      'title': query,
      'originalLanguage[]': 'ko',
      'order[followedCount]': 'desc',
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
      'hasAvailableChapters': 'true',
    });

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) {
        debugPrint('MangaDex Search Response Code: ${response.statusCode}');
        return [];
      }
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data'] ?? [];
      return data
          .map((item) => _mapMangaItem(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('MangaDex Search Error: $e');
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
    List<String> tagIds = const [],
    String tagMode = 'or',
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
    if (tagIds.isNotEmpty) {
      params['includedTags[]'] = tagIds;
      params['tagMode'] = tagMode;
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

    // Title Extraction (English first, then Korean, then first available)
    final Map<String, dynamic> titleMap =
        Map<String, dynamic>.from(attributes['title'] ?? {});
    final String title = titleMap['en'] ??
        titleMap['ko'] ??
        titleMap['ja-ro'] ??
        (titleMap.values.isNotEmpty
            ? titleMap.values.first.toString()
            : 'Untitled');

    // Real description (English first, then Korean)
    final Map<String, dynamic> descMap =
        Map<String, dynamic>.from(attributes['description'] ?? {});
    final String description = (descMap['en'] ?? descMap['ko'] ?? '').toString();

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
      rating: '—',
      description: description,
    );
  }

  /// Fetches the chapter feed for a manga across ALL languages.
  ///
  /// Returning every language guarantees chapters are available (Korean-only
  /// feeds are often empty). Duplicate chapter numbers are collapsed, keeping
  /// Korean first, then English, then anything else. External chapters (no
  /// readable pages) are skipped.
  Future<List<ChapterModel>> fetchChapters(
    String mangaId, {
    int limit = 500,
  }) async {
    final Uri url = Uri.https('api.mangadex.org', '/manga/$mangaId/feed', {
      'limit': '$limit',
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

      // Dedupe by chapter number, preferring Korean > English > other.
      final Map<String, ({int priority, ChapterModel chapter})> best = {};

      for (final item in data) {
        final attributes = item['attributes'] ?? {};

        final bool isExternal =
            (attributes['externalUrl']?.toString().isNotEmpty ?? false);
        final bool isUnavailable = attributes['isUnavailable'] == true;
        if (isExternal || isUnavailable) continue;

        final ChapterModel chapter =
            ChapterModel.fromMangaDexJson(Map<String, dynamic>.from(item));
        if (chapter.id.isEmpty) continue;

        final String lang = attributes['translatedLanguage']?.toString() ?? '';
        final int priority = lang == 'ko' ? 0 : (lang == 'en' ? 1 : 2);

        final existing = best[chapter.chapterNumber];
        if (existing == null || priority < existing.priority) {
          best[chapter.chapterNumber] = (priority: priority, chapter: chapter);
        }
      }

      final List<ChapterModel> chapters =
          best.values.map((e) => e.chapter).toList();

      // Newest first (numeric when possible).
      chapters.sort((a, b) {
        final double av = double.tryParse(a.chapterNumber) ?? -1;
        final double bv = double.tryParse(b.chapterNumber) ?? -1;
        return bv.compareTo(av);
      });

      return chapters;
    } catch (e) {
      debugPrint('MangaDex Feed Error: $e');
      return [];
    }
  }

  /// Fetches rating + follow counts for up to 100 manga ids at once.
  ///
  /// Returns `{mangaId: (rating, follows)}`. MangaDex has no public read count.
  Future<Map<String, ({double? rating, int follows})>> fetchStatistics(
    List<String> ids,
  ) async {
    final result = <String, ({double? rating, int follows})>{};
    if (ids.isEmpty) return result;

    for (int i = 0; i < ids.length; i += 100) {
      final int end = (i + 100 > ids.length) ? ids.length : i + 100;
      final chunk = ids.sublist(i, end);
      final Uri url = Uri.https('api.mangadex.org', '/statistics/manga', {
        'manga[]': chunk,
      });

      try {
        final response = await http.get(url, headers: _headers);
        if (response.statusCode != 200) continue;

        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final Map<String, dynamic> stats =
            Map<String, dynamic>.from(decoded['statistics'] ?? {});

        stats.forEach((id, value) {
          if (value is! Map) return;
          final ratingMap = value['rating'];
          final double? rating = (ratingMap is Map && ratingMap['average'] is num)
              ? (ratingMap['average'] as num).toDouble()
              : null;
          final int follows =
              (value['follows'] is num) ? (value['follows'] as num).toInt() : 0;
          result[id] = (rating: rating, follows: follows);
        });
      } catch (e) {
        debugPrint('MangaDex Statistics Error: $e');
      }
    }

    return result;
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

  /// Builds the Weekly Schedule from the top popular manhwa.
  ///
  /// Each series is assigned to a weekday using the release date of its most
  /// recent readable chapter, so every day of the week gets populated.
  Future<List<ScheduleEntry>> fetchScheduleEntries({int limit = 100}) async {
    final Uri mangaUrl = Uri.https('api.mangadex.org', '/manga', {
      'limit': '$limit',
      'originalLanguage[]': 'ko',
      'order[followedCount]': 'desc',
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
      'hasAvailableChapters': 'true',
    });

    try {
      final mangaResponse = await http.get(mangaUrl, headers: _headers);
      if (mangaResponse.statusCode != 200) {
        debugPrint(
            'MangaDex Schedule Manga Response Code: ${mangaResponse.statusCode}');
        return [];
      }

      final Map<String, dynamic> mangaDecoded = jsonDecode(mangaResponse.body);
      final List<dynamic> mangaData = mangaDecoded['data'] ?? [];

      final Map<String, MangaModel> byId = {};
      for (final item in mangaData) {
        final MangaModel manga =
            _mapMangaItem(Map<String, dynamic>.from(item));
        if (manga.id.isNotEmpty) byId[manga.id] = manga;
      }
      if (byId.isEmpty) return [];

      final List<String> ids = byId.keys.toList();

      // Collect recent chapters per manga so we can derive the weekday that
      // manga typically releases on (the mode), not just its latest chapter.
      final Map<String, ({String chapter, DateTime latest})> latest = {};
      final Map<String, List<int>> weekdayHistory = {};

      for (int i = 0; i < ids.length; i += 10) {
        final int end = (i + 10 > ids.length) ? ids.length : i + 10;
        final chunk = ids.sublist(i, end);
        final Uri url = Uri.https('api.mangadex.org', '/chapter', {
          'limit': '100',
          'manga': chunk,
          'order[createdAt]': 'desc',
          'contentRating[]': ['safe', 'suggestive'],
        });

        final response = await http.get(url, headers: _headers);
        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? [];

        for (final item in data) {
          final attributes = item['attributes'] ?? {};
          final bool isExternal =
              (attributes['externalUrl']?.toString().isNotEmpty ?? false);
          if (isExternal) continue;

          String mangaId = '';
          for (final rel in (item['relationships'] as List? ?? [])) {
            if (rel['type'] == 'manga') {
              mangaId = rel['id']?.toString() ?? '';
              break;
            }
          }
          if (mangaId.isEmpty) continue;

          final DateTime? date = DateTime.tryParse(
            (attributes['readableAt'] ?? attributes['publishAt'] ?? '')
                .toString(),
          );
          if (date == null) continue;
          final DateTime local = date.toLocal();
          if (local.isAfter(DateTime.now())) continue;

          final history = weekdayHistory.putIfAbsent(mangaId, () => []);
          if (history.length < 8) history.add(local.weekday);

          final existing = latest[mangaId];
          if (existing == null || local.isAfter(existing.latest)) {
            latest[mangaId] = (
              chapter: attributes['chapter']?.toString() ?? '',
              latest: local,
            );
          }
        }
      }

      int dominantWeekday(List<int> days) {
        if (days.isEmpty) return DateTime.now().weekday;
        final counts = <int, int>{};
        for (final day in days) {
          counts[day] = (counts[day] ?? 0) + 1;
        }
        int best = days.first;
        int bestCount = -1;
        counts.forEach((day, count) {
          if (count > bestCount) {
            bestCount = count;
            best = day;
          }
        });
        return best;
      }

      final List<ScheduleEntry> entries = [];
      latest.forEach((mangaId, value) {
        final manga = byId[mangaId];
        if (manga == null) return;
        final days = weekdayHistory[mangaId] ?? [value.latest.weekday];
        entries.add(
          ScheduleEntry(
            weekday: dominantWeekday(days),
            mangaId: mangaId,
            title: manga.title,
            coverUrl: manga.coverUrl,
            chapter: value.chapter,
            publishAt: value.latest,
          ),
        );
      });

      return entries;
    } catch (e) {
      debugPrint('MangaDex Schedule Error: $e');
      return [];
    }
  }
}
