import 'package:flutter/material.dart';
import 'activity_base.dart';
import 'activity_model.dart';

class ShapesActivity extends ActivityBase {
  @override
  String get activityName => 'Shapes';

  @override
  String get description => 'Learn shapes!';

  @override
  String get difficultyLevel => 'beginner';

  @override
  Color get activityColor => const Color(0xFFFF6B6B);

  @override
  IconData get activityIcon => Icons.category;

  @override
  List<ActivityQuestion> generateQuestions(int childAge) {
    final questions = <ActivityQuestion>[];

    // Your shape question logic here...
    // Example placeholder:
    questions.add(ActivityQuestion(
      visualOptions: [],  // fill with real widgets later
      correctOptionIndex: 0,
      visualHint: const SizedBox(),  // placeholder
    ));

    return questions;  // ← this line was missing
  }
}