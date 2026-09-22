import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../repositories/manga_repository.dart';

class ReaderView extends StatefulWidget {
  final MangaModel manga;
  final ChapterModel chapter;
  final bool isDark;

  const ReaderView({
    super.key,
    required this.manga,
    required this.chapter,
    required this.isDark,
  });

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final MangaRepository _repository = MangaRepository();
  late final ScrollController _scrollController;

  List<String> _pageImages = [];
  bool _isLoading = true;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadChapterImages();
  }

  Future<void> _loadChapterImages() async {
    setState(() {
      _isLoading = true;
      _pageImages = [];
    });

    // Full-quality pages by default; pass dataSaver: true for compressed pages.
    final List<String> images =
        await _repository.getChapterImages(widget.chapter.id);

    if (!mounted) return;
    setState(() {
      _pageImages = images;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            // 1. Webtoon Vertical Reader View
            _buildReaderContent(),

            // 2. Top Navigation Bar (Animated Visibility)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: _showOverlay
                  ? 0
                  : -(kToolbarHeight + MediaQuery.of(context).padding.top),
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.90),
                  border: const Border(
                    bottom: BorderSide(
                      color: Colors.white10,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.manga.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Chapter ${widget.chapter.chapterNumber}: ${widget.chapter.title}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // 3. Bottom Controls Overlay (Animated Visibility)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              bottom: _showOverlay ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                height: 64 + MediaQuery.of(context).padding.bottom,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.90),
                  border: const Border(
                    top: BorderSide(
                      color: Colors.white10,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : '${_pageImages.length} Pages',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_pageImages.isEmpty) {
      return _buildErrorState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: _showOverlay
            ? kToolbarHeight + MediaQuery.of(context).padding.top
            : 0,
        bottom: _showOverlay ? 80 : 0,
      ),
      itemCount: _pageImages.length,
      itemBuilder: (context, index) {
        return Image.network(
          _pageImages[index],
          fit: BoxFit.fitWidth,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final expectedBytes = loadingProgress.expectedTotalBytes;
            final loadedBytes = loadingProgress.cumulativeBytesLoaded;
            final progress = (expectedBytes != null && expectedBytes > 0)
                ? loadedBytes / expectedBytes
                : null;

            return Container(
              height: 400,
              color: const Color(0xFF121212),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: const Color(0xFF121212),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'Failed to load page',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load this chapter.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChapterImages,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
