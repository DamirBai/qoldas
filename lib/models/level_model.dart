import '../../services/translation_service.dart';

class AppLevel {
  final String id;
  final Map<String, String> labels;

  const AppLevel({
    required this.id,
    required this.labels,
  });

  String getLocalizedLabel([String? lang]) {
    final currentLang = lang ?? TranslationService.currentLang;
    return labels[currentLang] ?? labels['ru'] ?? id;
  }

  factory AppLevel.fromMap(String id, Map<String, dynamic> data) {
    return AppLevel(
      id: id,
      labels: {
        'ru': data['label_ru']?.toString() ?? '',
        'en': data['label_en']?.toString() ?? '',
        'kk': data['label_kk']?.toString() ?? '',
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label_ru': labels['ru'],
      'label_en': labels['en'],
      'label_kk': labels['kk'],
    };
  }
}