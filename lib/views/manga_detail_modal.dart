import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/manga_repository.dart';
import 'auth/auth_sheet.dart';
import 'reader_view.dart';

class MangaDetailModal extends StatefulWidget {
  final MangaModel manga;
  final bool isDark;

  const MangaDetailModal({
    super.key,
    required this.manga,
    required this.isDark,
  });

  @override
  State<MangaDetailModal> createState() => _MangaDetailModalState();
}

class _MangaDetailModalState extends State<MangaDetailModal> {
  static const int _lockedChapterCount = AppConfig.lockedChapterCount;
  static const int _unlockCost = AppConfig.chapterUnlockCost;

  final MangaRepository _repository = MangaRepository();

  List<ChapterModel> _chapters = [];
  bool _isLoadingChapters = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoadingChapters = true);

    final List<ChapterModel> chapters =
        await _repository.getChapters(widget.manga.id);

    if (!mounted) return;
    setState(() {
      // Gate the newest chapters behind coins; the feed is newest-first.
      _chapters = [
        for (int i = 0; i < chapters.length; i++)
          chapters[i].copyWith(
            isLocked: i < _lockedChapterCount,
            coinCost: i < _lockedChapterCount ? _unlockCost : 0,
          ),
      ];
      _isLoadingChapters = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---- Bookmarks ----

  Future<void> _handleBookmark(AuthProvider auth) async {
    final result = await auth.toggleBookmark(widget.manga);
    if (!mounted) return;

    switch (result) {
      case BookmarkAction.added:
        _snack('Added to bookmarks.');
        break;
      case BookmarkAction.removed:
        _snack('Removed from bookmarks.');
        break;
      case BookmarkAction.requiresLogin:
        await showAuthSheet(
          context,
          isDark: widget.isDark,
          reason: 'Log in to save bookmarks.',
        );
        break;
      case BookmarkAction.requiresPremium:
        _showBookmarkLimitDialog(auth);
        break;
      case BookmarkAction.insufficientCoins:
        _snack('Not enough coins.');
        break;
      case BookmarkAction.failed:
        _snack('Could not update bookmark.');
        break;
    }
  }

  void _showBookmarkLimitDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Bookmark limit reached'),
        content: Text(
          'Free accounts can save up to ${AppConfig.freeBookmarkLimit} bookmarks.\n\n'
          'Get Premium for unlimited bookmarks, or pay '
          '${AppConfig.extraBookmarkCost} coins for this one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await auth.purchaseBookmark(widget.manga);
              if (!mounted) return;
              _snack(result == BookmarkAction.added
                  ? 'Bookmark added.'
                  : 'Not enough coins.');
            },
            child: Text('Pay ${AppConfig.extraBookmarkCost} coins'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await auth.buyPremiumAndBookmark(widget.manga);
              if (!mounted) return;
              _snack(result == BookmarkAction.added
                  ? 'Premium active — bookmark added!'
                  : 'Not enough coins for Premium.');
            },
            child: const Text(
              'Get Premium',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Chapters ----

  void _openReader(ChapterModel chapter) {
    final navigator = Navigator.of(context);
    navigator.pop(); // Close modal
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ReaderView(
          manga: widget.manga,
          chapter: chapter,
          isDark: widget.isDark,
        ),
      ),
    );
  }

  Future<void> _handleChapter(AuthProvider auth, ChapterModel ch) async {
    final bool needsLogin = !auth.isLoggedIn;
    final bool alreadyUnlocked =
        auth.isChapterUnlocked(ch.id) || auth.isPremium;
    final bool locked = ch.isLocked && !alreadyUnlocked;

    if (!locked) {
      if (ch.isLocked) {
        await auth.unlockChapter(ch.id, ch.coinCost);
      }
      if (!mounted) return;
      _openReader(ch);
      return;
    }

    if (needsLogin) {
      await showAuthSheet(
        context,
        isDark: widget.isDark,
        reason: 'Log in to unlock premium chapters.',
      );
      return;
    }

    if (auth.coins < ch.coinCost) {
      _showInsufficientDialog(auth, ch);
      return;
    }

    _confirmUnlock(auth, ch);
  }

  void _showInsufficientDialog(AuthProvider auth, ChapterModel ch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: const Text('Not enough coins'),
        content: Text(
          'You need ${ch.coinCost} coins to unlock Chapter ${ch.chapterNumber}. '
          'You have ${auth.coins}. Visit the Coin Shop from the menu to top up, '
          'or get Premium to read new chapters free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmUnlock(AuthProvider auth, ChapterModel ch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text('Unlock Chapter ${ch.chapterNumber}?'),
        content: Text(
          'Unlocking "${ch.title}" costs ${ch.coinCost} coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await auth.unlockChapter(ch.id, ch.coinCost);
              if (!mounted) return;
              if (ok) {
                _snack('Unlocked Chapter ${ch.chapterNumber}!');
                _openReader(ch);
              } else {
                _snack('Not enough coins.');
              }
            },
            child: Text(
              'Unlock (${ch.coinCost} Coins)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    final isDark = widget.isDark;
    final auth = context.watch<AuthProvider>();
    final isBookmarked = auth.isBookmarked(manga.id);

    final bg = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          manga.coverUrl,
                          width: 100,
                          height: 148,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 100,
                            height: 148,
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            child: Icon(Icons.book, color: textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    manga.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _handleBookmark(auth),
                                  tooltip: isBookmarked
                                      ? 'Remove bookmark'
                                      : 'Add bookmark',
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: isBookmarked
                                        ? AppColors.primary
                                        : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                manga.category,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  manga.ratingLabel,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Text(
                                    manga.chapter,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Premium hint
                  if (auth.isPremium)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Premium active — new chapters are free to read.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    'Synopsis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    manga.description.trim().isEmpty
                        ? 'No description available yet.'
                        : manga.description.trim(),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Chapters (${_chapters.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildChapterList(
                    auth: auth,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList({
    required AuthProvider auth,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    if (_isLoadingChapters) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              'No Korean chapters found.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadChapters,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chapters.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        final ch = _chapters[index];
        final unlocked = auth.isChapterUnlocked(ch.id) || auth.isPremium;
        final showLock = ch.isLocked && !unlocked;

        return Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Chapter ${ch.chapterNumber}: ${ch.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              ch.releaseDate,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            trailing: showLock
                ? ElevatedButton.icon(
                    onPressed: () => _handleChapter(auth, ch),
                    icon: const Icon(Icons.lock_rounded, size: 14),
                    label: Text('${ch.coinCost} Coins'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                  )
                : Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: textSecondary,
                  ),
            onTap: () => _handleChapter(auth, ch),
          ),
        );
      },
    );
  }
}
