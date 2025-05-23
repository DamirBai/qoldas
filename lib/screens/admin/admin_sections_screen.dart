import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/translation_service.dart';
import 'admin_lessons_screen.dart';

class AdminSectionsScreen extends StatelessWidget {
  final String courseId;
  const AdminSectionsScreen({super.key, required this.courseId});

  Future<void> _addSection(BuildContext context) async {
    final controllers = {
      'ru': TextEditingController(),
      'en': TextEditingController(),
      'kk': TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('new_section')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var lang in ['ru', 'en', 'kk'])
              TextField(
                controller: controllers[lang],
                decoration: InputDecoration(labelText: '${TranslationService.t('section_name')} ($lang)'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(TranslationService.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final titleRu = controllers['ru']!.text.trim();
              final titleEn = controllers['en']!.text.trim();
              final titleKk = controllers['kk']!.text.trim();
              if (titleRu.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .collection('sections')
                    .add({
                  'title_ru': titleRu,
                  'title_en': titleEn,
                  'title_kk': titleKk,
                  'createdAt': Timestamp.now(), 
                });
              }
              Navigator.pop(context);
            },
            child: Text(TranslationService.t('create')),
          ),
        ],
      ),
    );
  }

  Future<void> _editSection(BuildContext context, DocumentSnapshot sectionDoc) async {
    final controllers = {
      'ru': TextEditingController(text: sectionDoc['title_ru']),
      'en': TextEditingController(text: sectionDoc['title_en']),
      'kk': TextEditingController(text: sectionDoc['title_kk']),
    };

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('edit_section')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var lang in ['ru', 'en', 'kk'])
              TextField(
                controller: controllers[lang],
                decoration: InputDecoration(labelText: '${TranslationService.t('section_name')} ($lang)'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(TranslationService.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              await sectionDoc.reference.update({
                'title_ru': controllers['ru']!.text.trim(),
                'title_en': controllers['en']!.text.trim(),
                'title_kk': controllers['kk']!.text.trim(),
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
    final sectionsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('sections');

    final lang = TranslationService.currentLang;

    return Scaffold(
      appBar: AppBar(title: Text(TranslationService.t('sections'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: sectionsRef.orderBy('createdAt').snapshots(), 
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(TranslationService.t('load_error')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(TranslationService.t('no_sections')));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final section = docs[index];
              final title = section['title_$lang'] ?? section['title_en'] ?? section['title_ru'] ?? section['title_kk'] ?? 'Без названия';

              return ListTile(
                title: Text(title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editSection(context, section),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => section.reference.delete(),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminLessonsScreen(
                      courseId: courseId,
                      sectionId: section.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSection(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
