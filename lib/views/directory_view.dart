import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/manga_provider.dart';
import 'manga_detail_modal.dart';

class DirectoryView extends StatefulWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const DirectoryView({
    super.key,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  State<DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends State<DirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _genreScrollController = ScrollController();
  final GlobalKey _topKey = GlobalKey();
  Timer? _searchDebounce;

  int? _hoveredCardIndex;

  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  final List<String> _genres = [
    'Action',
    'Reincarnation',
    'Isekai',
    'System',
    'Murim',
    'Leveling',
    'Fantasy',
    'Romance',
    'Villainess',
    'Revenge',
    'Comedy',
    'Drama',
    'Martial Arts',
    'Sci-Fi',
    'Time Travel',
  ];

  @override
  void initState() {
    super.initState();
    _genreScrollController.addListener(_updateScrollBounds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MangaProvider>().loadDirectoryPage(page: 0);
      _updateScrollBounds();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _genreScrollController.removeListener(_updateScrollBounds);
    _genreScrollController.dispose();
    super.dispose();
  }

  void _updateScrollBounds() {
    if (!_genreScrollController.hasClients) return;
    final maxScroll = _genreScrollController.position.maxScrollExtent;
    final currentScroll = _genreScrollController.offset;

    setState(() {
      _canScrollLeft = currentScroll > 5;
      _canScrollRight = currentScroll < (maxScroll - 5);
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<MangaProvider>().loadDirectoryPage(page: 0, query: value);
    });
  }

  void _selectGenre(String genre) {
    context.read<MangaProvider>().loadDirectoryPage(page: 0, genre: genre);

    if (genre == 'All' && _genreScrollController.hasClients) {
      _genreScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectSort(String sortBy) {
    context.read<MangaProvider>().loadDirectoryPage(page: 0, sortBy: sortBy);
  }

  void _scrollGenreList(double offset) {
    if (!_genreScrollController.hasClients) return;
    final targetOffset = _genreScrollController.offset + offset;
    _genreScrollController.animateTo(
      targetOffset.clamp(0.0, _genreScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPage(int page) {
    context.read<MangaProvider>().loadDirectoryPage(page: page);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topContext = _topKey.currentContext;
      if (topContext == null) return;
      Scrollable.ensureVisible(
        topContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );
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

  List<String> _getOrderedSortItems(String currentSort) {
    if (currentSort == 'Title') {
      return ['Title', 'Popularity', 'Rating'];
    } else if (currentSort == 'Popularity') {
      return ['Popularity', 'Title', 'Rating'];
    } else if (currentSort == 'Rating') {
      return ['Rating', 'Popularity', 'Title'];
    }
    return ['Popularity', 'Rating', 'Title'];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    final textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardBg =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bgColor =
        widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas;

    final inputFill =
        widget.isDark ? const Color(0xFF131822) : const Color(0xFFF1F5F9);
    final borderStyle =
        widget.isDark ? const Color(0xFF1E2638) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Consumer<MangaProvider>(
        builder: (context, provider, child) {
          final selectedGenre =
              provider.directoryGenre.isEmpty ? 'All' : provider.directoryGenre;
          final currentSort = provider.directorySort;
          final sortOptions = _getOrderedSortItems(currentSort);

          final allGenresList = ['All', ..._genres];

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  // --- MOBILE LAYOUT ---
                  Column(
                    key: _topKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'All Series',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          if (provider.directoryTotal > 0)
                            Text(
                              '${provider.directoryTotal} series • Pg ${provider.directoryPage + 1}/${provider.directoryTotalPages}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Full-width Search Field
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search series...',
                            hintStyle:
                                TextStyle(color: textSecondary, fontSize: 13),
                            filled: true,
                            fillColor: inputFill,
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: borderStyle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mobile Filter Bar: Genre Dropdown & Sort Dropdown side-by-side
                      Row(
                        children: [
                          // Genre Dropdown
                          Expanded(
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: inputFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedGenre != 'All'
                                      ? AppColors.primary
                                      : borderStyle,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: allGenresList.contains(selectedGenre)
                                      ? selectedGenre
                                      : 'All',
                                  dropdownColor: inputFill,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(16),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                  items: allGenresList.map((String val) {
                                    final isCurrent = val == selectedGenre;
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(
                                        val == 'All' ? 'Genre: All' : val,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? AppColors.primary
                                              : textPrimary,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) _selectGenre(newVal);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Sort Dropdown
                          Expanded(
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: inputFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderStyle),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentSort,
                                  dropdownColor: inputFill,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(16),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                  items: sortOptions.map((String val) {
                                    final isCurrent = val == currentSort;
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(
                                        'Sort: $val',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? AppColors.primary
                                              : textPrimary,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) _selectSort(newVal);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  // --- DESKTOP LAYOUT ---
                  Row(
                    key: _topKey,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Series',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          if (provider.directoryTotal > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${provider.directoryTotal} series • Page '
                              '${provider.directoryPage + 1} of '
                              '${provider.directoryTotalPages}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 220,
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              style:
                                  TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search series...',
                                hintStyle: TextStyle(
                                    color: textSecondary, fontSize: 13),
                                filled: true,
                                fillColor: inputFill,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 0),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: borderStyle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary),
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.filter_list_rounded,
                            color: textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderStyle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentSort,
                                dropdownColor: inputFill,
                                borderRadius: BorderRadius.circular(16),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                ),
                                items: sortOptions.map((String val) {
                                  final isCurrent = val == currentSort;
                                  return DropdownMenuItem<String>(
                                    value: val,
                                    child: Text(
                                      val,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : textPrimary,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) _selectSort(newVal);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Desktop Horizontal Genre Carousel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildGenreChip(
                        label: 'ALL',
                        isSelected:
                            selectedGenre == 'All' || selectedGenre.isEmpty,
                        onTap: () => _selectGenre('All'),
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                      ),
                      Container(
                        height: 22,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: borderStyle,
                      ),
                      _buildNavArrow(
                        icon: Icons.chevron_left,
                        enabled: _canScrollLeft,
                        onTap: () => _scrollGenreList(-140),
                        iconColor: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 480,
                        child: SingleChildScrollView(
                          controller: _genreScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _genres.map((genre) {
                              final isSelected = selectedGenre == genre;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildGenreChip(
                                  label: genre,
                                  isSelected: isSelected,
                                  onTap: () => _selectGenre(genre),
                                  cardBg: cardBg,
                                  textPrimary: textPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildNavArrow(
                        icon: Icons.chevron_right,
                        enabled: _canScrollRight,
                        onTap: () => _scrollGenreList(140),
                        iconColor: textSecondary,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (provider.isLoadingDirectory)
                  const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (provider.directoryError != null)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.directoryError!,
                            style: TextStyle(color: textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => provider.loadDirectoryPage(
                                page: provider.directoryPage),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.directoryManga.isEmpty)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No series found matching criteria.',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1024) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.directoryManga.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: isMobile ? 128 : 140,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          mainAxisSpacing: isMobile ? 12 : 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = provider.directoryManga[index];
                          final isHovered = _hoveredCardIndex == index;

                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredCardIndex = index),
                            onExit: (_) =>
                                setState(() => _hoveredCardIndex = null),
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              transform: Matrix4.identity()
                                ..scale(isHovered ? 1.02 : 1.0),
                              transformAlignment: Alignment.center,
                              child: InkWell(
                                onTap: () => _openDetailModal(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHovered
                                          ? AppColors.primary
                                          : borderStyle,
                                      width: isHovered ? 0.8 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: AspectRatio(
                                          aspectRatio: 0.7,
                                          child: Image.network(
                                            item.coverUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: Colors.grey.shade900,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 10 : 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    item.category.toUpperCase(),
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.star_rounded,
                                                    size: 14,
                                                    color: Colors.amber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  item.rating,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              'Discover the latest story arcs and new chapter releases.',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.chapter,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Center(
                  child: _buildPager(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenreChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardBg,
    required Color textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? iconColor : iconColor.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildPager(MangaProvider provider) {
    final int totalPages = provider.directoryTotalPages;
    if (provider.directoryTotal <= 0 || totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final int current = provider.directoryPage;
    const int window = 1;
    final int start = math.max(0, current - window);
    final int end = math.min(totalPages - 1, current + window);

    final List<Widget> items = [
      _buildArrow(
        icon: Icons.chevron_left_rounded,
        enabled: current > 0,
        tooltip: 'Previous page',
        onTap: () => _goToPage(current - 1),
      ),
    ];

    if (start > 0) {
      items.add(_buildPageButton(0, current));
      if (start > 1) items.add(_buildEllipsis());
    }
    for (int i = start; i <= end; i++) {
      items.add(_buildPageButton(i, current));
    }
    if (end < totalPages - 1) {
      if (end < totalPages - 2) items.add(_buildEllipsis());
      items.add(_buildPageButton(totalPages - 1, current));
    }

    items.add(
      _buildArrow(
        icon: Icons.chevron_right_rounded,
        enabled: current < totalPages - 1,
        tooltip: 'Next page',
        onTap: () => _goToPage(current + 1),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildArrow({
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

  Widget _buildPageButton(int index, int currentPage) {
    final bool isActive = index == currentPage;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveText =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _goToPage(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? AppColors.primary : border),
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

  Widget _buildEllipsis() {
    final color = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Text('…', style: TextStyle(color: color, fontSize: 14)),
      ),
    );
  }
}
