import 'package:flutter/material.dart';
import 'yin_yang_painter.dart';

class ThemeToggle extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  double _turns = 0.0;

  void _handleTap() {
    setState(() {
      _turns += 1.5; // Smooth rotation animation
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : const Color(0xFFF1F5F9);

    final borderColor =
        widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Primary accent color #EB164F for Dark Mode / Active State
    const accentColor = Color(0xFFEB164F);

    // Dark color for Light Mode Yin section
    const lightModeDarkColor = Color(0xFF0F172A);

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _turns,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: CustomPaint(
                size: const Size(20, 20),
                painter: YinYangPainter(
                  darkColor: widget.isDark ? accentColor : lightModeDarkColor,
                  lightColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isDark ? "Dark" : "Light",
              style: const TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
