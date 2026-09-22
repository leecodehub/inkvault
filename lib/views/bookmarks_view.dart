import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../services/mangadex_api_client.dart';
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
  final MangaDexApiClient _apiClient = MangaDexApiClient();

  List<MangaModel> _bookmarkedManga = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _sortBy = 'Update: Newest (DESC)';

  final List<String> _statuses = [
    'All Status',
    'Reading',
    'Completed',
    'On Hold'
  ];
  final List<String> _sortOptions = [
    'Update: Newest (DESC)',
    'Update: Oldest (ASC)',
    'Rating: High to Low',
    'Title: A-Z'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    try {
      final results = await _apiClient.fetchPopularManga(limit: 2);
      setState(() {
        _bookmarkedManga = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeBookmark(String id) {
    setState(() {
      _bookmarkedManga.removeWhere((item) => item.id == id);
    });
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
    final borderTileColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final filteredList = _bookmarkedManga.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      color: bgColor,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title Header & Control Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;
                return isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderTitle(textPrimary, textSecondary),
                          const SizedBox(height: 16),
                          _buildControls(cardBg, borderTileColor, textPrimary,
                              textSecondary),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeaderTitle(textPrimary, textSecondary),
                          _buildControls(cardBg, borderTileColor, textPrimary,
                              textSecondary),
                        ],
                      );
              },
            ),

            const SizedBox(height: 16),
            Divider(
                color: borderTileColor.withValues(alpha: 0.5), thickness: 1),
            const SizedBox(height: 28),

            // Card Grid Display
            if (_isLoading)
              const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (filteredList.isEmpty)
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline_rounded,
                          size: 48, color: textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No bookmarked series found.',
                        style: TextStyle(color: textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () => widget.onTabSelected('directory'),
                        child: const Text('Browse Directory'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: filteredList.map((item) {
                  return _buildBookmarkCard(item, textPrimary, textSecondary);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Header Title Component
  Widget _buildHeaderTitle(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark_rounded,
                color: AppColors.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              'Saved Library (${_bookmarkedManga.length})',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and filter your saved manhwa collection',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  // Filter and Search Controls Component
  Widget _buildControls(
      Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Input Bar
        SizedBox(
          width: 200,
          height: 38,
          child: TextField(
            style: TextStyle(color: textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search bookmarks...',
              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              filled: true,
              fillColor: cardBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),

        Icon(Icons.filter_list_rounded, size: 20, color: textSecondary),

        // Status Popup Menu
        PopupMenuButton<String>(
          offset: const Offset(0, 42),
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          onSelected: (String newVal) {
            setState(() => _selectedStatus = newVal);
          },
          itemBuilder: (BuildContext context) {
            // Place selected item first, followed by remaining options
            final remainingItems =
                _statuses.where((s) => s != _selectedStatus).toList();
            final orderedList = [_selectedStatus, ...remainingItems];

            return orderedList.map((String val) {
              final isSelected = val == _selectedStatus;
              return PopupMenuItem<String>(
                value: val,
                height: 36,
                child: Text(
                  val,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedStatus,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: textSecondary, size: 18),
              ],
            ),
          ),
        ),

        // Sort Order Popup Menu
        PopupMenuButton<String>(
          offset: const Offset(0, 42),
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          onSelected: (String newVal) {
            setState(() => _sortBy = newVal);
          },
          itemBuilder: (BuildContext context) {
            // Place selected item first, followed by remaining options
            final remainingItems =
                _sortOptions.where((s) => s != _sortBy).toList();
            final orderedList = [_sortBy, ...remainingItems];

            return orderedList.map((String val) {
              final isSelected = val == _sortBy;
              return PopupMenuItem<String>(
                value: val,
                height: 36,
                child: Text(
                  val,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortBy,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Individual Vertical Manga Card Container Component
  Widget _buildBookmarkCard(
      MangaModel item, Color textPrimary, Color textSecondary) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MangaDetailModal(
            manga: item,
            isDark: widget.isDark,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF16181E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark
                ? const Color(0xFF232730)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.network(
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

                // Remove Action Button (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
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
                      onPressed: () => _removeBookmark(item.id),
                    ),
                  ),
                ),

                // Chapter Badge Overlay (Bottom Left)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.chapter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Content Metadata Bottom Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        item.rating,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '5 mins ago',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
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
      ),
    );
  }
}
