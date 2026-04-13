// lib/screens/shapes_hub.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'shapes_find_shape.dart';
import 'shapes_find_pairs.dart';
import 'shapes_patterns.dart';
import 'shapes_tracing.dart';

class ShapesHubScreen extends StatefulWidget {
  final VoidCallback onSessionComplete;
  final String? rewardImagePath;
  final int? maxDurationMinutes;

  const ShapesHubScreen({
    super.key,
    required this.onSessionComplete,
    this.rewardImagePath,
    this.maxDurationMinutes,
  });

  @override
  State<ShapesHubScreen> createState() => _ShapesHubScreenState();
}

class _ShapesHubScreenState extends State<ShapesHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgPulse;
  late AnimationController _cardEntrance;
  late FlutterTts _tts;
  int? _pressedIndex;

  // Activity palette – no titles, purely visual
  static const _cards = [
    _CardMeta(
      type: _ActivityType.hunt,
      bg: Color(0xFFFFF3E0),
      accent: Color(0xFFFF7043),
      shadow: Color(0xFFFF8A65),
    ),
    _CardMeta(
      type: _ActivityType.pairs,
      bg: Color(0xFFEDE7F6),
      accent: Color(0xFF7C4DFF),
      shadow: Color(0xFF9575CD),
    ),
    _CardMeta(
      type: _ActivityType.patterns,
      bg: Color(0xFFE0F7FA),
      accent: Color(0xFF00ACC1),
      shadow: Color(0xFF4DD0E1),
    ),
    _CardMeta(
      type: _ActivityType.trace,
      bg: Color(0xFFE8F5E9),
      accent: Color(0xFF43A047),
      shadow: Color(0xFF81C784),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _bgPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _cardEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _speak('Choose a shapes activity!'),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _bgPulse.dispose();
    _cardEntrance.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _launch(int index) async {
    setState(() => _pressedIndex = index);
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => _pressedIndex = null);

    void onDone() {
      widget.onSessionComplete();
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (Navigator.canPop(context)) Navigator.pop(context);
    }

    Widget screen;
    switch (index) {
      case 0:
        screen = ShapesFindShapeScreen(
          onSessionComplete: onDone,
          rewardImagePath: widget.rewardImagePath,
          maxDurationMinutes: widget.maxDurationMinutes,
        );
        break;
      case 1:
        screen = ShapesFindPairsScreen(
          onSessionComplete: onDone,
          rewardImagePath: widget.rewardImagePath,
          maxDurationMinutes: widget.maxDurationMinutes,
        );
        break;
      case 2:
        screen = ShapesPatternsScreen(
          onSessionComplete: onDone,
          rewardImagePath: widget.rewardImagePath,
          maxDurationMinutes: widget.maxDurationMinutes,
        );
        break;
      case 3:
      default:
        screen = ShapesTracingScreen(
          onSessionComplete: onDone,
          rewardImagePath: widget.rewardImagePath,
        );
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgPulse,
        builder: (_, __) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF1A1035), const Color(0xFF0D1B40), _bgPulse.value)!,
                Color.lerp(const Color(0xFF0D1B40), const Color(0xFF1A1035), _bgPulse.value)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Floating background shapes
              ..._buildFloatingDecor(size),
              SafeArea(
                child: Column(
                  children: [
                    // Back button row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          _BackBtn(onTap: () => Navigator.pop(context)),
                          const Spacer(),
                          // Star decorations
                          const _StarRow(),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    // Card grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: AnimatedBuilder(
                          animation: _cardEntrance,
                          builder: (_, __) {
                            final t = CurvedAnimation(
                              parent: _cardEntrance,
                              curve: Curves.easeOutCubic,
                            ).value;
                            return Row(
                              children: List.generate(_cards.length, (i) {
                                final delay = i * 0.15;
                                final localT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Opacity(
                                      opacity: localT,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - localT)),
                                        child: _ActivityCard(
                                          meta: _cards[i],
                                          index: i,
                                          isPressed: _pressedIndex == i,
                                          floatAnim: _bgPulse,
                                          onTap: () => _launch(i),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
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
    );
  }

  List<Widget> _buildFloatingDecor(Size size) {
    return [
      _FloatingDecor(anim: _bgPulse, left: 30, top: 40, shape: _DecorShape.circle, color: Colors.white.withOpacity(0.04), size: 80),
      _FloatingDecor(anim: _bgPulse, right: 40, top: 30, shape: _DecorShape.triangle, color: Colors.white.withOpacity(0.04), size: 60, phase: 1.0),
      _FloatingDecor(anim: _bgPulse, left: size.width * 0.4, bottom: 20, shape: _DecorShape.square, color: Colors.white.withOpacity(0.04), size: 50, phase: 2.0),
      _FloatingDecor(anim: _bgPulse, right: 30, bottom: 30, shape: _DecorShape.diamond, color: Colors.white.withOpacity(0.04), size: 55, phase: 0.5),
    ];
  }
}

// ─── CARD ──────────────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final _CardMeta meta;
  final int index;
  final bool isPressed;
  final AnimationController floatAnim;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.meta,
    required this.index,
    required this.isPressed,
    required this.floatAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          decoration: BoxDecoration(
            color: meta.bg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: meta.shadow.withOpacity(0.55),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Accent top strip
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 6,
                  child: Container(color: meta.accent),
                ),
                // Main icon
                Positioned.fill(
                  top: 6,
                  child: AnimatedBuilder(
                    animation: floatAnim,
                    builder: (_, __) => Center(
                      child: Transform.translate(
                        offset: Offset(0, sin(floatAnim.value * pi + index * 0.8) * 5),
                        child: _buildIcon(),
                      ),
                    ),
                  ),
                ),
                // Bottom accent dot row
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(meta.accent.withOpacity(0.35), 5),
                      const SizedBox(width: 4),
                      _dot(meta.accent, 7),
                      const SizedBox(width: 4),
                      _dot(meta.accent.withOpacity(0.35), 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c, double r) => Container(
        width: r, height: r,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _buildIcon() {
    switch (meta.type) {
      case _ActivityType.hunt:
        return CustomPaint(size: const Size(130, 130), painter: _HuntIconPainter(meta.accent));
      case _ActivityType.pairs:
        return CustomPaint(size: const Size(130, 130), painter: _PairsIconPainter(meta.accent));
      case _ActivityType.patterns:
        return CustomPaint(size: const Size(140, 80), painter: _PatternsIconPainter(meta.accent));
      case _ActivityType.trace:
        return CustomPaint(size: const Size(130, 130), painter: _TraceIconPainter(meta.accent));
    }
  }
}

// ─── ICON PAINTERS ─────────────────────────────────────────────────────────────

/// Hunt: scattered shapes + magnifying glass overlay
class _HuntIconPainter extends CustomPainter {
  final Color accent;
  _HuntIconPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;

    // Background shape cluster
    fill.color = accent.withOpacity(0.18);
    canvas.drawCircle(Offset(w * 0.22, h * 0.30), 18, fill);
    _drawTriangle(canvas, Offset(w * 0.70, h * 0.25), 20, fill..color = accent.withOpacity(0.18));
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.35, h * 0.70), width: 26, height: 26), fill..color = accent.withOpacity(0.18));
    _drawStar(canvas, Offset(w * 0.75, h * 0.68), 16, fill..color = accent.withOpacity(0.18));

    // Solid small shapes
    fill.color = accent.withOpacity(0.60);
    canvas.drawCircle(Offset(w * 0.22, h * 0.30), 12, fill);
    fill.color = accent.withOpacity(0.45);
    _drawTriangle(canvas, Offset(w * 0.70, h * 0.25), 13, fill);
    fill.color = accent.withOpacity(0.50);
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.35, h * 0.70), width: 17, height: 17), fill);
    fill.color = accent.withOpacity(0.40);
    _drawStar(canvas, Offset(w * 0.75, h * 0.68), 11, fill);

    // Magnifying glass
    final glassPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final glassCenter = Offset(w * 0.50, h * 0.48);
    canvas.drawCircle(glassCenter, 28, glassPaint);
    canvas.drawCircle(glassCenter, 28, Paint()..color = Colors.white.withOpacity(0.22)..style = PaintingStyle.fill);
    final handleEnd = Offset(glassCenter.dx + 22, glassCenter.dy + 22);
    canvas.drawLine(Offset(glassCenter.dx + 18, glassCenter.dy + 18), handleEnd, glassPaint..strokeWidth = 6);
  }

  void _drawTriangle(Canvas canvas, Offset center, double r, Paint p) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy + r)
      ..lineTo(center.dx - r, center.dy + r)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = Offset(
        center.dx + r * cos((i * 4 * pi / 5) - pi / 2),
        center.dy + r * sin((i * 4 * pi / 5) - pi / 2),
      );
      final inner = Offset(
        center.dx + (r * 0.4) * cos((i * 4 * pi / 5 + 2 * pi / 5) - pi / 2),
        center.dy + (r * 0.4) * sin((i * 4 * pi / 5 + 2 * pi / 5) - pi / 2),
      );
      if (i == 0) path.moveTo(outer.dx, outer.dy);
      else path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override bool shouldRepaint(_HuntIconPainter o) => o.accent != accent;
}

