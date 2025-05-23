import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> importJsonToFirestore(String languageCode) async {
  try {
    final rawJson = await rootBundle.loadString('assets/data/i18n/strings_$languageCode.json');
    final Map<String, dynamic> translations = jsonDecode(rawJson);

    await FirebaseFirestore.instance
        .collection('translations')
        .doc(languageCode)
        .set(translations);

    print('✅ Переводы успешно загружены в Firestore: $languageCode');
  } catch (e) {
    print('❌ Ошибка загрузки переводов: $e');
  }
}
