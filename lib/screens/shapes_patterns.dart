// lib/screens/shapes_patterns.dart
// Sub-Activity 3: Identify and continue shape patterns
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nyota/theme.dart';
import 'package:nyota/widgets/mascots.dart';
import 'activity_extensions.dart';

class ShapesPatternsScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const ShapesPatternsScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<ShapesPatternsScreen> createState() => _ShapesPatternsScreenState();
}

class _ShapesPatternsScreenState extends State<ShapesPatternsScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late FlutterTts _tts;
  late AnimationController _bounceController;
  late AnimationController _wrongController;
  late Animation<double> _wrongShake;

  int _question = 0;
  final int _totalQuestions = 10;
  int _score = 0;
  int _hintsLeft = 3;
  DateTime? _sessionStart;
  int _extraMinutes = 0;
  int _extensionsUsed = 0;
  static const _maxExtensions = 3;

  late _PatternQuestion _current;
  int? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;

  static const _shapePool = ['circle', 'square', 'triangle', 'star', 'rectangle', 'heart', 'oval', 'diamond'];

  static const _colorSets = [
    [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1)],
    [Color(0xFFFFE66D), Color(0xFF6C63FF), Color(0xFFFF8B94)],
    [Color(0xFFA8E6CF), Color(0xFFFFB347), Color(0xFFDDA0DD)],
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _wrongController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _wrongShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _wrongController, curve: Curves.easeInOut));

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);
    _sessionStart = DateTime.now();
    _generateQuestion();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _bounceController.dispose();
    _wrongController.dispose();
    _tts.stop();
    super.dispose();
  }

  bool get _timeIsUp {
    if (widget.maxDurationMinutes == null || _sessionStart == null) return false;
    return DateTime.now().difference(_sessionStart!).inMinutes >= widget.maxDurationMinutes! + _extraMinutes;
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _handleTimeUp() {
    if (_extensionsUsed >= _maxExtensions) { _showResult(); return; }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimeExtensionDialog(
        extensionsLeft: _maxExtensions - _extensionsUsed,
        accentColor: const Color(0xFF11998E),
        onExtend: () {
          setState(() { _extraMinutes += 1; _extensionsUsed++; });
          Navigator.pop(context);
          _generateQuestion();
        },
        onFinish: () { Navigator.pop(context); _showResult(); },
      ),
    );
  }

  void _generateQuestion() {
    if (_timeIsUp) { _handleTimeUp(); return; }
    if (_question >= _totalQuestions) {
      _showResult();
      return;
    }

    final level = (_question ~/ 3) + 1; // 1, 2, 3
    _current = _buildPattern(level);
    _selectedAnswer = null;
    _answered = false;
    _isCorrect = false;

    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), () {
      _speak('What shape comes next?');
    });
  }

  _PatternQuestion _buildPattern(int level) {
    final colors = _colorSets[_rng.nextInt(_colorSets.length)];

    if (level == 1) {
      // AB pattern: circle square circle square circle [?] → square
      final shapes = _shapePool.take(4).toList()..shuffle(_rng);
      final a = shapes[0];
      final b = shapes[1];
      final seq = [a, b, a, b, a]; // answer = b
      final answer = b;
      final distractors = shapes.skip(2).take(3).toList();
      final opts = [answer, ...distractors]..shuffle(_rng);
      return _PatternQuestion(
        sequence: seq,
        answer: answer,
        options: opts,
        colors: List.generate(seq.length + 1, (i) => colors[i % colors.length]),
        optionColors: List.generate(opts.length, (_) => colors[_rng.nextInt(colors.length)]),
      );
    } else if (level == 2) {
      // ABC pattern: circle square triangle circle square [?] → triangle
      final shapes = _shapePool.take(6).toList()..shuffle(_rng);
      final a = shapes[0], b = shapes[1], c = shapes[2];
      final seq = [a, b, c, a, b]; // answer = c
      final answer = c;
      final distractors = shapes.skip(3).take(3).toList();
      final opts = [answer, ...distractors]..shuffle(_rng);
      return _PatternQuestion(
        sequence: seq,
        answer: answer,
        options: opts,
        colors: List.generate(seq.length + 1, (i) => colors[i % colors.length]),
        optionColors: List.generate(opts.length, (_) => colors[_rng.nextInt(colors.length)]),
      );
    } else {
      // AABB pattern: circle circle square square circle circle [?] → square
      final shapes = _shapePool.take(5).toList()..shuffle(_rng);
      final a = shapes[0], b = shapes[1];
      final seq = [a, a, b, b, a, a]; // answer = b
      final answer = b;
      final distractors = shapes.skip(2).take(3).toList();
      final opts = [answer, ...distractors]..shuffle(_rng);
      return _PatternQuestion(
        sequence: seq,
        answer: answer,
        options: opts,
        colors: List.generate(seq.length + 1, (i) => colors[i % colors.length]),
        optionColors: List.generate(opts.length, (_) => colors[_rng.nextInt(colors.length)]),
      );
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final correct = _current.options[index] == _current.answer;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _score++;
      _bounceController.forward(from: 0);
      _speak('Correct! Great job!');
    } else {
      _wrongController.forward(from: 0);
      _speak('Not quite! The answer is ${_current.answer}!');
      showMonkeyPrompt(context, "Not quite! Look at the pattern again! The answer is a ${_current.answer}! 💡");
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() => _question++);
      _generateQuestion();
    });
  }

  void _useHint() {
    if (_hintsLeft <= 0 || _answered) return;
    _hintsLeft--;
    _speak('The answer is a ${_current.answer}!');
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Hint: Look for the ${_current.answer}!', style: GoogleFonts.fredoka()),
      backgroundColor: Colors.amber[700],
      duration: const Duration(seconds: 2),
    ));
  }

  void _showResult() {
    final stars = _score >= _totalQuestions * 0.9 ? 3 : _score >= _totalQuestions * 0.6 ? 2 : _score >= 1 ? 1 : 0;
    showDinoResult(
      context: context,
      stars: stars,
      score: _score,
      total: _totalQuestions,
      accentColor: const Color(0xFF11998E),
      onContinue: () {
        Navigator.pop(context);
        widget.onSessionComplete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEFFF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            SizedBox(height: 12.h),
            _buildInstruction(),
            SizedBox(height: 16.h),
            Expanded(child: _buildContent()),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF11998E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back_rounded, color: const Color(0xFF11998E), size: 24.w),
            ),
          ),
          SizedBox(width: 12.w),
          Text('Shape Patterns', style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF11998E))),
          const Spacer(),
          // Progress bar
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: _question / _totalQuestions,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF11998E),
              minHeight: 10.h,
              borderRadius: BorderRadius.circular(5.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text('$_question/$_totalQuestions', style: GoogleFonts.fredoka(fontSize: 14.sp, color: const Color(0xFF11998E))),
          SizedBox(width: 12.w),
          // Hints
          GestureDetector(
            onTap: _useHint,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: _hintsLeft > 0 ? Colors.amber.withOpacity(0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _hintsLeft > 0 ? Colors.amber : Colors.grey[300]!, width: 1.5),
              ),
              child: Row(children: [
                Icon(Icons.lightbulb_rounded, color: _hintsLeft > 0 ? Colors.amber : Colors.grey, size: 16.w),
                SizedBox(width: 3.w),
                Text('$_hintsLeft', style: GoogleFonts.fredoka(fontSize: 14.sp, color: _hintsLeft > 0 ? Colors.amber[800]! : Colors.grey)),
              ]),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(16.r)),
            child: Row(children: [
              Icon(Icons.star_rounded, color: AppTheme.success, size: 16.w),
              SizedBox(width: 3.w),
              Text('$_score', style: GoogleFonts.fredoka(fontSize: 15.sp, color: AppTheme.success, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔮', style: TextStyle(fontSize: 24.sp)),
          SizedBox(width: 10.w),
          Text(
            'What shape comes next in the pattern?',
            style: GoogleFonts.fredoka(fontSize: 17.sp, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Pattern row
          Expanded(flex: 3, child: _buildPatternRow()),
          SizedBox(height: 16.h),
          // Answer choices
          Expanded(flex: 2, child: _buildChoices()),
        ],
      ),
    );
  }

  Widget _buildPatternRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: const Color(0xFF11998E).withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sequence shapes
          ...List.generate(_current.sequence.length, (i) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: _buildSequenceShape(_current.sequence[i], _current.colors[i], 44.w),
            );
          }),
          SizedBox(width: 8.w),
          // Arrow
          Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 28.w),
          SizedBox(width: 8.w),
          // Question mark slot
          AnimatedBuilder(
            animation: _answered && _isCorrect ? _bounceController : _wrongController,
            builder: (_, __) {
              if (_answered) {
                final offset = _isCorrect ? 0.0 : _wrongShake.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: _buildAnswerSlot(),
                );
              }
              return _buildAnswerSlot();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSlot() {
    return Container(
      width: 70.w,
      height: 70.h,
      decoration: BoxDecoration(
        color: _answered
            ? (_isCorrect ? AppTheme.success.withOpacity(0.15) : Colors.red[50])
            : const Color(0xFF11998E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _answered
              ? (_isCorrect ? AppTheme.success : Colors.red[300]!)
              : const Color(0xFF11998E).withOpacity(0.4),
          width: 2.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: _answered
            ? _buildSequenceShape(
                _current.options[_selectedAnswer!],
                _isCorrect ? AppTheme.success : Colors.red[400]!,
                40.w,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('?', style: GoogleFonts.fredoka(fontSize: 30.sp, color: const Color(0xFF11998E), fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildChoices() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_current.options.length, (i) {
        final isSelected = _selectedAnswer == i;
        final correct = _current.options[i] == _current.answer;
        Color borderColor = Colors.transparent;
        Color bgColor = Colors.white;

        if (_answered && isSelected) {
          borderColor = _isCorrect ? AppTheme.success : Colors.red[400]!;
          bgColor = _isCorrect ? AppTheme.success.withOpacity(0.1) : Colors.red[50]!;
        } else if (_answered && correct) {
          borderColor = AppTheme.success;
          bgColor = AppTheme.success.withOpacity(0.1);
        }

        return GestureDetector(
          onTap: () => _selectAnswer(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderColor.withOpacity(borderColor == Colors.transparent ? 0 : 1), width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: _buildSequenceShape(_current.options[i], _current.optionColors[i], 44.w),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSequenceShape(String shape, Color color, double size) {
    switch (shape) {
      case 'circle':
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
      case 'square':
        return Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)));
      case 'triangle':
        return CustomPaint(size: Size(size, size), painter: _TrianglePainter(color: color));
      case 'star':
        return Icon(Icons.star_rounded, size: size, color: color);
      case 'rectangle':
        return Container(width: size * 1.4, height: size * 0.7, color: color);
      case 'oval':
        return Container(width: size * 1.3, height: size * 0.8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2)));
      case 'diamond':
        return Transform.rotate(angle: pi / 4, child: Container(width: size * 0.7, height: size * 0.7, color: color));
      case 'heart':
        return Icon(Icons.favorite_rounded, size: size, color: color);
      default:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
  }
}

class _PatternQuestion {
  final List<String> sequence;
  final String answer;
  final List<String> options;
  final List<Color> colors;
  final List<Color> optionColors;

  const _PatternQuestion({
    required this.sequence,
    required this.answer,
    required this.options,
    required this.colors,
    required this.optionColors,
  });
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
