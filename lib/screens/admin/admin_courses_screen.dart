import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course_model.dart';
import 'admin_course_details_screen.dart';
import '../../services/translation_service.dart';

class AdminCoursesScreen extends StatelessWidget {
  const AdminCoursesScreen({super.key});

  Future<void> _createCourse(BuildContext context) async {
    final titleRuController = TextEditingController();
    final titleEnController = TextEditingController();
    final titleKkController = TextEditingController();
    final descRuController = TextEditingController();
    final descEnController = TextEditingController();
    final descKkController = TextEditingController();
    final imageUrlController = TextEditingController();

    String? selectedTopic;
    String? selectedLevel;

    final topicsSnap = await FirebaseFirestore.instance.collection('topics').get();
    final levelsSnap = await FirebaseFirestore.instance.collection('levels').get();

    final lang = TranslationService.currentLang;
    final topics = topicsSnap.docs;
    final levels = levelsSnap.docs;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(TranslationService.t('new_course')),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleRuController, decoration: const InputDecoration(labelText: 'Название (ru)')),
                TextField(controller: titleEnController, decoration: const InputDecoration(labelText: 'Title (en)')),
                TextField(controller: titleKkController, decoration: const InputDecoration(labelText: 'Атауы (kk)')),
                TextField(controller: descRuController, decoration: const InputDecoration(labelText: 'Описание (ru)')),
                TextField(controller: descEnController, decoration: const InputDecoration(labelText: 'Description (en)')),
                TextField(controller: descKkController, decoration: const InputDecoration(labelText: 'Сипаттама (kk)')),
                TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTopic,
                  decoration: const InputDecoration(labelText: 'Topic'),
                  items: topics.map((doc) {
                    final data = doc.data();
                    final label = data['label_$lang'] ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(label));
                  }).toList(),
                  onChanged: (value) => selectedTopic = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: levels.map((doc) {
                    final data = doc.data();
                    final label = data['label_$lang'] ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(label));
                  }).toList(),
                  onChanged: (value) => selectedLevel = value,
                ),
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
                final data = {
                  'title_ru': titleRuController.text.trim(),
                  'title_en': titleEnController.text.trim(),
                  'title_kk': titleKkController.text.trim(),
                  'description_ru': descRuController.text.trim(),
                  'description_en': descEnController.text.trim(),
                  'description_kk': descKkController.text.trim(),
                  'imageUrl': imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                  'createdAt': Timestamp.now(),
                  'topicId': selectedTopic ?? '',
                  'levelId': selectedLevel ?? '',
                };

                final docRef = await FirebaseFirestore.instance.collection('courses').add(data);

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCourseDetailsScreen(courseId: docRef.id),
                    ),
                  );
                }
              },
              child: Text(TranslationService.t('create')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang;

    return Scaffold(
      appBar: AppBar(title: Text(TranslationService.t('manage_courses'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(TranslationService.t('load_error')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final courses = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Course.fromMap(doc.id, data);
          }).toList();

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];

              return ListTile(
                leading: course.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          course.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(course.getLocalizedTitle()),
                subtitle: Text(course.getLocalizedDescription()),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminCourseDetailsScreen(courseId: course.id),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => FirebaseFirestore.instance.collection('courses').doc(course.id).delete(),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCourseDetailsScreen(courseId: course.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createCourse(context),
      ),
    );
  }
}
