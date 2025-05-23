import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> isAdmin(String userId) async {
    try {
      final snapshot = await _db.collection('users').doc(userId).get();
      final data = snapshot.data();
      return data?['isAdmin'] == true;
    } catch (e) {
      print('Ошибка при проверке isAdmin: $e');
      return false;
    }
  }

  Future<bool> updateEmailAndPassword(String email, String password) async {
    try {
      print("Updating in DB: email = $email, password = $password");
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print("Ошибка при обновлении данных: $e");
      return false;
    }
  }
}
