import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/auth_provider.dart';
import '../providers/manga_provider.dart';
import '../widgets/manga_card.dart';
import 'auth/auth_sheet.dart';
import 'manga_detail_modal.dart';

class HomeView extends StatefulWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const HomeView({
    super.key,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const int _latestPageSize = 16;
  static const int _maxLatestPages = 5;

  final GlobalKey _latestReleasesKey = GlobalKey();
  int _latestPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MangaProvider>();
      provider.loadTrendingManga();
      provider.loadLatestReleases(limit: _latestPageSize * _maxLatestPages);
    });
  }

  void _openDetailModal(MangaModel manga) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaDetailModal(
        manga: manga,
        isDark: widget.isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: widget.isDark ? AppColors.darkBg : AppColors.lightBg,
      width: double.infinity,
      child: Consumer<MangaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SizedBox(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFEB164F)),
              ),
            );
          }

          if (provider.errorMessage != null || provider.trendingManga.isEmpty) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage ?? 'No webtoons available.',
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadTrendingManga(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB164F),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final mangaList = provider.trendingManga;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(screenWidth, mangaList),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'Trending Manhwa',
                  onViewAll: () => widget.onTabSelected('All Series'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 600 ? 16 : 24,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mangaList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 1200
                          ? 6
                          : screenWidth > 900
                              ? 4
                              : screenWidth > 600
                                  ? 3
                                  : 2,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: screenWidth < 600 ? 12 : 16,
                      mainAxisSpacing: screenWidth < 600 ? 12 : 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = mangaList[index];
                      return MangaCard(
                        title: item.title,
                        coverUrl: item.coverUrl,
                        category: item.category,
                        chapter: item.chapter,
                        rating: item.rating,
                        rank: index + 1,
                        isDark: widget.isDark,
                        onTap: () => _openDetailModal(item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                KeyedSubtree(
                  key: _latestReleasesKey,
                  child: _buildSectionHeader(
                    title: 'Latest Chapter Releases',
                    onViewAll: () => widget.onTabSelected('All Series'),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaginatedLatestReleases(screenWidth, provider),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onViewAll,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB164F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFFEB164F),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(double screenWidth, List<MangaModel> mangaList) {
    return _3DStackedHeroCarousel(
      mangaList: mangaList.take(9).toList(),
      isDark: widget.isDark,
      onCardTap: _openDetailModal,
    );
  }

  Widget _buildLatestReleasesGrid(
      double screenWidth, List<MangaModel> releases) {
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: releases.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 900 ? 2 : 1,
          mainAxisExtent: 160,
          crossAxisSpacing: isMobile ? 12 : 16,
          mainAxisSpacing: isMobile ? 12 : 16,
        ),
        itemBuilder: (context, index) {
          return LatestReleaseCard(
            item: releases[index],
            isDark: widget.isDark,
            onTap: () => _openDetailModal(releases[index]),
          );
        },
      ),
    );
  }

  void _goToLatestPage(int page) {
    if (page == _latestPage) return;
    setState(() => _latestPage = page);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _latestReleasesKey.currentContext;
      if (sectionContext == null) return;
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );
    });
  }

  Widget _buildPaginatedLatestReleases(
    double screenWidth,
    MangaProvider provider,
  ) {
    final releases = provider.latestReleases;

    if (provider.isLoadingLatest && releases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFEB164F)),
        ),
      );
    }

    if (releases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Text(
              provider.latestError ?? 'No recent releases found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<MangaProvider>().loadLatestReleases(
                    limit: _latestPageSize * _maxLatestPages,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB164F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final int totalPages = math.min(
      _maxLatestPages,
      (releases.length / _latestPageSize).ceil(),
    );
    final int currentPage = _latestPage.clamp(0, totalPages - 1);
    final int start = currentPage * _latestPageSize;
    final int end = math.min(start + _latestPageSize, releases.length);
    final List<MangaModel> pageItems = releases.sublist(start, end);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey<int>(currentPage),
            child: _buildLatestReleasesGrid(screenWidth, pageItems),
          ),
        ),
        const SizedBox(height: 24),
        _buildPaginationControls(totalPages, currentPage),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages, int currentPage) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageArrow(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 0,
          tooltip: 'Previous page',
          onTap: () => _goToLatestPage(currentPage - 1),
        ),
        const SizedBox(width: 8),
        for (int i = 0; i < totalPages; i++) ...[
          _buildPageNumber(i, currentPage),
          if (i != totalPages - 1) const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        _buildPageArrow(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages - 1,
          tooltip: 'Next page',
          onTap: () => _goToLatestPage(currentPage + 1),
        ),
      ],
    );
  }

  Widget _buildPageArrow({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = enabled
        ? (widget.isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary)
        : (widget.isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int index, int currentPage) {
    final bool isActive = index == currentPage;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveText =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _goToLatestPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEB164F) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFFEB164F) : border,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : inactiveText,
            ),
          ),
        ),
      ),
    );
  }
}

