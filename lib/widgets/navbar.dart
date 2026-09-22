import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'theme_toggle.dart'; // Imports your custom Yin-Yang toggle widget

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String activeTab;
  final Function(String) onTabSelected;
  final int coinBalance;
  final ValueChanged<String>? onSearchChanged;

  const Navbar({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.activeTab,
    required this.onTabSelected,
    this.coinBalance = 200,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final showCompactSearch = screenWidth >= 750 && !isDesktop;

    final navBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Logo Badge
          _buildLogo(),
          const SizedBox(width: 24),

          // 2. Navigation Links (Desktop)
          if (isDesktop) ...[
            Row(
              children: [
                _navItem('Home'),
                _navItem('All Series'),
                _navItem('Weekly Schedule'),
                _navItem('Bookmarks (2)'),
                _navItem('Coin Shop'),
              ],
            ),
            const SizedBox(width: 20),
          ],

          // 3. Embedded Search Bar
          if (isDesktop || showCompactSearch)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildSearchBar(),
              ),
            )
          else
            const Spacer(),

          // 4. Right Action Items
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Integrated Custom Yin-Yang Theme Toggle Widget
              ThemeToggle(
                isDark: isDark,
                onToggle: onToggleTheme,
              ),
              const SizedBox(width: 10),
              _buildCoinBadge(),
              const SizedBox(width: 10),
              _buildLoginButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return InkWell(
      onTap: () => onTabSelected('Home'),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replaced icon with your custom image asset
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/images/InkVaultPink.png', // Check path matches pubspec.yaml
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  color: AppColors.primary,
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontFamily: 'Plus Jakarta Sans',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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
    );
  }

  Widget _navItem(String label) {
    final isSelected = activeTab == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onTabSelected(label),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Plus Jakarta Sans',
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 38,
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: searchBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 16,
            color: textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search 12+ titles...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinBadge() {
    final badgeBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 6),
          Text(
            '$coinBalance Coins',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.login_rounded, size: 14),
          SizedBox(width: 6),
          Text(
            'Log In',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
