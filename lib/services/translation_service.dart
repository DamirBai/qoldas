import 'package:cloud_firestore/cloud_firestore.dart';

class TranslationService {
  static Map<String, dynamic> _strings = {};
  static String _lang = 'ru';

  static Future<void> load(String lang) async {
    final doc = await FirebaseFirestore.instance
        .collection('translations')
        .doc(lang)
        .get();

    _strings = doc.data() ?? {};
    _lang = lang;
  }

  static String t(String key) {
    return _strings[key] ?? key;
  }

  static String get currentLang => _lang;
}
