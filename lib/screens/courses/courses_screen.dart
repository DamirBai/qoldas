import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Импорт Hive Flutter
import '../../models/course_model.dart';
import '../../models/topic_model.dart';
import '../../models/level_model.dart';
import '../../services/firebase_services/firebase_topic_service.dart';
import '../../services/firebase_services/firebase_level_service.dart';
import '../../widgets/course_card.dart';
import '../../services/translation_service.dart';

class CoursesScreen extends StatefulWidget {
  final String userId;
  final bool isAdmin;

  const CoursesScreen({
    super.key,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final ValueNotifier<Map<String, String>> filters = ValueNotifier({
    'topic': 'all',
    'level': 'all',
    'search': '',
  });

  final ScrollController _scrollController = ScrollController();
  bool showShadow = false;

  List<Course> allCourses = [];
  List<AppTopic> topics = [];
  List<AppLevel> levels = [];
  bool isLoading = true;

  late Box<Course> _coursesBox;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 5;
      if (scrolled != showShadow) {
        setState(() {
          showShadow = scrolled;
        });
      }
    });

    _initAndLoadData();
  }

  Future<void> _initAndLoadData() async {
    // Инициализация Hive (если не инициализирован)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CourseAdapter()); // Зарегистрируй адаптер Course
    }
    await Hive.initFlutter();

    _coursesBox = await Hive.openBox<Course>('coursesBox');

    // Загрузка тем и уровней с Firestore
    final topicSnap = await FirebaseTopicService.getAllTopics();
    final levelSnap = await FirebaseLevelService.getAllLevels();

    // Загрузка кэшированных курсов
    final cachedCourses = _coursesBox.values.toList();

    setState(() {
      allCourses = cachedCourses;
      topics = topicSnap;
      levels = levelSnap;
      isLoading = false; // Убираем индикатор
    });

    // Асинхронная синхронизация с Firestore
    _syncCoursesWithFirestore().then((_) {
      final updatedCourses = _coursesBox.values.toList();
      if (!listEquals(allCourses, updatedCourses)) {
        setState(() {
          allCourses = updatedCourses;
        });
      }
    });
  }

  Future<void> _syncCoursesWithFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('courses').get();

      final firestoreCourses = {
        for (var doc in querySnapshot.docs)
          doc.id: Course.fromMap(doc.id, doc.data()),
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

  void _updateFilter(String key, String value) {
    final updated = Map<String, String>.from(filters.value);
    updated[key] = value;
    filters.value = updated;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _coursesBox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchFieldColor = isDark ? const Color(0xFF2F3552) : const Color(0xFFE9EBF4);
    final searchIconColor = isDark ? Colors.white : Colors.black54;
    final hintColor = isDark ? Colors.white70 : Colors.black38;
    final inputTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Поисковая строка
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: searchFieldColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: searchIconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (value) => _updateFilter('search', value),
                              style: TextStyle(color: inputTextColor),
                              decoration: InputDecoration(
                                hintText: TranslationService.t('search_course'),
                                hintStyle: TextStyle(color: hintColor),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Фильтр по темам
                  ValueListenableBuilder<Map<String, String>>(
                    valueListenable: filters,
                    builder: (context, value, _) => SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildChip(
                            context,
                            label: TranslationService.t('all_topics'),
                            selected: value['topic'] == 'all',
                            onTap: () => _updateFilter('topic', 'all'),
                          ),
                          ...topics.map((t) => _buildChip(
                                context,
                                label: t.getLocalizedLabel(),
                                selected: value['topic'] == t.id,
                                onTap: () => _updateFilter('topic', t.id),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Фильтр по уровням
                  ValueListenableBuilder<Map<String, String>>(
                    valueListenable: filters,
                    builder: (context, value, _) => SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildChip(
                            context,
                            label: TranslationService.t('all_levels'),
                            selected: value['level'] == 'all',
                            onTap: () => _updateFilter('level', 'all'),
                          ),
                          ...levels.map((l) => _buildChip(
                                context,
                                label: l.getLocalizedLabel(),
                                selected: value['level'] == l.id,
                                onTap: () => _updateFilter('level', l.id),
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Тень под AppBar (скролл)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: showShadow ? 8 : 0,
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                        bottom: Radius.circular(20),
                      ),
                    ),
                  ),

                  // Список курсов
                  Expanded(
                    child: ValueListenableBuilder<Map<String, String>>(
                      valueListenable: filters,
                      builder: (context, value, _) {
                        final search = value['search']!.toLowerCase();
                        final topic = value['topic'];
                        final level = value['level'];

                        final filtered = allCourses.where((c) {
                          final title = c.getLocalizedTitle().toLowerCase();
                          final matchesSearch = title.contains(search);
                          final matchesTopic = topic == 'all' || c.topicId == topic;
                          final matchesLevel = level == 'all' || c.levelId == level;
                          return matchesSearch && matchesTopic && matchesLevel;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              TranslationService.t('no_courses_found'),
                              style: TextStyle(color: colorScheme.onBackground),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final course = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CourseCard(
                                course: course,
                                userId: widget.userId,
                                isAdmin: widget.isAdmin,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChip(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark ? const Color(0xFF4751A2) : const Color(0xFFD6DCFF);
    final borderColor = selected ? Colors.transparent : Colors.grey.withOpacity(0.4);
    final labelColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : Theme.of(context).colorScheme.onBackground;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: selectedColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
