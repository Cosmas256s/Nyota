// lib/screens/shapes_find_shape.dart
// Sub-Activity 1: Find the hidden shape in a scene
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

class ShapesFindShapeScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const ShapesFindShapeScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<ShapesFindShapeScreen> createState() => _ShapesFindShapeScreenState();
}

class _ShapesFindShapeScreenState extends State<ShapesFindShapeScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  late FlutterTts _tts;
  late AnimationController _successController;
  late AnimationController _pulseController;

  int _round = 0;
  int _totalRounds = 8;
  int _score = 0;
  String _targetShape = '';
  late List<_SceneItem> _sceneItems;
  Set<int> _foundIndices = {};
  bool _roundComplete = false;
  int _hintsLeft = 3;
  DateTime? _sessionStart;
  int _extraMinutes = 0;
  int _extensionsUsed = 0;
  static const _maxExtensions = 3;

  static const _shapes = ['circle', 'square', 'triangle', 'star', 'rectangle', 'oval', 'diamond', 'heart'];
  static const _sceneColors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFFFE66D), Color(0xFFA8E6CF), Color(0xFFFF8B94),
    Color(0xFF6C63FF), Color(0xFFFFB347), Color(0xFF98D8C8),
    Color(0xFFDDA0DD), Color(0xFF87CEEB), Color(0xFFF0E68C),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);
    _sessionStart = DateTime.now();
    _startRound();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _successController.dispose();
    _pulseController.dispose();
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
    if (_extensionsUsed >= _maxExtensions) { _endSession(); return; }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimeExtensionDialog(
        extensionsLeft: _maxExtensions - _extensionsUsed,
        accentColor: const Color(0xFFFF6B6B),
        onExtend: () {
          setState(() { _extraMinutes += 1; _extensionsUsed++; });
          Navigator.pop(context);
          _startRound();
        },
        onFinish: () { Navigator.pop(context); _endSession(); },
      ),
    );
  }

  void _startRound() {
    if (_timeIsUp) { _handleTimeUp(); return; }
    if (_round >= _totalRounds) {
      _endSession();
      return;
    }

    final level = (_round ~/ 3) + 1; // levels 1-3
    final shapesForLevel = level == 1
        ? ['circle', 'square', 'triangle']
        : level == 2
            ? ['circle', 'square', 'triangle', 'star', 'rectangle']
            : _shapes;

    _targetShape = shapesForLevel[_rng.nextInt(shapesForLevel.length)];
    _foundIndices = {};
    _roundComplete = false;

    // Build scene: 12-16 shapes scattered
    final count = 12 + level * 2;
    final items = <_SceneItem>[];

    // How many targets to find: 2-3
    final targetCount = 2 + _rng.nextInt(2);
    int placed = 0;

    for (int i = 0; i < count; i++) {
      final isTarget = placed < targetCount && (_rng.nextInt(count - i) < (targetCount - placed));
      final shape = isTarget ? _targetShape : _pickDistractor(shapesForLevel, _targetShape);
      if (isTarget) placed++;
      final color = _sceneColors[_rng.nextInt(_sceneColors.length)];
      final size = 36.0 + _rng.nextDouble() * 28;
      final angle = _rng.nextDouble() * pi * 2;
      items.add(_SceneItem(
        shape: shape,
        isTarget: isTarget,
        color: color,
        size: size,
        rotation: angle,
      ));
    }

    // Make sure at least 2 targets are in
    while (placed < 2) {
      final idx = _rng.nextInt(items.length);
      if (!items[idx].isTarget) {
        items[idx] = _SceneItem(
          shape: _targetShape,
          isTarget: true,
          color: _sceneColors[_rng.nextInt(_sceneColors.length)],
          size: items[idx].size,
          rotation: items[idx].rotation,
        );
        placed++;
      }
    }

    items.shuffle(_rng);

    setState(() {
      _sceneItems = items;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _speak('Find all the ${_targetShape}s!');
    });
  }

  String _pickDistractor(List<String> pool, String exclude) {
    final choices = pool.where((s) => s != exclude).toList();
    if (choices.isEmpty) return pool[_rng.nextInt(pool.length)];
    return choices[_rng.nextInt(choices.length)];
  }

  void _tapItem(int index) {
    if (_foundIndices.contains(index) || _roundComplete) return;
    final item = _sceneItems[index];

    if (item.isTarget) {
      _speak('Great!');
      setState(() => _foundIndices.add(index));

      final allTargets = _sceneItems.asMap().entries.where((e) => e.value.isTarget).map((e) => e.key).toSet();
      if (_foundIndices.containsAll(allTargets)) {
        setState(() {
          _roundComplete = true;
          _score++;
        });
        _successController.forward(from: 0);
        _speak('You found them all! Amazing!');
        Future.delayed(const Duration(milliseconds: 1800), () {
          setState(() => _round++);
          _startRound();
        });
      }
    } else {
      _speak('That\'s a ${item.shape}, keep looking!');
      showMonkeyPrompt(context, "That\'s a ${item.shape}! Keep looking for the ${_targetShape}! 🔍");
      setState(() {
        _sceneItems[index] = _SceneItem(
          shape: item.shape,
          isTarget: false,
          color: item.color,
          size: item.size,
          rotation: item.rotation,
          isWrong: true,
        );
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _sceneItems[index] = _SceneItem(
              shape: item.shape,
              isTarget: false,
              color: item.color,
              size: item.size,
              rotation: item.rotation,
            );
          });
        }
      });
    }
  }

  void _useHint() {
    if (_hintsLeft <= 0 || _roundComplete) return;
    final unfound = _sceneItems.asMap().entries.where((e) => e.value.isTarget && !_foundIndices.contains(e.key)).toList();
    if (unfound.isEmpty) return;
    final pick = unfound[_rng.nextInt(unfound.length)];
    setState(() {
      _sceneItems[pick.key] = _SceneItem(
        shape: pick.value.shape,
        isTarget: true,
        color: pick.value.color,
        size: pick.value.size,
        rotation: pick.value.rotation,
        isHinted: true,
      );
      _hintsLeft--;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _sceneItems.length > pick.key && !_foundIndices.contains(pick.key)) {
        setState(() {
          _sceneItems[pick.key] = _SceneItem(
            shape: pick.value.shape,
            isTarget: true,
            color: pick.value.color,
            size: pick.value.size,
            rotation: pick.value.rotation,
          );
        });
      }
    });
  }

  void _endSession() {
    _showResult();
  }

  void _showResult() {
    final stars = _score >= _totalRounds * 0.9 ? 3 : _score >= _totalRounds * 0.6 ? 2 : _score >= 1 ? 1 : 0;
    showDinoResult(
      context: context,
      stars: stars,
      score: _score,
      total: _totalRounds,
      accentColor: const Color(0xFFFF6B6B),
      onContinue: () {
        Navigator.pop(context);
        widget.onSessionComplete();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetCount = _sceneItems.where((s) => s.isTarget).length;
    final foundCount = _foundIndices.length;
    final remaining = targetCount - foundCount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(remaining),
            SizedBox(height: 4.h),

            // Instruction banner
            _buildInstruction(),
            SizedBox(height: 6.h),

            // Scene
            Expanded(child: _buildScene()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int remaining) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: const Color(0xFFFFF8F0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back_rounded, color: const Color(0xFFFF6B6B), size: 24.w),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Shape Hunt',
            style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B6B)),
          ),
          const Spacer(),
          // Progress dots
          Row(
            children: List.generate(_totalRounds, (i) => Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _round
                    ? AppTheme.success
                    : i == _round
                        ? const Color(0xFFFF6B6B)
                        : Colors.grey[300],
              ),
            )),
          ),
          SizedBox(width: 16.w),
          // Hints
          GestureDetector(
            onTap: _useHint,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _hintsLeft > 0 ? Colors.amber.withOpacity(0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _hintsLeft > 0 ? Colors.amber : Colors.grey[300]!, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: _hintsLeft > 0 ? Colors.amber : Colors.grey, size: 18.w),
                  SizedBox(width: 4.w),
                  Text('$_hintsLeft', style: GoogleFonts.fredoka(fontSize: 15.sp, color: _hintsLeft > 0 ? Colors.amber[800]! : Colors.grey)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: AppTheme.success, size: 18.w),
                SizedBox(width: 4.w),
                Text('$_score', style: GoogleFonts.fredoka(fontSize: 16.sp, color: AppTheme.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    final targetCount = _sceneItems.where((s) => s.isTarget).length;
    final foundCount = _foundIndices.length;
    final remaining = targetCount - foundCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Transform.scale(
              scale: 1.0 + _pulseController.value * 0.08,
              child: child,
            ),
            child: _buildShapePreview(_targetShape, 36.w, Colors.white),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find all the ${_targetShape}s!',
                style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                remaining > 0 ? '$remaining more to find' : '✅ All found!',
                style: GoogleFonts.fredoka(fontSize: 13.sp, color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          // Found indicators
          Row(
            children: List.generate(targetCount, (i) => Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: 14.w,
              height: 14.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < foundCount ? Colors.white : Colors.white38,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildScene() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.blue[100]!, width: 2),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cols = 8;
          final rows = (_sceneItems.length / cols).ceil();
          final cellW = constraints.maxWidth / cols;
          final cellH = constraints.maxHeight / rows;

          return Stack(
            children: [
              // Grid of scene items
              ...List.generate(_sceneItems.length, (i) {
                final col = i % cols;
                final row = i ~/ cols;
                final item = _sceneItems[i];
                final found = _foundIndices.contains(i);

                return Positioned(
                  left: col * cellW + (cellW - item.size) / 2,
                  top: row * cellH + (cellH - item.size) / 2,
                  child: GestureDetector(
                    onTap: () => _tapItem(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Transform.rotate(
                        angle: item.rotation,
                        child: _buildShapeWidget(item, found),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShapeWidget(_SceneItem item, bool found) {
    Color color = item.color;
    if (found) color = AppTheme.success;
    if (item.isWrong) color = Colors.red[300]!;
    if (item.isHinted) color = Colors.amber;

    Widget shape = _buildShapePreview(item.shape, item.size, color);

    if (found) {
      return Stack(
        children: [
          Opacity(opacity: 0.4, child: shape),
          Positioned.fill(
            child: Center(
              child: Icon(Icons.check_circle_rounded, color: AppTheme.success, size: item.size * 0.6),
            ),
          ),
        ],
      );
    }
    if (item.isHinted) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 12, spreadRadius: 3)],
        ),
        child: shape,
      );
    }
    return shape;
  }

  Widget _buildShapePreview(String shape, double size, Color color) {
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
        return Container(width: size * 1.5, height: size, color: color);
      case 'oval':
        return Container(width: size * 1.4, height: size * 0.85, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2)));
      case 'diamond':
        return Transform.rotate(angle: pi / 4, child: Container(width: size * 0.7, height: size * 0.7, color: color));
      case 'heart':
        return Icon(Icons.favorite_rounded, size: size, color: color);
      default:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
  }
}

class _SceneItem {
  final String shape;
  final bool isTarget;
  final Color color;
  final double size;
  final double rotation;
  final bool isWrong;
  final bool isHinted;

  const _SceneItem({
    required this.shape,
    required this.isTarget,
    required this.color,
    required this.size,
    required this.rotation,
    this.isWrong = false,
    this.isHinted = false,
  });
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
