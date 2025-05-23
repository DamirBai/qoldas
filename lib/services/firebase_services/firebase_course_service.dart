import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCourseService {
  static final _firestore = FirebaseFirestore.instance;

  /// Получить список курсов по topicId и levelId
  static Future<List<Map<String, dynamic>>> getCoursesByTopicAndLevel(
      String topicId, String levelId) async {
    final snapshot = await _firestore
        .collection('courses')
        .where('topicId', isEqualTo: topicId)
        .where('levelId', isEqualTo: levelId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Получить локализованное название темы по её ID
  static Future<String> getLocalizedTopicTitle(String topicId, String lang) async {
    final doc = await _firestore.collection('topics').doc(topicId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return data['label_$lang'] ?? data['label'] ?? topicId;
    } else {
      return topicId;
    }
  }
}
