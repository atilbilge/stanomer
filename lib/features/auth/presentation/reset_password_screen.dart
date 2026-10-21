import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/language_picker.dart';
import '../../../core/providers/locale_provider.dart';
import '../data/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? token;

  const ResetPasswordScreen({
    super.key,
    this.email,
    this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _tokenController = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getMismatchError(String lang) {
    if (lang == 'tr') return 'Şifreler birbiriyle eşleşmiyor.';
    if (lang == 'sr') return 'Lozinke se ne podudaraju.';
    if (lang == 'ru') return 'Пароли не совпадают.';
    return 'Passwords do not match.';
  }

  String _getConfirmPasswordLabel(String lang) {
    if (lang == 'tr') return 'Şifre Tekrarı';
    if (lang == 'sr') return 'Potvrdite lozinku';
    if (lang == 'ru') return 'Повторите пароль';
    return 'Confirm Password';
  }

  Future<void> _handleReset() async {
    final loc = AppLocalizations.of(context)!;
    final lang = ref.read(localeProvider).languageCode;
    final email = _emailController.text.trim();
    final tokenOrCode = _tokenController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = loc.invalidEmail);
      return;
    }
    if (tokenOrCode.isEmpty) {
      setState(() => _errorMessage = loc.enterVerificationCode);
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = loc.passwordTooShort);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = _getMismatchError(lang));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(authRepositoryProvider).verifyAndResetPassword(
        email: email,
        codeOrToken: tokenOrCode,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circleCheck, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(loc.passwordResetSuccess)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/login');
      } else {
        final err = res['error']?.toString();
        String msg = err ?? 'Error';
        if (err == 'invalid_or_expired_code') {
          msg = loc.invalidOrExpiredCode;
        } else if (err == 'password_too_short') {
          msg = loc.passwordTooShort;
        } else if (err == 'user_not_found') {
          msg = loc.userNotFoundWithEmail;
        }
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: StanomerColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          loc.forgotPasswordTitle,
          style: const TextStyle(
            color: StanomerColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguagePicker(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: StanomerColors.brandPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.keyRound,
                      color: StanomerColors.brandPrimary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.resetPasswordButton,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: StanomerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: StanomerColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StanomerColors.alertPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: StanomerColors.alertPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 18,
                          color: StanomerColors.alertPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: StanomerColors.alertPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: loc.email,
                    prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Token or 6-digit Code Field
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: loc.verificationCode,
                    hintText: loc.enterVerificationCode,
                    prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: loc.newPassword,
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: _getConfirmPasswordLabel(lang),
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StanomerColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            loc.resetPasswordButton,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to login button
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    loc.cancel,
                    style: const TextStyle(color: StanomerColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
