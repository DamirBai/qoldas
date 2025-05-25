import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lessons/lesson_stage_list_screen.dart';
import '../../services/translation_service.dart';
import '../../services/lesson_progress_service.dart';
import '../../models/topic_model.dart';
import '../../models/level_model.dart';
import '../../services/firebase_services/firebase_topic_service.dart';
import '../../services/firebase_services/firebase_level_service.dart';

class ProgressScreen extends StatefulWidget {
  final String userId;

  const ProgressScreen({super.key, required this.userId});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ValueNotifier<Map<String, String>> filters = ValueNotifier({
    'topic': 'all',
    'level': 'all',
  });

  List<Map<String, dynamic>> courseData = [];
  List<AppTopic> topics = [];
  List<AppLevel> levels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    final courseSnap = await FirebaseFirestore.instance.collection('courses').get();
    final progressSnap = await LessonProgressService.getAllCompletedLessons(widget.userId);
    final testSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('testResults')
        .get();
    final topicSnap = await FirebaseTopicService.getAllTopics();
    final levelSnap = await FirebaseLevelService.getAllLevels();
    final List<Map<String, dynamic>> tempData = [];

    for (var course in courseSnap.docs) {
      final courseId = course.id;
      final courseMap = course.data();
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
      final title = courseMap[titleField] ??
          courseMap['title'] ??
          courseMap['title_en'] ??
          courseMap['title_ru'] ??
          'Course';

      if (totalLessons > 0) {
        tempData.add({
          'completedLessons': completed,
          'totalLessons': totalLessons,
          'title': title,
          'courseId': courseId,
          'progress': percent,
          'avgTest': avgPercent.round(),
          'topicId': courseMap['topicId'],
          'levelId': courseMap['levelId'],
        });
      }
    }

    setState(() {
      courseData = tempData;
      topics = topicSnap;
      levels = levelSnap;
      isLoading = false;
    });
  }

  void _updateFilter(String key, String value) {
    final updated = Map<String, String>.from(filters.value);
    updated[key] = value;
    filters.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(TranslationService.t('my_progress'))),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                ValueListenableBuilder<Map<String, String>>(
                  valueListenable: filters,
                  builder: (context, value, _) => SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildChip(
                          context,
                          label: TranslationService.t('all_topics'),
                          selected: value['topic'] == 'all',
                          onTap: () => _updateFilter('topic', 'all'),
                        ),
                        ...topics.map((t) => _buildChip(
                              context,
                              label: t.getLocalizedLabel(),
                              selected: value['topic'] == t.id,
                              onTap: () => _updateFilter('topic', t.id),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Map<String, String>>(
                  valueListenable: filters,
                  builder: (context, value, _) => SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildChip(
                          context,
                          label: TranslationService.t('all_levels'),
                          selected: value['level'] == 'all',
                          onTap: () => _updateFilter('level', 'all'),
                        ),
                        ...levels.map((l) => _buildChip(
                              context,
                              label: l.getLocalizedLabel(),
                              selected: value['level'] == l.id,
                              onTap: () => _updateFilter('level', l.id),
                            )),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    TranslationService.t('progress_description'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ValueListenableBuilder<Map<String, String>>(
                    valueListenable: filters,
                    builder: (context, value, _) {
                      final topic = value['topic'];
                      final level = value['level'];
                      final filtered = courseData.where((c) {
                        final matchesTopic = topic == 'all' || c['topicId'] == topic;
                        final matchesLevel = level == 'all' || c['levelId'] == level;
                        return matchesTopic && matchesLevel;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(child: Text(TranslationService.t('no_progress_yet')));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final course = filtered[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LessonStageListScreen(
                                    courseId: course['courseId'],
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).cardColor.withOpacity(0.75),
                                    Theme.of(context).cardColor.withOpacity(0.55),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        course['progress'] >= 1.0
                                            ? Icons.check_circle
                                            : Icons.hourglass_bottom,
                                        color: course['progress'] >= 1.0
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          course['title'] ?? 'Course',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: course['progress'],
                                    backgroundColor: Colors.grey.shade300,
                                    color: theme.colorScheme.primary,
                                    minHeight: 6,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${(course['progress'] * 100).round()}% • ${TranslationService.t('average_accuracy')}: ${course['avgTest']}%\n${TranslationService.t('completed')}: ${course['completedLessons']} / ${course['totalLessons']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChip(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? const Color(0xFF4751A2) : const Color(0xFFD6DCFF);
    final borderColor = selected ? Colors.transparent : Colors.grey.withOpacity(0.4);
    final labelColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: selectedColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
