import 'package:flutter/material.dart';
import 'activity_base.dart';
import 'activity_model.dart';

class CountingActivity extends ActivityBase {
  @override
  String get activityName => 'Counting';

  @override
  String get description => 'Count objects!';

  @override
  String get difficultyLevel => 'beginner';

  @override
  Color get activityColor => const Color(0xFF4ECDC4);

  @override
  IconData get activityIcon => Icons.calculate;

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
