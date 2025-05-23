import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lessons/lesson_stage_list_screen.dart';
import '../../services/translation_service.dart';
import '../../services/lesson_progress_service.dart';

class ProgressScreen extends StatelessWidget {
  final String userId;

  const ProgressScreen({super.key, required this.userId});

  Future<List<Map<String, dynamic>>> _loadCourseProgress() async {
    final courseSnap = await FirebaseFirestore.instance.collection('courses').get();
    final progressSnap = await LessonProgressService.getAllCompletedLessons(userId);
    final testSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('testResults')
        .get();

    final courseData = <Map<String, dynamic>>[];

    for (var course in courseSnap.docs) {
      final courseId = course.id;
      final sectionsSnap = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .get();

      int totalLessons = 0;
      Set<String> actualLessonIds = {};

      for (var section in sectionsSnap.docs) {
        final lessonsSnap = await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .collection('sections')
            .doc(section.id)
            .collection('lessons')
            .get();

        for (var lesson in lessonsSnap.docs) {
          actualLessonIds.add(lesson.id);
        }

        totalLessons += lessonsSnap.docs.length;
      }

      final completedLessons = progressSnap
          .where((entry) =>
              entry['courseId'] == courseId &&
              entry['completed'] == true &&
              actualLessonIds.contains(entry['lessonId']))
          .toList();

      final completed = completedLessons.length;
      final percent = totalLessons > 0 ? (completed / totalLessons) : 0.0;

      final testResults = testSnap.docs
          .where((t) => t['courseId'] == courseId)
          .map((t) => t['percent'] ?? 0)
          .toList();

      final avgPercent = testResults.isNotEmpty
          ? testResults.reduce((a, b) => a + b) / testResults.length
          : 0;

      final lang = TranslationService.currentLang;
      final titleField = 'title_$lang';
      final courseMap = course.data();
      final title = courseMap[titleField] ?? courseMap['title'] ?? courseMap['title_en'] ?? courseMap['title_ru'] ?? 'Course';

      if (totalLessons > 0) {
        courseData.add({
          'completedLessons': completed,
          'totalLessons': totalLessons,
          'title': title,
          'courseId': courseId,
          'progress': percent,
          'avgTest': avgPercent.round(),
        });
      }
    }
    return courseData;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('my_progress')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadCourseProgress(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!..sort((a, b) => b['progress'].compareTo(a['progress']));

          if (data.isEmpty) {
            return Center(child: Text(TranslationService.t('no_progress_yet')));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                TranslationService.t('progress_description'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...data.map((course) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Row(
                        children: [
                          Icon(
                            course['progress'] >= 1.0 ? Icons.check_circle : Icons.hourglass_bottom,
                            color: course['progress'] >= 1.0 ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course['title'] ?? 'Course',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: course['progress'],
                            backgroundColor: Colors.grey.shade300,
                            color: color.primary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(course['progress'] * 100).round()}% • ${TranslationService.t('average_accuracy')}: ${course['avgTest']}%\n${TranslationService.t('completed')}: ${course['completedLessons']} / ${course['totalLessons']}',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonStageListScreen(
                              courseId: course['courseId'],
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
