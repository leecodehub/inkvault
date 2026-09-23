import 'package:flutter/material.dart';
import '../constants/app_config.dart';
import '../models/manga_model.dart';
import '../repositories/manga_repository.dart';

class MangaProvider extends ChangeNotifier {
  final MangaRepository _repository;

  MangaProvider({MangaRepository? repository})
      : _repository = repository ?? MangaRepository();

  List<MangaModel> _trendingManga = [];
  List<MangaModel> _directoryManga = [];
  List<MangaModel> _latestReleases = [];
  bool _isLoading = false;
  bool _isLoadingDirectory = false;
  bool _isLoadingLatest = false;
  String? _errorMessage;
  String? _directoryError;
  String? _latestError;

  // Directory (All Series) server-side pagination + filters
  static const int _directoryLimit = AppConfig.directoryPageSize;
  int _directoryPage = 0;
  int _directoryTotal = 0;
  String _directoryQuery = '';
  List<String> _directoryGenres = <String>[];
  String _directorySort = 'Popularity';
  Map<String, String>? _tagNameToId;

  // Getters
  List<MangaModel> get trendingManga => _trendingManga;
  List<MangaModel> get directoryManga => _directoryManga;
  List<MangaModel> get latestReleases => _latestReleases;
  bool get isLoading => _isLoading;
  bool get isLoadingDirectory => _isLoadingDirectory;
  bool get isLoadingLatest => _isLoadingLatest;
  String? get errorMessage => _errorMessage;
  String? get directoryError => _directoryError;
  String? get latestError => _latestError;

  int get directoryPage => _directoryPage;

  /// Total series exposed, capped at [AppConfig.maxDirectoryEntries].
  int get directoryTotal {
    return _directoryTotal > AppConfig.maxDirectoryEntries
        ? AppConfig.maxDirectoryEntries
        : _directoryTotal;
  }

  int get directoryLimit => _directoryLimit;
  String get directoryQuery => _directoryQuery;
  List<String> get directoryGenres => _directoryGenres;
  String get directorySort => _directorySort;

  /// Number of pages in the currently filtered directory result.
  int get directoryTotalPages =>
      directoryTotal <= 0 ? 1 : (directoryTotal / _directoryLimit).ceil();

  /// Loads trending manhwa from repository
  Future<void> loadTrendingManga({int limit = 12}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.getPopularManga(limit: limit);
      if (results.isEmpty) {
        _errorMessage = 'No manhwa found or failed to connect.';
      } else {
        _trendingManga = await _repository.enrichWithStats(results);
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch series. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads a single page of the All Series directory from the API.
  ///
  /// Search, genre and sort are sent to MangaDex so paging always works across
  /// the FULL catalog, not just whatever is already in memory. Any filter change
  /// should be accompanied by `page: 0`.
  Future<void> loadDirectoryPage({
    int page = 0,
    String? query,
    List<String>? genres,
    String? sortBy,
  }) async {
    if (_isLoadingDirectory) return;

    _directoryPage = page < 0 ? 0 : page;

    // Never page past the 1,000-series cap.
    if (_directoryPage > 0 &&
        _directoryPage * _directoryLimit >= AppConfig.maxDirectoryEntries) {
      return;
    }

    if (query != null) _directoryQuery = query;
    if (genres != null) _directoryGenres = List<String>.from(genres);
    if (sortBy != null) _directorySort = sortBy;

    _isLoadingDirectory = true;
    _directoryError = null;
    notifyListeners();

    try {
      List<String> tagIds = const [];
      if (_directoryGenres.isNotEmpty) {
        final tags = await _loadTagMap();
        tagIds = _directoryGenres
            .map((g) => tags[g.toLowerCase()])
            .whereType<String>()
            .toList();
      }

      final result = await _repository.getDirectoryPage(
        limit: _directoryLimit,
        offset: _directoryPage * _directoryLimit,
        title: _directoryQuery.trim().isEmpty ? null : _directoryQuery.trim(),
        tagIds: tagIds,
        tagMode: 'or',
        orderKey: _orderKey,
        ascending: _orderAscending,
      );

      _directoryManga = await _repository.enrichWithStats(result.items);
      _directoryTotal = result.total;
    } catch (e) {
      _directoryError = 'Failed to fetch series. Please try again.';
    } finally {
      _isLoadingDirectory = false;
      notifyListeners();
    }
  }

  /// Lazily resolves MangaDex tag name -> UUID (used for genre filtering).
  Future<Map<String, String>> _loadTagMap() async {
    final cached = _tagNameToId;
    if (cached != null) return cached;
    final map = await _repository.getTagMap();
    _tagNameToId = map;
    return map;
  }

  String get _orderKey {
    switch (_directorySort) {
      case 'Rating':
        return 'rating';
      case 'Title':
        return 'title';
      default:
        return 'followedCount';
    }
  }

  bool get _orderAscending => _directorySort == 'Title';

  /// Loads recently updated manhwa for the Latest Releases section
  Future<void> loadLatestReleases({int limit = 30}) async {
    _isLoadingLatest = true;
    _latestError = null;
    notifyListeners();

    try {
      final results = await _repository.getLatestReleases(limit: limit);
      _latestReleases = await _repository.enrichWithStats(results);
      if (results.isEmpty) {
        _latestError = 'No recent releases found.';
      }
    } catch (e) {
      _latestError = 'Failed to load latest releases.';
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  /// Clears error messages manually if needed
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
