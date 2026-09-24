import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:inkvault2/firebase_options.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/manga_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';
import 'views/bookmarks_view.dart';
import 'views/coin_shop_view.dart';
import 'views/directory_view.dart';
import 'views/home_view.dart';
import 'views/history_view.dart';
import 'views/profile_view.dart';
import 'views/schedule_view.dart';
import 'views/splash_view.dart';
import 'widgets/app_drawer.dart';
import 'widgets/footer.dart';
import 'widgets/navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface widget build errors instead of showing a blank/black screen.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: const Color(0xFF0B0E14),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Text(
                'InkVault hit an error:\n\n${details.exception}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
      );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    // Never let Firebase init block the UI from starting.
    debugPrint('Firebase.initializeApp failed: $e\n$s');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(
          create: (_) => MangaProvider()..loadTrendingManga(),
        ),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentTab = 'Home';

  /// Show the animated splash on mobile only — never on web.
  bool _showSplash = !kIsWeb;

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
        final isDark = themeProvider.isDark;

        return MaterialApp(
          title: 'InkVault',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: _showSplash
                ? SplashView(
                    key: const ValueKey('splash'),
                    onFinished: () => setState(() => _showSplash = false),
                  )
                : KeyedSubtree(
                    key: const ValueKey('home'),
                    child: _buildHomeScaffold(isDark, themeProvider),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHomeScaffold(bool isDark, ThemeProvider themeProvider) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Navbar(
          isDark: isDark,
          onToggleTheme: themeProvider.toggleTheme,
          activeTab: _currentTab,
          onTabSelected: _onTabSelected,
          onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          onProfileTap: () => _onTabSelected('Profile'),
          onHistoryTap: () => _onTabSelected('History'),
        ),
      ),
      endDrawer: AppDrawer(
        isDark: isDark,
        activeTab: _currentTab,
        onTabSelected: _onTabSelected,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCurrentView(isDark),
              Footer(
                isDark: isDark,
                onTabSelected: _onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(bool isDark) {
    switch (_currentTab) {
      case 'Home':
        return HomeView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'All Series':
      case 'Directory':
        return DirectoryView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'Weekly Schedule':
      case 'Schedule':
        return ScheduleView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'Bookmarks':
      case 'Bookmarks (2)':
      case 'Library':
        return BookmarksView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'Profile':
        return ProfileView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'History':
        return HistoryView(isDark: isDark, onTabSelected: _onTabSelected);
      case 'Coin Shop':
      case 'Get Coins':
        return CoinShopView(isDark: isDark);
      default:
        return HomeView(isDark: isDark, onTabSelected: _onTabSelected);
    }
  }
}
