import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course_model.dart';
import '../screens/lessons/lesson_stage_list_screen.dart';
import '../services/translation_service.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final String userId;
  final bool isAdmin;

  const CourseCard({
    super.key,
    required this.course,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = course.getLocalizedTitle();
    final description = course.getLocalizedDescription();
    final imageUrl = course.imageUrl ?? '';

    final cardColor = isDark ? const Color(0xFF181A25) : colorScheme.surface;
    final descriptionColor = isDark ? Colors.grey[400] : Colors.grey[700];

    Widget imageWidget = imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasAbsolutePath == true
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            ),
          )
        : Container(
            height: 160,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 40, color: Colors.grey),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonStageListScreen(courseId: course.id, userId: userId),
          ),
        );
      },
      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      highlightColor: Colors.transparent,
      hoverColor: Theme.of(context).hoverColor.withOpacity(0.03), 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageWidget,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(color: descriptionColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
