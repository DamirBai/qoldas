import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/translation_service.dart';
import '../../services/lesson_progress_service.dart';
import 'package:flutter/services.dart';
import '../../widgets/lesson_video_player.dart';

class LessonTestScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;
  final String userId;

  const LessonTestScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.userId,
  });

  @override
  State<LessonTestScreen> createState() => _LessonTestScreenState();
}

class _LessonTestScreenState extends State<LessonTestScreen> {
  List<QueryDocumentSnapshot> allQuestions = [];
  List<QueryDocumentSnapshot> questions = [];
  List<QueryDocumentSnapshot> incorrect = [];
  Map<String, int> selectedAnswers = {};
  bool isLoading = true;
  int currentIndex = 0;
  Set<String> retried = {};
  bool answered = false;
  int? selectedOption;

  final AudioPlayer player = AudioPlayer();
  String emoji = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final testSnap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('test')
        .limit(1)
        .get();

    if (testSnap.docs.isEmpty) return;

    final testId = testSnap.docs.first.id;
    final qSnap = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('sections')
        .doc(widget.sectionId)
        .collection('lessons')
        .doc(widget.lessonId)
        .collection('test')
        .doc(testId)
        .collection('question')
        .get();

    final docs = qSnap.docs..shuffle();
    setState(() {
      allQuestions = docs;
      questions = List.from(docs);
      isLoading = false;
    });
  }

  void _submit(int selected) {
    if (answered) return;

    final currentQ = questions[currentIndex];
    final correct = currentQ['rightAnswerIndex'];
    final isCorrect = selected == correct;

    setState(() {
      selectedAnswers[currentQ.id] = selected;
      selectedOption = selected;
      answered = true;
    });

    if (!isCorrect && !retried.contains(currentQ.id)) {
      HapticFeedback.heavyImpact();
      incorrect.add(currentQ);
      retried.add(currentQ.id);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (currentIndex + 1 < questions.length) {
        setState(() {
          currentIndex++;
          answered = false;
          selectedOption = null;
        });
      } else if (incorrect.isNotEmpty) {
        setState(() {
          questions = [...incorrect];
          incorrect.clear();
          currentIndex = 0;
          answered = false;
          selectedOption = null;
        });
      } else {
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    int correctCount = selectedAnswers.entries.where((e) {
      final q = allQuestions.firstWhere((q) => q.id == e.key);
      return e.value == q['rightAnswerIndex'];
    }).length;

    final percent = (correctCount / allQuestions.length * 100).round();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('testResults')
        .doc(widget.lessonId)
        .set({
      'lessonId': widget.lessonId,
      'courseId': widget.courseId,
      'correct': correctCount,
      'total': allQuestions.length,
      'percent': percent,
      'completedAt': DateTime.now(),
    });

    await LessonProgressService.completeLesson(
      userId: widget.userId,
      courseId: widget.courseId,
      sectionId: widget.sectionId,
      lessonId: widget.lessonId,
      percent: percent,
    );

    if (percent >= 70) {
      emoji = '🎉';
      player.play(AssetSource('sounds/success.mp3'));
    } else if (percent >= 40) {
      emoji = '👍';
      player.play(AssetSource('sounds/ok.mp3'));
    } else {
      emoji = '😕';
      player.play(AssetSource('sounds/fail.mp3'));
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Result',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOut.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    '${TranslationService.t('correct')}: $correctCount / ${allQuestions.length}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${TranslationService.t('percent')}: $percent%',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 150), () {
                      Navigator.of(context).pop();
                    });
                  },
                  child: Text(TranslationService.t('ok')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionWithKey() {
    return KeyedSubtree(
      key: ValueKey(currentIndex),
      child: _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = questions[currentIndex];
    final lang = TranslationService.currentLang;
    final answersMap = Map<String, dynamic>.from(q['answers']);
    final answers = List<String>.from(answersMap[lang] ?? answersMap['en'] ?? []);
    final title = q['title_$lang'] ?? q['title'];
    final videoUrl = q['questionUrl'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (videoUrl != null && videoUrl.toString().endsWith('.mp4'))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: MediaQuery.of(context).size.height * 0.35 * (9 / 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LessonVideoPlayer(
                    key: ValueKey(videoUrl),
                    videoUrl: videoUrl,
                  ),
                ),
              ),
            ),
          ),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(answers.length, (i) {
          final isCorrect = i == q['rightAnswerIndex'];
          final isSelected = selectedOption == i;

          Color? color;
          if (answered && isSelected) {
            color = isCorrect ? Colors.green : Colors.red;
          } else if (answered && isCorrect) {
            color = Colors.green;
          }

          return Card(
            color: color,
            child: ListTile(
              title: Text(
                answers[i],
                style: TextStyle(
                  color: color != null ? Colors.white : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: answered ? null : () => _submit(i),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: LinearProgressIndicator(
          value: selectedAnswers.length / (allQuestions.length + retried.length),
          minHeight: 4,
          backgroundColor: Colors.grey[300],
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _buildQuestionWithKey(),
      ),
    );
  }
}
