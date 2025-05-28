import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для AnnotatedRegion и SystemUiOverlayStyle
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/lesson_video_player.dart';
import '../../services/lesson_progress_service.dart';
import '../../services/translation_service.dart';
import 'lesson_test_screen.dart';

class LessonScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;
  final String userId;

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.userId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> steps = [];
  Map<String, dynamic>? lessonData;
  bool hasTest = false;
  bool isUnlocked = true;
  bool isLessonCompleted = false;
  int currentStep = 0;
  List<bool> watchedSteps = [];
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    try {
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
          .orderBy('createdAt')
          .get();

      final testSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('sections')
          .doc(widget.sectionId)
          .collection('lessons')
          .doc(widget.lessonId)
          .collection('test')
          .get();

      final isCompleted = await LessonProgressService.isLessonCompleted(
        userId: widget.userId,
        courseId: widget.courseId,
        lessonId: widget.lessonId,
      );
      isLessonCompleted = isCompleted;

      final currentIndex = int.tryParse(widget.lessonId.split('_').last) ?? 0;
      if (currentIndex > 0) {
        final previousLessonId = 'lesson_${currentIndex - 1}';
        final prevCompleted = await LessonProgressService.isLessonCompleted(
          userId: widget.userId,
          courseId: widget.courseId,
          lessonId: previousLessonId,
        );
        isUnlocked = prevCompleted;
      }

      setState(() {
        lessonData = lessonDoc.data();
        steps = stepsSnapshot.docs.map((doc) => doc.data()).toList();
        watchedSteps = List.generate(steps.length, (i) => i == 0);
        hasTest = testSnapshot.docs.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки урока: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _completeLesson() async {
    if (isLessonCompleted || watchedSteps.contains(false)) return;

    await LessonProgressService.completeLesson(
      userId: widget.userId,
      courseId: widget.courseId,
      sectionId: widget.sectionId,
      lessonId: widget.lessonId,
      percent: 100,
    );

    setState(() {
      isLessonCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TranslationService.t('lesson_completed'))),
    );
  }

  void _goToTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTestScreen(
          courseId: widget.courseId,
          sectionId: widget.sectionId,
          lessonId: widget.lessonId,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = TranslationService.currentLang ?? 'en';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!isUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.t('lesson')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
        ),
        body: Center(
          child: Text(TranslationService.t('complete_previous_lesson')),
        ),
      );
    }

    if (lessonData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.t('lesson')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
        ),
        body: Center(
          child: Text(TranslationService.t('no_content')),
        ),
      );
    }

    final title = lessonData?['title_$lang'] ??
        lessonData?['title_en'] ??
        lessonData?['title_ru'] ??
        lessonData?['title_kk'] ??
        '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title.isNotEmpty ? title : TranslationService.t('lesson')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
        ),
        body: Column(
          children: [
            if (steps.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: LinearProgressIndicator(
                  value: (watchedSteps.where((e) => e).length) / steps.length,
                  minHeight: 6,
                  color: colorScheme.primary,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: currentStep > 0
                        ? () => setState(() {
                              currentStep--;
                              watchedSteps[currentStep] = true;
                              _pageController.jumpToPage(currentStep);
                            })
                        : null,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() {
                        currentStep = index;
                        watchedSteps[index] = true;
                      }),
                      itemCount: steps.length,
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        final video = step['videoUrl'] ?? '';
                        final desc = step['description_$lang'] ??
                            step['description_en'] ??
                            step['description_ru'] ??
                            step['description_kk'] ??
                            '';

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (video.isNotEmpty)
                                AspectRatio(
                                  aspectRatio: 9 / 16,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: LessonVideoPlayer(videoUrl: video),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                '${TranslationService.t('step')} ${index + 1} / ${steps.length}',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(desc, style: const TextStyle(fontSize: 18)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: currentStep < steps.length - 1
                        ? () => setState(() {
                              currentStep++;
                              watchedSteps[currentStep] = true;
                              _pageController.jumpToPage(currentStep);
                            })
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed:
                    (!isLessonCompleted && !watchedSteps.contains(false))
                        ? _completeLesson
                        : null,
                child: Text(
                  isLessonCompleted
                      ? TranslationService.t('completed')
                      : TranslationService.t('mark_as_completed'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (hasTest && isLessonCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _goToTest,
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(TranslationService.t('start_test')),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
