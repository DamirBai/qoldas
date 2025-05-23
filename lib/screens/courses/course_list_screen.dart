import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/firebase_services/firebase_course_service.dart';
import '../../widgets/course_card.dart';
import '../../services/translation_service.dart';

class CourseListScreen extends StatefulWidget {
  final String topicId;
  final String levelId;
  final String userId;
  final bool isAdmin;

  const CourseListScreen({
    super.key,
    required this.topicId,
    required this.levelId,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<Course> courses = [];
  String topicTitle = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoursesAndTopic();
  }

  Future<void> _loadCoursesAndTopic() async {
    try {
      final lang = TranslationService.currentLang;

      final fetchedCourses = await FirebaseCourseService.getCoursesByTopicAndLevel(
        widget.topicId,
        widget.levelId,
      );

      final localizedTitle = await FirebaseCourseService.getLocalizedTopicTitle(
        widget.topicId,
        lang,
      );

      setState(() {
        topicTitle = localizedTitle;
        courses = fetchedCourses.map((map) => Course.fromMap(map['id'], map)).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки курсов или темы: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${TranslationService.t('courses')}: $topicTitle',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
              ? Center(
                  child: Text(
                    TranslationService.t('no_courses_found'),
                    style: TextStyle(color: colorScheme.onBackground),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CourseCard(
                        course: course,
                        userId: widget.userId,
                        isAdmin: widget.isAdmin,
                      ),
                    );
                  },
                ),
    );
  }
}
