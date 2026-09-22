import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'providers/bookmark_provider.dart';
import 'providers/coin_provider.dart';
import 'providers/manga_provider.dart';
import 'providers/theme_provider.dart';
import 'views/bookmarks_view.dart';
import 'views/coin_shop_view.dart';
import 'views/directory_view.dart';
import 'views/home_view.dart';
import 'widgets/footer.dart';
import 'widgets/navbar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => MangaProvider()..loadTrendingManga(),
        ),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: const InkVaultApp(),
    ),
  );
}

class InkVaultApp extends StatefulWidget {
  const InkVaultApp({super.key});

  @override
  State<InkVaultApp> createState() => _InkVaultAppState();
}

class _InkVaultAppState extends State<InkVaultApp> {
  String _currentTab = 'Home';

  void _onTabSelected(String tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds MaterialApp whenever themeProvider calls notifyListeners()
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'InkVault',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Navbar(
                isDark: themeProvider.isDark,
                onToggleTheme: themeProvider.toggleTheme,
                activeTab: _currentTab,
                onTabSelected: _onTabSelected,
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCurrentView(themeProvider.isDark),
                  Footer(
                    isDark: themeProvider.isDark,
                    onTabSelected: _onTabSelected,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(bool isDark) {
    switch (_currentTab) {
      case 'Home':
        return HomeView(
          isDark: isDark,
          onTabSelected: _onTabSelected,
        );
      case 'All Series':
      case 'Directory':
        return DirectoryView(
          isDark: isDark,
          onTabSelected: _onTabSelected,
        );
      case 'Bookmarks':
      case 'Bookmarks (2)':
      case 'Library':
        return BookmarksView(
          isDark: isDark,
          onTabSelected: _onTabSelected,
        );
      case 'Coin Shop':
      case 'Get Coins':
        return CoinShopView(isDark: isDark);
      default:
        return HomeView(
          isDark: isDark,
          onTabSelected: _onTabSelected,
        );
    }
  }
}
