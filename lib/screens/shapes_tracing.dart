// lib/screens/shapes_tracing.dart
// Dot-connect shape tracing activity
// Kids join numbered dots to form a shape; the app verifies correct sequential
// connection then rewards with animated stars and the shape name.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nyota/widgets/nav_buttons.dart';

// ─── Shape Definitions ────────────────────────────────────────────────────────
// Dots are normalised (0–1) relative to the panel bounding box.
class _ShapeDef {
  final String name;
  final Color accent;
  final Color bg;
  final List<Offset> dots; // normalised panel coords
  final bool closed;       // whether to draw line from last→first dot

  const _ShapeDef({
    required this.name,
    required this.accent,
    required this.bg,
    required this.dots,
    this.closed = true,
  });

  List<Offset> pixelDots(Size panelSize) => dots
      .map((d) => Offset(panelSize.width * d.dx, panelSize.height * d.dy))
      .toList();
}

double _rad(double deg) => deg * pi / 180;

List<Offset> _polygon(int n, {double cx = 0.5, double cy = 0.5, double r = 0.36, double startDeg = -90}) =>
    List.generate(n, (i) {
      final a = _rad(startDeg + 360 * i / n);
      return Offset(cx + r * cos(a), cy + r * sin(a));
    });

List<Offset> _star5() {
  // Alternates outer (r=0.36) and inner (r=0.15) for a 5-pointed star (10 dots)
  const cx = 0.5; const cy = 0.5;
  const outer = 0.36; const inner = 0.16;
  return List.generate(10, (i) {
    final r = i.isEven ? outer : inner;
    final a = _rad(-90 + 36.0 * i);
    return Offset(cx + r * cos(a), cy + r * sin(a));
  });
}

const List<_ShapeDef> _kShapes = [
  _ShapeDef(
    name: 'Triangle',
    accent: Color(0xFF7B1FA2),
    bg: Color(0xFFF3E5F5),
    dots: [Offset(0.50, 0.14), Offset(0.82, 0.83), Offset(0.18, 0.83)],
  ),
  _ShapeDef(
    name: 'Square',
    accent: Color(0xFF0277BD),
    bg: Color(0xFFE3F2FD),
    dots: [Offset(0.18, 0.18), Offset(0.82, 0.18), Offset(0.82, 0.82), Offset(0.18, 0.82)],
  ),
  _ShapeDef(
    name: 'Rectangle',
    accent: Color(0xFFE53935),
    bg: Color(0xFFFFF3E0),
    dots: [Offset(0.10, 0.28), Offset(0.90, 0.28), Offset(0.90, 0.72), Offset(0.10, 0.72)],
  ),
  _ShapeDef(
    name: 'Diamond',
    accent: Color(0xFFFF6F00),
    bg: Color(0xFFFFF8E1),
    dots: [Offset(0.50, 0.12), Offset(0.84, 0.50), Offset(0.50, 0.88), Offset(0.16, 0.50)],
  ),
  _ShapeDef(
    name: 'Pentagon',
    accent: Color(0xFF2E7D32),
    bg: Color(0xFFE8F5E9),
    dots: [
      Offset(0.50, 0.13), Offset(0.84, 0.38), Offset(0.70, 0.83),
      Offset(0.30, 0.83), Offset(0.16, 0.38),
    ],
  ),
  _ShapeDef(
    name: 'Hexagon',
    accent: Color(0xFF00838F),
    bg: Color(0xFFE0F7FA),
    dots: [
      Offset(0.50, 0.13), Offset(0.82, 0.31), Offset(0.82, 0.69),
      Offset(0.50, 0.87), Offset(0.18, 0.69), Offset(0.18, 0.31),
    ],
  ),
  _ShapeDef(
    name: 'Star',
    accent: Color(0xFFF9A825),
    bg: Color(0xFFFFFDE7),
    dots: [], // filled dynamically below via _star5()
    closed: true,
  ),
  _ShapeDef(
    name: 'Circle',
    accent: Color(0xFFC62828),
    bg: Color(0xFFFFEBEE),
    // 8 equidistant dots on a circle
    dots: [],
    closed: true,
  ),
];

