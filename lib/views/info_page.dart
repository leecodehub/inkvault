import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Lightweight in-app placeholder page for footer/menu links
/// (About, Feedback, Help, Terms, Privacy, Contact).
class InfoPage extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;

  const InfoPage({
    super.key,
    required this.title,
    required this.body,
    required this.isDark,
  });

  static void open(
    BuildContext context, {
    required String title,
    required String body,
    required bool isDark,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InfoPage(title: title, body: body, isDark: isDark),
      ),
    );
  }

  /// Convenience: opens the standard content for a known [key].
  static void openKey(
    BuildContext context,
    String key, {
    required bool isDark,
  }) {
    open(context, title: key, body: contentFor(key), isDark: isDark);
  }

  static String contentFor(String key) {
    switch (key) {
      case 'About':
        return 'InkVault is a modern manhwa reader powered by the public '
            'MangaDex API.\n\nBrowse trending and recently updated Korean '
            'webtoons, build your personal library, and read chapter-by-chapter '
            'with a clean, distraction-free reader.\n\n'
            'This is a demo application built for learning purposes.';
      case 'Feedback':
        return 'We would love to hear what you think!\n\n'
            'Send suggestions, bug reports, or feature requests to '
            'feedback@inkvault.app and we will take a look.';
      case 'Help':
        return 'Frequently asked questions:\n\n'
            '• Why do some chapters need coins?\n'
            '  The 5 most recent chapters of each series are premium unlocks.\n\n'
            '• How many bookmarks can I save for free?\n'
            '  Up to 10. Buy Premium or spend coins for more.\n\n'
            '• Where do the images come from?\n'
            '  All content is served live from the MangaDex API.';
      case 'Terms':
        return 'By using InkVault you agree to use it respectfully and only '
            'for personal, non-commercial reading.\n\n'
            'All manga, covers, and chapter content belong to their respective '
            'rights holders and are provided through the MangaDex API.';
      case 'Privacy':
        return 'We store only what is needed to run your account: your email, '
            'display name, coin balance, bookmarks, and unlocked chapters.\n\n'
            'This data lives in Google Cloud Firestore and is never sold or '
            'shared with third parties.';
      case 'Contact':
        return 'Reach us at:\n\n'
            'Email: hello@inkvault.app\n'
            'Feedback: feedback@inkvault.app\n\n'
            'Or use the social links in the footer.';
      case 'Advertise':
        return 'Want to advertise on InkVault?\n\n'
            'We offer banner placements and sponsored series spotlights.\n\n'
            'Get in touch at ads@inkvault.app and we will share our media kit.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(fontSize: 14, height: 1.5, color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
