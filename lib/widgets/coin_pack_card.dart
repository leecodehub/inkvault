import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A single purchasable coin bundle.
class CoinPack {
  final int coins;
  final int bonus;
  final String price;
  final bool bestValue;

  const CoinPack({
    required this.coins,
    required this.bonus,
    required this.price,
    this.bestValue = false,
  });

  int get total => coins + bonus;
}

/// Minimal coin bundle card with a hover lift. Fits narrow phone widths.
class CoinPackCard extends StatefulWidget {
  final CoinPack pack;
  final bool isDark;
  final VoidCallback onBuy;

  const CoinPackCard({
    super.key,
    required this.pack,
    required this.isDark,
    required this.onBuy,
  });

  @override
  State<CoinPackCard> createState() => _CoinPackCardState();
}

class _CoinPackCardState extends State<CoinPackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final pack = widget.pack;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final bool highlight = pack.bestValue || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? const Color(0xFF1F2530) : const Color(0xFFF8FAFC))
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? AppColors.primary : borderColor,
            width: highlight ? 1.4 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 18,
              child: pack.bestValue
                  ? const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                    )
                  : (pack.bonus > 0
                      ? Text(
                          '+${pack.bonus} bonus',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${pack.total}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  'coins',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: widget.onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      highlight ? AppColors.primary : Colors.transparent,
                  foregroundColor:
                      highlight ? Colors.white : AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.primary, width: 1),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    pack.price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
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