/// Pairs: two matching shapes side by side with sparkle links
class _PairsIconPainter extends CustomPainter {
  final Color accent;
  _PairsIconPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    // Left shape – circle
    fill.color = accent;
    canvas.drawCircle(Offset(w * 0.25, h * 0.45), 28, fill);
    fill.color = Colors.white.withOpacity(0.30);
    canvas.drawCircle(Offset(w * 0.20, h * 0.38), 8, fill);

    // Right shape – circle (mirrored)
    fill.color = accent;
    canvas.drawCircle(Offset(w * 0.75, h * 0.45), 28, fill);
    fill.color = Colors.white.withOpacity(0.30);
    canvas.drawCircle(Offset(w * 0.70, h * 0.38), 8, fill);

    // Dashed connecting line
    stroke.color = accent.withOpacity(0.55);
    _drawDashedLine(canvas, Offset(w * 0.25 + 29, h * 0.45), Offset(w * 0.75 - 29, h * 0.45), stroke, 6, 4);

    // Sparkles between
    fill.color = accent.withOpacity(0.75);
    _drawSparkle(canvas, Offset(w * 0.50, h * 0.32), 7, fill);
    fill.color = accent.withOpacity(0.50);
    _drawSparkle(canvas, Offset(w * 0.50, h * 0.60), 5, fill);

