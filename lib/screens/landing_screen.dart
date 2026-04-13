// lib/screens/landing_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyota/theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _floatController;
  late AnimationController _entranceController;
  late AnimationController _pulseController;

  List<Animation<double>> _letterAnimations = [];
  late Animation<double> _taglineAnim;
  late Animation<double> _imageAnim;
  late Animation<double> _btnAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  final String title = "NYOTA";
  final List<String> letters = [];

  final _rng = Random();
  late List<_FloatingDot> _dots;

  @override
  void initState() {
    super.initState();
    letters.addAll(title.split(''));

    _dots = List.generate(14, (i) => _FloatingDot(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      size: 8 + _rng.nextDouble() * 18,
      color: _dotColors[i % _dotColors.length],
      phase: _rng.nextDouble() * 2 * pi,
      speed: 0.5 + _rng.nextDouble() * 0.8,
    ));

    // Title letter-by-letter animation
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _letterAnimations = List.generate(
      letters.length,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _titleController,
          curve: Interval(0.08 * i, 0.08 * i + 0.55, curve: Curves.elasticOut),
        ),
      ),
    );

    // Entrance animations for image, tagline, buttons
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _imageAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );

    _taglineAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
    );

    _btnAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack),
    );

    // Continuous float for the image
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse for the Sign Up button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _entranceController.forward();
    });
  }

  static const List<Color> _dotColors = [
    Color(0xFFF4A3A3),
    Color(0xFFFFD580),
    Color(0xFFC2D4C2),
    Color(0xFFAEC6F4),
    Color(0xFFD9A78F),
    Color(0xFFB5EAD7),
    Color(0xFFFFB7B2),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF4EC),
                  Color(0xFFFEEDE0),
                  Color(0xFFFDF8F2),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Floating decorative dots ──────────────────────
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => CustomPaint(
              painter: _DotsPainter(
                dots: _dots,
                t: _floatController.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Main content ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Hero image with float
                AnimatedBuilder(
                  animation: Listenable.merge([_imageAnim, _floatAnim]),
                  builder: (_, child) => Opacity(
                    opacity: _imageAnim.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _floatAnim.value + (1 - _imageAnim.value) * 40),
                      child: Transform.scale(
                        scale: 0.85 + _imageAnim.value * 0.15,
                        child: child,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 32.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE0A78A).withOpacity(0.28),
                          blurRadius: 32.r,
                          offset: Offset(0, 12.h),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: Image.asset(
                        'assets/images/learn.png',
                        height: 210.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // NYOTA title with letter animations
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(letters.length, (i) {
                        return AnimatedBuilder(
                          animation: _letterAnimations[i],
                          builder: (_, child) {
                            final v = _letterAnimations[i].value.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: v,
                              child: Transform.scale(
                                scale: 0.5 + v * 0.5,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - v) * 30),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFE07A5F), Color(0xFFD4A574)],
                            ).createShader(bounds),
                            child: Text(
                              letters[i],
                              style: GoogleFonts.fredoka(
                                fontSize: 82.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: 2.sp,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                // Welcome subtitle
                AnimatedBuilder(
                  animation: _taglineAnim,
                  builder: (_, child) => Opacity(
                    opacity: _taglineAnim.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - _taglineAnim.value) * 22),
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to Your',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7D5A50),
                        ),
                      ),
                      Text(
                        'Learning Adventure! ⭐',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE07A5F),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Math is Easy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFA08070).withOpacity(0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Buttons
                AnimatedBuilder(
                  animation: _btnAnim,
                  builder: (_, child) => Opacity(
                    opacity: _btnAnim.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - _btnAnim.value) * 50),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AnimatedNavButton(
                            label: 'Log In',
                            background: Colors.white,
                            textColor: const Color(0xFFE07A5F),
                            borderColor: const Color(0xFFE0A78A),
                            onTap: () => Navigator.pushNamed(context, '/login'),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: child,
                            ),
                            child: _AnimatedNavButton(
                              label: 'Sign Up',
                              background: const Color(0xFFE07A5F),
                              textColor: Colors.white,
                              onTap: () => Navigator.pushNamed(context, '/signup'),
                              isPrimary: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated press button ──────────────────────────────────────────────────
class _AnimatedNavButton extends StatefulWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AnimatedNavButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.borderColor,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(30.r),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 2)
                : null,
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFFE07A5F).withOpacity(0.38),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.fredoka(
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: widget.textColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating dots painter ──────────────────────────────────────────────────
class _FloatingDot {
  final double x, y, size, phase, speed;
  final Color color;
  _FloatingDot({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
    required this.color,
  });
}

class _DotsPainter extends CustomPainter {
  final List<_FloatingDot> dots;
  final double t;

  _DotsPainter({required this.dots, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final float = sin(dot.phase + t * dot.speed * 2 * pi) * 12;
      final dx = dot.x * size.width;
      final dy = dot.y * size.height + float;
      canvas.drawCircle(
        Offset(dx, dy),
        dot.size / 2,
        Paint()..color = dot.color.withOpacity(0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.t != t;
}
