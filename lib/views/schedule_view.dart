import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../models/schedule_entry.dart';
import '../providers/schedule_provider.dart';
import '../utils/responsive.dart';
import 'manga_detail_modal.dart';

class ScheduleView extends StatefulWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const ScheduleView({
    super.key,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  static const List<String> _labels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  String? _hoveredDay;
  String? _hoveredEntryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().load();
    });
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }
    if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  void _openEntry(ScheduleEntry entry) {
    final manga = MangaModel(
      id: entry.mangaId,
      title: entry.title,
      coverUrl: entry.coverUrl,
      category: 'MANHWA',
      rating: '—',
      chapter: entry.chapter.isEmpty ? 'Latest' : 'Ch. ${entry.chapter}',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaDetailModal(manga: manga, isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final bool mobile = isMobileWidth(context);

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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: EdgeInsets.all(pagePadding(context)),
            child: Column(
              crossAxisAlignment:
                  mobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                // Header (centered on web, left on mobile)
                Row(
                  mainAxisAlignment:
                      mobile ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 26),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Weekly Schedule',
                        textAlign: mobile ? TextAlign.left : TextAlign.center,
                        style: TextStyle(
                          fontSize: mobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.load(force: true),
                      icon: Icon(Icons.refresh_rounded, color: textSecondary),
                    ),
                  ],
                ),
                Text(
                  'Recent chapter releases for each day of the week',
                  textAlign: mobile ? TextAlign.left : TextAlign.center,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 16),

                // Day selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final selected = provider.selectedDay == day;
                      final count = provider.countForDay(day);
                      return Padding(
                        padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
                        child: _dayButton(
                          label: _labels[i],
                          count: count,
                          selected: selected,
                          onTap: () => provider.selectDay(day),
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Text(provider.error!,
                              style: TextStyle(color: textSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => provider.load(force: true),
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
                else
                  ..._buildDayContent(
                    provider.entriesForSelectedDay,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDayContent(
    List<ScheduleEntry> entries, {
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Center(
            child: Text(
              'No releases recorded for this day.',
              style: TextStyle(color: textSecondary),
            ),
          ),
        ),
      ];
    }

    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 640 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 96,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _entryCard(
                entry,
                highlighted:
                    DateTime.now().difference(entry.publishAt).inDays <= 7,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            },
          );
        },
      ),
      const SizedBox(height: 40),
    ];
  }

  Widget _entryCard(
    ScheduleEntry entry, {
    required bool highlighted,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hovered = _hoveredEntryId == entry.mangaId;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredEntryId = entry.mangaId),
      onExit: (_) => setState(() {
        if (_hoveredEntryId == entry.mangaId) _hoveredEntryId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        child: InkWell(
          onTap: () => _openEntry(entry),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (highlighted || hovered)
                    ? AppColors.primary
                    : borderColor,
                width: (highlighted || hovered) ? 1.4 : 1,
              ),
              boxShadow: hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 74,
                child: entry.coverUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white38, size: 18),
                      )
                    : Image.network(
                        entry.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.white38, size: 18),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.chapter.isEmpty
                        ? 'Latest chapter'
                        : 'Chapter ${entry.chapter}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(entry.publishAt),
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _dayButton({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final hovered = _hoveredDay == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredDay = label),
      onExit: (_) => setState(() {
        if (_hoveredDay == label) _hoveredDay = null;
      }),
      child: AnimatedScale(
        scale: hovered ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : (widget.isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (hovered
                        ? AppColors.primary.withValues(alpha: 0.7)
                        : borderColor),
              ),
              boxShadow: hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.primary,
                ),
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
