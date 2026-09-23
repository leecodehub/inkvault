import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/manga_model.dart';
import '../providers/auth_provider.dart';
import '../repositories/manga_repository.dart';
import '../views/auth/auth_sheet.dart';
import '../views/manga_detail_modal.dart';
import 'theme_toggle.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final String activeTab;
  final Function(String) onTabSelected;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHistoryTap;

  const Navbar({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.activeTab,
    required this.onTabSelected,
    this.onMenuTap,
    this.onProfileTap,
    this.onHistoryTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MangaRepository _repository = MangaRepository();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectSuggestion(MangaModel manga) {
    _controller.clear();
    _focusNode.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaDetailModal(manga: manga, isDark: widget.isDark),
    );
  }

  Future<Iterable<MangaModel>> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const <MangaModel>[];
    }
    // Small debounce to be gentle on the API while typing.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || _controller.text.trim() != trimmed) {
      return const <MangaModel>[];
    }
    return _repository.searchManga(trimmed, limit: 8);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isMobile = screenWidth < 760;

    final navBg =
        widget.isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          _buildLogo(showText: !isMobile),
          if (!isMobile) const SizedBox(width: 24),
          if (isDesktop) ...[
            Row(
              children: [
                _navItem('Home'),
                _navItem('All Series'),
                _navItem('Weekly Schedule'),
                _navItem('Bookmarks'),
                _navItem('Coin Shop'),
              ],
            ),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
              child: _buildSearchBar(context),
            ),
          ),
          if (!isMobile) ...[
            _buildCoinBadge(context),
            const SizedBox(width: 10),
          ],
          if (!isMobile) ...[
            _buildAccountAction(context),
            const SizedBox(width: 10),
          ],
          ThemeToggle(
            isDark: widget.isDark,
            onToggle: widget.onToggleTheme,
          ),
          if (isMobile)
            IconButton(
              onPressed: widget.onMenuTap,
              icon: Icon(
                Icons.menu_rounded,
                color: widget.isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              tooltip: 'Menu',
            ),
        ],
      ),
    );
  }

  Widget _buildLogo({required bool showText}) {
    return InkWell(
      onTap: () => widget.onTabSelected('Home'),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/images/InkVaultPink.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                color: AppColors.primary,
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'Plus Jakarta Sans',
                  color: widget.isDark
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
        ],
      ),
    );
  }

  Widget _navItem(String label) {
    final isSelected = widget.activeTab == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => widget.onTabSelected(label),
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
                  : (widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = widget.isDark;
    final searchBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return RawAutocomplete<MangaModel>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (option) => option.title,
      optionsBuilder: (TextEditingValue value) => _search(value.text),
      onSelected: _selectSuggestion,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onFieldSubmitted(),
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(color: textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search titles...',
              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
              filled: true,
              fillColor: searchBg,
              isDense: true,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: textSecondary,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final double fallback = MediaQuery.of(context).size.width - 32;
            final double panelWidth =
                constraints.maxWidth.isFinite ? constraints.maxWidth : fallback;

            return Material(
              elevation: 8,
              color: surface,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: panelWidth,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No results found.',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return ListTile(
                            dense: true,
                            onTap: () => onSelected(item),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 30,
                                height: 42,
                                child: item.coverUrl.isEmpty
                                    ? Container(color: Colors.grey.shade800)
                                    : Image.network(
                                        item.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey.shade800),
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
                              style:
                                  TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          );
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoinBadge(BuildContext context) {
    final coins = context.watch<AuthProvider>().coins;
    final isDark = widget.isDark;
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
          const Icon(Icons.monetization_on_rounded,
              size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            '$coins Coins',
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

  Widget _buildAccountAction(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (!auth.isLoggedIn) {
      return ElevatedButton(
        onPressed: () => showAuthSheet(context, isDark: isDark),
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
            Text('Log In',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 44),
      color: surface,
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          context.read<AuthProvider>().signOut();
        } else if (value == 'profile') {
          widget.onProfileTap?.call();
        } else if (value == 'history') {
          widget.onHistoryTap?.call();
        } else if (value == 'premium') {
          context.read<AuthProvider>().activatePremium();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                backgroundImage: (auth.user?.photoUrl.isNotEmpty ?? false)
                    ? NetworkImage(auth.user!.photoUrl)
                    : null,
                child: (auth.user?.photoUrl.isEmpty ?? true)
                    ? Text(
                        (auth.user?.displayName.isNotEmpty ?? false)
                            ? auth.user!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      auth.user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: auth.isPremium
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      auth.isPremium ? 'PREMIUM ACTIVE' : 'PREMIUM',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  auth.isPremium
                      ? 'Enjoy ad-free, unlimited bookmarks and free new chapters.'
                      : 'Unlock unlimited bookmarks and free new-release chapters.',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                if (!auth.isPremium) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Get Started  ›',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'profile',
          child: _menuRow(Icons.person_outline_rounded, 'Profile',
              'View your public profile', textPrimary, textSecondary),
        ),
        PopupMenuItem(
          value: 'history',
          child: _menuRow(Icons.history_rounded, 'History',
              'Your reading history', textPrimary, textSecondary),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: _menuRow(Icons.logout_rounded, 'Sign out', null, textPrimary,
              textSecondary),
        ),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.primary,
        backgroundImage: (auth.user?.photoUrl.isNotEmpty ?? false)
            ? NetworkImage(auth.user!.photoUrl)
            : null,
        child: (auth.user?.photoUrl.isEmpty ?? true)
            ? Text(
                (auth.user?.displayName.isNotEmpty ?? false)
                    ? auth.user!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String title,
    String? subtitle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
