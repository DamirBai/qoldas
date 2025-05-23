import 'package:flutter/material.dart';
import '../models/topic_model.dart';
import '../services/translation_service.dart';

class TopicCard extends StatelessWidget {
  final AppTopic topic;
  final VoidCallback onTap;

  const TopicCard({super.key, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = topic.getLocalizedLabel();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
          color: isDark
              ? colorScheme.surface.withOpacity(0.3)
              : colorScheme.surfaceVariant.withOpacity(0.1),
        ),
        clipBehavior: Clip.hardEdge, 
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (topic.image.isNotEmpty)
              Opacity(
                opacity: 0.3, 
                child: Image.network(
                  topic.image,
                  fit: BoxFit.cover,
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
