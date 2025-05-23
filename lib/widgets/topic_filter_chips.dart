import 'package:flutter/material.dart';
import '../../models/topic_model.dart';
import '../../services/firebase_services/firebase_topic_service.dart';

class TopicFilterChips extends StatelessWidget {
  final String selectedTopic;
  final void Function(String) onChanged;

  const TopicFilterChips({
    super.key,
    required this.selectedTopic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AppTopic>>(
      future: FirebaseTopicService.getAllTopics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final topics = snapshot.data!;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) {
            final isSelected = topic.id == selectedTopic;
            final selectedColor = isDark ? const Color(0xFF4751A2) : const Color(0xFFD6DCFF);
            final labelColor = isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Theme.of(context).colorScheme.onBackground;
            final borderColor = isSelected
                ? Colors.transparent
                : Colors.grey.withOpacity(0.3);

            return ChoiceChip(
              label: Text(
                topic.getLocalizedLabel(),
                style: TextStyle(
                  color: labelColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(topic.id),
              selectedColor: selectedColor,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        );
      },
    );
  }
}
