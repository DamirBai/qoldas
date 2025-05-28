import 'package:flutter/material.dart';
import 'admin_questions_screen.dart';

class AdminQuestionsScreenWrapper extends StatelessWidget {
  const AdminQuestionsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return AdminQuestionsScreen(
      courseId: args['courseId'],
      sectionId: args['sectionId'],
      lessonId: args['lessonId'],
      testId: args['testId'],
    );
  }
}
