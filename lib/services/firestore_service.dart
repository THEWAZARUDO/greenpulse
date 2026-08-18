import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/farm_model.dart';
import 'rtdb_service.dart';

/// Wrap tất cả truy vấn Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User ─────────────────────────────────────────────────────────────────
  /// Lấy thông tin user từ Firestore users/{uid}.
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Stream theo dõi thay đổi realtime của user document.
  Stream<UserModel?> watchUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Đổi username người dùng
  Future<void> updateUsername(String uid, String newUsername) async {
    final trimmed = newUsername.trim();
    await _db.collection('users').doc(uid).set({
      'username': trimmed,
    }, SetOptions(merge: true));

    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(trimmed);
    } catch (_) {}
  }

  /// Lưu FCM Device Token phục vụ Push Notification 24/7 từ Cloud Function
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Xóa FCM Token khi người dùng đăng xuất
  Future<void> deleteFcmToken(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }


  // ─── Farms CRUD ────────────────────────────────────────────────────────────
  /// Lấy danh sách farms của user (một lần).
  Future<List<FarmModel>> getFarms(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .get();
    return snap.docs.map(FarmModel.fromFirestore).toList();
  }

  /// Stream danh sách farms realtime.
  Stream<List<FarmModel>> watchFarms(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .snapshots()
        .map((snap) => snap.docs.map(FarmModel.fromFirestore).toList());
  }

  /// Thêm nông trại mới
  Future<String> addFarm(String uid, String farmName) async {
    final ref = _db.collection('users').doc(uid).collection('farms').doc();
    await ref.set({
      'name': farmName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Đổi tên nông trại
  Future<void> updateFarm(String uid, String farmId, String newName) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .update({'name': newName.trim()});
  }

  /// Xóa nông trại
  Future<void> deleteFarm(String uid, String farmId) async {
    // 1. Xóa thông tin nông trại trên Firestore
    await _db
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .delete();
    
    // 2. Xóa toàn bộ dữ liệu cảm biến của nông trại trên Realtime Database
    await RTDBService().deleteFarmData(uid, farmId);
  }
}
