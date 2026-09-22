import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../providers/bookmark_provider.dart';
import '../providers/coin_provider.dart';
import '../repositories/manga_repository.dart';
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
  static const int _lockedChapterCount = 2;
  static const int _unlockCost = 5;

  final MangaRepository _repository = MangaRepository();

  List<ChapterModel> _chapters = [];
  bool _isLoadingChapters = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoadingChapters = true;
    });

    final List<ChapterModel> chapters =
        await _repository.getChapters(widget.manga.id);

    if (!mounted) return;
    setState(() {
      // Gate the most recent chapters behind coins; the feed is newest-first.
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

  void _handleUnlockChapter(
    BuildContext context,
    ChapterModel ch,
    CoinProvider coinProvider,
  ) {
    final isDark = widget.isDark;
    if (coinProvider.coins >= ch.coinCost) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text('Unlock Chapter ${ch.chapterNumber}?'),
          content:
              Text('Unlocking "${ch.title}" will cost ${ch.coinCost} coins.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final success = coinProvider.spendCoins(ch.coinCost);
                Navigator.pop(ctx);

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Unlocked Chapter ${ch.chapterNumber}!'),
                    ),
                  );
                  // Open Chapter in ReaderView after unlock
                  navigator.pop(); // Close sheet
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => ReaderView(
                        manga: widget.manga,
                        chapter: ch,
                        isDark: isDark,
                      ),
                    ),
                  );
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
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: const Text('Insufficient Coins'),
          content: Text(
            'You need ${ch.coinCost} coins to unlock Chapter ${ch.chapterNumber}. You currently have ${coinProvider.coins} coins.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    final isDark = widget.isDark;
    final coinProvider = Provider.of<CoinProvider>(context);
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final isBookmarked = bookmarkProvider.isBookmarked(manga.id);

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
          // Drag Handle bar
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          manga.coverUrl,
                          width: 110,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 110,
                            height: 160,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    manga.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    bookmarkProvider.toggleBookmark(manga);
                                  },
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
                                  manga.rating,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  manga.chapter,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Synopsis Text
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
                    'Follow the journey in this action-packed series. Dive deep into dungeons, unlock powerful skills, and rise to become the supreme hunter.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Chapter List Header
                  Text(
                    'Chapters (${_chapters.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chapter List Items
                  _buildChapterList(
                    coinProvider: coinProvider,
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
    required CoinProvider coinProvider,
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
              'No readable English chapters found.',
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
        return Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Chapter ${ch.chapterNumber}: ${ch.title}',
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
            trailing: ch.isLocked
                ? ElevatedButton.icon(
                    onPressed: () => _handleUnlockChapter(
                      context,
                      ch,
                      coinProvider,
                    ),
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
            onTap: ch.isLocked
                ? () => _handleUnlockChapter(
                      context,
                      ch,
                      coinProvider,
                    )
                : () => _openReader(ch),
          ),
        );
      },
    );
  }
}
