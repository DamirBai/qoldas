import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/translation_service.dart';

class EditLessonScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;

  const EditLessonScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
  });

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _titleRu = TextEditingController();
  final _titleEn = TextEditingController();
  final _titleKk = TextEditingController();
  List<Map<String, TextEditingController>> _stepsControllers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    final lessonDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('lessons')
        .doc(widget.lessonId)
        .get();

    final stepsSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('steps')
        .orderBy('order')
        .get();

    _titleRu.text = lessonDoc['title_ru'] ?? '';
    _titleEn.text = lessonDoc['title_en'] ?? '';
    _titleKk.text = lessonDoc['title_kk'] ?? '';

    _stepsControllers = stepsSnapshot.docs.map((doc) {
      return {
        'video': TextEditingController(text: doc['videoUrl'] ?? ''),
        'ru': TextEditingController(text: doc['description_ru'] ?? ''),
        'en': TextEditingController(text: doc['description_en'] ?? ''),
        'kk': TextEditingController(text: doc['description_kk'] ?? ''),
        'id': TextEditingController(text: doc.id),
      };
    }).toList();

    setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    try {
      final lessonRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('sections')
          .doc(widget.sectionId)
          .collection('lessons')
          .doc(widget.lessonId);

      await lessonRef.update({
        'title_ru': _titleRu.text.trim(),
        'title_en': _titleEn.text.trim(),
        'title_kk': _titleKk.text.trim(),
      });

      for (int i = 0; i < _stepsControllers.length; i++) {
        final s = _stepsControllers[i];
        await lessonRef.collection('steps').doc(s['id']!.text).update({
          'videoUrl': s['video']!.text.trim(),
          'description_ru': s['ru']!.text.trim(),
          'description_en': s['en']!.text.trim(),
          'description_kk': s['kk']!.text.trim(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.t('save_success'))),
      );
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.t('save_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('edit_lesson')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(controller: _titleRu, decoration: InputDecoration(labelText: 'Title (ru)')),
                TextField(controller: _titleEn, decoration: InputDecoration(labelText: 'Title (en)')),
                TextField(controller: _titleKk, decoration: InputDecoration(labelText: 'Title (kk)')),
                const Divider(height: 32),
                for (int i = 0; i < _stepsControllers.length; i++) ...[
                  Text('Step ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: _stepsControllers[i]['video'], decoration: const InputDecoration(labelText: 'Video URL')),
                  TextField(controller: _stepsControllers[i]['ru'], decoration: const InputDecoration(labelText: 'Description (ru)')),
                  TextField(controller: _stepsControllers[i]['en'], decoration: const InputDecoration(labelText: 'Description (en)')),
                  TextField(controller: _stepsControllers[i]['kk'], decoration: const InputDecoration(labelText: 'Description (kk)')),
                  const Divider(height: 32),
                ],
              ],
            ),
    );
  }
}
