import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseRepository {
  static const String cacheKey = 'cached_courses';

  static Future<List<Map<String, dynamic>>> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    List<Map<String, dynamic>> cachedCourses = [];
    if (cached != null) {
      cachedCourses = List<Map<String, dynamic>>.from(jsonDecode(cached));
    }

    _syncFromServer();

    return cachedCourses;
  }

  static Future<void> _syncFromServer() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('courses').get();
      final freshData = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(freshData));
    } catch (e) {
      print('Ошибка синхронизации курсов: $e');
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
  }
}
