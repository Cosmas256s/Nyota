// lib/widgets/nav_buttons.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KidNavButton – big, chunky, animated button for children's navigation
// ─────────────────────────────────────────────────────────────────────────────
class KidNavButton extends StatefulWidget {
  final String label;
  final String emoji;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool wide; // if true fills available width

  const KidNavButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  State<KidNavButton> createState() => _KidNavButtonState();
}

class _KidNavButtonState extends State<KidNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.38),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize:
                widget.wide ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.wide ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KidBackButton – terracotta back arrow
// ─────────────────────────────────────────────────────────────────────────────
class KidBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const KidBackButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return KidNavButton(
      label: 'Back',
      emoji: '⬅️',
      icon: Icons.arrow_back_ios_new_rounded,
      color: color ?? const Color(0xFFE07A5F),
      onTap: onTap ?? () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KidHomeButton – warm blue "go home" button
// ─────────────────────────────────────────────────────────────────────────────
class KidHomeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const KidHomeButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return KidNavButton(
      label: 'Home',
      emoji: '🏠',
      icon: Icons.home_rounded,
      color: const Color(0xFF3A86C8),
      onTap: onTap ?? () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KidNavRow – Back + Home side by side (for top-of-screen nav bars)
// ─────────────────────────────────────────────────────────────────────────────
class KidNavRow extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final Widget? trailing; // optional right-side widget (score, timer, etc.)

  const KidNavRow({
    super.key,
    this.onBack,
    this.onHome,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Row(
        children: [
          KidBackButton(onTap: onBack),
          const SizedBox(width: 10),
          KidHomeButton(onTap: onHome),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KidNextButton – coloured "forward/next" pill (used in onboarding)
// ─────────────────────────────────────────────────────────────────────────────
class KidNextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLoading;

  const KidNextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFFE07A5F)).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          ),
        ),
      );
    }
    return KidNavButton(
      label: label,
      emoji: '➡️',
      icon: Icons.arrow_forward_ios_rounded,
      color: color ?? const Color(0xFFE07A5F),
      onTap: onTap,
      wide: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy wrappers kept for backward compatibility
// ─────────────────────────────────────────────────────────────────────────────

/// Animated back button — bounces on press, slides in on first build.
class AnimatedBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;
  const AnimatedBackButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) =>
      KidBackButton(onTap: onTap, color: color);
}

/// Forward / next arrow button — for going to the next step.
class AnimatedForwardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLoading;

  const AnimatedForwardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => KidNextButton(
        label: label,
        onTap: onTap,
        color: color,
        isLoading: isLoading,
      );
}
