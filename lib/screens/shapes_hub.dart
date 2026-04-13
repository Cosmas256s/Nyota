// lib/screens/shapes_hub.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shapes_find_shape.dart';
import 'shapes_find_pairs.dart';
import 'shapes_patterns.dart';

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
  late AnimationController _floatController;
  late FlutterTts _tts;

  final List<_SubActivityInfo> _activities = [
    _SubActivityInfo(
      index: 0,
      title: 'Shape Hunt',
      subtitle: 'Find shapes hidden in the scene!',
      emoji: '🔍',
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      bgColor: Color(0xFFFFF0EE),
    ),
    _SubActivityInfo(
      index: 1,
      title: 'Shape Pairs',
      subtitle: 'Match two identical shapes!',
      emoji: '✌️',
      gradient: [Color(0xFF6C63FF), Color(0xFF3F3D90)],
      bgColor: Color(0xFFF0EFFF),
    ),
    _SubActivityInfo(
      index: 2,
      title: 'Shape Patterns',
      subtitle: 'What comes next in the pattern?',
      emoji: '🔮',
      gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
      bgColor: Color(0xFFEEFFF9),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.75);
    Future.delayed(const Duration(milliseconds: 600), () => _speak('Choose a shapes activity!'));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _floatController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sound_enabled') ?? true) await _tts.speak(text);
  }

  void _launchActivity(int index) {
    // When a sub-activity finishes: mark completed, then pop sub-activity + hub
    void onDone() {
      widget.onSessionComplete();
      if (Navigator.canPop(context)) Navigator.pop(context); // pop sub-activity
      if (Navigator.canPop(context)) Navigator.pop(context); // pop hub → back to child dashboard
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
      default:
        screen = ShapesPatternsScreen(
          onSessionComplete: onDone,
          rewardImagePath: widget.rewardImagePath,
          maxDurationMinutes: widget.maxDurationMinutes,
        );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background blobs
          ..._buildBackgroundBlobs(size),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    children: [
                      _IconBtn(
                        icon: Icons.arrow_back_rounded,
                        color: Colors.white,
                        bg: Colors.black26,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        '⭐ Shapes World ⭐',
                        style: GoogleFonts.fredoka(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Sub-activity cards in a row
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      children: List.generate(_activities.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: _SubActivityCard(
                              info: _activities[i],
                              floatController: _floatController,
                              onTap: () => _launchActivity(i),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundBlobs(Size size) {
    return [
      AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final t = _floatController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF6C63FF), const Color(0xFFFF6B6B), t * 0.3)!,
                  Color.lerp(const Color(0xFF11998E), const Color(0xFF6C63FF), t * 0.3)!,
                ],
              ),
            ),
          );
        },
      ),
      // Floating shape decorations
      _FloatingShapeWidget(controller: _floatController, left: 40, top: 60, shape: 'circle', color: Colors.white24, size: 60),
      _FloatingShapeWidget(controller: _floatController, right: 50, top: 40, shape: 'triangle', color: Colors.white24, size: 50),
      _FloatingShapeWidget(controller: _floatController, left: 80, bottom: 40, shape: 'star', color: Colors.white24, size: 45),
      _FloatingShapeWidget(controller: _floatController, right: 80, bottom: 60, shape: 'square', color: Colors.white24, size: 40),
    ];
  }
}

class _FloatingShapeWidget extends StatelessWidget {
  final AnimationController controller;
  final double? left, right, top, bottom;
  final String shape;
  final Color color;
  final double size;

  const _FloatingShapeWidget({
    required this.controller,
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.shape,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(0, sin(controller.value * pi) * 8),
            child: _buildShape(),
          );
        },
      ),
    );
  }

  Widget _buildShape() {
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
      default:
        return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
  }
}

class _SubActivityCard extends StatefulWidget {
  final _SubActivityInfo info;
  final AnimationController floatController;
  final VoidCallback onTap;

  const _SubActivityCard({
    required this.info,
    required this.floatController,
    required this.onTap,
  });

  @override
  State<_SubActivityCard> createState() => _SubActivityCardState();
}

class _SubActivityCardState extends State<_SubActivityCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: widget.info.gradient[0].withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top gradient banner
              Container(
                height: 130.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.info.gradient,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: widget.floatController,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, sin(widget.floatController.value * pi + widget.info.index) * 6),
                      child: Text(
                        widget.info.emoji,
                        style: TextStyle(fontSize: 56.sp),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.info.title,
                        style: GoogleFonts.fredoka(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        widget.info.subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.info.gradient),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'Play!',
                          style: GoogleFonts.fredoka(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubActivityInfo {
  final int index;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;
  final Color bgColor;

  const _SubActivityInfo({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.bgColor,
  });
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r)),
        child: Icon(icon, color: color, size: 24.w),
      ),
    );
  }
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
