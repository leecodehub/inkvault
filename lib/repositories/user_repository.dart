import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Bridges Firebase auth identities with their Firestore user profile.
class UserRepository {
  final FirestoreService _firestore;

  UserRepository({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  /// Loads the user doc, creating it with defaults on first sign-in.
  Future<UserModel> loadOrCreateUser({
    required String uid,
    required String email,
    String displayName = '',
    String photoUrl = '',
  }) async {
    final defaults = UserModel.initial(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    ).toMap();
    defaults['createdAt'] = Timestamp.fromDate(DateTime.now());

    final data = await _firestore.ensureUser(uid, defaults);
    return UserModel.fromMap(uid, data);
  }

  Future<void> saveUser(UserModel user) {
    return _firestore.updateUser(user.uid, user.toMap());
  }
}
