import 'dart:convert';
import 'package:hive/hive.dart';
import '../../services/translation_service.dart';

part 'course_model.g.dart';

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String titlesJson; // JSON с локализациями названий

  @HiveField(2)
  final String descriptionsJson; // JSON с локализациями описаний

  @HiveField(3)
  final String topicId;

  @HiveField(4)
  final String levelId;

  @HiveField(5)
  final String? imageUrl;

  /// Конструктор для Hive — принимает сериализованные JSON строки
  Course({
    required this.id,
    required this.titlesJson,
    required this.descriptionsJson,
    required this.topicId,
    required this.levelId,
    this.imageUrl,
  });

  /// Фабричный конструктор для создания из Map с локализациями (например, из Firestore)
  factory Course.fromLocalizedMaps({
    required String id,
    required Map<String, String> titles,
    required Map<String, String> descriptions,
    required String topicId,
    required String levelId,
    String? imageUrl,
  }) {
    return Course(
      id: id,
      titlesJson: jsonEncode(titles),
      descriptionsJson: jsonEncode(descriptions),
      topicId: topicId,
      levelId: levelId,
      imageUrl: imageUrl,
    );
  }

  /// Фабрика для создания из Map данных Firestore
  factory Course.fromMap(String id, Map<String, dynamic> data) {
    return Course.fromLocalizedMaps(
      id: id,
      topicId: data['topicId']?.toString() ?? '',
      levelId: data['levelId']?.toString() ?? '',
      titles: {
        'ru': data['title_ru']?.toString() ?? '',
        'en': data['title_en']?.toString() ?? '',
        'kk': data['title_kk']?.toString() ?? '',
      },
      descriptions: {
        'ru': data['description_ru']?.toString() ?? '',
        'en': data['description_en']?.toString() ?? '',
        'kk': data['description_kk']?.toString() ?? '',
      },
      imageUrl: data['imageUrl'],
    );
  }

  /// Доступ к локализованным названиям как Map<String, String>
  Map<String, String> get titles => Map<String, String>.from(jsonDecode(titlesJson));

  /// Доступ к локализованным описаниям как Map<String, String>
  Map<String, String> get descriptions => Map<String, String>.from(jsonDecode(descriptionsJson));

  /// Получить название на текущем языке
  String getLocalizedTitle() {
    final lang = TranslationService.currentLang;
    return titles[lang] ?? titles['ru'] ?? id;
  }

  /// Получить описание на текущем языке
  String getLocalizedDescription() {
    final lang = TranslationService.currentLang;
    return descriptions[lang] ?? descriptions['ru'] ?? '';
  }
}
