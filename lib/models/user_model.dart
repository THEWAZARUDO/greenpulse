import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String gmail;
  final String id; // custom ID field in Firestore

  const UserModel({
    required this.uid,
    required this.username,
    required this.gmail,
    required this.id,
  });

  /// Tạo UserModel từ Firestore document. uid truyền riêng vì nó là doc ID.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      gmail: data['gmail'] as String? ?? '',
      id: data['ID'] as String? ?? '',
    );
  }

  /// Chuyển về Map để ghi vào Firestore.
  Map<String, dynamic> toMap() {
    return {'username': username, 'gmail': gmail, 'ID': id};
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, username: $username, gmail: $gmail)';
}
