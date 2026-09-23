import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../views/auth/auth_sheet.dart';
import '../widgets/coin_pack_card.dart';

class CoinShopView extends StatelessWidget {
  final bool isDark;

  const CoinShopView({super.key, required this.isDark});

  static const List<CoinPack> _packs = [
    CoinPack(coins: 50, bonus: 0, price: '\$0.99'),
    CoinPack(coins: 200, bonus: 20, price: '\$3.99'),
    CoinPack(coins: 500, bonus: 75, price: '\$8.99'),
    CoinPack(coins: 1200, bonus: 250, price: '\$19.99', bestValue: true),
  ];

  Future<void> _buy(
      BuildContext context, AuthProvider auth, CoinPack pack) async {
    if (!auth.isLoggedIn) {
      await showAuthSheet(context,
          isDark: isDark, reason: 'Log in to buy coins and keep your balance.');
      return;
    }
    await auth.addCoins(pack.total);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${pack.total} coins!')),
      );
    }
  }

  Future<void> _buyPremium(BuildContext context, AuthProvider auth) async {
    if (!auth.isLoggedIn) {
      await showAuthSheet(context,
          isDark: isDark, reason: 'Log in to subscribe to Premium.');
      return;
    }
    final ok = await auth.activatePremium();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Premium activated for ${AppConfig.premiumDurationDays} days!'
              : 'Not enough coins for Premium.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coin Shop',
            style: TextStyle(
              fontSize: isMobileWidth(context) ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlock chapters, save more bookmarks, and go Premium.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 18),

          // Balance (minimal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your balance',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${auth.coins} coins',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Premium pass (minimal, primary outline)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium — ${AppConfig.premiumDurationDays} days',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlimited bookmarks + free new-release chapters',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '${AppConfig.premiumCost} coins',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: auth.isBusy
                      ? null
                      : () => _buyPremium(context, auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    auth.isPremium ? 'Extend' : 'Get',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Coin bundles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _packs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  responsiveColumns(context, xs: 2, sm: 3, md: 3, lg: 4),
              mainAxisExtent: 160,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final pack = _packs[index];
              return CoinPackCard(
                pack: pack,
                isDark: isDark,
                onBuy: () => _buy(context, auth, pack),
              );
            },
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Purchases are simulated. New chapters cost ${AppConfig.chapterUnlockCost} coins each; extra bookmarks cost ${AppConfig.extraBookmarkCost} coins.',
                  style:
                      TextStyle(fontSize: 11, height: 1.4, color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
