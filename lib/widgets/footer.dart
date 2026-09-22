import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class Footer extends StatelessWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const Footer({super.key, required this.isDark, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Branding & Navigation Links
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              // Logo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'iV',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: 'INK',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const TextSpan(
                          text: 'VAULT',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Footer Quick Links
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _footerLink('Home'),
                  _footerLink('All Series'),
                  _footerLink('Weekly Schedule'),
                  _footerLink('Coin Shop'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          const SizedBox(height: 24),

          // Copyright & Disclaimer
          Text(
            '© ${DateTime.now().year} InkVault. All rights reserved. Powered by MangaDex API.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => onTabSelected(label),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}
