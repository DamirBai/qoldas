import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/level_model.dart';

class FirebaseLevelService {
  static Future<List<AppLevel>> getAllLevels() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('levels')
        .orderBy('order') 
        .get();

    return snapshot.docs.map((doc) {
      return AppLevel.fromMap(doc.id, doc.data());
    }).toList();
  }
}
