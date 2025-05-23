import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/translation_service.dart';
import 'admin_sections_screen.dart';

class AdminCourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const AdminCourseDetailsScreen({super.key, required this.courseId});

  @override
  State<AdminCourseDetailsScreen> createState() => _AdminCourseDetailsScreenState();
}

class _AdminCourseDetailsScreenState extends State<AdminCourseDetailsScreen> {
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};
  final List<String> _langs = ['ru', 'en', 'kk'];

  String? bannerUrl;
  String? topicId;
  String? levelId;

  List<Map<String, dynamic>> topicOptions = [];
  List<Map<String, dynamic>> levelOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).get();
      final topicsSnap = await FirebaseFirestore.instance.collection('topics').get();
      final levelsSnap = await FirebaseFirestore.instance.collection('levels').get();

      final topics = topicsSnap.docs.map((e) => {'id': e.id, ...e.data()}).toList();
      final levels = levelsSnap.docs.map((e) => {'id': e.id, ...e.data()}).toList();

      if (!doc.exists) return;

      final data = doc.data()!;
      setState(() {
        topicOptions = topics;
        levelOptions = levels;
        bannerUrl = data['imageUrl'];
        topicId = data['topicId'];
        levelId = data['levelId'];

        for (var lang in _langs) {
          _titleControllers[lang] = TextEditingController(text: data['title_$lang'] ?? '');
          _descriptionControllers[lang] = TextEditingController(text: data['description_$lang'] ?? '');
        }
      });
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке курса: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      final updates = {
        'imageUrl': bannerUrl,
        'topicId': topicId ?? '',
        'levelId': levelId ?? '',
        for (var lang in _langs) ...{
          'title_$lang': _titleControllers[lang]?.text.trim() ?? '',
          'description_$lang': _descriptionControllers[lang]?.text.trim() ?? '',
        }
      };

      await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update(updates);
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

  Future<void> _changeBannerManually() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('change_banner')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: TranslationService.t('enter_image_url')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(widget.courseId)
                    .update({'imageUrl': url});
                if (mounted) {
                  setState(() => bannerUrl = url);
                  Navigator.pop(context);
                }
              }
            },
            child: Text(TranslationService.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.t('confirm_delete')),
        content: Text(TranslationService.t('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationService.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(TranslationService.t('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.t('edit_course')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: TranslationService.t('save'),
            onPressed: _saveChanges,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: TranslationService.t('change_banner'),
            onPressed: _changeBannerManually,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: TranslationService.t('delete'),
            onPressed: _confirmDeleteCourse,
          ),
          IconButton(
            icon: const Icon(Icons.folder_copy_outlined),
            tooltip: TranslationService.t('sections'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminSectionsScreen(courseId: widget.courseId),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (bannerUrl != null && bannerUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                bannerUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 160),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: topicId,
            decoration: const InputDecoration(labelText: 'Topic ID'),
            items: topicOptions.map((topic) {
              final label = topic['label_$lang'] ?? topic['id'];
              return DropdownMenuItem<String>(
                value: topic['id'],
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) => setState(() => topicId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: levelId,
            decoration: const InputDecoration(labelText: 'Level ID'),
            items: levelOptions.map((level) {
              final label = level['label_$lang'] ?? level['id'];
              return DropdownMenuItem<String>(
                value: level['id'],
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) => setState(() => levelId = value),
          ),
          const SizedBox(height: 16),
          for (var l in _langs) ...[
            TextField(
              controller: _titleControllers[l],
              decoration: InputDecoration(labelText: 'Title ($l)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionControllers[l],
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Description ($l)'),
            ),
            const SizedBox(height: 16),
          ]
        ],
      ),
    );
  }
}
