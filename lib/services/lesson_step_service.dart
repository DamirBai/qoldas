import 'lesson_progress_service.dart';

bool isAnswerCorrect(String selected, String correct) {
  return selected == correct;
}

Future<void> completeCurrentLesson({
  required String userId,
  required String courseId,
  required String sectionId,
  required String lessonId,
  required int percent, 
}) async {
  await LessonProgressService.completeLesson(
    userId: userId,
    courseId: courseId,
    sectionId: sectionId,
    lessonId: lessonId,
    percent: percent, 
  );
}
