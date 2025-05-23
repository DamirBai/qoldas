import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/translation_service.dart';
import 'admin_questions_screen.dart';

class AdminTestsScreen extends StatelessWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;

  const AdminTestsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
  });

  Future<void> _addTest(BuildContext context) async {
    try {
      final newTestRef = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('sections')
          .doc(sectionId)
          .collection('lessons')
          .doc(lessonId)
          .collection('test')
          .add({
        'title_ru': 'Новый тест',
        'title_en': 'New test',
        'title_kk': 'Жаңа тест'
      });

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminQuestionsScreen(
              courseId: courseId,
              sectionId: sectionId,
              lessonId: lessonId,
              testId: newTestRef.id,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Ошибка добавления теста: $e');
    }
  }

  Future<void> _editTest(BuildContext context, DocumentSnapshot testDoc) async {
    final ru = TextEditingController(text: testDoc['title_ru'] ?? '');
    final en = TextEditingController(text: testDoc['title_en'] ?? '');
    final kk = TextEditingController(text: testDoc['title_kk'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('edit_test')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ru, decoration: const InputDecoration(labelText: 'Название (ru)')),
              TextField(controller: en, decoration: const InputDecoration(labelText: 'Title (en)')),
              TextField(controller: kk, decoration: const InputDecoration(labelText: 'Атауы (kk)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(TranslationService.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              await testDoc.reference.update({
                'title_ru': ru.text.trim(),
                'title_en': en.text.trim(),
                'title_kk': kk.text.trim(),
              });
              Navigator.pop(context);
            },
            child: Text(TranslationService.t('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang ?? 'ru';
    final testsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('sections')
        .doc(sectionId)
        .collection('lessons')
        .doc(lessonId)
        .collection('test');

    return Scaffold(
      appBar: AppBar(title: Text(TranslationService.t('tests'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: testsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(TranslationService.t('load_error')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              final title = test['title_$lang'] ?? test['title_en'] ?? test['title_ru'] ?? test['title_kk'] ?? TranslationService.t('no_title');

              return ListTile(
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editTest(context, test),
                      tooltip: TranslationService.t('edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => test.reference.delete(),
                      tooltip: TranslationService.t('delete'),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminQuestionsScreen(
                      courseId: courseId,
                      sectionId: sectionId,
                      lessonId: lessonId,
                      testId: test.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTest(context),
        child: const Icon(Icons.add),
        tooltip: TranslationService.t('add_test'),
      ),
    );
  }
}