    // Equal/match mark at center
    stroke.color = accent;
    stroke.strokeWidth = 3;
    canvas.drawLine(Offset(w * 0.44, h * 0.43), Offset(w * 0.56, h * 0.43), stroke);
    canvas.drawLine(Offset(w * 0.44, h * 0.50), Offset(w * 0.56, h * 0.50), stroke);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint p, double dash, double gap) {
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double drawn = 0;
    while (drawn < total) {
      final from = start + dir * drawn;
      final to = start + dir * (drawn + dash).clamp(0, total);
      canvas.drawLine(from, to, p);
      drawn += dash + gap;
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint p) {
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      canvas.drawLine(
        Offset(c.dx + cos(angle) * r * 0.3, c.dy + sin(angle) * r * 0.3),
        Offset(c.dx + cos(angle) * r, c.dy + sin(angle) * r),
        p..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      );
    }
  }

  @override bool shouldRepaint(_PairsIconPainter o) => o.accent != accent;
}

/// Patterns: ○ △ ○ △ → ?
class _PatternsIconPainter extends CustomPainter {
  final Color accent;
  _PatternsIconPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;

    const count = 5;
    final spacing = w / (count + 0.5);

    for (int i = 0; i < count; i++) {
      final cx = spacing * (i + 0.75);
      final cy = h * 0.48;
      final isCircle = i.isEven;
      final isLast = i == count - 1;

      if (isLast) {
        // Question mark card
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 36, height: 36),
          const Radius.circular(8),
        );
        canvas.drawRRect(rr, fill..color = accent.withOpacity(0.15));
        canvas.drawRRect(rr, stroke..color = accent.withOpacity(0.50));
        // Draw "?"
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      } else if (isCircle) {
        fill.color = accent;
        canvas.drawCircle(Offset(cx, cy), 15, fill);
        fill.color = Colors.white.withOpacity(0.28);
        canvas.drawCircle(Offset(cx - 4, cy - 5), 5, fill);
      } else {
        final path = Path()
          ..moveTo(cx, cy - 17)
          ..lineTo(cx + 15, cy + 14)
          ..lineTo(cx - 15, cy + 14)
          ..close();
        fill.color = accent.withOpacity(0.75);
        canvas.drawPath(path, fill);
        fill.color = Colors.white.withOpacity(0.22);
        canvas.drawCircle(Offset(cx, cy - 4), 4, fill);
      }

      // Arrow between shapes
      if (i < count - 1) {
        final arrowX = cx + spacing * 0.48;
        stroke.color = accent.withOpacity(0.30);
        stroke.strokeWidth = 2;
        canvas.drawLine(Offset(arrowX - 6, cy), Offset(arrowX + 6, cy), stroke);
        canvas.drawLine(Offset(arrowX + 1, cy - 5), Offset(arrowX + 6, cy), stroke);
        canvas.drawLine(Offset(arrowX + 1, cy + 5), Offset(arrowX + 6, cy), stroke);
      }
    }
  }

  @override bool shouldRepaint(_PatternsIconPainter o) => o.accent != accent;
}

