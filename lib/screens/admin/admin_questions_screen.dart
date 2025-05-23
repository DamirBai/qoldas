import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/translation_service.dart';

class AdminQuestionsScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;
  final String testId;

  const AdminQuestionsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.testId,
  });

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _titleControllers;
  late Map<String, List<TextEditingController>> _answerControllers;
  late TextEditingController _questionUrlController;
  late TextEditingController _correctIndexController;

  @override
  void initState() {
    super.initState();
    _titleControllers = {
      'ru': TextEditingController(),
      'en': TextEditingController(),
      'kk': TextEditingController(),
    };
    _answerControllers = {
      'ru': List.generate(4, (_) => TextEditingController()),
      'en': List.generate(4, (_) => TextEditingController()),
      'kk': List.generate(4, (_) => TextEditingController()),
    };
    _questionUrlController = TextEditingController();
    _correctIndexController = TextEditingController(text: '0');
  }

  Future<void> _addQuestion() async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('sections')
          .doc(widget.sectionId)
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('test')
          .doc(widget.testId)
          .collection('question')
          .add({
        'title_ru': _titleControllers['ru']!.text.trim(),
        'title_en': _titleControllers['en']!.text.trim(),
        'title_kk': _titleControllers['kk']!.text.trim(),
        'type': 'text',
        'questionUrl': _questionUrlController.text.trim(),
        'answers': {
          for (var lang in ['ru', 'en', 'kk'])
            lang: _answerControllers[lang]!.map((c) => c.text.trim()).toList(),
        },
        'rightAnswerIndex': int.tryParse(_correctIndexController.text) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _clearFields();
    } catch (e) {
      debugPrint('❌ Ошибка добавления вопроса: $e');
    }
  }

  void _clearFields() {
    for (var controller in _titleControllers.values) {
      controller.clear();
    }
    for (var lang in _answerControllers.keys) {
      for (var controller in _answerControllers[lang]!) {
        controller.clear();
      }
    }
    _questionUrlController.clear();
    _correctIndexController.text = '0';
  }

  Future<void> _editQuestion(BuildContext context, DocumentSnapshot questionDoc) async {
    final data = questionDoc.data() as Map<String, dynamic>;
    _titleControllers['ru']!.text = data['title_ru'] ?? '';
    _titleControllers['en']!.text = data['title_en'] ?? '';
    _titleControllers['kk']!.text = data['title_kk'] ?? '';
    _questionUrlController.text = data['questionUrl'] ?? '';
    _correctIndexController.text = (data['rightAnswerIndex'] ?? 0).toString();

    final answers = Map<String, List>.from(data['answers'] ?? {});
    for (var lang in ['ru', 'en', 'kk']) {
      for (int i = 0; i < 4; i++) {
        _answerControllers[lang]![i].text = answers[lang]?[i] ?? '';
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TranslationService.t('edit_question')),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _questionUrlController,
                  decoration: InputDecoration(labelText: 'Video URL'),
                ),
                ...['ru', 'en', 'kk'].map((lang) => TextFormField(
                      controller: _titleControllers[lang],
                      decoration: InputDecoration(labelText: 'Title ($lang)'),
                    )),
                const SizedBox(height: 12),
                Text(TranslationService.t('answers_by_lang')),
                ...['ru', 'en', 'kk'].expand((lang) {
                  return List.generate(4, (i) {
                    return TextFormField(
                      controller: _answerControllers[lang]![i],
                      decoration: InputDecoration(labelText: 'Answer ${i + 1} ($lang)'),
                    );
                  });
                }),
                TextFormField(
                  controller: _correctIndexController,
                  decoration: InputDecoration(labelText: TranslationService.t('correct_index')),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = {
                'title_ru': _titleControllers['ru']!.text.trim(),
                'title_en': _titleControllers['en']!.text.trim(),
                'title_kk': _titleControllers['kk']!.text.trim(),
                'type': 'text',
                'questionUrl': _questionUrlController.text.trim(),
                'answers': {
                  for (var lang in ['ru', 'en', 'kk'])
                    lang: _answerControllers[lang]!.map((c) => c.text.trim()).toList(),
                },
                'rightAnswerIndex': int.tryParse(_correctIndexController.text) ?? 0,
              };
              await questionDoc.reference.update(updated);
              if (mounted) Navigator.pop(context);
            },
            child: Text(TranslationService.t('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang;
    final questionsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('test')
        .doc(widget.testId)
        .collection('question')
        .orderBy('createdAt');

    return Scaffold(
      appBar: AppBar(title: Text(TranslationService.t('questions'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(TranslationService.t('load_error')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final questions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final title = q['title_$lang'] ?? q['title_en'] ?? q['title_ru'] ?? q['title_kk'] ?? 'No title';
              return ListTile(
                title: Text(title),
                subtitle: Text('${TranslationService.t('type')}: ${q['type']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _editQuestion(context, q)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => q.reference.delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(TranslationService.t('add_question')),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _questionUrlController,
                        decoration: InputDecoration(labelText: 'Video URL'),
                      ),
                      ...['ru', 'en', 'kk'].map((lang) => TextFormField(
                            controller: _titleControllers[lang],
                            decoration: InputDecoration(labelText: 'Title ($lang)'),
                          )),
                      const SizedBox(height: 12),
                      Text(TranslationService.t('answers_by_lang')),
                      ...['ru', 'en', 'kk'].expand((lang) {
                        return List.generate(4, (i) {
                          return TextFormField(
                            controller: _answerControllers[lang]![i],
                            decoration: InputDecoration(labelText: 'Answer ${i + 1} ($lang)'),
                          );
                        });
                      }),
                      TextFormField(
                        controller: _correctIndexController,
                        decoration: InputDecoration(labelText: TranslationService.t('correct_index')),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(TranslationService.t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _addQuestion();
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(TranslationService.t('create')),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: TranslationService.t('add_question'),
      ),
    );
  }
}
