// lib/screens/maindashboard_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parentdashboard.dart';
import 'childdashboard.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _headerController;
  late AnimationController _orbitController;

  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;

  int? _pressedCard;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _headerController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen, int cardIndex) async {
    setState(() => _pressedCard = cardIndex);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _pressedCard = null);
    Navigator.push(context, _buildRoute(screen));
  }

  PageRouteBuilder _buildRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFFFFF0E8), const Color(0xFFFFE4D6),
                      _bgController.value)!,
                  Color.lerp(const Color(0xFFFDE8D8), const Color(0xFFF5C9B0),
                      _bgController.value)!,
                  Color.lerp(const Color(0xFFFAD5C0), const Color(0xFFFFEADF),
                      _bgController.value)!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                _buildFloatingOrbs(size),
                _buildContent(size),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingOrbs(Size size) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (_, __) {
        final t = _orbitController.value * 2 * math.pi;
        return Stack(
          children: [
            _orb(left: size.width * 0.12 + math.cos(t) * 18, top: size.height * 0.10 + math.sin(t) * 12, radius: 56, color: const Color(0xFFFFD6C2), opacity: 0.55),
            _orb(right: size.width * 0.08 + math.cos(t + 1.2) * 14, top: size.height * 0.18 + math.sin(t + 1.2) * 10, radius: 38, color: const Color(0xFFF4B8A0), opacity: 0.40),
            _orb(left: size.width * 0.05 + math.cos(t + 2.1) * 10, bottom: size.height * 0.28 + math.sin(t + 2.1) * 14, radius: 44, color: const Color(0xFFFFCDB8), opacity: 0.45),
            _orb(right: size.width * 0.10 + math.cos(t + 0.8) * 16, bottom: size.height * 0.18 + math.sin(t + 0.8) * 12, radius: 62, color: const Color(0xFFE8A88C), opacity: 0.30),
            _orb(left: size.width * 0.42 + math.cos(t + 3.0) * 20, top: size.height * 0.05 + math.sin(t + 3.0) * 8, radius: 28, color: const Color(0xFFF5C4A8), opacity: 0.50),
            _orb(right: size.width * 0.30 + math.cos(t + 1.8) * 12, bottom: size.height * 0.08 + math.sin(t + 1.8) * 16, radius: 36, color: const Color(0xFFFFD0B8), opacity: 0.42),
          ],
        );
      },
    );
  }

  Widget _orb({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildContent(Size size) {
    final isWide = size.width > 600;
    final hPad = isWide ? size.width * 0.12 : 24.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            SizedBox(height: isWide ? 48 : 36),
            _buildCards(size, isWide),
            SizedBox(height: isWide ? 40 : 28),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (_, __) => Opacity(
        opacity: _headerFade.value,
        child: Transform.translate(
          offset: Offset(0, _headerSlide.value),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Star icon badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A07A).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFFE8A07A).withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Math is Easy',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBF7A56),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // NYOTA title with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD4693A), Color(0xFFE8956A), Color(0xFFC45B2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'NYOTA',
                  style: GoogleFonts.fredoka(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 6,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Who\'s learning today?',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B5E44).withOpacity(0.85),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your learning mode to get started',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8B5E44).withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCards(Size size, bool isWide) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (_, __) => Opacity(
        opacity: _cardFade.value,
        child: Transform.translate(
          offset: Offset(0, _cardSlide.value),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDashboardCard(
                      index: 0,
                      imageAsset: 'assets/images/child.png',
                      label: 'Child',
                      subtitle: 'Fun activities & games',
                      description: 'Start your math adventure with shapes, counting and more!',
                      gradientColors: const [Color(0xFFFFD4BD), Color(0xFFFFB899)],
                      accentColor: const Color(0xFFE8724A),
                      badgeText: 'Let\'s Play!',
                      emoji: '🚀',
                      onTap: () => _navigateTo(const ChildDashboard(), 0),
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildDashboardCard(
                      index: 1,
                      imageAsset: 'assets/images/parent.png',
                      label: 'Parent',
                      subtitle: 'Manage & monitor',
                      description: 'Set schedules, track progress and customise rewards.',
                      gradientColors: const [Color(0xFFC8DFC8), Color(0xFFA8C4A8)],
                      accentColor: const Color(0xFF5A8A5A),
                      badgeText: 'Dashboard',
                      emoji: '🎯',
                      onTap: () => _navigateTo(const ParentDashboard(), 1),
                    )),
                  ],
                )
              : Column(
                  children: [
                    _buildDashboardCard(
                      index: 0,
                      imageAsset: 'assets/images/child.png',
                      label: 'Child',
                      subtitle: 'Fun activities & games',
                      description: 'Start your math adventure with shapes, counting and more!',
                      gradientColors: const [Color(0xFFFFD4BD), Color(0xFFFFB899)],
                      accentColor: const Color(0xFFE8724A),
                      badgeText: 'Let\'s Play!',
                      emoji: '🚀',
                      onTap: () => _navigateTo(const ChildDashboard(), 0),
                    ),
                    const SizedBox(height: 20),
                    _buildDashboardCard(
                      index: 1,
                      imageAsset: 'assets/images/parent.png',
                      label: 'Parent',
                      subtitle: 'Manage & monitor',
                      description: 'Set schedules, track progress and customise rewards.',
                      gradientColors: const [Color(0xFFC8DFC8), Color(0xFFA8C4A8)],
                      accentColor: const Color(0xFF5A8A5A),
                      badgeText: 'Dashboard',
                      emoji: '🎯',
                      onTap: () => _navigateTo(const ParentDashboard(), 1),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required int index,
    required String imageAsset,
    required String label,
    required String subtitle,
    required String description,
    required List<Color> gradientColors,
    required Color accentColor,
    required String badgeText,
    required String emoji,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedCard == index;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradientColors[1].withOpacity(0.45),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative background circles
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: badge + emoji
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Avatar image
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  label == 'Child' ? Icons.child_care : Icons.person,
                                  size: 56,
                                  color: accentColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Labels
                        Text(
                          label,
                          style: GoogleFonts.fredoka(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: accentColor.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: accentColor.withOpacity(0.70),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // CTA button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label == 'Child' ? 'Start Learning' : 'Open Dashboard',
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (_, __) => Opacity(
        opacity: (_headerFade.value * 0.7).clamp(0.0, 1.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _footerDot(const Color(0xFFE8724A)),
                const SizedBox(width: 6),
                _footerDot(const Color(0xFF5A8A5A)),
                const SizedBox(width: 6),
                _footerDot(const Color(0xFFE8B07A)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Every star starts with one step ⭐',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8B5E44).withOpacity(0.50),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerDot(Color color) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.55),
        ),
      );
}
