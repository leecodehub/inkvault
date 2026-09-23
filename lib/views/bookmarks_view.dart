import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../views/auth/auth_sheet.dart';
import '../widgets/genre_filter_sheet.dart';
import 'manga_detail_modal.dart';

class BookmarksView extends StatefulWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const BookmarksView({
    super.key,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  State<BookmarksView> createState() => _BookmarksViewState();
}

class _BookmarksViewState extends State<BookmarksView> {
  String _searchQuery = '';
  bool _sortAscending = true;
  List<String> _selectedGenres = <String>[];
  String? _hoveredBookmarkId;

  final ScrollController _genreScrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  static const List<String> _genres = [
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
    _genreScrollController.addListener(_updateGenreScrollBounds);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateGenreScrollBounds());
  }

  @override
  void dispose() {
    _genreScrollController.removeListener(_updateGenreScrollBounds);
    _genreScrollController.dispose();
    super.dispose();
  }

  void _updateGenreScrollBounds() {
    if (!mounted || !_genreScrollController.hasClients) return;
    final maxScroll = _genreScrollController.position.maxScrollExtent;
    final offset = _genreScrollController.offset;
    setState(() {
      _canScrollLeft = offset > 4;
      _canScrollRight = offset < maxScroll - 4;
    });
  }

  void _scrollGenres(double delta) {
    if (!_genreScrollController.hasClients) return;
    final target = (_genreScrollController.offset + delta)
        .clamp(0.0, _genreScrollController.position.maxScrollExtent);
    _genreScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openDetailModal(MangaModel manga) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaDetailModal(manga: manga, isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final bgColor =
        widget.isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: bgColor,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: !auth.isLoggedIn
            ? _buildLoginGate(context, textPrimary, textSecondary)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark_rounded,
                          color: AppColors.primary, size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saved Library (${auth.bookmarks.length})',
                          style: TextStyle(
                            fontSize: isMobileWidth(context) ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage and filter your saved manhwa collection',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Search + filter icon + anchored sort dropdown
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final search = Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search bookmarks...',
                            hintStyle:
                                TextStyle(color: textSecondary, fontSize: 13),
                            prefixIcon: Icon(Icons.search,
                                color: textSecondary, size: 18),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 42,
                              maxHeight: 42,
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(right: 12),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            search,
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _filterButton(
                                    label: _selectedGenres.isEmpty
                                        ? 'Genres'
                                        : 'Genres (${_selectedGenres.length})',
                                    active: _selectedGenres.isNotEmpty,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    onTap: _openGenreFilter,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _sortDropdown(
                                      cardBg, borderColor, textPrimary),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 320),
                                  child: search,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.filter_list_rounded,
                                  color: textSecondary, size: 20),
                              const SizedBox(width: 12),
                              _sortDropdown(cardBg, borderColor, textPrimary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: constraints.maxWidth > 560
                                  ? 560
                                  : constraints.maxWidth,
                              child: _genreCarousel(cardBg, borderColor,
                                  textPrimary, textSecondary),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  if (!auth.isPremium &&
                      auth.bookmarks.length >= 10) ...[
                    const SizedBox(height: 12),
                    _buildLimitBanner(context, auth, textSecondary),
                  ],

                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),

                  Builder(
                    builder: (context) {
                      final query = _searchQuery.toLowerCase();
                      final filtered = auth.bookmarks.where((item) {
                        final matchesSearch =
                            item.title.toLowerCase().contains(query);
                        final matchesGenre = _selectedGenres.isEmpty ||
                            _selectedGenres.any((g) =>
                                item.category.toLowerCase() ==
                                g.toLowerCase());
                        return matchesSearch && matchesGenre;
                      }).toList()
                        ..sort((a, b) => _sortAscending
                            ? a.title
                                .toLowerCase()
                                .compareTo(b.title.toLowerCase())
                            : b.title
                                .toLowerCase()
                                .compareTo(a.title.toLowerCase()));

                      if (filtered.isEmpty) {
                        return _buildEmpty(context, textSecondary);
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 190,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.62,
                        ),
                        itemBuilder: (context, index) {
                          return _buildBookmarkCard(
                            filtered[index],
                            textPrimary,
                            textSecondary,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _clearGenres() {
    setState(() => _selectedGenres = <String>[]);
  }

  Future<void> _openGenreFilter() async {
    final result = await showGenreFilterSheet(
      context,
      isDark: widget.isDark,
      allGenres: _genres,
      selected: _selectedGenres,
    );
    if (result == null) return;
    setState(() => _selectedGenres = result);
  }

  Widget _filterButton({
    required String label,
    required bool active,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? AppColors.primary : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded,
                size: 16,
                color: active ? AppColors.primary : textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _sortDropdown(Color cardBg, Color borderColor, Color textPrimary) {
    final value = _sortAscending ? 'Sort: A-Z' : 'Sort: Z-A';
    final options = _sortAscending
        ? const ['Sort: A-Z', 'Sort: Z-A']
        : const ['Sort: Z-A', 'Sort: A-Z'];

    return Container(
      height: 42,
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: cardBg,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(color: textPrimary, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          selectedItemBuilder: (context) => options
              .map((o) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      o,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
          items: options.map((option) {
            final isCurrent = option == value;
            return DropdownMenuItem<String>(
              value: option,
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
                  option,
                  style: TextStyle(
                    color: isCurrent ? AppColors.primary : textPrimary,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _sortAscending = v == 'Sort: A-Z');
            }
          },
        ),
      ),
    );
  }

  Widget _genreCarousel(
      Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        _genreChip('ALL', _selectedGenres.isEmpty, textPrimary, _clearGenres),
        Container(
          height: 22,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: borderColor,
        ),
        InkWell(
          onTap: _canScrollLeft ? () => _scrollGenres(-140) : null,
          child: Icon(
            Icons.chevron_left,
            color: textSecondary.withValues(alpha: _canScrollLeft ? 1 : 0.25),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            controller: _genreScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _genres.map((genre) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _genreChip(
                    genre,
                    _selectedGenres.contains(genre),
                    textPrimary,
                    () => _toggleGenre(genre),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: _canScrollRight ? () => _scrollGenres(140) : null,
          child: Icon(
            Icons.chevron_right,
            color: textSecondary.withValues(alpha: _canScrollRight ? 1 : 0.25),
          ),
        ),
      ],
    );
  }

  Widget _genreChip(
      String label, bool selected, Color textPrimary, VoidCallback onTap) {
    final borderColor = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textPrimary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginGate(
      BuildContext context, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              'Bookmarks need an account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in or sign up to save series and sync them everywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showAuthSheet(
                context,
                isDark: widget.isDark,
                reason: 'Log in to use your bookmarks.',
              ),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Log In / Sign Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitBanner(
      BuildContext context, AuthProvider auth, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free limit reached (${10}). Go Premium for unlimited bookmarks, or pay ${25} coins per extra bookmark.',
              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
            ),
          ),
          TextButton(
            onPressed: () => widget.onTabSelected('Coin Shop'),
            child: const Text('Get Premium'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, Color textSecondary) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline_rounded, size: 48, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              'No bookmarked series found.',
              style: TextStyle(color: textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () => widget.onTabSelected('All Series'),
              child: const Text('Browse Series'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(
      MangaModel item, Color textPrimary, Color textSecondary) {
    final hovered = _hoveredBookmarkId == item.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredBookmarkId = item.id),
      onExit: (_) => setState(() {
        if (_hoveredBookmarkId == item.id) _hoveredBookmarkId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
        child: InkWell(
          onTap: () => _openDetailModal(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF16181E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovered
                    ? AppColors.primary
                    : (widget.isDark
                        ? const Color(0xFF232730)
                        : const Color(0xFFE2E8F0)),
                width: hovered ? 1.4 : 1,
              ),
              boxShadow: hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: item.coverUrl.isEmpty
                          ? Container(
                              color: Colors.grey.shade900,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white38),
                            )
                          : Image.network(
                              item.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade900,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.white38),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white),
                        onPressed: () => context
                            .read<AuthProvider>()
                            .removeBookmark(item.id),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        item.ratingLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
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
      ),
    );
  }
}
