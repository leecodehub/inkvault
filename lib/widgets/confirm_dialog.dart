import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A themed confirmation dialog used to guard actions that would otherwise
/// happen from an accidental tap (purchases, logging out, ...).
///
/// Returns true only when the user explicitly confirms; false when they
/// cancel or dismiss the dialog.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required bool isDark,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final textPrimary =
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final textSecondary =
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 13, height: 1.45, color: textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel, style: TextStyle(color: textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
