// lib/screens/shapes_tracing.dart
// Shape tracing activity – split screen: example (left) + practice (right)
// Hints shown for the first 2 shapes only; from shape 3 onwards the child traces unaided.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────
class _ShapeMeta {
  final String name;
  final Color accent;  // stroke / fill colour
  final Color bg;      // screen background
  const _ShapeMeta({required this.name, required this.accent, required this.bg});
}

const _kShapes = [
  _ShapeMeta(name: 'Circle',   accent: Color(0xFFE53935), bg: Color(0xFFFFF3E0)),
  _ShapeMeta(name: 'Triangle', accent: Color(0xFF7B1FA2), bg: Color(0xFFF3E5F5)),
  _ShapeMeta(name: 'Square',   accent: Color(0xFF0277BD), bg: Color(0xFFE3F2FD)),
  _ShapeMeta(name: 'Star',     accent: Color(0xFF2E7D32), bg: Color(0xFFE8F5E9)),
  _ShapeMeta(name: 'Diamond',  accent: Color(0xFFFF6F00), bg: Color(0xFFFFF8E1)),
];

// Up to which shape index to show hints (0-indexed, inclusive)
const _kHintUpTo = 1;

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

  int _shapeIndex = 0;
  int _completedCount = 0;
  bool _shapeComplete = false;

  // Drawing
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  double _progress = 0.0;

  // Animations
  late AnimationController _celebrateCtrl;
  late AnimationController _hintCtrl;   // drives the animated finger on example
  late AnimationController _bgCtrl;

  late FlutterTts _tts;

  _ShapeMeta get _meta => _kShapes[_shapeIndex % _kShapes.length];
  bool get _showHint => _shapeIndex <= _kHintUpTo;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _celebrateCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

    _hintCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();

    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);

    Future.delayed(const Duration(milliseconds: 500), _announce);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _celebrateCtrl.dispose();
    _hintCtrl.dispose();
    _bgCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _announce() {
    if (_showHint) {
      _speak('Watch the guide, then trace the ${_meta.name}!');
    } else {
      _speak('Now try tracing the ${_meta.name} on your own!');
    }
  }

  // Build the normalised guide path for any given canvas Rect
  Path _buildPath(Rect r) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    const rad = 90.0;

    switch (_meta.name) {
      case 'Circle':
        return Path()
          ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rad * 2, height: rad * 2));

      case 'Triangle':
        return Path()
          ..moveTo(cx, cy - rad)
          ..lineTo(cx + rad, cy + rad * 0.8)
          ..lineTo(cx - rad, cy + rad * 0.8)
          ..close();

      case 'Square':
        return Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: rad * 1.9, height: rad * 1.9));

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
      default:
        return Path()
          ..moveTo(cx, cy - rad)
          ..lineTo(cx + rad * 0.65, cy)
          ..lineTo(cx, cy + rad)
          ..lineTo(cx - rad * 0.65, cy)
          ..close();
    }
  }

  // ── Drawing callbacks ────────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (_shapeComplete) return;
    setState(() => _currentStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_shapeComplete) return;
    setState(() {
      _currentStroke.add(d.localPosition);
      _recalcProgress(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_shapeComplete) return;
    setState(() {
      if (_currentStroke.isNotEmpty) _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  // Cheap coverage check against the practice panel path
  void _recalcProgress(Offset pos) {
    final size = context.size;
    if (size == null) return;

    // Practice panel occupies the right 60% of the screen
    final practiceRect = Rect.fromLTWH(
      size.width * 0.38, 0, size.width * 0.62, size.height);
    final guidePath = _buildPath(practiceRect);
    final metrics = guidePath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    const samples = 60;
    int covered = 0;

    for (int i = 0; i < samples; i++) {
      final t = i / samples;
      double d = totalLen * t;
      double acc = 0;
      for (final m in metrics) {
        if (d <= acc + m.length) {
          final tangent = m.getTangentForOffset(d - acc);
          if (tangent != null) {
            final gp = tangent.position;
            bool near = false;
            for (final stroke in _strokes) {
              for (final pt in stroke) {
                if ((pt - gp).distance < 32) { near = true; break; }
              }
              if (near) break;
            }
            if (!near) {
              for (final pt in _currentStroke) {
                if ((pt - gp).distance < 32) { near = true; break; }
              }
            }
            if (near) covered++;
          }
          break;
        }
        acc += m.length;
      }
    }

    final np = (covered / samples).clamp(0.0, 1.0);
    if (np > _progress) setState(() => _progress = np);

    if (_progress >= 0.68 && !_shapeComplete) _onComplete();
  }

  void _onComplete() {
    setState(() => _shapeComplete = true);
    _celebrateCtrl.forward(from: 0);
    _speak('Wonderful! You traced the ${_meta.name}!');

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final next = _shapeIndex + 1;
      if (next >= _kShapes.length) {
        widget.onSessionComplete();
        Navigator.pop(context);
        return;
      }
      setState(() {
        _shapeIndex = next;
        _completedCount++;
        _strokes.clear();
        _currentStroke = [];
        _progress = 0;
        _shapeComplete = false;
      });
      _celebrateCtrl.reset();
      Future.delayed(const Duration(milliseconds: 350), _announce);
    });
  }

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _progress = 0;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final exampleRect = Rect.fromLTWH(0, 0, size.width * 0.38, size.height);
    final practiceRect = Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.62, size.height);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Scaffold(
        key: ValueKey(_shapeIndex),
        backgroundColor: _meta.bg,
        body: Row(
          children: [
            // ── LEFT: Example panel ──────────────────────────────────────────
            SizedBox(
              width: size.width * 0.38,
              height: size.height,
              child: _buildExamplePanel(exampleRect),
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
                    _meta.accent.withOpacity(0.08),
                    _meta.accent.withOpacity(0.30),
                    _meta.accent.withOpacity(0.08),
                  ],
                ),
              ),
            ),
            // ── RIGHT: Practice panel ────────────────────────────────────────
            Expanded(
              child: _buildPracticePanel(practiceRect),
            ),
          ],
        ),
      ),
    );
  }

  // ── Example panel ────────────────────────────────────────────────────────────
  Widget _buildExamplePanel(Rect rect) {
    return Stack(
      children: [
        // Soft background circle
        Positioned.fill(
          child: Center(
            child: Container(
              width: rect.width * 0.85,
              height: rect.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _meta.accent.withOpacity(0.07),
              ),
            ),
          ),
        ),

        // Shape + optional hint
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _hintCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ExamplePainter(
                path: _buildPath(rect),
                accent: _meta.accent,
                showHint: _showHint,
                hintProgress: _hintCtrl.value,
              ),
            ),
          ),
        ),

        // Top: back button + shape counter
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                _Btn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  color: _meta.accent,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Shape dots
                Row(
                  children: List.generate(_kShapes.length, (i) {
                    final done = i < _completedCount;
                    final active = i == _shapeIndex % _kShapes.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: done
                            ? _meta.accent
                            : active
                                ? _meta.accent.withOpacity(0.75)
                                : _meta.accent.withOpacity(0.20),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // "Example" label at bottom
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_showHint)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _meta.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: _meta.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Watch & copy',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          color: _meta.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _meta.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Try it yourself! ✨',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: _meta.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Practice panel ────────────────────────────────────────────────────────────
  Widget _buildPracticePanel(Rect rect) {
    return Stack(
      children: [
        // Drawing canvas
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedBuilder(
            animation: _hintCtrl,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _PracticePainter(
                guidePath: _buildPath(rect),
                strokes: _strokes,
                currentStroke: _currentStroke,
                accent: _meta.accent,
                hintAnim: _hintCtrl,
                showStartHint: _progress < 0.08,
              ),
            ),
          ),
        ),

        // Top-right: clear button
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 14, 0),
              child: _Btn(
                icon: Icons.refresh_rounded,
                color: _meta.accent,
                onTap: _clearDrawing,
              ),
            ),
          ),
        ),

        // Bottom progress bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: _meta.accent.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(_meta.accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
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
                      color: _meta.accent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _meta.accent.withOpacity(0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 6),
                        Text(
                          _meta.name,
                          style: GoogleFonts.fredoka(
                            fontSize: 30,
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
    );
  }
}

