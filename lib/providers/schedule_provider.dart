import 'package:flutter/foundation.dart';

import '../models/schedule_entry.dart';
import '../repositories/manga_repository.dart';

/// Loads recent Korean chapter releases and groups them by weekday.
class ScheduleProvider extends ChangeNotifier {
  final MangaRepository _repository;

  ScheduleProvider({MangaRepository? repository})
      : _repository = repository ?? MangaRepository();

  final Map<int, List<ScheduleEntry>> _byDay = {};
  bool _isLoading = false;
  bool _loaded = false;
  String? _error;
  int _selectedDay = DateTime.now().weekday;

  bool get isLoading => _isLoading;
  bool get isLoaded => _loaded;
  String? get error => _error;
  int get selectedDay => _selectedDay;

  List<ScheduleEntry> get entriesForSelectedDay =>
      _byDay[_selectedDay] ?? const [];

  int countForDay(int day) => _byDay[day]?.length ?? 0;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_loaded && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entries = await _repository.getScheduleEntries();
      _byDay.clear();
      for (final entry in entries) {
        _byDay.putIfAbsent(entry.weekday, () => []).add(entry);
      }
      _loaded = entries.isNotEmpty;
      if (entries.isEmpty) {
        _error = 'No recent releases found.';
      }
    } catch (e) {
      _error = 'Failed to load the weekly schedule.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDay(int day) {
    if (day == _selectedDay) return;
    _selectedDay = day;
    notifyListeners();
  }
}
