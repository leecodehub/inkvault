import 'package:cloud_firestore/cloud_firestore.dart';

/// Low-level access to the `users` collection.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snapshot = await userDoc(uid).get();
    return snapshot.data();
  }

  /// Creates the document if it does not exist yet, otherwise returns current.
  Future<Map<String, dynamic>> ensureUser(
    String uid,
    Map<String, dynamic> defaults,
  ) async {
    final ref = userDoc(uid);
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data()!;
    }
    await ref.set(defaults);
    // Re-read so server/client timestamps are real values, not sentinels.
    final created = await ref.get();
    return created.data() ?? defaults;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return userDoc(uid).set(data, SetOptions(merge: true));
  }
}