/// Trace: dotted star outline + finger trail
class _TraceIconPainter extends CustomPainter {
  final Color accent;
  _TraceIconPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final center = Offset(w / 2, h / 2);
    const outerR = 46.0;
    const innerR = 20.0;

    // Glow background
    final glow = Paint()
      ..color = accent.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, outerR + 10, glow);

    // Build star path
    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * pi / 5) - pi / 2;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      i == 0 ? starPath.moveTo(p.dx, p.dy) : starPath.lineTo(p.dx, p.dy);
    }
    starPath.close();

    // Filled star (light)
    canvas.drawPath(starPath, Paint()..color = accent.withOpacity(0.15)..style = PaintingStyle.fill);

    // Dashed star outline
    final dash = Paint()
      ..color = accent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, starPath, dash, 8, 5);

    // Finger/pencil trail (partial trace – bottom-right section)
    final trailPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trailPath = Path();
    bool started = false;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * pi / 5) - pi / 2;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i <= 4) {
        if (!started) { trailPath.moveTo(p.dx, p.dy); started = true; }
        else trailPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(trailPath, trailPaint);

    // Finger circle indicator at trail end
    final endAngle = (4 * pi / 5) - pi / 2;
    final endP = Offset(center.dx + innerR * cos(endAngle), center.dy + innerR * sin(endAngle));
    canvas.drawCircle(endP, 9, Paint()..color = accent..style = PaintingStyle.fill);
    canvas.drawCircle(endP, 9, Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Sparkle dots around the trail end
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2 + 0.4;
      final sp = Offset(endP.dx + 16 * cos(a), endP.dy + 16 * sin(a));
      canvas.drawCircle(sp, 3, Paint()..color = accent.withOpacity(0.6)..style = PaintingStyle.fill);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      final total = metric.length;
      while (dist < total) {
        final end = (dist + dash).clamp(0.0, total);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override bool shouldRepaint(_TraceIconPainter o) => o.accent != accent;
}

// ─── SUPPORT TYPES ─────────────────────────────────────────────────────────────
enum _ActivityType { hunt, pairs, patterns, trace }

class _CardMeta {
  final _ActivityType type;
  final Color bg, accent, shadow;
  const _CardMeta({required this.type, required this.bg, required this.accent, required this.shadow});
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
      );
}

class _StarRow extends StatelessWidget {
  const _StarRow();
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.yellow.shade200, size: 22),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, color: Colors.yellow.shade300, size: 28),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, color: Colors.yellow.shade200, size: 22),
        ],
      );
}

// ─── FLOATING BACKGROUND DECOR ─────────────────────────────────────────────────
enum _DecorShape { circle, triangle, square, diamond }

class _FloatingDecor extends StatelessWidget {
  final AnimationController anim;
  final double? left, right, top, bottom;
  final _DecorShape shape;
  final Color color;
  final double size;
  final double phase;

  const _FloatingDecor({
    required this.anim,
    this.left, this.right, this.top, this.bottom,
    required this.shape, required this.color, required this.size,
    this.phase = 0,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        left: left, right: right, top: top, bottom: bottom,
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, sin((anim.value + phase) * pi) * 7),
            child: _buildShape(),
          ),
        ),
      );

  Widget _buildShape() {
    switch (shape) {
      case _DecorShape.circle:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
      case _DecorShape.square:
        return Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: color));
      case _DecorShape.triangle:
        return CustomPaint(size: Size(size, size), painter: _DecorTriangle(color));
      case _DecorShape.diamond:
        return Transform.rotate(angle: pi / 4, child: Container(width: size * 0.7, height: size * 0.7, color: color));
    }
  }
}

class _DecorTriangle extends CustomPainter {
  final Color color;
  _DecorTriangle(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(_DecorTriangle o) => o.color != color;
}
