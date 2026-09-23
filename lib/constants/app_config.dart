/// Central place for the app's monetization and content rules.
class AppConfig {
  AppConfig._();

  // ---- Bookmarks ----
  /// How many bookmarks a free (non-premium) account can save.
  static const int freeBookmarkLimit = 10;

  /// Coins charged for each bookmark added beyond [freeBookmarkLimit].
  static const int extraBookmarkCost = 25;

  // ---- Premium ----
  /// Coins charged for a premium pass.
  static const int premiumCost = 500;

  /// How long a premium pass lasts.
  static const int premiumDurationDays = 30;

  // ---- Chapters ----
  /// The newest N chapters are locked behind coins.
  static const int lockedChapterCount = 5;

  /// Coins required to unlock one locked chapter.
  static const int chapterUnlockCost = 5;

  // ---- Directory ----
  /// Hard cap on how many series the All Series directory exposes.
  static const int maxDirectoryEntries = 1000;

  /// Directory page size (MangaDex caps `limit` at 100).
  static const int directoryPageSize = 40;
}