// ─── Example Painter ──────────────────────────────────────────────────────────
// Draws: filled shape + optional animated finger hint
class _ExamplePainter extends CustomPainter {
  final Path path;
  final Color accent;
  final bool showHint;
  final double hintProgress; // 0→1

  _ExamplePainter({
    required this.path,
    required this.accent,
    required this.showHint,
    required this.hintProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Filled shape
    canvas.drawPath(path, Paint()
      ..color = accent.withOpacity(0.18)
      ..style = PaintingStyle.fill);

    // Solid outline
    canvas.drawPath(path, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    if (!showHint) return;

    // Animated trail: draw path up to hintProgress
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    final targetLen = totalLen * hintProgress;

    // Build trail path
    final trail = Path();
    bool started = false;
    double acc = 0;
    for (final m in metrics) {
      final take = (targetLen - acc).clamp(0.0, m.length);
      if (take <= 0) break;
      final sub = m.extractPath(0, take);
      if (!started) { trail.addPath(sub, Offset.zero); started = true; }
      else trail.addPath(sub, Offset.zero);
      acc += m.length;
      if (acc >= targetLen) break;
    }

    // Draw trail in bright accent
    canvas.drawPath(trail, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Finger dot at current position
    if (metrics.isNotEmpty) {
      double d = targetLen;
      double a2 = 0;
      for (final m in metrics) {
        if (d <= a2 + m.length) {
          final tangent = m.getTangentForOffset(d - a2);
          if (tangent != null) {
            final pos = tangent.position;
            // Outer glow
            canvas.drawCircle(pos, 16, Paint()
              ..color = accent.withOpacity(0.22)
              ..style = PaintingStyle.fill);
            // Inner finger
            canvas.drawCircle(pos, 10, Paint()
              ..color = accent
              ..style = PaintingStyle.fill);
            canvas.drawCircle(pos, 10, Paint()
              ..color = Colors.white.withOpacity(0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
          }
          break;
        }
        a2 += m.length;
      }
    }
  }

  @override
  bool shouldRepaint(_ExamplePainter o) =>
      o.hintProgress != hintProgress || o.showHint != showHint || o.accent != accent;
}

// ─── Practice Painter ─────────────────────────────────────────────────────────
class _PracticePainter extends CustomPainter {
  final Path guidePath;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color accent;
  final AnimationController hintAnim;
  final bool showStartHint;

  _PracticePainter({
    required this.guidePath,
    required this.strokes,
    required this.currentStroke,
    required this.accent,
    required this.hintAnim,
    required this.showStartHint,
  }) : super(repaint: hintAnim);

  @override
  void paint(Canvas canvas, Size size) {
    // Light fill
    canvas.drawPath(guidePath, Paint()
      ..color = accent.withOpacity(0.06)
      ..style = PaintingStyle.fill);

    // Dashed guide
    _dashedPath(canvas, guidePath, Paint()
      ..color = accent.withOpacity(0.28 + hintAnim.value * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round);

    // Thick guide outline (softer)
    canvas.drawPath(guidePath, Paint()
      ..color = accent.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // User strokes
    final draw = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final s in strokes) {
      if (s.length < 2) continue;
      final p = Path()..moveTo(s[0].dx, s[0].dy);
      for (int i = 1; i < s.length; i++) p.lineTo(s[i].dx, s[i].dy);
      canvas.drawPath(p, draw);
    }
    if (currentStroke.length >= 2) {
      final p = Path()..moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) p.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      canvas.drawPath(p, draw);
    }

    // Pulsing start hint
    if (showStartHint) {
      final metrics = guidePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final tangent = metrics[0].getTangentForOffset(0);
        if (tangent != null) {
          final pos = tangent.position;
          final pulse = hintAnim.value;
          canvas.drawCircle(pos, 18 + pulse * 8, Paint()
            ..color = accent.withOpacity(0.10 + pulse * 0.10)
            ..style = PaintingStyle.fill);
          canvas.drawCircle(pos, 11, Paint()
            ..color = accent.withOpacity(0.80)
            ..style = PaintingStyle.fill);
          canvas.drawCircle(pos, 11, Paint()
            ..color = Colors.white.withOpacity(0.60)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);

          // Downward arrow
          final ap = Offset(pos.dx, pos.dy - 32 - pulse * 6);
          final arr = Path()
            ..moveTo(ap.dx, ap.dy + 14)
            ..lineTo(ap.dx - 8, ap.dy)
            ..lineTo(ap.dx + 8, ap.dy)
            ..close();
          canvas.drawPath(arr, Paint()
            ..color = accent.withOpacity(0.65)
            ..style = PaintingStyle.fill);
        }
      }
    }
  }

  void _dashedPath(Canvas canvas, Path path, Paint p) {
    const dash = 12.0, gap = 7.0;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final end = (d + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, end), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PracticePainter o) =>
      o.strokes != strokes ||
      o.currentStroke != currentStroke ||
      o.accent != accent ||
      o.showStartHint != showStartHint;
}

// ─── Shared button ────────────────────────────────────────────────────────────
class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.22), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}
