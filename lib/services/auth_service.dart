import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Wrap toàn bộ logic Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Stream trạng thái đăng nhập ─────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại (null nếu chưa đăng nhập)
  User? get currentUser => _auth.currentUser;

  // ─── Đăng nhập ────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return _fetchUserModel(credential.user!.uid);
  }

  // ─── Đăng ký ──────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user!.uid;

    // Lưu tên người dùng vào profile Firebase Auth
    try {
      await credential.user?.updateDisplayName(username.trim());
    } catch (_) {}

    final model = UserModel(
      uid: uid,
      username: username.trim(),
      gmail: email.trim(),
      id: uid,
    );

    // Ghi document vào Firestore – nếu thất bại vẫn để user đăng nhập được
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set(model.toMap(), SetOptions(merge: true));
    } catch (_) {}

    return model;
  }

  // ─── Đăng xuất ────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ─── Helper ───────────────────────────────────────────────────────────────
  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    final authUser = _auth.currentUser!;
    return UserModel(
      uid: uid,
      username: authUser.displayName ?? '',
      gmail: authUser.email ?? '',
      id: uid,
    );
  }
}
