import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'auth/auth_sheet.dart';
import 'manga_detail_modal.dart';

/// Shows only what the user has recently read.
class HistoryView extends StatelessWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const HistoryView({
    super.key,
    required this.isDark,
    required this.onTabSelected,
  });

  void _openDetail(BuildContext context, MangaModel manga) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaDetailModal(manga: manga, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bgColor = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: bgColor,
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      child: Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: !auth.isLoggedIn
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 56, color: textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Log in to see your reading history',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => showAuthSheet(context,
                          isDark: isDark,
                          reason: 'Log in to see your reading history.'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Log In / Sign Up'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: AppColors.primary, size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reading History (${auth.history.length})',
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
                    'Series you recently opened',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),
                  if (auth.history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          'Nothing read yet.',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: auth.history
                          .map((m) => _historyRow(
                              context, m, cardBg, borderColor, textPrimary,
                              textSecondary))
                          .toList(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _historyRow(
    BuildContext context,
    MangaModel item,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
        onTap: () => _openDetail(context, item),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 54,
            child: item.coverUrl.isEmpty
                ? Container(color: Colors.grey.shade800)
                : Image.network(
                    item.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade800),
                  ),
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          item.chapter,
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
        ),
      ),
    );
  }
}
