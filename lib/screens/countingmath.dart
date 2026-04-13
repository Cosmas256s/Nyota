// lib/screens/countingmath.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyota/theme.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class CountingActivityScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const CountingActivityScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<CountingActivityScreen> createState() => _CountingActivityScreenState();
}

class _CountingActivityScreenState extends State<CountingActivityScreen> {
  int currentTrial = 0;
  final int questionsPerLevel = 10;
  int currentLevel = 1;
  final int maxLevel = 4;
  int correctInLevel = 0;
  int totalCorrect = 0;

  int targetCount = 0;
  List<int> choices = [];
  bool showHint = false;

  FlutterTts flutterTts = FlutterTts();
  DateTime? sessionStartTime;

  final List<IconData> objectIcons = [
    Icons.star_rounded,
    Icons.circle,
    Icons.favorite,
    Icons.rocket_launch,
    Icons.pets,
  ];

  @override
  void initState() {
    super.initState();
    _initTTS();
    sessionStartTime = DateTime.now();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _loadLevel().then((_) => _generateNewTrial());
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

  @override
  void dispose() {
    flutterTts.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentLevel = prefs.getInt('counting_level') ?? 1);
  }

  Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final accuracy = totalCorrect > 0 ? (totalCorrect / (currentTrial + 1) * 100).round() : 0;
    if (accuracy >= 85 && currentLevel < maxLevel) {
      currentLevel++;
    } else if (accuracy < 70 && currentLevel > 1) {
      currentLevel--;
    }
    await prefs.setInt('counting_level', currentLevel);
  }

  bool _timeIsUp() {
    if (widget.maxDurationMinutes == null || sessionStartTime == null) return false;
    final elapsedMinutes = DateTime.now().difference(sessionStartTime!).inMinutes;
    return elapsedMinutes >= widget.maxDurationMinutes!;
  }

  void _generateNewTrial() {
    if (_timeIsUp()) {
      _endSessionGracefully();
      return;
    }

    setState(() {
      final maxObjects = [5, 7, 10, 13][currentLevel - 1].clamp(5, 13);

      const minCount = 4;
      final possibleCounts = List.generate(maxObjects - minCount + 1, (i) => minCount + i);

      targetCount = possibleCounts[Random().nextInt(possibleCounts.length)];

      choices = [targetCount];
      while (choices.length < 3) {
        final distr = possibleCounts[Random().nextInt(possibleCounts.length)];
        if (distr != targetCount && !choices.contains(distr)) {
          choices.add(distr);
        }
      }
      choices.shuffle();
      showHint = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _speak("How many objects do you see?");
    });
  }

  void _handleTap(int selected) {
    if (_timeIsUp()) {
      _endSessionGracefully();
      return;
    }

    final isCorrect = selected == targetCount;

    setState(() {
      if (isCorrect) {
        correctInLevel++;
        totalCorrect++;
        _speak("Great job!");
        _showMiniRewardIfNeeded();
      } else {
        showHint = true;
        _speak("Try again");
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
          _speak("Level up! Let's count even more!");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Level $currentLevel unlocked! 🌟"),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (currentTrial >= questionsPerLevel * maxLevel || _timeIsUp()) {
          _saveLevel();
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
          content: Text("Fantastic streak! $correctInLevel correct! ⭐⭐⭐"),
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.success.withOpacity(0.2),
                Colors.amber.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500 + (index * 200)),
                      curve: Curves.elasticOut,
                      child: Icon(
                        index < starCount ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 80.w,
                        color: index < starCount ? Colors.amber : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24.h),
              
              // Message
              Text(
                starCount == 3 ? "AMAZING! 🌟🌟🌟" :
                starCount == 2 ? "GREAT JOB! 🌟🌟" :
                starCount == 1 ? "GOOD WORK! 🌟" :
                "KEEP PRACTICING! 💪",
                style: GoogleFonts.fredoka(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Score
              Text(
                "You got $totalCorrect out of ${questionsPerLevel * maxLevel} correct!",
                style: GoogleFonts.fredoka(
                  fontSize: 20.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 24.h),
              
              // Final Reward for Perfect Score
              if (totalCorrect == questionsPerLevel * maxLevel && widget.rewardImagePath != null)
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.amber, width: 3.w),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "🏆 PERFECT SCORE! 🏆",
                        style: GoogleFonts.fredoka(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: 120.w,
                        height: 120.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          image: DecorationImage(
                            image: AssetImage(widget.rewardImagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "You earned your special reward! 🎁",
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 32.h),
              
              // Continue Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSessionComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: GoogleFonts.fredoka(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              _loadLevel().then((_) => _generateNewTrial());
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

  Widget _buildObjects(int count, double size) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: List.generate(count, (_) => Icon(
        objectIcons[Random().nextInt(objectIcons.length)],
        size: size.w,
        color: Theme.of(context).colorScheme.primary,
      )),
    );
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
                      'Counting Activity',
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
                        _speak("Count the objects and choose the correct number.");
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

            // Objects display
            Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Center(child: _buildObjects(targetCount, 42.w)),
            ),

            const Spacer(),

            // Choice buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: choices.map((num) {
                  final isHinted = num == targetCount && showHint;
                  return GestureDetector(
                    onTap: () => _handleTap(num),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 100.w,
                      height: 110.h,
                      decoration: BoxDecoration(
                        color: isHinted ? AppTheme.success.withOpacity(0.25) : colorScheme.surface,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isHinted ? AppTheme.success : colorScheme.surfaceVariant,
                          width: isHinted ? 7.w : 3.w,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            num.toString(),
                            style: GoogleFonts.fredoka(fontSize: 32.sp, fontWeight: FontWeight.w700, color: colorScheme.primary),
                          ),
                          SizedBox(height: 6.h),
                          _buildObjects(num, 14.w),
                        ],
                      ),
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