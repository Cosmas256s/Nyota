// lib/screens/shapes_find_pairs.dart
// Sub-Activity 2: Find pairs of identical shapes hidden in a scene
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

class ShapesFindPairsScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const ShapesFindPairsScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<ShapesFindPairsScreen> createState() => _ShapesFindPairsScreenState();
}

class _ShapesFindPairsScreenState extends State<ShapesFindPairsScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late FlutterTts _tts;
  late AnimationController _celebrateController;
  late AnimationController _shakeController;

  int _round = 0;
  final int _totalRounds = 6;
  int _score = 0;
  int? _firstSelectedIndex;
  String? _firstSelectedShape;
  Set<int> _matchedIndices = {};
  bool _checking = false;
  int _mistakes = 0;
  DateTime? _sessionStart;
  int _extraMinutes = 0;
  int _extensionsUsed = 0;
  static const _maxExtensions = 3;

  late List<_PairItem> _gridItems;
  late int _gridCols;
  late int _gridRows;

  static const _shapePool = ['circle', 'square', 'triangle', 'star', 'rectangle', 'oval', 'diamond', 'heart'];
  static const _colorPalette = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFFFE66D), Color(0xFFA8E6CF), Color(0xFF6C63FF),
    Color(0xFFFF8B94), Color(0xFFFFB347),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _celebrateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);
    _sessionStart = DateTime.now();
    _buildRound();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _celebrateController.dispose();
    _shakeController.dispose();
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
        accentColor: const Color(0xFF6C63FF),
        onExtend: () {
          setState(() { _extraMinutes += 1; _extensionsUsed++; });
          Navigator.pop(context);
          _buildRound();
        },
        onFinish: () { Navigator.pop(context); _showResult(); },
      ),
    );
  }

  void _buildRound() {
    if (_timeIsUp) { _handleTimeUp(); return; }
    if (_round >= _totalRounds) {
      _showResult();
      return;
    }

    // Determine grid size based on round
    final level = (_round ~/ 2) + 1;
    final pairsCount = 3 + level * 2; // 5, 5, 7, 7, 9, 9...
    _gridCols = 5 + (level - 1);
    _gridRows = ((pairsCount * 2) / _gridCols).ceil();

    // Pick shapes: each appears exactly twice
    final shapes = List<String>.from(_shapePool)..shuffle(_rng);
    final picked = shapes.take(pairsCount).toList();

    // Assign colors: same shape may have different color (size/color variation)
    final items = <_PairItem>[];
    for (final shape in picked) {
      // Two instances with potentially different colors & sizes
      final color1 = _colorPalette[_rng.nextInt(_colorPalette.length)];
      Color color2;
      do {
        color2 = _colorPalette[_rng.nextInt(_colorPalette.length)];
      } while (color2 == color1 && _colorPalette.length > 1);

      final size1 = 32.0 + _rng.nextDouble() * 18;
      final size2 = 32.0 + _rng.nextDouble() * 18;

      items.add(_PairItem(shape: shape, color: color1, size: size1, pairId: shape));
      items.add(_PairItem(shape: shape, color: color2, size: size2, pairId: shape));
    }
    items.shuffle(_rng);

    // Pad to fill grid
    while (items.length < _gridCols * _gridRows) {
      items.add(_PairItem(shape: 'empty', color: Colors.transparent, size: 32, pairId: 'empty'));
    }

    setState(() {
      _gridItems = items;
      _firstSelectedIndex = null;
      _firstSelectedShape = null;
      _matchedIndices = {};
      _mistakes = 0;
      _checking = false;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _speak('Find the matching shape pairs!');
    });
  }

  void _tapItem(int index) async {
    if (_checking) return;
    final item = _gridItems[index];
    if (item.shape == 'empty') return;
    if (_matchedIndices.contains(index)) return;
    if (_firstSelectedIndex == index) {
      setState(() => _firstSelectedIndex = null);
      return;
    }

    if (_firstSelectedIndex == null) {
      setState(() {
        _firstSelectedIndex = index;
        _firstSelectedShape = item.shape;
      });
      _speak(item.shape);
    } else {
      final first = _firstSelectedIndex!;
      setState(() => _checking = true);

      if (item.shape == _firstSelectedShape) {
        // Match!
        await Future.delayed(const Duration(milliseconds: 300));
        _celebrateController.forward(from: 0);
        setState(() {
          _matchedIndices.addAll([first, index]);
          _firstSelectedIndex = null;
          _firstSelectedShape = null;
          _checking = false;
        });
        _speak('Matched! Great job!');

        // Check if all matched
        final totalReal = _gridItems.where((i) => i.shape != 'empty').length;
        if (_matchedIndices.length >= totalReal) {
          _score++;
          Future.delayed(const Duration(milliseconds: 800), () {
            setState(() => _round++);
            _buildRound();
          });
        }
      } else {
        // Wrong
        _mistakes++;
        setState(() => _firstSelectedIndex = null);
        _speak('Not a match, try again!');
        showMonkeyPrompt(context, "Hmm, those don't match! Try again! 🤔");
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() => _checking = false);
      }
    }
  }

  void _showResult() {
    final stars = _score >= _totalRounds * 0.9 ? 3 : _score >= _totalRounds * 0.6 ? 2 : _score >= 1 ? 1 : 0;
    showDinoResult(
      context: context,
      stars: stars,
      score: _score,
      total: _totalRounds,
      accentColor: const Color(0xFF6C63FF),
      onContinue: () {
        Navigator.pop(context);
        widget.onSessionComplete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalReal = _gridItems.where((i) => i.shape != 'empty').length;
    final pairsLeft = (totalReal - _matchedIndices.length) ~/ 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(pairsLeft),
            SizedBox(height: 8.h),
            _buildInstructions(pairsLeft),
            SizedBox(height: 10.h),
            Expanded(child: _buildGrid()),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int pairsLeft) {
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
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back_rounded, color: const Color(0xFF6C63FF), size: 24.w),
            ),
          ),
          SizedBox(width: 12.w),
          Text('Shape Pairs', style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF))),
          const Spacer(),
          // Round progress
          Row(
            children: List.generate(_totalRounds, (i) => Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _round ? AppTheme.success : i == _round ? const Color(0xFF6C63FF) : Colors.grey[300],
              ),
            )),
          ),
          SizedBox(width: 16.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20.r)),
            child: Row(children: [
              Icon(Icons.star_rounded, color: AppTheme.success, size: 18.w),
              SizedBox(width: 4.w),
              Text('$_score', style: GoogleFonts.fredoka(fontSize: 16.sp, color: AppTheme.success, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(int pairsLeft) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F3D90)]),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Text('✌️', style: TextStyle(fontSize: 28.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Tap two shapes that look the same!',
              style: GoogleFonts.fredoka(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12.r)),
            child: Text(
              '$pairsLeft pairs left',
              style: GoogleFonts.fredoka(fontSize: 14.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final cellW = constraints.maxWidth / _gridCols;
            final cellH = constraints.maxHeight / _gridRows;

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridCols,
                childAspectRatio: cellW / cellH,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
              ),
              itemCount: _gridItems.length,
              itemBuilder: (ctx, i) => _buildCell(i),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final item = _gridItems[index];
    if (item.shape == 'empty') return const SizedBox();

    final isSelected = _firstSelectedIndex == index;
    final isMatched = _matchedIndices.contains(index);

    return GestureDetector(
      onTap: () => _tapItem(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isMatched
              ? AppTheme.success.withOpacity(0.15)
              : isSelected
                  ? const Color(0xFF6C63FF).withOpacity(0.15)
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isMatched
                ? AppTheme.success
                : isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.grey[200]!,
            width: isSelected || isMatched ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Center(
          child: isMatched
              ? Icon(Icons.check_circle_rounded, color: AppTheme.success, size: item.size)
              : _buildShape(item.shape, item.size, item.color),
        ),
      ),
    );
  }

  Widget _buildShape(String shape, double size, Color color) {
    switch (shape) {
      case 'circle':
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
      case 'square':
        return Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
      case 'triangle':
        return CustomPaint(size: Size(size, size), painter: _TrianglePainter(color: color));
      case 'star':
        return Icon(Icons.star_rounded, size: size, color: color);
      case 'rectangle':
        return Container(width: size * 1.5, height: size * 0.75, color: color);
      case 'oval':
        return Container(width: size * 1.3, height: size * 0.85, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2)));
      case 'diamond':
        return Transform.rotate(angle: pi / 4, child: Container(width: size * 0.7, height: size * 0.7, color: color));
      case 'heart':
        return Icon(Icons.favorite_rounded, size: size, color: color);
      default:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
  }
}

class _PairItem {
  final String shape;
  final Color color;
  final double size;
  final String pairId;

  const _PairItem({required this.shape, required this.color, required this.size, required this.pairId});
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
