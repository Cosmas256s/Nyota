// lib/screens/shapes_tracing.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

class ShapesTracingScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;

  const ShapesTracingScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
  });

  @override
  State<ShapesTracingScreen> createState() => _ShapesTracingScreenState();
}

class _ShapesTracingScreenState extends State<ShapesTracingScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrateCtrl;
  late AnimationController _hintCtrl;
  late FlutterTts _tts;

  // Which shape we're currently tracing
  int _shapeIndex = 0;
  int _completedCount = 0;

  // User's drawn strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Progress: how much of the shape guide path has been covered
  double _progress = 0.0;
  bool _shapeComplete = false;

  static const _shapes = [
    _ShapeMeta(name: 'Circle', color: Color(0xFFE53935), bg: Color(0xFFFFF3E0)),
    _ShapeMeta(name: 'Triangle', color: Color(0xFF7B1FA2), bg: Color(0xFFF3E5F5)),
    _ShapeMeta(name: 'Square', color: Color(0xFF0277BD), bg: Color(0xFFE3F2FD)),
    _ShapeMeta(name: 'Star', color: Color(0xFF2E7D32), bg: Color(0xFFE8F5E9)),
    _ShapeMeta(name: 'Diamond', color: Color(0xFFFF6F00), bg: Color(0xFFFFF8E1)),
  ];

  _ShapeMeta get _current => _shapes[_shapeIndex % _shapes.length];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);

    Future.delayed(const Duration(milliseconds: 500), _announceShape);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _celebrateCtrl.dispose();
    _hintCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _announceShape() => _speak('Trace the ${_current.name}!');

  // Build the guide path for the current shape (in a given canvas rect)
  Path _buildGuidePath(Rect r) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    const rad = 110.0;

    switch (_current.name) {
      case 'Circle':
        return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rad * 2, height: rad * 2));

      case 'Triangle':
        return Path()
          ..moveTo(cx, cy - rad)
          ..lineTo(cx + rad, cy + rad)
          ..lineTo(cx - rad, cy + rad)
          ..close();

      case 'Square':
        return Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: rad * 2, height: rad * 2));

      case 'Star':
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final rr = i.isEven ? rad : rad * 0.42;
          final angle = (i * pi / 5) - pi / 2;
          final p = Offset(cx + rr * cos(angle), cy + rr * sin(angle));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        return path;

      case 'Diamond':
        return Path()
          ..moveTo(cx, cy - rad)
          ..lineTo(cx + rad * 0.7, cy)
          ..lineTo(cx, cy + rad)
          ..lineTo(cx - rad * 0.7, cy)
          ..close();

      default:
        return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rad * 2, height: rad * 2));
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (_shapeComplete) return;
    setState(() {
      _currentStroke = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_shapeComplete) return;
    setState(() {
      _currentStroke.add(d.localPosition);
      _updateProgress(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_shapeComplete) return;
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes.add(List.from(_currentStroke));
      }
      _currentStroke = [];
    });
  }

  // Measure coverage by sampling the guide path and checking proximity of drawn strokes
  void _updateProgress(Offset pos) {
    // Cheap approximation: count how many sample points on the path are
    // within a threshold distance of any drawn point
    // We update incrementally for performance.
    // Real approach: check proximity to guide path
    // For fluid UX we just grow progress when the user draws near the guide
    final size = context.size;
    if (size == null) return;
    final guideRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.5),
      width: size.width,
      height: size.height,
    );
    final guidePath = _buildGuidePath(guideRect);
    final metrics = guidePath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    const samples = 60;
    int covered = 0;

    for (int i = 0; i < samples; i++) {
      final t = i / samples;
      final dist = totalLen * t;
      double acc = 0;
      for (final m in metrics) {
        if (dist <= acc + m.length) {
          final tangent = m.getTangentForOffset(dist - acc);
          if (tangent != null) {
            final guidePoint = tangent.position;
            // Check all drawn points for proximity
            bool near = false;
            for (final stroke in _strokes) {
              for (final pt in stroke) {
                if ((pt - guidePoint).distance < 28) { near = true; break; }
              }
              if (near) break;
            }
            if (!near) {
              for (final pt in _currentStroke) {
                if ((pt - guidePoint).distance < 28) { near = true; break; }
              }
            }
            if (near) covered++;
          }
          break;
        }
        acc += m.length;
      }
    }

    final newProgress = (covered / samples).clamp(0.0, 1.0);
    if (newProgress > _progress) {
      _progress = newProgress;
    }

    if (_progress >= 0.72 && !_shapeComplete) {
      _onShapeComplete();
    }
  }

  void _onShapeComplete() {
    setState(() => _shapeComplete = true);
    _celebrateCtrl.forward();
    _speak('Amazing! You traced the ${_current.name}!');

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _completedCount++;
        _shapeIndex++;
        _strokes.clear();
        _currentStroke = [];
        _progress = 0;
        _shapeComplete = false;
      });
      _celebrateCtrl.reset();
      Future.delayed(const Duration(milliseconds: 400), _announceShape);

      // After all shapes, finish session
      if (_completedCount >= _shapes.length) {
        widget.onSessionComplete();
        Navigator.pop(context);
      }
    });
  }

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final guideRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.5),
      width: size.width,
      height: size.height,
    );
    final guidePath = _buildGuidePath(guideRect);

    return Scaffold(
      backgroundColor: _current.bg,
      body: Stack(
        children: [
          // Drawing canvas
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TracingPainter(
                guidePath: guidePath,
                strokes: _strokes,
                currentStroke: _currentStroke,
                accentColor: _current.color,
                progress: _progress,
                hintAnim: _hintCtrl,
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Back
                  _RoundBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: _current.color,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  // Clear
                  _RoundBtn(
                    icon: Icons.refresh_rounded,
                    color: _current.color,
                    onTap: _clearDrawing,
                  ),
                  const Spacer(),
                  // Progress dots
                  Row(
                    children: List.generate(_shapes.length, (i) {
                      final done = i < _completedCount;
                      final active = i == _shapeIndex % _shapes.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: done
                              ? _current.color
                              : active
                                  ? _current.color.withOpacity(0.8)
                                  : _current.color.withOpacity(0.2),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Progress ring
                  SizedBox(
                    width: 44, height: 44,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 5,
                          backgroundColor: _current.color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(_current.color),
                        ),
                        Center(
                          child: Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _current.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Celebration overlay
          if (_shapeComplete)
            AnimatedBuilder(
              animation: _celebrateCtrl,
              builder: (_, __) {
                final t = CurvedAnimation(parent: _celebrateCtrl, curve: Curves.elasticOut).value;
                return Center(
                  child: Transform.scale(
                    scale: t,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      decoration: BoxDecoration(
                        color: _current.color,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: _current.color.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 54)),
                          const SizedBox(height: 8),
                          Text(
                            '${_current.name}!',
                            style: GoogleFonts.fredoka(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── TRACING PAINTER ───────────────────────────────────────────────────────────
class _TracingPainter extends CustomPainter {
  final Path guidePath;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color accentColor;
  final double progress;
  final AnimationController hintAnim;

  _TracingPainter({
    required this.guidePath,
    required this.strokes,
    required this.currentStroke,
    required this.accentColor,
    required this.progress,
    required this.hintAnim,
  }) : super(repaint: hintAnim);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Glow behind guide
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.08 + hintAnim.value * 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(guidePath, glowPaint);

    // 2. Dashed guide outline
    _drawDashedPath(canvas, guidePath, Paint()
      ..color = accentColor.withOpacity(0.30 + hintAnim.value * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);

    // 3. Filled guide shape (very light)
    canvas.drawPath(guidePath, Paint()
      ..color = accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill);

    // 4. Solid guide outline
    canvas.drawPath(guidePath, Paint()
      ..color = accentColor.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // 5. User strokes
    final drawPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, drawPaint);
    }

    if (currentStroke.length >= 2) {
      final path = Path()..moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, drawPaint);
    }

    // 6. Hint arrow at the starting point of the guide
    final metrics = guidePath.computeMetrics().toList();
    if (metrics.isNotEmpty && progress < 0.15) {
      final tangent = metrics[0].getTangentForOffset(0);
      if (tangent != null) {
        _drawHintArrow(canvas, tangent.position, hintAnim.value);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint p) {
    const dash = 12.0, gap = 8.0;
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final end = (dist + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(dist, end), p);
        dist += dash + gap;
      }
    }
  }

  void _drawHintArrow(Canvas canvas, Offset pos, double pulse) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.6 + pulse * 0.3)
      ..style = PaintingStyle.fill;

    // Pulsing ring
    canvas.drawCircle(pos, 16 + pulse * 8, Paint()
      ..color = accentColor.withOpacity(0.12 + pulse * 0.08)
      ..style = PaintingStyle.fill);
    canvas.drawCircle(pos, 10, paint);
    canvas.drawCircle(pos, 10, Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);

    // "Start here" arrow above
    final arrowTop = Offset(pos.dx, pos.dy - 28 - pulse * 6);
    final arrowPaint = Paint()
      ..color = accentColor.withOpacity(0.70)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(arrowTop.dx, arrowTop.dy + 14)
      ..lineTo(arrowTop.dx - 9, arrowTop.dy)
      ..lineTo(arrowTop.dx + 9, arrowTop.dy)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(_TracingPainter o) =>
      o.progress != progress ||
      o.strokes != strokes ||
      o.currentStroke != currentStroke ||
      o.accentColor != accentColor;
}

// ─── SUPPORT TYPES ─────────────────────────────────────────────────────────────
class _ShapeMeta {
  final String name;
  final Color color, bg;
  const _ShapeMeta({required this.name, required this.color, required this.bg});
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}
