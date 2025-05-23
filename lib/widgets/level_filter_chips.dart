import 'package:flutter/material.dart';
import '../../models/level_model.dart';
import '../../services/firebase_services/firebase_level_service.dart';

class LevelFilterChips extends StatelessWidget {
  final String selectedLevel;
  final void Function(String) onChanged;

  const LevelFilterChips({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<AppLevel>>(
      future: FirebaseLevelService.getAllLevels(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final levels = snapshot.data!;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((level) {
            final isSelected = level.id == selectedLevel;
            final selectedColor = isDark ? const Color(0xFF4751A2) : const Color(0xFFD6DCFF);
            final labelColor = isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Theme.of(context).colorScheme.onBackground;
            final borderColor = isSelected
                ? Colors.transparent
                : Colors.grey.withOpacity(0.3);

            return ChoiceChip(
              label: Text(
                level.getLocalizedLabel(),
                style: TextStyle(
                  color: labelColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(level.id),
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

