// Basic unit tests for InkVault's models and configuration.

import 'package:flutter_test/flutter_test.dart';
import 'package:inkvault2/constants/app_config.dart';
import 'package:inkvault2/models/manga_model.dart';

void main() {
  group('MangaModel serialization', () {
    test('round-trips through toMap/fromMap', () {
      final original = MangaModel(
        id: 'abc',
        title: 'Solo Leveling',
        coverUrl: 'https://example.com/cover.jpg',
        category: 'ACTION',
        rating: '4.8',
        chapter: 'Ch. 200',
      );

      final restored = MangaModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.coverUrl, original.coverUrl);
      expect(restored.category, original.category);
      expect(restored.rating, original.rating);
      expect(restored.chapter, original.chapter);
    });
  });

  group('AppConfig', () {
    test('monetization rules match the product spec', () {
      expect(AppConfig.freeBookmarkLimit, 10);
      expect(AppConfig.extraBookmarkCost, 25);
      expect(AppConfig.premiumCost, 500);
      expect(AppConfig.premiumDurationDays, 30);
      expect(AppConfig.lockedChapterCount, 5);
      expect(AppConfig.chapterUnlockCost, 5);
      expect(AppConfig.maxDirectoryEntries, 1000);
    });
  });
}
