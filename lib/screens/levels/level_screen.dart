import 'package:flutter/material.dart';
import '../../models/topic_model.dart';
import '../../models/level_model.dart';
import '../../services/firebase_services/firebase_level_service.dart';
import '../courses/course_list_screen.dart';
import '../../services/translation_service.dart';

class LevelScreen extends StatefulWidget {
  final AppTopic topic;
  final String userId;
  final bool isAdmin;

  const LevelScreen({
    super.key,
    required this.topic,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  List<AppLevel> levels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final loadedLevels = await FirebaseLevelService.getAllLevels();
      setState(() {
        levels = loadedLevels;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки уровней: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${TranslationService.t('select_level')} — ${widget.topic.getLocalizedLabel()}',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : levels.isEmpty
              ? Center(
                  child: Text(
                    TranslationService.t('no_levels_found'),
                    style: TextStyle(color: colorScheme.onBackground, fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: levels.map((level) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseListScreen(
                                  topicId: widget.topic.id,
                                  levelId: level.id,
                                  userId: widget.userId,
                                  isAdmin: widget.isAdmin,
                                ),
                              ),
                            );
                          },
                          child: Text(level.getLocalizedLabel()),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
