import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../views/auth/auth_sheet.dart';

/// Navigation drawer (opens from the right): sections on top, account pinned
/// to the bottom.
class AppDrawer extends StatelessWidget {
  final bool isDark;
  final String activeTab;
  final Function(String) onTabSelected;

  const AppDrawer({
    super.key,
    required this.isDark,
    required this.activeTab,
    required this.onTabSelected,
  });

  static const List<({String label, IconData icon})> _items = [
    (label: 'Home', icon: Icons.home_rounded),
    (label: 'All Series', icon: Icons.grid_view_rounded),
    (label: 'Weekly Schedule', icon: Icons.calendar_month_rounded),
    (label: 'Bookmarks', icon: Icons.bookmark_rounded),
    (label: 'Coin Shop', icon: Icons.monetization_on_rounded),
  ];

  void _select(BuildContext context, String label) {
    Navigator.of(context).pop();
    onTabSelected(label);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'lib/images/InkVaultPink.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 32,
                        height: 32,
                        color: AppColors.primary,
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                      children: const [
                        TextSpan(text: 'INK'),
                        TextSpan(
                          text: 'VAULT',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (auth.isLoggedIn)
                    _navTile(
                      context,
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  if (auth.isLoggedIn)
                    _navTile(
                      context,
                      label: 'History',
                      icon: Icons.history_rounded,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ..._items.map((item) => _navTile(
                        context,
                        label: item.label,
                        icon: item.icon,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      )),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Account pinned to the bottom
            if (auth.isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          backgroundImage:
                              (auth.user?.photoUrl.isNotEmpty ?? false)
                                  ? NetworkImage(auth.user!.photoUrl)
                                  : null,
                          child: (auth.user?.photoUrl.isEmpty ?? true)
                              ? Text(
                                  (auth.user?.displayName.isNotEmpty ?? false)
                                      ? auth.user!.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?.displayName.isNotEmpty == true
                                    ? auth.user!.displayName
                                    : 'Reader',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                auth.user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          Icons.monetization_on_rounded,
                          '${auth.coins} Coins',
                          Colors.amber,
                        ),
                        if (auth.isPremium)
                          _chip(
                            Icons.workspace_premium_rounded,
                            'Premium',
                            AppColors.primary,
                          ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await auth.signOut();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Log out'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log in to save bookmarks, unlock chapters and keep your coins.',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await showAuthSheet(context, isDark: isDark);
                        },
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text('Log In / Sign Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'InkVault • Powered by MangaDex',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final selected = activeTab == label;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : textSecondary,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: () => _select(context, label),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
