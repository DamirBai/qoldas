import 'package:qoldas/services/translation_service.dart'; 

class AppLevel {
  final String key;
  final Map<String, String> labels;

  AppLevel({
    required this.key,
    required this.labels,
  });

  factory AppLevel.fromJson(Map<String, dynamic> json) {
    return AppLevel(
      key: json['key'].toString(),
      labels: {
        'ru': json['label_ru'].toString(),
        'en': json['label_en'].toString(),
        'kk': json['label_kk'].toString(),
      },
    );
  }

  String getLocalizedLabel([String? lang]) {
    final currentLang = lang ?? TranslationService.currentLang;
    return labels[currentLang] ?? key;
  }
}
