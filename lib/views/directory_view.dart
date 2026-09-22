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
  final GlobalKey _topKey = GlobalKey();
  Timer? _searchDebounce;

  final List<String> _genres = [
    'All',
    'Action',
    'Fantasy',
    'Romance',
    'Drama',
    'Martial Arts',
    'Sci-Fi',
  ];

  @override
  void initState() {
    super.initState();
    // Load the first page of the full directory after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MangaProvider>().loadDirectoryPage(page: 0);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      // Reset to page 0 whenever the query changes.
      context.read<MangaProvider>().loadDirectoryPage(page: 0, query: value);
    });
  }

  void _selectGenre(String genre) {
    context.read<MangaProvider>().loadDirectoryPage(page: 0, genre: genre);
  }

  void _selectSort(String sortBy) {
    context.read<MangaProvider>().loadDirectoryPage(page: 0, sortBy: sortBy);
  }

  void _goToPage(int page) {
    context.read<MangaProvider>().loadDirectoryPage(page: page);

    // Glide back to the top of the directory after the new page renders.
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

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardBg =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bgColor =
        widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas;

    return Container(
      color: bgColor,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Consumer<MangaProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                  key: _topKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Series Directory',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      if (provider.directoryTotal > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${provider.directoryTotal} series • Page '
                          '${provider.directoryPage + 1} of '
                          '${provider.directoryTotalPages}',
                          style:
                              TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Filter Header
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search titles...',
                          hintStyle:
                              TextStyle(color: textSecondary, fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: textSecondary, size: 20),
                          filled: true,
                          fillColor: cardBg,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.directorySort,
                          dropdownColor: cardBg,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          icon:
                              Icon(Icons.sort, color: textSecondary, size: 18),
                          items: ['Popularity', 'Rating', 'Title']
                              .map((String val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
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

                const SizedBox(height: 16),

                // Genre Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _genres.map((genre) {
                      final isSelected = provider.directoryGenre == genre;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(genre),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: cardBg,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : (widget.isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) _selectGenre(genre);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Dynamic Card List with Provider State
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
                            onPressed: () =>
                                provider.loadDirectoryPage(
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
                      final isWide = constraints.maxWidth > 768;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.directoryManga.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 2 : 1,
                          mainAxisExtent: 140,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = provider.directoryManga[index];

                          return InkWell(
                            onTap: () => _openDetailModal(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Cover Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AspectRatio(
                                      aspectRatio: 0.7,
                                      child: Image.network(
                                        item.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade900,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details Section
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.category.toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.star_rounded,
                                                size: 14, color: Colors.amber),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
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
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 24),
                _buildPager(provider),
              ],
            ),
          );
        },
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
    final border =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
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
    final border =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveText = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

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
