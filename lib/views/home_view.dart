import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/manga_provider.dart';
import '../widgets/manga_card.dart';
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
  // Latest Chapter Releases pagination: 16 cards per page, 5 pages max.
  static const int _latestPageSize = 16;
  static const int _maxLatestPages = 5;

  final GlobalKey _latestReleasesKey = GlobalKey();
  int _latestPage = 0;

  @override
  void initState() {
    super.initState();
    // Fetch trending data using Provider after the initial frame
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
          final featuredManga = mangaList.first;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(screenWidth, featuredManga),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  title: 'Trending Manhwa',
                  onViewAll: () => widget.onTabSelected('All Series'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
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
                const SizedBox(height: 48),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  fontSize: 18,
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

  Widget _buildHeroBanner(double screenWidth, MangaModel featured) {
    final isCompact = screenWidth < 800;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E102A), Color(0xFF0F0814)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEB164F).withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEB164F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '#1 FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    featured.rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          featured.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Explore this featured release now on MangaDex.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openDetailModal(featured),
                              icon:
                                  const Icon(Icons.menu_book_rounded, size: 16),
                              label: Text('Read ${featured.chapter}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEB164F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.bookmark_border_rounded,
                                  size: 16),
                              label: const Text('Bookmark'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 150,
                          height: 210,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              featured.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2A2E3D),
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white38),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReleasesGrid(
      double screenWidth, List<MangaModel> releases) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: releases.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 900 ? 2 : 1,
          mainAxisExtent: 160,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
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

  /// Switches to [page] and glides the Latest Releases section back to the top.
  void _goToLatestPage(int page) {
    if (page == _latestPage) return;
    setState(() => _latestPage = page);

    // Wait for the new page to lay out, then animate the section to the top.
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

    // Cap at 5 pages regardless of how many releases came back.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _HoverableChapterRow(
                    chapterText: '${widget.item.chapter} - Latest Chapter',
                    timeAgo: '1 day ago',
                    isHighlighted: true,
                    isDark: widget.isDark,
                    onTap: widget.onTap,
                  ),
                  _HoverableChapterRow(
                    chapterText: 'Chapter Previous',
                    timeAgo: 'last week',
                    isHighlighted: false,
                    isDark: widget.isDark,
                    onTap: widget.onTap,
                  ),
                  _HoverableChapterRow(
                    chapterText: 'Chapter Older',
                    timeAgo: '2 weeks ago',
                    isHighlighted: false,
                    isDark: widget.isDark,
                    onTap: widget.onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableChapterRow extends StatefulWidget {
  final String chapterText;
  final String timeAgo;
  final bool isHighlighted;
  final bool isDark;
  final VoidCallback onTap;

  const _HoverableChapterRow({
    required this.chapterText,
    required this.timeAgo,
    required this.isHighlighted,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HoverableChapterRow> createState() => _HoverableChapterRowState();
}

class _HoverableChapterRowState extends State<_HoverableChapterRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isHighlighted || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: activeColor
                ? const Color(0xFFEB164F).withValues(alpha: 0.12)
                : (widget.isDark
                    ? const Color(0xFF161A24)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activeColor
                  ? const Color(0xFFEB164F).withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.chapterText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        activeColor ? FontWeight.w600 : FontWeight.normal,
                    color: activeColor
                        ? const Color(0xFFEB164F)
                        : (widget.isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              Text(
                widget.timeAgo,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
