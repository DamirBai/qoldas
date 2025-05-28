import '../../services/translation_service.dart';

class AppTopic {
  final String id;
  final Map<String, String> labels;
  final String image;

  AppTopic({
    required this.id,
    required this.labels,
    required this.image,
  });

  String getLocalizedLabel([String? langCode]) {
    final lang = langCode ?? TranslationService.currentLang;
    return labels[lang] ?? labels['ru'] ?? id;
  }

  factory AppTopic.fromMap(String id, Map<String, dynamic> data) {
    final Map<String, String> localizedLabels = {};

    data.forEach((k, v) {
      if (k.startsWith('label_') && v is String) {
        final lang = k.replaceFirst('label_', '');
        localizedLabels[lang] = v;
      }
    });

    return AppTopic(
      id: id,
      labels: localizedLabels,
      image: data['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final labelFields = {
      for (final entry in labels.entries) 'label_${entry.key}': entry.value
    };

    return {
      ...labelFields,
      'image': image, 
    };
  }
}
