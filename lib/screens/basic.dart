import 'package:flutter/material.dart';
import 'activity_base.dart';
import 'activity_model.dart';

class BasicMathActivity extends ActivityBase {
  @override
  String get activityName => 'Basic Math';

  @override
  String get description => 'Add & subtract!';

  @override
  String get difficultyLevel => 'intermediate';

  @override
  Color get activityColor => const Color(0xFF45B7D1);

  @override
  IconData get activityIcon => Icons.add_circle;

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
