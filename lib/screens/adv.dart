import 'package:flutter/material.dart';
import 'activity_base.dart';
import 'activity_model.dart';
class AdvancedMathActivity extends ActivityBase {
  @override
  String get activityName => 'Advanced Math';

  @override
  String get description => 'Multiply & divide!';

  @override
  String get difficultyLevel => 'advanced';

  @override
  Color get activityColor => const Color(0xFF96CEB4);

  @override
  IconData get activityIcon => Icons.grid_view;

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
