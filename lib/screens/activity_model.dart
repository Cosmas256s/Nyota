import 'package:flutter/material.dart';

class ActivityQuestion {
  final String? questionText; // Optional minimal text
  final List<Widget> visualOptions; // Visual answer options
  final int correctOptionIndex;
  final Widget visualHint; // Visual hint instead of text
  final String? audioHintPath; // Optional audio support
  final IconData? visualIcon;

  ActivityQuestion({
    this.questionText, // Can be null for purely visual activities
    required this.visualOptions,
    required this.correctOptionIndex,
    required this.visualHint,
    this.audioHintPath,
    this.visualIcon,
  });
}

