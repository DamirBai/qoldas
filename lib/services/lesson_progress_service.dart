import 'package:cloud_firestore/cloud_firestore.dart';

class LessonProgressService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> completeLesson({
    required String userId,
    required String courseId,
    required String sectionId,
    required String lessonId,
    required int percent,
  }) async {
    final lessonRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(courseId);

    await lessonRef.set({}, SetOptions(merge: true));

    await lessonRef.collection('lessons').doc(lessonId).set({
      'lessonId': lessonId,
      'sectionId': sectionId,
      'percent': percent,
      'completed': true,
      'completedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> getCompletedLessons(
    String userId,
    String courseId,
  ) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(courseId)
        .collection('lessons')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['lessonId'] = doc.id;
      data['courseId'] = courseId;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllCompletedLessons(String userId) async {
    final courseSnap = await _db.collection('users').doc(userId).collection('progress').get();
    final List<Map<String, dynamic>> allLessons = [];

    for (var courseDoc in courseSnap.docs) {
      final courseId = courseDoc.id;
      final lessonsSnap = await _db
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(courseId)
          .collection('lessons')
          .get();

      for (var lessonDoc in lessonsSnap.docs) {
        final data = lessonDoc.data();
        data['lessonId'] = lessonDoc.id;
        data['courseId'] = courseId;
        allLessons.add(data);
      }
    }

    return allLessons;
  }

  static Future<int?> getLessonPercent({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['percent'];
  }

  static Future<bool> isLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    final percent = await getLessonPercent(
      userId: userId,
      courseId: courseId,
      lessonId: lessonId,
    );

    return percent != null;
  }
}
