// lib/screens/activity_extensions.dart
// Shared time-extension dialog used by all activity screens
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeExtensionDialog extends StatelessWidget {
  final int extensionsLeft;
  final Color accentColor;
  final VoidCallback onExtend;
  final VoidCallback onFinish;

  const TimeExtensionDialog({
    super.key,
    required this.extensionsLeft,
    required this.accentColor,
    required this.onExtend,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.25),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_rounded, size: 38, color: accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              "Time's up!",
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              extensionsLeft > 0
                  ? 'Need a little more time?\nYou can add 1 extra minute.'
                  : 'Great effort! Ready to see your result?',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            if (extensionsLeft > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(extensionsLeft, (i) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.add_circle_rounded, size: 16, color: accentColor.withOpacity(0.55)),
                  ),
                ),
              ),
              Text(
                '$extensionsLeft extension${extensionsLeft == 1 ? '' : 's'} left',
                style: GoogleFonts.fredoka(fontSize: 13, color: accentColor.withOpacity(0.70)),
              ),
            ],
            const SizedBox(height: 24),
            // Buttons
            if (extensionsLeft > 0)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    '+1 Minute',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: onFinish,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                ),
                child: Text(
                  extensionsLeft > 0 ? 'Finish Activity' : 'See My Result',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
