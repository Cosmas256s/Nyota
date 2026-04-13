import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/activity_model.dart';

abstract class ActivityBase {
  String get activityName;
  String get description;
  String get difficultyLevel;
  Color get activityColor;
  IconData get activityIcon;
  
  List<ActivityQuestion> generateQuestions(int childAge);
  
  String getEncouragementMessage() {
    final messages = [
      "You're doing great! 🌟",
      "Amazing work! ✨",
      "Keep shining! ⭐",
      "Wonderful job! 🎉",
      "You're a star learner! 🚀",
      "Fantastic! Keep going! 💫",
      "Brilliant effort! 🌈",
      "You make learning fun! 🎨",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }
  
  String getCompletionMessage() {
    return "You completed $activityName! 🎉";
  }
  
  String getWelcomeMessage() {
    return "Let's learn about $activityName!";
  }
}