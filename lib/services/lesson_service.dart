import 'package:qoldas/services/json_data_service.dart';

class LessonService {
  static Future<List<Map<String, dynamic>>> getStages({
    required int courseId,
    required String topic,
    required String level,
  }) async {
    final data = await JsonDataService.loadList('lib/data/lessons/lessons_data.json');

    final course = data.firstWhere(
      (item) =>
          item['courseId'] == courseId &&
          item['topic'] == topic &&
          item['level'] == level,
      orElse: () => {},
    );

    return course['stages'] != null
        ? List<Map<String, dynamic>>.from(course['stages'])
        : [];
  }
}
