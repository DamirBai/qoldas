import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final _db = FirebaseFirestore.instance;

  static const List<String> _adminUIDs = [
    'DUJZTBpZtfY8Z7MSvBvSj4Pd1yj1',
    'm8phzEdilpY6WaJBDLz9wKSzEwD3',
    'dmLPxGetGbXGpd828yBGx33bkeL2',
  ];

  static bool _checkAdmin(String uid) {
    return _adminUIDs.contains(uid);
  }

  static Future<void> createCourse(String uid, Map<String, dynamic> data) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses').add(data);
  }

  static Future<void> updateCourse(String uid, String courseId, Map<String, dynamic> data) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses').doc(courseId).update(data);
  }

  static Future<void> deleteCourse(String uid, String courseId) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses').doc(courseId).delete();
  }

  static Future<void> createSection(String uid, String courseId, Map<String, dynamic> data) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses').doc(courseId).collection('sections').add(data);
  }

  static Future<void> deleteSection(String uid, String courseId, String sectionId) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses').doc(courseId).collection('sections').doc(sectionId).delete();
  }

  static Future<void> createLesson(String uid, String courseId, String sectionId, Map<String, dynamic> data) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lessons')
        .add(data);
  }

  static Future<void> deleteLesson(String uid, String courseId, String sectionId, String lessonId) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lessons')
        .doc(lessonId)
        .delete();
  }

  static Future<void> createTest(String uid, String courseId, String sectionId, String lessonId, Map<String, dynamic> data) async {
    if (!_checkAdmin(uid)) throw Exception('Access denied');
    await _db.collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lessons')
        .doc(lessonId)
        .collection('tests')
        .add(data);
  }
}
