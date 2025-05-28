import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для AnnotatedRegion и SystemUiOverlayStyle
import '../../models/topic_model.dart';
import '../../widgets/topic_card.dart';
import '../levels/level_screen.dart';
import '../admin/admin_courses_screen.dart';
import '../../services/translation_service.dart';
import '../../services/firebase_services/firebase_topic_service.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final bool isAdmin;

  const HomeScreen({super.key, required this.userId, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<AppTopic>> _futureTopics;

  @override
  void initState() {
    super.initState();
    _futureTopics = FirebaseTopicService.getAllTopics();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? colorScheme.surfaceVariant.withOpacity(0.2)
            : colorScheme.surfaceVariant.withOpacity(0.05),
        appBar: AppBar(
          title: Text(
            TranslationService.t('learning_topics'),
            style: TextStyle(color: colorScheme.onBackground),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
        body: Column(
          children: [
            if (widget.isAdmin)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminCoursesScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(TranslationService.t('manage_courses')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<AppTopic>>(
                future: _futureTopics,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final topics = snapshot.data ?? [];

                  if (topics.isEmpty) {
                    return Center(
                      child: Text(
                        TranslationService.t('no_topics_available'),
                        style: TextStyle(
                          color: colorScheme.onBackground,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: topics.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return TopicCard(
                        topic: topic,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LevelScreen(
                                topic: topic,
                                userId: widget.userId,
                                isAdmin: widget.isAdmin,
                              ),
                            ),
                          );
                        },
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
}
