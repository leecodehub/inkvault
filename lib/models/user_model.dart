import 'package:cloud_firestore/cloud_firestore.dart';
import 'manga_model.dart';

/// A user's account data, mirrored from `users/{uid}` in Firestore.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int coins;
  final DateTime? premiumUntil;
  final List<MangaModel> bookmarks;
  final List<String> unlockedChapterIds;
  final int chaptersRead;
  final List<MangaModel> history;
  final DateTime? joinedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.coins,
    required this.premiumUntil,
    required this.bookmarks,
    required this.unlockedChapterIds,
    required this.chaptersRead,
    required this.history,
    required this.joinedAt,
  });

  bool get isPremium =>
      premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  int get bookmarkCount => bookmarks.length;

  static const int initialCoins = 100;

  factory UserModel.initial({
    required String uid,
    required String email,
    String displayName = '',
    String photoUrl = '',
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      coins: initialCoins,
      premiumUntil: null,
      bookmarks: const [],
      unlockedChapterIds: const [],
      chaptersRead: 0,
      history: const [],
      joinedAt: DateTime.now(),
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    List<MangaModel> parseList(dynamic raw) {
      return ((raw as List?) ?? [])
          .whereType<Map>()
          .map((b) => MangaModel.fromMap(Map<String, dynamic>.from(b)))
          .toList();
    }

    final premiumRaw = map['premiumUntil'];
    final DateTime? premiumUntil =
        premiumRaw is Timestamp ? premiumRaw.toDate() : null;
    final createdRaw = map['createdAt'];
    final DateTime? joinedAt =
        createdRaw is Timestamp ? createdRaw.toDate() : null;

    return UserModel(
      uid: uid,
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      coins: (map['coins'] is int) ? map['coins'] as int : initialCoins,
      premiumUntil: premiumUntil,
      bookmarks: parseList(map['bookmarks']),
      unlockedChapterIds: ((map['unlockedChapters'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      chaptersRead:
          (map['chaptersRead'] is int) ? map['chaptersRead'] as int : 0,
      history: parseList(map['history']),
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coins': coins,
      'premiumUntil':
          premiumUntil == null ? null : Timestamp.fromDate(premiumUntil!),
      'bookmarks': bookmarks.map((b) => b.toMap()).toList(),
      'unlockedChapters': unlockedChapterIds,
      'chaptersRead': chaptersRead,
      'history': history.map((b) => b.toMap()).toList(),
      'createdAt': joinedAt == null ? null : Timestamp.fromDate(joinedAt!),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    int? coins,
    DateTime? premiumUntil,
    bool clearPremium = false,
    List<MangaModel>? bookmarks,
    List<String>? unlockedChapterIds,
    int? chaptersRead,
    List<MangaModel>? history,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      premiumUntil: clearPremium ? null : (premiumUntil ?? this.premiumUntil),
      bookmarks: bookmarks ?? this.bookmarks,
      unlockedChapterIds: unlockedChapterIds ?? this.unlockedChapterIds,
      chaptersRead: chaptersRead ?? this.chaptersRead,
      history: history ?? this.history,
      joinedAt: joinedAt,
    );
  }
}