class _3DStackedHeroCarousel extends StatefulWidget {
  final List<MangaModel> mangaList;
  final bool isDark;
  final Function(MangaModel) onCardTap;

  const _3DStackedHeroCarousel({
    required this.mangaList,
    required this.isDark,
    required this.onCardTap,
  });

  @override
  State<_3DStackedHeroCarousel> createState() => _3DStackedHeroCarouselState();
}

class _3DStackedHeroCarouselState extends State<_3DStackedHeroCarousel>
    with SingleTickerProviderStateMixin {
  /// Fractional card position. The rounded value is the active card, so
  /// dragging spins the wheel continuously and momentum carries it forward.
  double _position = 0;
  int? _hoveredCardIndex;

  Animation<double>? _spinAnimation;
  late final AnimationController _spinController;

  int get _total => widget.mangaList.length;

  int _indexFor(num position) {
    if (_total == 0) return 0;
    return ((position.round() % _total) + _total) % _total;
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _spinController.addListener(() {
      final animation = _spinAnimation;
      if (animation != null && mounted) {
        setState(() => _position = animation.value);
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _stopSpin() {
    _spinController.stop();
    _spinAnimation = null;
  }

  void _spinTo(double target) {
    _spinAnimation = Tween<double>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
    _spinController.forward(from: 0);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleHeroBookmark(MangaModel manga) async {
    final auth = context.read<AuthProvider>();
    final result = await auth.toggleBookmark(manga);
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
        _snack('Bookmark limit reached. Visit the Coin Shop for Premium.');
        break;
      case BookmarkAction.insufficientCoins:
        _snack('Not enough coins.');
        break;
      case BookmarkAction.failed:
        _snack('Could not update bookmark.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mangaList.isEmpty) return const SizedBox.shrink();

    final activeManga = widget.mangaList[_indexFor(_position)];
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 24),
      height: isMobile ? 540 : 500,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            widget.isDark ? const Color(0xFF10141D) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0xFFEB164F).withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _stopSpin(),
          onHorizontalDragUpdate: (details) {
            final double extent = isMobile ? 80 : 70;
            setState(() => _position -= details.delta.dx / extent);
          },
          onHorizontalDragEnd: (details) {
            final double velocity = details.primaryVelocity ?? 0;
            // Projected landing point, including momentum from the fling.
            final double projected = _position - velocity / 2600;
            _spinTo(projected.roundToDouble());
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: ImageFiltered(
                    key: ValueKey<String>(activeManga.coverUrl),
                    imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(activeManga.coverUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            widget.isDark
                                ? Colors.black.withValues(alpha: 0.65)
                                : Colors.white.withValues(alpha: 0.52),
                            widget.isDark
                                ? BlendMode.darken
                                : BlendMode.lighten,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isDark
                          ? [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.75),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.88),
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.7),
                            ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 36),
                  child: isMobile
                      ? Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: _buildStackedCards(isMobile: true),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildDetailsOverlay(
                                activeManga,
                                isMobile: true,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child:
                                  Alignment.centerLeft == Alignment.centerLeft
                                      ? Container(
                                          alignment: Alignment.centerLeft,
                                          child: _buildDetailsOverlay(
                                            activeManga,
                                            isMobile: false,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 6,
                              child: Stack(
                                alignment: Alignment.center,
                                children: _buildStackedCards(isMobile: false),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsOverlay(MangaModel manga, {required bool isMobile}) {
    final auth = context.watch<AuthProvider>();
    final textColorPrimary =
        widget.isDark ? Colors.white : AppColors.lightTextPrimary;
    final textColorSecondary =
        widget.isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final borderDividerColor =
        widget.isDark ? Colors.white12 : AppColors.lightBorder;

    return SizedBox(
      height: isMobile ? null : 380,
      child: Column(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: isMobile ? 8 : 16),
          SizedBox(
            height: isMobile ? null : 90,
            child: Align(
              alignment: isMobile ? Alignment.center : Alignment.centerLeft,
              child: Text(
                manga.title,
                maxLines: 2,
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColorPrimary,
                  fontSize: isMobile ? 20 : (manga.title.length > 30 ? 30 : 38),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            manga.description.trim().isEmpty
                ? 'No description available yet.'
                : manga.description.trim(),
            maxLines: isMobile ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: textColorSecondary,
              fontSize: isMobile ? 12 : 15,
              height: 1.35,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderDividerColor),
                bottom: BorderSide(color: borderDividerColor),
              ),
            ),
            child: Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              spacing: isMobile ? 12 : 18,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFEB164F),
                      size: isMobile ? 15 : 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${manga.ratingLabel} / 10',
                      style: TextStyle(
                        color: const Color(0xFFEB164F),
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 11 : 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${manga.followsLabel} Follows',
                  style: TextStyle(
                    color: textColorSecondary,
                    fontSize: isMobile ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Row(
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onCardTap(manga),
                icon: Icon(
                  Icons.play_arrow_rounded,
                  size: isMobile ? 18 : 22,
                ),
                label: Text(
                  'READ ${manga.chapter.toUpperCase()}',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEB164F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 26,
                    vertical: isMobile ? 10 : 16,
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFEB164F).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _toggleHeroBookmark(manga),
                icon: Icon(
                  auth.isBookmarked(manga.id)
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  size: isMobile ? 20 : 24,
                  color: auth.isBookmarked(manga.id)
                      ? const Color(0xFFEB164F)
                      : (widget.isDark
                          ? Colors.white
                          : AppColors.lightTextPrimary),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: auth.isBookmarked(manga.id)
                      ? const Color(0xFFEB164F).withValues(alpha: 0.15)
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  padding: EdgeInsets.all(isMobile ? 8 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: auth.isBookmarked(manga.id)
                          ? const Color(0xFFEB164F)
                          : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStackedCards({required bool isMobile}) {
    final int total = _total;
    if (total == 0) return [];

    // Scale the stack down on very narrow phones so nothing is clipped.
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool compact = screenWidth < 380;
    final double cardWidth = isMobile ? (compact ? 92 : 115) : 210;
    final double cardHeight = isMobile ? (compact ? 136 : 170) : 320;
    final double step = isMobile ? (compact ? 30 : 50) : 46;
    final int span = isMobile ? 2 : 4;

    final int base = _position.floor();
    final List<Widget> cardWidgets = [];

    // Paint farthest cards first so the active (center) card stays on top.
    final List<int> slots = [
      for (int k = base - span; k <= base + span; k++) k,
    ]..sort((a, b) =>
        (b - _position).abs().compareTo((a - _position).abs()));

    for (final int k in slots) {
      final double d = k - _position;
      final int itemIndex = ((k % total) + total) % total;
      final item = widget.mangaList[itemIndex];
      final bool isActive = d.abs() < 0.5;
      final bool isHovered = _hoveredCardIndex == itemIndex;

      double scale = 1.0 - (d.abs() * 0.12);
      if (scale < 0.55) scale = 0.55;
      if (isHovered) scale += 0.05;
      double opacity = (1.0 - (d.abs() * 0.25)).clamp(0.2, 1.0);

      cardWidgets.add(
        Positioned(
          key: ValueKey<String>('hero_stack_${item.coverUrl}_$itemIndex'),
          right: null,
          top: isMobile
              ? (isActive ? 10 : 22.0)
              : (isActive ? 5 : 20.0 + (d.abs() * 6.0)),
          child: Transform.translate(
            offset: Offset(d * step, 0),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredCardIndex = itemIndex),
              onExit: (_) => setState(() => _hoveredCardIndex = null),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (isActive) {
                    widget.onCardTap(item);
                  } else {
                    _spinTo(k.toDouble());
                  }
                },
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isActive
                                ? const Color(0xFFEB164F).withValues(alpha: 0.5)
                                : Colors.black.withValues(
                                    alpha: widget.isDark ? 0.6 : 0.2,
                                  ),
                            blurRadius: isActive ? 20 : 10,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: isActive
                            ? Border.all(
                                color: const Color(0xFFEB164F),
                                width: 2.5,
                              )
                            : Border.all(
                                color: widget.isDark
                                    ? Colors.white24
                                    : Colors.black12,
                              ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: widget.isDark
                                    ? const Color(0xFF2A2E3D)
                                    : Colors.grey.shade300,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (!isActive)
                              Container(
                                color: widget.isDark
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return cardWidgets;
  }
}

class LatestReleaseCard extends StatefulWidget {
  final MangaModel item;
  final bool isDark;
  final VoidCallback onTap;

  const LatestReleaseCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<LatestReleaseCard> createState() => _LatestReleaseCardState();
}

class _LatestReleaseCardState extends State<LatestReleaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isDark
              ? (_isHovered ? const Color(0xFF1A1F2B) : const Color(0xFF121620))
              : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFEB164F).withValues(alpha: 0.5)
                : (widget.isDark
                    ? const Color(0xFF1E2430)
                    : AppColors.lightBorder),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFFEB164F).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.item.coverUrl,
                width: 85,
                height: 128,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 85,
                  height: 128,
                  color: widget.isDark
                      ? const Color(0xFF2A2E3D)
                      : Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.chapter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEB164F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.description.trim().isEmpty
                        ? 'No description available yet.'
                        : widget.item.description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: widget.isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        widget.item.ratingLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: widget.isDark
                            ? Colors.white54
                            : Colors.black38,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.item.followsLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              widget.isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// End of file.

