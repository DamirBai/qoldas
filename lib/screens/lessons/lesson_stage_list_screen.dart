import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/translation_service.dart';
import 'lesson_module_list_screen.dart';
import '../../services/lesson_progress_service.dart';

class LessonStageListScreen extends StatefulWidget {
  final String courseId;
  final String userId;

  const LessonStageListScreen({
    super.key,
    required this.courseId,
    required this.userId,
  });

  @override
  State<LessonStageListScreen> createState() => _LessonStageListScreenState();
}

class _LessonStageListScreenState extends State<LessonStageListScreen> {
  bool isLoading = true;
  List<QueryDocumentSnapshot> sections = [];
  Map<String, double> sectionProgress = {};
  Map<String, int> sectionTotals = {};
  Map<String, int> sectionCompleted = {};

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final sectionQuery = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('sections')
          .orderBy('createdAt')
          .get();

      final allProgress = await LessonProgressService.getCompletedLessons(
        widget.userId,
        widget.courseId,
      );

      final sectionDocs = sectionQuery.docs;
      final Map<String, double> progressMap = {};
      final Map<String, int> totals = {};
      final Map<String, int> completedMap = {};

      for (final section in sectionDocs) {
        final sectionId = section.id;

        final lessonQuery = await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .collection('sections')
            .doc(sectionId)
            .collection('lessons')
            .get();

        final lessonIds = lessonQuery.docs.map((doc) => doc.id).toSet();
        final total = lessonIds.length;

        final completed = allProgress
            .where((entry) =>
                lessonIds.contains(entry['lessonId']) &&
                entry['sectionId'] == sectionId &&
                entry['completed'] == true)
            .toList();

        final completedCount = completed.length;
        final percent = total > 0 ? (completedCount / total) * 100 : 0.0;

        progressMap[sectionId] = percent;
        totals[sectionId] = total;
        completedMap[sectionId] = completedCount;
      }

      setState(() {
        sections = sectionDocs;
        sectionProgress = progressMap;
        sectionTotals = totals;
        sectionCompleted = completedMap;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки секций: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = TranslationService.currentLang;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text(TranslationService.t('sections')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final sectionId = section.id;
                  final percent = sectionProgress[sectionId] ?? 0.0;
                  final total = sectionTotals[sectionId] ?? 0;
                  final completed = sectionCompleted[sectionId] ?? 0;

                  final sectionMap = section.data() as Map<String, dynamic>;
                  final titleField = 'title_$lang';

                  final title = sectionMap[titleField] ??
                      sectionMap['title'] ??
                      sectionMap['title_en'] ??
                      sectionMap['title_ru'] ??
                      '${TranslationService.t('section')} ${index + 1}';

                  final isUnlocked = index == 0 ||
                      (sectionProgress[sections[index - 1].id] ?? 0) >= 100;

                  final progressText = percent >= 100
                      ? TranslationService.t('completed')
                      : '${TranslationService.t('in_progress')} • ${percent.toStringAsFixed(0)}%';

                  final progressDetails = '$progressText ($completed / $total)';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isDark
                              ? const Color(0xFF2D2F3B)
                              : const Color(0xFFF4F6FC))
                          : Theme.of(context).disabledColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked ? colorScheme.primary.withOpacity(0.4) : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      title: Row(
                        children: [
                          Icon(
                            percent >= 100 ? Icons.check_circle : Icons.hourglass_bottom,
                            color: percent >= 100 ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isUnlocked ? colorScheme.onSurface : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 6,
                            color: colorScheme.primary,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progressDetails,
                            style: TextStyle(
                              color: isUnlocked ? colorScheme.primary : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: isUnlocked ? colorScheme.primary : Colors.grey,
                      ),
                      onTap: isUnlocked
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LessonModuleListScreen(
                                    courseId: widget.courseId,
                                    userId: widget.userId,
                                    sectionId: sectionId,
                                  ),
                                ),
                              ).then((_) => _loadSections());
                            }
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}