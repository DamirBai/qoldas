import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_screen.dart';
import '../../services/lesson_progress_service.dart';
import '../../services/translation_service.dart';

class LessonModuleListScreen extends StatefulWidget {
  final String courseId;
  final String userId;
  final String sectionId;

  const LessonModuleListScreen({
    super.key,
    required this.courseId,
    required this.userId,
    required this.sectionId,
  });

  @override
  State<LessonModuleListScreen> createState() => _LessonModuleListScreenState();
}

class _LessonModuleListScreenState extends State<LessonModuleListScreen> {
  List<String> completedLessonIds = [];
  List<QueryDocumentSnapshot> lessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessonsQuery = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('sections')
          .doc(widget.sectionId)
          .collection('lessons')
          .orderBy('createdAt')
          .get();

      final progressList = await LessonProgressService.getCompletedLessons(
        widget.userId,
        widget.courseId,
      );

      final completed = progressList
          .where((lesson) => lesson['completed'] == true)
          .map((lesson) => lesson['lessonId'].toString())
          .toList();

      setState(() {
        lessons = lessonsQuery.docs;
        completedLessonIds = completed;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки уроков: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('lessons')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final lessonId = lesson.id;

                final lessonMap = lesson.data() as Map<String, dynamic>;
                final title = lessonMap['title_$lang'] ??
                    lessonMap['title'] ??
                    lessonMap['title_en'] ??
                    lessonMap['title_ru'] ??
                    '${TranslationService.t('lesson')} ${index + 1}';

                final isCompleted = completedLessonIds.contains(lessonId);
                final isUnlocked = index == 0 ||
                    completedLessonIds.contains(lessons[index - 1].id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? colorScheme.surface.withOpacity(0.95)
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnlocked ? colorScheme.primary : Colors.grey.shade400,
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    leading: isUnlocked
                        ? const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 28)
                        : const Icon(Icons.lock, color: Colors.grey, size: 24),
                    title: Text(
                      title,
                      style: TextStyle(
                        color: isUnlocked ? colorScheme.onSurface : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                        : null,
                    onTap: isUnlocked
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonScreen(
                                  courseId: widget.courseId,
                                  sectionId: widget.sectionId,
                                  lessonId: lessonId,
                                  userId: widget.userId,
                                ),
                              ),
                            ).then((_) => _loadLessons())
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
