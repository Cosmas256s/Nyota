// lib/widgets/nav_buttons.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated back button — bounces on press, slides in on first build.
class AnimatedBackButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? color;

  const AnimatedBackButton({super.key, this.onTap, this.color});

  @override
  State<AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    final nav = Navigator.of(context);
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (nav.canPop()) {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.color ?? const Color(0xFFE07A5F);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        _handleTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: btnColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: btnColor.withOpacity(0.30), width: 1.5),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: btnColor,
            size: 20.w,
          ),
        ),
      ),
    );
  }
}

/// Forward / next arrow button — for going to the next step.
class AnimatedForwardButton extends StatefulWidget {
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
  State<AnimatedForwardButton> createState() => _AnimatedForwardButtonState();
}

class _AnimatedForwardButtonState extends State<AnimatedForwardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
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
    final btnColor = widget.color ?? const Color(0xFFE07A5F);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            color: widget.isLoading ? btnColor.withOpacity(0.6) : btnColor,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: btnColor.withOpacity(0.35),
                blurRadius: 14.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else ...[
                Text(
                  widget.label,
                  style: GoogleFonts.fredoka(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16.w),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
