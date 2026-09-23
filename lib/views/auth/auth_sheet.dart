import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../info_page.dart';

/// Shows the login / sign-up UI. Centered dialog on wide screens, bottom sheet
/// on phones. Returns true when authentication succeeded.
Future<bool> showAuthSheet(
  BuildContext context, {
  required bool isDark,
  String? reason,
}) async {
  final bool isWide = MediaQuery.of(context).size.width >= 760;

  if (isWide) {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AuthSheet(isDark: isDark, reason: reason, asDialog: true),
        ),
      ),
    );
    return result ?? false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AuthSheet(isDark: isDark, reason: reason),
  );
  return result ?? false;
}

class AuthSheet extends StatefulWidget {
  final bool isDark;
  final String? reason;
  final bool asDialog;

  const AuthSheet({
    super.key,
    required this.isDark,
    this.reason,
    this.asDialog = false,
  });

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _acceptedTerms = false;
  XFile? _pickedAvatar;
  Uint8List? _avatarBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedAvatar = picked;
        _avatarBytes = bytes;
      });
    } catch (_) {
      if (mounted) _toast('Could not open your gallery.');
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _toast('Please fill in your email and password.');
      return;
    }
    if (!_isLogin) {
      if (password.length < 6) {
        _toast('Password must be at least 6 characters.');
        return;
      }
      if (_confirmController.text != password) {
        _toast('Passwords do not match.');
        return;
      }
      if (!_acceptedTerms) {
        _toast('Please accept the Terms and Privacy Policy.');
        return;
      }
    }

    final bool ok = _isLogin
        ? await auth.signIn(email: email, password: password)
        : await auth.signUp(
            email: email,
            password: password,
            displayName: _nameController.text,
          );

    if (!mounted) return;
    if (ok) {
      if (!_isLogin && _pickedAvatar != null) {
        await auth.waitForUser();
        await auth.updateProfileImage(_pickedAvatar!);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Welcome back!' : 'Account created!')),
      );
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    Color textSecondary,
    Color fieldFill,
    Color borderColor, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSecondary, fontSize: 13),
      filled: true,
      fillColor: fieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = widget.isDark;

    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fieldFill = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget field({
      required String label,
      required TextEditingController controller,
      required String hint,
      bool obscure = false,
      TextInputType? keyboardType,
      String? autofillHint,
      Widget? suffixIcon,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            autofillHints: autofillHint == null ? null : [autofillHint],
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: _inputDecoration(
              hint,
              textSecondary,
              fieldFill,
              borderColor,
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.asDialog ? 0 : MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.asDialog ? 18 : 20),
            bottom: Radius.circular(widget.asDialog ? 18 : 0),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.asDialog && _isLogin)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                // Brand header (log-in only; sign-up stays minimal)
                if (_isLogin) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'lib/images/InkVaultPink.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'INKVAULT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'WELCOME BACK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _diamondDivider(borderColor),
                ],
                if (widget.reason != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.reason!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
                const SizedBox(height: 18),

                if (!_isLogin) ...[
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: fieldFill,
                            backgroundImage: _avatarBytes != null
                                ? MemoryImage(_avatarBytes!)
                                : null,
                            child: _avatarBytes == null
                                ? const Icon(Icons.person_rounded,
                                    size: 30, color: AppColors.primary)
                                : null,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickAvatar,
                          child: const Text(
                            'Choose profile photo',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  field(
                    label: 'Display name',
                    controller: _nameController,
                    hint: 'Your reader name (optional)',
                  ),
                  const SizedBox(height: 14),
                ],

                field(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                field(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Enter your password',
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),

                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  field(
                    label: 'Confirm Password',
                    controller: _confirmController,
                    hint: 'Re-enter your password',
                    obscure: _obscure,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                          activeColor: AppColors.primary,
                          side: BorderSide(color: borderColor, width: 1),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('I agree to the ',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary)),
                            _termLink('Terms of Service', 'Terms'),
                            Text(' and ',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary)),
                            _termLink('Privacy Policy', 'Privacy'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.error!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isBusy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: auth.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Log In' : 'Create Account',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    context.read<AuthProvider>().clearError();
                  }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Log in',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _diamondDivider(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 46, height: 1, color: color),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 46, height: 1, color: color),
      ],
    );
  }

  Widget _termLink(String label, String key) {
    return GestureDetector(
      onTap: () => InfoPage.openKey(context, key, isDark: widget.isDark),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
