import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/translation_service.dart';
import '../lessons/lesson_screen.dart';
import '../admin/admin_tests_screen.dart';
import '../admin/edit_lesson_screen.dart';
import '../../services/admin_service.dart';

class AdminLessonsScreen extends StatelessWidget {
  final String courseId;
  final String sectionId;

  const AdminLessonsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
  });

  Future<void> _addLesson(BuildContext context, String userId) async {
    final titleRu = TextEditingController();
    final titleEn = TextEditingController();
    final titleKk = TextEditingController();

    final stepVideoControllers = List.generate(3, (_) => TextEditingController());
    final stepDescControllers = List.generate(3, (_) => {
      'ru': TextEditingController(),
      'en': TextEditingController(),
      'kk': TextEditingController(),
    });

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('new_lesson')),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleRu, decoration: const InputDecoration(labelText: 'Title (ru)')),
              TextField(controller: titleEn, decoration: const InputDecoration(labelText: 'Title (en)')),
              TextField(controller: titleKk, decoration: const InputDecoration(labelText: 'Title (kk)')),
              const Divider(height: 24),
              for (int i = 0; i < 3; i++) ...[
                Text('Step ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: stepVideoControllers[i], decoration: const InputDecoration(labelText: 'Video URL')),
                TextField(controller: stepDescControllers[i]['ru'], decoration: const InputDecoration(labelText: 'Description (ru)')),
                TextField(controller: stepDescControllers[i]['en'], decoration: const InputDecoration(labelText: 'Description (en)')),
                TextField(controller: stepDescControllers[i]['kk'], decoration: const InputDecoration(labelText: 'Description (kk)')),
                const Divider(height: 24),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleRu.text.trim();
              if (title.isEmpty || stepVideoControllers.any((c) => c.text.trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Заполните заголовок и ссылки на все видео')),
                );
                return;
              }

              try {
                final lessonRef = await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .collection('sections')
                    .doc(sectionId)
                    .collection('lessons')
                    .add({
                  'title_ru': titleRu.text.trim(),
                  'title_en': titleEn.text.trim(),
                  'title_kk': titleKk.text.trim(),
                  'createdAt': Timestamp.now(),
                });

                for (int i = 0; i < 3; i++) {
                  await lessonRef.collection('steps').add({
                    'videoUrl': stepVideoControllers[i].text.trim(),
                    'description_ru': stepDescControllers[i]['ru']!.text.trim(),
                    'description_en': stepDescControllers[i]['en']!.text.trim(),
                    'description_kk': stepDescControllers[i]['kk']!.text.trim(),
                    'createdAt': Timestamp.now(),
                    'order': i,
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(TranslationService.t('save_success'))),
                );
              } catch (e) {
                debugPrint('❌ Ошибка создания урока со steps: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(TranslationService.t('save_error'))),
                );
              }
            },
            child: Text(TranslationService.t('create')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang ?? 'en';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    final lessonsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lessons')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('lessons')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lessonsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(TranslationService.t('load_error')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(TranslationService.t('no_lessons')));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final lesson = docs[index];
              final title = lesson['title_$lang'] ??
                  lesson['title_en'] ??
                  lesson['title_ru'] ??
                  lesson['title_kk'] ??
                  '${TranslationService.t('lesson')} ${index + 1}';

              final createdAt = lesson['createdAt'] != null
                  ? DateFormat.yMMMd().format(lesson['createdAt'].toDate())
                  : TranslationService.t('no_date');

              return ListTile(
                title: Text(title),
                subtitle: Text(createdAt),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: TranslationService.t('edit'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditLessonScreen(
                            courseId: courseId,
                            sectionId: sectionId,
                            lessonId: lesson.id,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        try {
                          await AdminService.deleteLesson(userId, courseId, sectionId, lesson.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(TranslationService.t('delete_success'))),
                          );
                        } catch (e) {
                          debugPrint('❌ Ошибка удаления урока: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(TranslationService.t('delete_error'))),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonScreen(
                              courseId: courseId,
                              sectionId: sectionId,
                              lessonId: lesson.id,
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminTestsScreen(
                        courseId: courseId,
                        sectionId: sectionId,
                        lessonId: lesson.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addLesson(context, userId),
        child: const Icon(Icons.add),
        tooltip: TranslationService.t('add_lesson'),
      ),
    );
  }
}
