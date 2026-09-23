import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_config.dart';
import '../models/manga_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_auth_service.dart';

/// Result of a bookmark attempt, used by the UI to decide what to show.
enum BookmarkAction {
  added,
  removed,
  requiresLogin,
  requiresPremium,
  insufficientCoins,
  failed,
}

/// Owns the signed-in user's account state: auth, coins, premium, bookmarks
/// and unlocked chapters. All of it is persisted per-user in Firestore.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  final CloudinaryService _cloudinary;
  StreamSubscription<fb.User?>? _authSubscription;

  UserModel? _user;
  bool _isInitializing = true;
  bool _isBusy = false;
  String? _error;

  AuthProvider({
    FirebaseAuthService? authService,
    UserRepository? userRepository,
    CloudinaryService? cloudinary,
  })  : _authService = authService ?? FirebaseAuthService(),
        _userRepository = userRepository ?? UserRepository(),
        _cloudinary = cloudinary ?? CloudinaryService();

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isBusy => _isBusy;
  String? get error => _error;

  int get coins => _user?.coins ?? 0;
  bool get isPremium => _user?.isPremium ?? false;
  DateTime? get premiumUntil => _user?.premiumUntil;
  List<MangaModel> get bookmarks => _user?.bookmarks ?? const [];
  int get chaptersRead => _user?.chaptersRead ?? 0;
  List<MangaModel> get history => _user?.history ?? const [];
  DateTime? get joinedAt => _user?.joinedAt;

  bool isBookmarked(String mangaId) =>
      _user?.bookmarks.any((m) => m.id == mangaId) ?? false;

  void init() {
    try {
      _authSubscription ??=
          _authService.authStateChanges().listen(_onAuthChanged);
    } catch (e) {
      // Firebase may be unavailable (bad config / no Play services).
      _isInitializing = false;
      _error = 'Sign-in is unavailable on this device.';
      notifyListeners();
    }
  }

  Future<void> _onAuthChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      _user = await _userRepository.loadOrCreateUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
      );
      _error = null;
    } catch (e) {
      _error = 'Could not load your profile. Check your connection.';
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _run(() => _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(
      () => _authService.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error = _messageFor(e);
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // ---- Coins & premium ----

  Future<void> addCoins(int amount) async {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(coins: current.coins + amount);
    notifyListeners();
    await _persist();
  }

  Future<bool> spendCoins(int amount) async {
    final current = _user;
    if (current == null || current.coins < amount) return false;
    _user = current.copyWith(coins: current.coins - amount);
    notifyListeners();
    await _persist();
    return true;
  }

  /// Buys a premium pass (or extends it if already active).
  Future<bool> activatePremium() async {
    final current = _user;
    if (current == null || current.coins < AppConfig.premiumCost) return false;

    final DateTime base =
        current.isPremium ? current.premiumUntil! : DateTime.now();
    _user = current.copyWith(
      coins: current.coins - AppConfig.premiumCost,
      premiumUntil:
          base.add(const Duration(days: AppConfig.premiumDurationDays)),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  // ---- Bookmarks ----

  Future<BookmarkAction> toggleBookmark(MangaModel manga) async {
    final current = _user;
    if (current == null) return BookmarkAction.requiresLogin;

    final list = List<MangaModel>.from(current.bookmarks);
    final index = list.indexWhere((m) => m.id == manga.id);

    if (index >= 0) {
      list.removeAt(index);
      _user = current.copyWith(bookmarks: list);
      notifyListeners();
      await _persist();
      return BookmarkAction.removed;
    }

    // Free tier limit reached and not premium.
    if (!current.isPremium &&
        list.length >= AppConfig.freeBookmarkLimit) {
      return BookmarkAction.requiresPremium;
    }

    list.add(manga);
    _user = current.copyWith(bookmarks: list);
    notifyListeners();
    await _persist();
    return BookmarkAction.added;
  }

  /// Adds a bookmark beyond the free limit by paying coins.
  Future<BookmarkAction> purchaseBookmark(MangaModel manga) async {
    final current = _user;
    if (current == null) return BookmarkAction.requiresLogin;
    if (current.coins < AppConfig.extraBookmarkCost) {
      return BookmarkAction.insufficientCoins;
    }

    final list = List<MangaModel>.from(current.bookmarks)
      ..removeWhere((m) => m.id == manga.id)
      ..add(manga);
    _user = current.copyWith(
      coins: current.coins - AppConfig.extraBookmarkCost,
      bookmarks: list,
    );
    notifyListeners();
    await _persist();
    return BookmarkAction.added;
  }

  /// Buys premium and then saves the bookmark.
  Future<BookmarkAction> buyPremiumAndBookmark(MangaModel manga) async {
    final ok = await activatePremium();
    if (!ok) return BookmarkAction.insufficientCoins;
    return toggleBookmark(manga);
  }

  /// Removes a bookmark by id (used by the bookmarks grid's close button).
  Future<BookmarkAction> removeBookmark(String mangaId) async {
    final current = _user;
    if (current == null) return BookmarkAction.requiresLogin;
    if (!current.bookmarks.any((m) => m.id == mangaId)) {
      return BookmarkAction.removed;
    }

    final list = List<MangaModel>.from(current.bookmarks)
      ..removeWhere((m) => m.id == mangaId);
    _user = current.copyWith(bookmarks: list);
    notifyListeners();
    await _persist();
    return BookmarkAction.removed;
  }

  // ---- Chapter unlocking ----

  bool isChapterUnlocked(String chapterId) =>
      _user?.unlockedChapterIds.contains(chapterId) ?? false;

  /// Unlocks [chapterId]. Premium users unlock for free; otherwise [cost] coins
  /// are spent. Returns true when the chapter is unlocked afterwards.
  Future<bool> unlockChapter(String chapterId, int cost) async {
    final current = _user;
    if (current == null) return false;
    if (current.unlockedChapterIds.contains(chapterId)) return true;
    if (current.isPremium) {
      _user = current.copyWith(
        unlockedChapterIds: [...current.unlockedChapterIds, chapterId],
      );
      notifyListeners();
      await _persist();
      return true;
    }
    if (current.coins < cost) return false;

    _user = current.copyWith(
      coins: current.coins - cost,
      unlockedChapterIds: [...current.unlockedChapterIds, chapterId],
    );
    notifyListeners();
    await _persist();
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Uploads [file] to Cloudinary and stores it as the profile picture.
  Future<bool> updateProfileImage(XFile file) async {
    final current = _user;
    if (current == null) return false;

    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final String url = await _cloudinary.uploadProfileImage(file);
      _user = current.copyWith(photoUrl: url);
      notifyListeners();
      await _persist();
      try {
        await _authService.updatePhotoUrl(url);
      } catch (_) {
        // Firestore already has it; auth profile mirror is best-effort.
      }
      return true;
    } catch (e) {
      _error = 'Could not upload your image. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Waits (briefly) until the authenticated user profile has loaded.
  Future<void> waitForUser({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final end = DateTime.now().add(timeout);
    while (_user == null && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Records that the user opened a chapter (history + chaptersRead).
  Future<void> recordRead(MangaModel manga) async {    final current = _user;
    if (current == null) return;

    final list = [
      manga,
      ...current.history.where((m) => m.id != manga.id),
    ];
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }

    _user = current.copyWith(
      chaptersRead: current.chaptersRead + 1,
      history: list,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final current = _user;
    if (current == null) return;
    try {
      await _userRepository.saveUser(current);
    } catch (_) {
      // Non-fatal: local state stays; a later action retries the write.
    }
  }

  String _messageFor(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (6+ characters).';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'popup-closed-by-user':
      case 'cancelled':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
