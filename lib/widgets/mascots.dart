// lib/widgets/mascots.dart
// Shared mascot widgets: Dino (celebration) + Monkey (wrong answer prompt)
import 'dart:js' as js;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyota/theme.dart';

// ─── Celebration Sound ────────────────────────────────────────────────────────

void playCelebrationSound() {
  try {
    js.context.callMethod('eval', ['''
      (function() {
        try {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          var notes = [523, 659, 784, 1047, 784, 1047, 1319];
          notes.forEach(function(freq, i) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.frequency.value = freq;
            osc.type = 'sine';
            var t = ctx.currentTime + i * 0.13;
            gain.gain.setValueAtTime(0.25, t);
            gain.gain.exponentialRampToValueAtTime(0.001, t + 0.35);
            osc.start(t);
            osc.stop(t + 0.38);
          });
        } catch(e) {}
      })();
    ''']);
  } catch (_) {}
}

void playWrongSound() {
  try {
    js.context.callMethod('eval', ['''
      (function() {
        try {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          var osc = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.frequency.value = 280;
          osc.type = 'sine';
          gain.gain.setValueAtTime(0.18, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
          osc.start(ctx.currentTime);
          osc.stop(ctx.currentTime + 0.45);
        } catch(e) {}
      })();
    ''']);
  } catch (_) {}
}

// ─── Dino Celebration Dialog ──────────────────────────────────────────────────

class DinoResultDialog extends StatefulWidget {
  final int stars;
  final int score;
  final int total;
  final Color accentColor;
  final VoidCallback onContinue;
  final String? message;

  const DinoResultDialog({
    super.key,
    required this.stars,
    required this.score,
    required this.total,
    required this.accentColor,
    required this.onContinue,
    this.message,
  });

  @override
  State<DinoResultDialog> createState() => _DinoResultDialogState();
}

class _DinoResultDialogState extends State<DinoResultDialog> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _sparkleController;
  late Animation<double> _bounceAnim;
  late Animation<double> _sparkleAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _bounceAnim = CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut);
    _sparkleAnim = CurvedAnimation(parent: _sparkleController, curve: Curves.linear);
    _bounceController.forward();
    if (widget.stars >= 1) playCelebrationSound();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.stars == 3
        ? 'AMAZING! 🌟'
        : widget.stars == 2
            ? 'GREAT JOB! 🎉'
            : widget.stars == 1
                ? 'GOOD WORK! 👍'
                : 'KEEP GOING! 💪';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card
          Container(
            padding: EdgeInsets.fromLTRB(28.w, 36.h, 28.w, 28.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 30.h),

                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (_, __) => Transform.scale(
                      scale: i < widget.stars ? _bounceAnim.value.clamp(0.0, 1.3) : 1.0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(
                          i < widget.stars ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 44.w,
                          color: i < widget.stars ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 12.h),

                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
                SizedBox(height: 6.h),

                Text(
                  '${widget.score} out of ${widget.total} correct!',
                  style: GoogleFonts.fredoka(fontSize: 16.sp, color: Colors.grey[600]),
                ),

                if (widget.message != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    widget.message!,
                    style: GoogleFonts.fredoka(fontSize: 14.sp, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 24.h),

                // Continue button
                ElevatedButton(
                  onPressed: widget.onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                    elevation: 4,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.fredoka(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating sparkles (only on good result)
          if (widget.stars >= 2)
            ..._buildSparkles(),

          // Dino peeking from the top
          Positioned(
            top: -60.h,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _bounceAnim,
              child: Center(
                child: Image.asset(
                  'assets/images/dino_celebration.png',
                  width: 110.w,
                  height: 110.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final positions = [
      Offset(20, 60), Offset(-10, 120), Offset(260, 50),
      Offset(280, 130), Offset(140, 20),
    ];
    return positions.asMap().entries.map((e) {
      final offset = (e.key * 0.2) % 1.0;
      return Positioned(
        left: e.value.dx.w,
        top: e.value.dy.h,
        child: AnimatedBuilder(
          animation: _sparkleAnim,
          builder: (_, __) {
            final t = (_sparkleAnim.value + offset) % 1.0;
            return Opacity(
              opacity: sin(t * pi),
              child: Transform.scale(
                scale: 0.5 + sin(t * pi) * 0.5,
                child: Icon(Icons.star_rounded, color: Colors.amber, size: 18.w),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}

// ─── Monkey Wrong Answer Prompt ───────────────────────────────────────────────

class MonkeyPromptOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const MonkeyPromptOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<MonkeyPromptOverlay> createState() => _MonkeyPromptOverlayState();
}

class _MonkeyPromptOverlayState extends State<MonkeyPromptOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    playWrongSound();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _slideController.forward();

    // Auto-dismiss after 2.2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(color: Colors.orange[200]!, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/monkey_hint.png',
                width: 56.w,
                height: 56.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12.w),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    widget.message,
                    style: GoogleFonts.fredoka(
                      fontSize: 15.sp,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
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

// ─── Helper: show monkey as a bottom overlay (not a dialog) ──────────────────

OverlayEntry? _activeMonkeyEntry;

void showMonkeyPrompt(BuildContext context, String message) {
  _activeMonkeyEntry?.remove();
  _activeMonkeyEntry = null;

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: MonkeyPromptOverlay(
          message: message,
          onDismiss: () {
            _activeMonkeyEntry?.remove();
            _activeMonkeyEntry = null;
          },
        ),
      ),
    ),
  );

  _activeMonkeyEntry = entry;
  Overlay.of(context).insert(entry);
}

// ─── Helper: show dino result dialog ─────────────────────────────────────────

void showDinoResult({
  required BuildContext context,
  required int stars,
  required int score,
  required int total,
  required Color accentColor,
  required VoidCallback onContinue,
  String? message,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => DinoResultDialog(
      stars: stars,
      score: score,
      total: total,
      accentColor: accentColor,
      onContinue: onContinue,
      message: message,
    ),
  );
}
