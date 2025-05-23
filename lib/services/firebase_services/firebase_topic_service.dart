import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/topic_model.dart';

class FirebaseTopicService {
  static Future<List<AppTopic>> getAllTopics() async {
    final snapshot = await FirebaseFirestore.instance.collection('topics').get();
    return snapshot.docs.map((doc) => AppTopic.fromMap(doc.id, doc.data())).toList();
  }
}
