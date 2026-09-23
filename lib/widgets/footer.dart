import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../views/info_page.dart';

class Footer extends StatefulWidget {
  final bool isDark;
  final Function(String) onTabSelected;

  const Footer({super.key, required this.isDark, required this.onTabSelected});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  static const String _githubUrl = 'https://github.com/leecodehub';

  String _language = 'English';

  final List<({FaIconData icon, String label})> _socials = const [
    (icon: FontAwesomeIcons.facebookF, label: 'Facebook'),
    (icon: FontAwesomeIcons.instagram, label: 'Instagram'),
    (icon: FontAwesomeIcons.xTwitter, label: 'X'),
    (icon: FontAwesomeIcons.youtube, label: 'YouTube'),
  ];

  static const List<String> _links = [
    'About',
    'Feedback',
    'Help',
    'Terms',
    'Privacy',
    'Advertise',
    'Contact',
  ];

  Future<void> _openGithub() async {
    final uri = Uri.parse(_githubUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open GitHub profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkCard : AppColors.lightSurface;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          // Decorative social icons + the one real GitHub link.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final social in _socials) _iconTile(social.icon),
              _iconTile(
                FontAwesomeIcons.github,
                onTap: _openGithub,
                tooltip: 'GitHub',
                highlighted: true,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Links row
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int i = 0; i < _links.length; i++) ...[
                _linkButton(_links[i], textSecondary),
                if (i != _links.length - 1)
                  Text('|', style: TextStyle(color: borderColor)),
              ],
            ],
          ),

          const SizedBox(height: 18),

          // Language selector (visual)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isDense: true,
                dropdownColor: widget.isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                style: TextStyle(color: textPrimary, fontSize: 13),
                icon: Icon(Icons.arrow_drop_down, color: textSecondary),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: '한국어', child: Text('한국어')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _language = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Brand wordmark
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'lib/images/InkVaultPink.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34,
                    height: 34,
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
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(text: 'INK', style: TextStyle(color: textPrimary)),
                    const TextSpan(
                      text: 'VAULT',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} InkVault. Powered by MangaDex API.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _iconTile(
    FaIconData icon, {
    VoidCallback? onTap,
    String? tooltip,
    bool highlighted = false,
  }) {
    final color = AppColors.primary;
    final tile = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.18)
            : (widget.isDark ? AppColors.darkSurface : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(10),
        border: highlighted ? Border.all(color: color) : null,
      ),
      child: Center(child: FaIcon(icon, size: 16, color: color)),
    );

    if (onTap == null) return tile;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: tile,
      ),
    );
  }

  Widget _linkButton(String label, Color textSecondary) {
    return InkWell(
      onTap: () => InfoPage.openKey(context, label, isDark: widget.isDark),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
      ),
    );
  }
}
