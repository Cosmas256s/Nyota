// lib/screens/shapesactivity.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyota/theme.dart';
import 'package:nyota/widgets/mascots.dart';

class ShapesActivityScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const ShapesActivityScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<ShapesActivityScreen> createState() => ShapesActivityScreenState();
}

class ShapesActivityScreenState extends State<ShapesActivityScreen> {
  int currentTrial = 0;
  final int questionsPerLevel = 10;
  int currentLevel = 1;
  final int maxLevel = 4;
  int correctInLevel = 0;
  int totalCorrect = 0;

  String targetShape = '';
  List<String> choices = [];
  bool showHint = false;

  FlutterTts flutterTts = FlutterTts();
  DateTime? sessionStartTime;

  final List<String> _shapePool = [
    'circle', 'square', 'triangle', 'star',
    'rectangle', 'oval', 'diamond', 'heart',
    'hexagon', 'pentagon'
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initTTS();
    sessionStartTime = DateTime.now();
    _loadProgress().then((_) => _generateNewTrial());
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.75);
    await flutterTts.setVolume(0.95);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    if (soundEnabled) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentLevel = prefs.getInt('shapes_level') ?? 1);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final accuracy = totalCorrect > 0 ? (totalCorrect / (currentTrial + 1) * 100).round() : 0;
    if (accuracy >= 85 && currentLevel < maxLevel) currentLevel++;
    else if (accuracy < 70 && currentLevel > 1) currentLevel--;
    await prefs.setInt('shapes_level', currentLevel);
  }

  bool _timeIsUp() {
    if (widget.maxDurationMinutes == null || sessionStartTime == null) return false;
    final elapsed = DateTime.now().difference(sessionStartTime!).inMinutes;
    return elapsed >= widget.maxDurationMinutes!;
  }

  List<String> _getShapesForLevel(int level) {
    switch (level) {
      case 1:
        return ['circle', 'square', 'triangle'];
      case 2:
        return ['circle', 'square', 'triangle', 'star', 'rectangle'];
      case 3:
        return ['circle', 'square', 'triangle', 'star', 'rectangle', 'oval', 'diamond'];
      case 4:
      default:
        return _shapePool;
    }
  }

  void _generateNewTrial() {
    if (_timeIsUp()) {
      _endSessionGracefully();
      return;
    }

    setState(() {
      final available = _getShapesForLevel(currentLevel);
      targetShape = available[Random().nextInt(available.length)];

      choices = [targetShape];
      while (choices.length < 3) {
        final distr = available[Random().nextInt(available.length)];
        if (distr != targetShape && !choices.contains(distr)) choices.add(distr);
      }
      choices.shuffle();
      showHint = false;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _speak("Find the $targetShape");
    });
  }

  void _handleTap(String selected) {
    if (_timeIsUp()) {
      _endSessionGracefully();
      return;
    }

    final isCorrect = selected == targetShape;

    setState(() {
      if (isCorrect) {
        correctInLevel++;
        totalCorrect++;
        _speak("Great job!");
        _showMiniRewardIfNeeded();
      } else {
        showHint = true;
        _speak("Try again");
        showMonkeyPrompt(context, "Oops! Look for the $targetShape! The hint will help! 💡");
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (isCorrect) {
        currentTrial++;

        if (correctInLevel >= questionsPerLevel && currentLevel < maxLevel) {
          setState(() {
            currentLevel++;
            correctInLevel = 0;
          });
          _speak("Level up! Let's find more shapes!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Level $currentLevel unlocked! 🌟"),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (currentTrial >= questionsPerLevel * maxLevel || _timeIsUp()) {
          _saveProgress();
          _endSessionGracefully();
        } else {
          _generateNewTrial();
        }
      }
    });
  }

  void _showMiniRewardIfNeeded() {
    if (correctInLevel > 0 && correctInLevel % 5 == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Amazing streak! $correctInLevel correct! ⭐⭐⭐"),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _endSessionGracefully() {
    _speak("Great work today! See you next time!");
    _showSessionReward();
  }

  void _showSessionReward() {
    double percentage = totalCorrect / (questionsPerLevel * maxLevel);
    int starCount = percentage >= 0.9 ? 3 : percentage >= 0.7 ? 2 : percentage >= 0.5 ? 1 : 0;
    showDinoResult(
      context: context,
      stars: starCount,
      score: totalCorrect,
      total: questionsPerLevel * maxLevel,
      accentColor: AppTheme.success,
      message: totalCorrect == questionsPerLevel * maxLevel ? '🏆 Perfect score!' : null,
      onContinue: () {
        Navigator.pop(context);
        widget.onSessionComplete();
      },
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 28.w),
            SizedBox(width: 12.w),
            Text(
              'Exit Activity?',
              style: GoogleFonts.fredoka(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Your progress will be saved. Are you sure you want to exit?',
          style: GoogleFonts.fredoka(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(fontSize: 16.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSessionComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.fredoka(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _restartActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.orange, size: 28.w),
            SizedBox(width: 12.w),
            Text(
              'Restart Activity?',
              style: GoogleFonts.fredoka(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will reset all your progress in this session. Continue?',
          style: GoogleFonts.fredoka(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(fontSize: 16.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentTrial = 0;
                currentLevel = 1;
                correctInLevel = 0;
                totalCorrect = 0;
              });
              Navigator.pop(context);
              _loadProgress().then((_) => _generateNewTrial());
              _speak("Starting over! Let's do our best!");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            child: Text(
              'Restart',
              style: GoogleFonts.fredoka(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(String shape, double size, {bool isHint = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color = isHint ? AppTheme.success : colorScheme.primary;

    switch (shape) {
      case 'circle':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      case 'square':
        return Container(width: size, height: size, color: color);
      case 'triangle':
        return CustomPaint(
          size: Size(size, size),
          painter: _TrianglePainter(color: color),
        );
      case 'star':
        return Icon(Icons.star_rounded, size: size, color: color);
      case 'rectangle':
        return Container(width: size * 1.4, height: size, color: color);
      case 'oval':
        return Container(
          width: size * 1.3,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(size / 2), color: color),
        );
      case 'diamond':
        return Transform.rotate(
          angle: pi / 4,
          child: Container(width: size * 0.7, height: size * 0.7, color: color),
        );
      case 'heart':
        return Icon(Icons.favorite, size: size, color: color);
      case 'hexagon':
      case 'pentagon':
        return Icon(Icons.polyline_rounded, size: size, color: color);
      default:
        return Icon(Icons.star_rounded, size: size, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back/Exit button
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      onPressed: _showExitConfirmation,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.primary,
                        size: 28.w,
                      ),
                      tooltip: 'Exit Activity',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Activity Title
                  Expanded(
                    child: Text(
                      'Shapes Activity',
                      style: GoogleFonts.fredoka(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  
                  // Restart button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      onPressed: _restartActivity,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.orange,
                        size: 28.w,
                      ),
                      tooltip: 'Restart Activity',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Help/Instructions button
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _speak("Find the matching shape. Tap on the shape that matches the one above.");
                      },
                      icon: Icon(
                        Icons.help_outline_rounded,
                        color: colorScheme.primary,
                        size: 28.w,
                      ),
                      tooltip: 'Instructions',
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress Bar
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentTrial + 1) / (questionsPerLevel * maxLevel),
                      backgroundColor: colorScheme.surfaceVariant,
                      color: colorScheme.primary,
                      minHeight: 14.h,
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    '${currentTrial + 1} / ${questionsPerLevel * maxLevel}',
                    style: GoogleFonts.fredoka(
                      fontSize: 18.sp, 
                      fontWeight: FontWeight.w600, 
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => setState(() => showHint = true),
                    icon: Icon(Icons.lightbulb_outline_rounded, color: colorScheme.primary, size: 28.w),
                    tooltip: 'Hint',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Target shape display
            Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Center(child: _buildShape(targetShape, 220.w)),
            ),

            const Spacer(),

            // Choice buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: choices.map((shape) {
                  final isHintedCorrect = shape == targetShape && showHint;
                  return GestureDetector(
                    onTap: () => _handleTap(shape),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 120.w,
                      height: 130.h,
                      decoration: BoxDecoration(
                        color: isHintedCorrect ? AppTheme.success.withOpacity(0.25) : colorScheme.surface,
                        borderRadius: BorderRadius.circular(28.r),
                        border: Border.all(
                          color: isHintedCorrect ? AppTheme.success : colorScheme.surfaceVariant,
                          width: isHintedCorrect ? 8.w : 4.w,
                        ),
                      ),
                      child: Center(child: _buildShape(shape, 78.w, isHint: isHintedCorrect)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(flex: 2),
            
            // Timer (only if time limit is set)
            if (widget.maxDurationMinutes != null && sessionStartTime != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Text(
                    "Time left: ${widget.maxDurationMinutes! - DateTime.now().difference(sessionStartTime!).inMinutes} min",
                    style: GoogleFonts.fredoka(fontSize: 16.sp, color: colorScheme.onSurface),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}