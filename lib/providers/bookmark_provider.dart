import 'package:flutter/material.dart';
import '../models/manga_model.dart';

class BookmarkProvider extends ChangeNotifier {
  final List<MangaModel> _bookmarkedManga = [];

  List<MangaModel> get bookmarkedManga => _bookmarkedManga;

  bool isBookmarked(String id) {
    return _bookmarkedManga.any((manga) => manga.id == id);
  }

  void toggleBookmark(MangaModel manga) {
    final index = _bookmarkedManga.indexWhere((item) => item.id == manga.id);
    if (index >= 0) {
      _bookmarkedManga.removeAt(index);
    } else {
      _bookmarkedManga.add(manga);
    }
    notifyListeners();
  }
}
