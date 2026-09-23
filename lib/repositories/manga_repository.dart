import 'package:flutter/foundation.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../models/schedule_entry.dart';
import '../services/mangadex_api_client.dart';

class MangaRepository {
  final MangaDexApiClient _apiClient;

  MangaRepository({MangaDexApiClient? apiClient})
      : _apiClient = apiClient ?? MangaDexApiClient();

  /// Fetches trending Korean Manhwa sorted by popularity
  Future<List<MangaModel>> getPopularManga({int limit = 12}) async {
    try {
      final list = await _apiClient.fetchPopularManga(limit: limit);
      return list;
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getPopularManga): $e');
      }
      return [];
    }
  }

  /// Searches manhwa by title
  Future<List<MangaModel>> searchManga(String query, {int limit = 10}) async {
    try {
      return await _apiClient.searchManga(query, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (searchManga): $e');
      }
      return [];
    }
  }

  /// Fetches manhwa with the most recently uploaded chapters
  Future<List<MangaModel>> getLatestReleases({int limit = 30}) async {
    try {
      final list = await _apiClient.fetchLatestReleases(limit: limit);
      return list;
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getLatestReleases): $e');
      }
      return [];
    }
  }

  /// Fetches one offset-paged slice of the full manhwa directory
  Future<({List<MangaModel> items, int total})> getDirectoryPage({
    int limit = 50,
    int offset = 0,
    String? title,
    List<String> tagIds = const [],
    String tagMode = 'or',
    String orderKey = 'followedCount',
    bool ascending = false,
  }) async {
    try {
      return await _apiClient.fetchDirectoryPage(
        limit: limit,
        offset: offset,
        title: title,
        tagIds: tagIds,
        tagMode: tagMode,
        orderKey: orderKey,
        ascending: ascending,
      );
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getDirectoryPage): $e');
      }
      return (items: const <MangaModel>[], total: 0);
    }
  }

  /// Fetches the MangaDex tag name -> UUID map used for genre filtering
  Future<Map<String, String>> getTagMap() async {
    try {
      return await _apiClient.fetchTagMap();
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getTagMap): $e');
      }
      return {};
    }
  }

  /// Fetches the readable Korean chapter list for a manga
  Future<List<ChapterModel>> getChapters(String mangaId) async {
    try {
      return await _apiClient.fetchChapters(mangaId);
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getChapters): $e');
      }
      return [];
    }
  }

  /// Resolves the ordered page image URLs for a chapter
  Future<List<String>> getChapterImages(
    String chapterId, {
    bool dataSaver = false,
  }) async {
    try {
      return await _apiClient.fetchChapterImages(
        chapterId,
        dataSaver: dataSaver,
      );
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getChapterImages): $e');
      }
      return [];
    }
  }

  /// Fetches recently released chapters for the Weekly Schedule
  Future<List<ScheduleEntry>> getScheduleEntries({int limit = 100}) async {
    try {
      return await _apiClient.fetchScheduleEntries(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (getScheduleEntries): $e');
      }
      return [];
    }
  }

  /// Attaches real rating + follows to each manga (batched).
  Future<List<MangaModel>> enrichWithStats(List<MangaModel> list) async {
    if (list.isEmpty) return list;
    try {
      final stats = await _apiClient.fetchStatistics(
        list.map((m) => m.id).toList(),
      );
      if (stats.isEmpty) return list;
      return list.map((m) {
        final stat = stats[m.id];
        if (stat == null) return m;
        return m.copyWith(
          ratingValue: stat.rating,
          rating: stat.rating == null ? m.rating : stat.rating!.toStringAsFixed(1),
          follows: stat.follows,
        );
      }).toList(growable: false);
    } catch (e) {
      if (kDebugMode) {
        print('MangaRepository Error (enrichWithStats): $e');
      }
      return list;
    }
  }
}
