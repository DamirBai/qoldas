import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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

  late Box<Course> _coursesBox;

  @override
  void initState() {
    super.initState();
    _initAndLoadData();
  }

  Future<void> _initAndLoadData() async {
    _coursesBox = await Hive.openBox<Course>('coursesBox');

    // Загрузить локализованный заголовок темы из локального или сетевого источника
    final lang = TranslationService.currentLang;
    final cachedCourses = _coursesBox.values
        .where((c) => c.topicId == widget.topicId && c.levelId == widget.levelId)
        .toList();

    // Показываем курсы из кэша
    setState(() {
      courses = cachedCourses;
      isLoading = false;
    });

    // Загружаем заголовок темы (можно кэшировать отдельно, если нужно)
    final localizedTitle = await FirebaseCourseService.getLocalizedTopicTitle(widget.topicId, lang);
    setState(() {
      topicTitle = localizedTitle;
    });

    // Фоновая синхронизация курсов из Firestore
    await _syncCoursesWithFirestore();

    // После синхронизации обновляем курсы в UI
    final updatedCourses = _coursesBox.values
        .where((c) => c.topicId == widget.topicId && c.levelId == widget.levelId)
        .toList();

    if (!listEquals(courses, updatedCourses)) {
      setState(() {
        courses = updatedCourses;
      });
    }
  }

  Future<void> _syncCoursesWithFirestore() async {
    try {
      final fetchedCourses = await FirebaseCourseService.getCoursesByTopicAndLevel(
        widget.topicId,
        widget.levelId,
      );

      final firestoreCourses = {
        for (var map in fetchedCourses) map['id']: Course.fromMap(map['id'], map),
      };

      final localIds = _coursesBox.keys.cast<String>().toSet();

      for (final id in firestoreCourses.keys) {
        final firestoreCourse = firestoreCourses[id]!;
        if (localIds.contains(id)) {
          final localCourse = _coursesBox.get(id);
          if (localCourse == null ||
              localCourse.titlesJson != firestoreCourse.titlesJson ||
              localCourse.descriptionsJson != firestoreCourse.descriptionsJson) {
            await _coursesBox.put(id, firestoreCourse);
          }
          localIds.remove(id);
        } else {
          await _coursesBox.put(id, firestoreCourse);
        }
      }

      for (final idToRemove in localIds) {
        await _coursesBox.delete(idToRemove);
      }
    } catch (e) {
      debugPrint('Ошибка синхронизации курсов: $e');
    }
  }

  @override
  void dispose() {
    _coursesBox.close();
    super.dispose();
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
