import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../providers/manga_provider.dart';
import '../repositories/manga_repository.dart';
import '../widgets/genre_filter_sheet.dart';
import 'manga_detail_modal.dart';
import 'reader_view.dart';

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

  final MangaRepository _repository = MangaRepository();
  final Map<String, List<ChapterModel>> _hoverChapters = {};
  final Set<String> _hoverLoading = {};

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

  void _toggleGenre(String genre) {
    final provider = context.read<MangaProvider>();
    final current = List<String>.from(provider.directoryGenres);
    if (current.contains(genre)) {
      current.remove(genre);
    } else {
      current.add(genre);
    }
    provider.loadDirectoryPage(page: 0, genres: current);
  }

  void _clearGenres() {
    context.read<MangaProvider>().loadDirectoryPage(page: 0, genres: const []);
    if (_genreScrollController.hasClients) {
      _genreScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openGenreFilter() async {
    final provider = context.read<MangaProvider>();
    final result = await showGenreFilterSheet(
      context,
      isDark: widget.isDark,
      allGenres: _genres,
      selected: provider.directoryGenres,
    );
    if (result == null) return;
    provider.loadDirectoryPage(page: 0, genres: result);
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

  void _openReader(MangaModel manga, ChapterModel chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderView(
          manga: manga,
          chapter: chapter,
          isDark: widget.isDark,
        ),
      ),
    );
  }

  Future<void> _ensureHoverChapters(String mangaId) async {
    if (_hoverChapters.containsKey(mangaId) || _hoverLoading.contains(mangaId)) {
      return;
    }
    _hoverLoading.add(mangaId);
    final chapters = await _repository.getChapters(mangaId);
    if (!mounted) return;
    setState(() {
      _hoverChapters[mangaId] = chapters.take(3).toList();
      _hoverLoading.remove(mangaId);
    });
  }

  Widget _chapterRow(
      MangaModel manga, ChapterModel chapter, Color textPrimary) {
    return InkWell(
      onTap: () => _openReader(manga, chapter),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.play_arrow_rounded,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Ch. ${chapter.chapterNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
          final selectedGenres = provider.directoryGenres;
          final currentSort = provider.directorySort;
          final sortOptions = _getOrderedSortItems(currentSort);

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

                      // Mobile Filter Bar: Genres button & Sort dropdown
                      Row(
                        children: [
                          Expanded(
                            child: _filterButton(
                              label: selectedGenres.isEmpty
                                  ? 'Genres'
                                  : 'Genres (${selectedGenres.length})',
                              active: selectedGenres.isNotEmpty,
                              inputFill: inputFill,
                              borderStyle: borderStyle,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onTap: _openGenreFilter,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _sortDropdown(
                              value: currentSort,
                              options: sortOptions,
                              inputFill: inputFill,
                              borderStyle: borderStyle,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onChanged: _selectSort,
                              expand: true,
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
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Series',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                          _sortDropdown(
                            value: currentSort,
                            options: sortOptions,
                            inputFill: inputFill,
                            borderStyle: borderStyle,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onChanged: _selectSort,
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
                        isSelected: selectedGenres.isEmpty,
                        onTap: _clearGenres,
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
                      Flexible(
                        child: SizedBox(
                          width: 480,
                          child: SingleChildScrollView(
                            controller: _genreScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _genres.map((genre) {
                                final isSelected =
                                    selectedGenres.contains(genre);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildGenreChip(
                                    label: genre,
                                    isSelected: isSelected,
                                    onTap: () => _toggleGenre(genre),
                                    cardBg: cardBg,
                                    textPrimary: textPrimary,
                                  ),
                                );
                              }).toList(),
                            ),
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
                          mainAxisExtent: isMobile ? 148 : 160,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          mainAxisSpacing: isMobile ? 12 : 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = provider.directoryManga[index];
                          final isHovered = _hoveredCardIndex == index;

                          return MouseRegion(
                            onEnter: (_) {
                              setState(() => _hoveredCardIndex = index);
                              _ensureHoverChapters(item.id);
                            },
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
                                                  item.ratingLabel,
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
                                            if (isHovered &&
                                                (_hoverChapters[item.id]
                                                        ?.isNotEmpty ??
                                                    false))
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: _hoverChapters[item.id]!
                                                    .map((ch) => _chapterRow(
                                                        item, ch, textPrimary))
                                                    .toList(),
                                              )
                                            else
                                              Text(
                                                item.description.trim().isEmpty
                                                    ? 'No description available yet.'
                                                    : item.description.trim(),
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

  Widget _filterButton({
    required String label,
    required bool active,
    required Color inputFill,
    required Color borderStyle,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : borderStyle),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: active ? AppColors.primary : textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : textPrimary,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _sortDropdown({
    required String value,
    required List<String> options,
    required Color inputFill,
    required Color borderStyle,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<String> onChanged,
    bool expand = false,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderStyle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: expand,
          isDense: true,
          dropdownColor: inputFill,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: textSecondary, size: 18),
          selectedItemBuilder: (context) => options
              .map((o) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sort: $o',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
          items: options.map((val) {
            final isCurrent = val == value;
            return DropdownMenuItem<String>(
              value: val,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sort: $val',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? AppColors.primary : textPrimary,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
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
