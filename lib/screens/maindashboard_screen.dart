// lib/screens/maindashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyota/theme.dart';
import 'parentdashboard.dart';
import 'childdashboard.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with TickerProviderStateMixin {
  AnimationController? _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _starController?.dispose();
    super.dispose();
  }

  void _openParentDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double scaleFactor = (screenWidth / 375).clamp(0.8, 1.2);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24 * scaleFactor,
                    vertical: 40 * scaleFactor,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to your\nlearning adventure!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 22 * scaleFactor,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 40 * scaleFactor),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              imageAsset: 'assets/images/parent.png',
                              label: 'Parent',
                              scaleFactor: scaleFactor,
                              onTap: _openParentDashboard,
                            ),
                          ),
                          SizedBox(width: 16 * scaleFactor),
                          Expanded(
                            child: _buildOptionCard(
                              imageAsset: 'assets/images/child.png',
                              label: 'Child',
                              scaleFactor: scaleFactor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChildDashboard()),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildOptionCard({
    required String imageAsset,
    required String label,
    required double scaleFactor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24 * scaleFactor),
                color: colorScheme.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(imageAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * scaleFactor),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}