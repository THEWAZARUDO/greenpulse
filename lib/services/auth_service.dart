import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Wrap toàn bộ logic Firebase Auth & Luồng trung gian greenpulse-auth-web.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// URL Backend Web trung gian xử lý Auth Action & Brevo Mailer
  static String authWebBaseUrl = 'https://greenpulse-auth.vercel.app';

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

  // ─── Xóa Tài Khoản Vĩnh Viễn (Google Play / Privacy Standard) ─────────────
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Xóa document người dùng trong Firestore
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (_) {}

    // Xóa tài khoản Firebase Auth
    await user.delete();
  }

  // ─── Quên Mật Khẩu (Qua Backend greenpulse-auth-web) ──────────────────────
  Future<void> sendPasswordResetEmail({required String email}) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final response = await http
          .post(
            Uri.parse('$authWebBaseUrl/api/auth/send-password-reset-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          debugPrint(
            '[AuthService] Đã gửi email đặt lại mật khẩu qua backend greenpulse-auth-web: $cleanEmail',
          );
          return;
        }
      } else if (response.statusCode == 404) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Không tìm thấy tài khoản nào khớp với địa chỉ email này.',
        );
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (data['error'] == 'INVALID_EMAIL') {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Địa chỉ email không hợp lệ.',
          );
        }
      }

      // Fallback về Firebase Auth native nếu server trả mã lỗi khác
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      debugPrint(
        '[AuthService] Backend auth-web timeout/lỗi, fallback về Firebase native: $e',
      );
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    }
  }

  // ─── Xác Thực Email (Qua Backend greenpulse-auth-web) ────────────────────
  Future<void> sendEmailVerification({String? targetEmail}) async {
    final email =
        (targetEmail ?? _auth.currentUser?.email)?.trim().toLowerCase();
    if (email == null || email.isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse('$authWebBaseUrl/api/auth/send-verification-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          debugPrint(
            '[AuthService] Đã gửi email xác thực qua backend greenpulse-auth-web: $email',
          );
          return;
        }
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (data['error'] == 'ALREADY_VERIFIED') {
          debugPrint('[AuthService] Email $email đã được xác thực trước đó.');
          return;
        }
      }

      // Fallback về Firebase Auth native nếu backend không phản hồi 200
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      debugPrint(
        '[AuthService] Backend auth-web timeout/lỗi, fallback về Firebase native: $e',
      );
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    }
  }

  /// Reload lại thông tin user từ Firebase Auth (cập nhật trạng thái emailVerified)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Kiểm tra email đã được xác minh chưa
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

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