// Build the actual dot lists for shapes that need computation
List<_ShapeDef> get _shapesPool {
  return _kShapes.map((s) {
    if (s.name == 'Star') {
      return _ShapeDef(name: s.name, accent: s.accent, bg: s.bg, dots: _star5(), closed: true);
    }
    if (s.name == 'Circle') {
      final dots = List.generate(8, (i) {
        final a = _rad(-90 + 45.0 * i);
        return Offset(0.5 + 0.37 * cos(a), 0.5 + 0.37 * sin(a));
      });
      return _ShapeDef(name: s.name, accent: s.accent, bg: s.bg, dots: dots, closed: true);
    }
    return s;
  }).toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────
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

  late final List<_ShapeDef> _shapes;
  int _shapeIndex = 0;
  int _completedCount = 0;

  // Dot-connect state
  int _nextDot = 0;                      // next dot that must be hit
  final List<int> _connectedDots = [];   // dots hit in order (indices)
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _shapeComplete = false;

  // Animations
  late AnimationController _celebrateCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _pulseCtrl;   // pulses the next-dot indicator
  late AnimationController _bgCtrl;

  late FlutterTts _tts;

  _ShapeDef get _shape => _shapes[_shapeIndex % _shapes.length];

  // Hit threshold in logical pixels
  static const double _kDotRadius = 22.0;
  static const double _kHitRadius = 30.0;

  @override
  void initState() {
    super.initState();
    _shapes = _shapesPool..shuffle(Random());

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _celebrateCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _starsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);

    Future.delayed(const Duration(milliseconds: 600), _announce);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _celebrateCtrl.dispose();
    _starsCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _announce() {
    _speak('Connect the dots to make a ${_shape.name}!');
  }

  // ── Drawing callbacks ────────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d, Size panelSize) {
    if (_shapeComplete) return;
    setState(() => _currentStroke = [d.localPosition]);
    _checkDotHit(d.localPosition, panelSize);
  }

  void _onPanUpdate(DragUpdateDetails d, Size panelSize) {
    if (_shapeComplete) return;
    setState(() => _currentStroke.add(d.localPosition));
    _checkDotHit(d.localPosition, panelSize);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_shapeComplete) return;
    setState(() {
      if (_currentStroke.length > 1) _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _checkDotHit(Offset pos, Size panelSize) {
    if (_nextDot >= _shape.dots.length) return;
    final dots = _shape.pixelDots(panelSize);
    final target = dots[_nextDot];
    if ((pos - target).distance < _kHitRadius) {
      setState(() {
        _connectedDots.add(_nextDot);
        _nextDot++;
      });
      if (_nextDot >= dots.length) {
        _onComplete();
      }
    }
  }

  void _onComplete() {
    setState(() => _shapeComplete = true);
    _celebrateCtrl.forward(from: 0);
    _starsCtrl.forward(from: 0);
    _speak('Amazing! You made a ${_shape.name}! ⭐');

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final next = _shapeIndex + 1;
      if (next >= _shapes.length) {
        widget.onSessionComplete();
        Navigator.pop(context);
        return;
      }
      setState(() {
        _shapeIndex = next;
        _completedCount++;
        _nextDot = 0;
        _connectedDots.clear();
        _strokes.clear();
        _currentStroke = [];
        _shapeComplete = false;
      });
      _celebrateCtrl.reset();
      _starsCtrl.reset();
      Future.delayed(const Duration(milliseconds: 400), _announce);
    });
  }

  void _clearDrawing() {
    if (_shapeComplete) return;
    setState(() {
      _nextDot = 0;
      _connectedDots.clear();
      _strokes.clear();
      _currentStroke = [];
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Scaffold(
        key: ValueKey(_shapeIndex),
        backgroundColor: _shape.bg,
        body: Row(
          children: [
            // ── LEFT: Example panel ──────────────────────────────────────────
            SizedBox(
              width: size.width * 0.38,
              height: size.height,
              child: _buildExamplePanel(size),
            ),
            // Divider
            Container(
              width: 2,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _shape.accent.withOpacity(0.08),
                    _shape.accent.withOpacity(0.30),
                    _shape.accent.withOpacity(0.08),
                  ],
                ),
              ),
            ),
            // ── RIGHT: Practice panel ────────────────────────────────────────
            Expanded(
              child: _buildPracticePanel(size),
            ),
          ],
        ),
      ),
    );
  }

  // ── Example panel ─────────────────────────────────────────────────────────
  Widget _buildExamplePanel(Size screenSize) {
    final panelSize = Size(screenSize.width * 0.38, screenSize.height);
    return Stack(
      children: [
        // Soft background glow
        Positioned.fill(
          child: Center(
            child: Container(
              width: panelSize.width * 0.80,
              height: panelSize.width * 0.80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _shape.accent.withOpacity(0.06),
              ),
            ),
          ),
        ),

        // Shape drawing (example – filled + outlined with dots)
        Positioned.fill(
          child: CustomPaint(
            painter: _ExamplePainter(
              shape: _shape,
              panelSize: panelSize,
            ),
          ),
        ),

        // Top nav row
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 0),
            child: Row(
              children: [
                KidBackButton(onTap: () => Navigator.pop(context), color: _shape.accent),
                const SizedBox(width: 8),
                KidHomeButton(onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
                const Spacer(),
                // Shape progress dots
                Row(
                  children: List.generate(_shapes.length, (i) {
                    final done = i < _completedCount;
                    final active = i == _shapeIndex % _shapes.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: done
                            ? _shape.accent
                            : active
                                ? _shape.accent.withOpacity(0.75)
                                : _shape.accent.withOpacity(0.20),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // Shape name label
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _shape.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                _shape.name,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: _shape.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Practice panel ───────────────────────────────────────────────────────
  Widget _buildPracticePanel(Size screenSize) {
    final panelWidth = screenSize.width * 0.62;
    final panelSize = Size(panelWidth, screenSize.height);

    return Stack(
      children: [
        // Drawing + dots canvas
        Positioned.fill(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final lSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, lSize),
                onPanUpdate: (d) => _onPanUpdate(d, lSize),
                onPanEnd: _onPanEnd,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _PracticePainter(
                      shape: _shape,
                      panelSize: lSize,
                      connectedDots: _connectedDots,
                      nextDot: _nextDot,
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      pulseValue: _pulseCtrl.value,
                      shapeComplete: _shapeComplete,
                      dotRadius: _kDotRadius,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Top-right: clear button
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 14, 0),
              child: KidNavButton(
                label: 'Clear',
                emoji: '🔄',
                icon: Icons.refresh_rounded,
                color: _shape.accent,
                onTap: _clearDrawing,
              ),
            ),
          ),
        ),

        // Dot counter bottom bar
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _shape.accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                _nextDot >= _shape.dots.length
                    ? 'All connected! ✨'
                    : 'Dots connected: $_nextDot / ${_shape.dots.length}',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: _shape.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // ── Celebration overlay ──────────────────────────────────────────────
        if (_shapeComplete) _buildCelebration(panelSize),
      ],
    );
  }

  Widget _buildCelebration(Size panelSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_celebrateCtrl, _starsCtrl]),
      builder: (_, __) {
        final t = CurvedAnimation(
          parent: _celebrateCtrl,
          curve: Curves.elasticOut,
        ).value;

        return Stack(
          children: [
            // Floating stars
            ..._buildFlyingStars(panelSize),

            // Central card
            Center(
              child: Transform.scale(
                scale: t,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
                  decoration: BoxDecoration(
                    color: _shape.accent,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _shape.accent.withOpacity(0.50),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stars row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final delay = i * 0.18;
                          final localT = ((_starsCtrl.value - delay) / (1 - delay))
                              .clamp(0.0, 1.0);
                          final scale = CurvedAnimation(
                            parent: AlwaysStoppedAnimation(localT),
                            curve: Curves.elasticOut,
                          ).value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.scale(
                              scale: scale,
                              child: const Text('⭐', style: TextStyle(fontSize: 34)),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _shape.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Great job! 🎉',
                        style: GoogleFonts.fredoka(
                          fontSize: 17,
                          color: Colors.white.withOpacity(0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildFlyingStars(Size panelSize) {
    final rng = Random(42);
    return List.generate(8, (i) {
      final startX = rng.nextDouble() * panelSize.width;
      final startY = panelSize.height * 0.6 + rng.nextDouble() * panelSize.height * 0.3;
      final endY = -40.0;
      final delay = i * 0.08;
      final localT = ((_starsCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0);
      final y = lerpDouble(startY, endY, Curves.easeOut.transform(localT))!;
      final opacity = (1.0 - localT * 0.7).clamp(0.0, 1.0);
      final emojis = ['⭐', '🌟', '✨', '💫'];
      return Positioned(
        left: startX - 12,
        top: y,
        child: Opacity(
          opacity: opacity,
          child: Text(
            emojis[i % emojis.length],
            style: TextStyle(fontSize: 20 + rng.nextDouble() * 10),
          ),
        ),
      );
    });
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─── Example Painter ──────────────────────────────────────────────────────────
class _ExamplePainter extends CustomPainter {
  final _ShapeDef shape;
  final Size panelSize;

  _ExamplePainter({required this.shape, required this.panelSize});

  @override
  void paint(Canvas canvas, Size size) {
    final dots = shape.pixelDots(size);
    if (dots.isEmpty) return;

    // Build path through all dots
    final path = _buildPath(dots, shape.closed);

    // Fill
    canvas.drawPath(path, Paint()
      ..color = shape.accent.withOpacity(0.15)
      ..style = PaintingStyle.fill);

    // Outline
    canvas.drawPath(path, Paint()
      ..color = shape.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dots
    for (int i = 0; i < dots.length; i++) {
      _drawDot(canvas, dots[i], i, shape.accent, filled: true);
    }
  }

  void _drawDot(Canvas canvas, Offset pos, int idx, Color accent, {bool filled = false}) {
    // Outer ring
    canvas.drawCircle(pos, 11, Paint()
      ..color = accent.withOpacity(0.20)
      ..style = PaintingStyle.fill);
    // Inner fill
    canvas.drawCircle(pos, 7, Paint()
      ..color = filled ? accent : Colors.white
      ..style = PaintingStyle.fill);
    canvas.drawCircle(pos, 7, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // Number
    final tp = TextPainter(
      text: TextSpan(
        text: '${idx + 1}',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  Path _buildPath(List<Offset> dots, bool closed) {
    final path = Path()..moveTo(dots[0].dx, dots[0].dy);
    for (int i = 1; i < dots.length; i++) {
      path.lineTo(dots[i].dx, dots[i].dy);
    }
    if (closed) path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ExamplePainter o) => o.shape != shape;
}

// ─── Practice Painter ─────────────────────────────────────────────────────────
class _PracticePainter extends CustomPainter {
  final _ShapeDef shape;
  final Size panelSize;
  final List<int> connectedDots;
  final int nextDot;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double pulseValue;
  final bool shapeComplete;
  final double dotRadius;

  _PracticePainter({
    required this.shape,
    required this.panelSize,
    required this.connectedDots,
    required this.nextDot,
    required this.strokes,
    required this.currentStroke,
    required this.pulseValue,
    required this.shapeComplete,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dots = shape.pixelDots(size);
    if (dots.isEmpty) return;

    // ── Draw free-form strokes (kid's drawings) ──────────────────────────────
    final inkPaint = Paint()
      ..color = shape.accent.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) path.lineTo(stroke[i].dx, stroke[i].dy);
      canvas.drawPath(path, inkPaint);
    }
    if (currentStroke.length > 1) {
      final path = Path()..moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, inkPaint);
    }

    // ── Draw connected segments ──────────────────────────────────────────────
    if (connectedDots.length > 1) {
      final connPath = Paint()
        ..color = shape.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final linePath = Path()..moveTo(dots[connectedDots[0]].dx, dots[connectedDots[0]].dy);
      for (int i = 1; i < connectedDots.length; i++) {
        linePath.lineTo(dots[connectedDots[i]].dx, dots[connectedDots[i]].dy);
      }
      canvas.drawPath(linePath, connPath);
    }

    // Close the shape when complete
    if (shapeComplete && shape.closed && connectedDots.length == dots.length) {
      final closePaint = Paint()
        ..color = shape.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(dots[connectedDots.last], dots[connectedDots.first], closePaint);

      // Fill the completed shape lightly
      final fillPath = Path()..moveTo(dots[0].dx, dots[0].dy);
      for (int i = 1; i < dots.length; i++) fillPath.lineTo(dots[i].dx, dots[i].dy);
      fillPath.close();
      canvas.drawPath(fillPath, Paint()
        ..color = shape.accent.withOpacity(0.18)
        ..style = PaintingStyle.fill);
    }

    // ── Draw dots ────────────────────────────────────────────────────────────
    for (int i = 0; i < dots.length; i++) {
      final isConnected = connectedDots.contains(i);
      final isNext = i == nextDot && !shapeComplete;
      _drawDot(canvas, dots[i], i, isConnected, isNext);
    }

    // ── Hint arrow pointing to next dot ─────────────────────────────────────
    if (!shapeComplete && nextDot < dots.length && connectedDots.isNotEmpty) {
      final from = dots[connectedDots.last];
      final to = dots[nextDot];
      _drawArrowHint(canvas, from, to);
    } else if (!shapeComplete && nextDot == 0 && dots.isNotEmpty) {
      // Pulse on the first dot to get kid started
      final firstDot = dots[0];
      final pulse = dotRadius + 8 + pulseValue * 10;
      canvas.drawCircle(firstDot, pulse, Paint()
        ..color = shape.accent.withOpacity(0.15 * (1 - pulseValue))
        ..style = PaintingStyle.fill);
    }
  }

  void _drawDot(Canvas canvas, Offset pos, int idx, bool connected, bool isNext) {
    final pulseScale = isNext ? (1.0 + pulseValue * 0.25) : 1.0;
    final r = dotRadius * pulseScale;

    // Glow for next dot
    if (isNext) {
      canvas.drawCircle(pos, r + 10, Paint()
        ..color = shape.accent.withOpacity(0.18 + pulseValue * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill);
    }

    // Shadow
    canvas.drawCircle(pos, r + 2, Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.fill);

    // Outer ring
    canvas.drawCircle(pos, r, Paint()
      ..color = connected
          ? shape.accent
          : isNext
              ? shape.accent.withOpacity(0.85)
              : Colors.white
      ..style = PaintingStyle.fill);

    canvas.drawCircle(pos, r, Paint()
      ..color = shape.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Number label
    final numStr = '${idx + 1}';
    final tp = TextPainter(
      text: TextSpan(
        text: numStr,
        style: TextStyle(
          fontSize: r * 0.7,
          fontWeight: FontWeight.bold,
          color: connected || isNext ? Colors.white : shape.accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawArrowHint(Canvas canvas, Offset from, Offset to) {
    final dir = (to - from);
    final dist = dir.distance;
    if (dist < 10) return;
    final unit = dir / dist;

    // Start just outside the source dot, end just before the target dot
    final start = from + unit * (dotRadius + 4);
    final end = to - unit * (dotRadius + 6);
    if ((end - start).distance < 10) return;

    final paint = Paint()
      ..color = shape.accent.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Dashed line
    _drawDashed(canvas, start, end, paint, 7, 5);

    // Arrowhead
    final arrowSize = 9.0;
    final perp = Offset(-unit.dy, unit.dx);
    final arrowTip = end;
    final arrowLeft = arrowTip - unit * arrowSize + perp * arrowSize * 0.5;
    final arrowRight = arrowTip - unit * arrowSize - perp * arrowSize * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(arrowTip.dx, arrowTip.dy)
        ..lineTo(arrowLeft.dx, arrowLeft.dy)
        ..lineTo(arrowRight.dx, arrowRight.dy)
        ..close(),
      Paint()
        ..color = shape.accent.withOpacity(0.40)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint, double dash, double gap) {
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double drawn = 0;
    while (drawn < total) {
      final a = start + dir * drawn;
      final b = start + dir * (drawn + dash).clamp(0.0, total);
      canvas.drawLine(a, b, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_PracticePainter o) =>
      o.connectedDots != connectedDots ||
      o.nextDot != nextDot ||
      o.pulseValue != pulseValue ||
      o.strokes != strokes ||
      o.currentStroke != currentStroke ||
      o.shapeComplete != shapeComplete;
}
