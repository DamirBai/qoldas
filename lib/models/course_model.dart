import '../../services/translation_service.dart';

class Course {
  final String id;
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String? imageUrl;
  final String topicId;
  final String levelId;

  Course({
    required this.id,
    required this.titles,
    required this.descriptions,
    required this.topicId,
    required this.levelId,
    this.imageUrl,
  });

  factory Course.fromMap(String id, Map<String, dynamic> data) {
    return Course(
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

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'levelId': levelId,
      'title_ru': titles['ru'],
      'title_en': titles['en'],
      'title_kk': titles['kk'],
      'description_ru': descriptions['ru'],
      'description_en': descriptions['en'],
      'description_kk': descriptions['kk'],
      'imageUrl': imageUrl,
      'createdAt': DateTime.now(),
    };
  }

  String getLocalizedTitle() {
    final lang = TranslationService.currentLang;
    return titles[lang] ?? titles['ru'] ?? id;
  }

  String getLocalizedDescription() {
    final lang = TranslationService.currentLang;
    return descriptions[lang] ?? descriptions['ru'] ?? '';
  }
}
