import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/language_picker.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/theme/colors.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/apple_sign_in_button.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final loc = AppLocalizations.of(context)!;
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fieldRequired)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signIn(_emailController.text.trim(), _passwordController.text.trim());
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithApple();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: StanomerColors.alertPrimary,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final loc = AppLocalizations.of(context)!;
    final emailController = TextEditingController(text: _emailController.text.trim());

    final String? email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(loc.forgotPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.loginToAccount,
                style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.email,
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, emailController.text.trim()),
              child: Text(loc.sendReminder),
            ),
          ],
        );
      },
    );

    if (email != null && email.isNotEmpty) {
      try {
        await ref.read(authRepositoryProvider).resetPassword(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.reminderMessageCopied),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: StanomerColors.alertPrimary,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            if (isDesktop) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 960,
                      minHeight: 600,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Hero Panel
                          Expanded(
                            flex: 5,
                            child: _buildLeftHeroPanel(context, loc),
                          ),
                          // Right Form Panel
                          Expanded(
                            flex: 6,
                            child: _buildRightFormPanel(context, loc, isDesktop: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Mobile / Narrow View
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildRightFormPanel(context, loc, isDesktop: false),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftHeroPanel(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Center(
                  child: AppLogo(height: 24, width: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stanomer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Central Graphic Illustration / Badge
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    LucideIcons.building2,
                    color: Color(0xFF38BDF8),
                    size: 48,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Main Hero Text Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.5,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(text: loc.heroHeadline),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loc.heroSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightFormPanel(BuildContext context, AppLocalizations loc, {required bool isDesktop}) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 44.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Bar (Logo + Dev Badge & Language Picker)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppLogo(height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    'Stanomer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: StanomerColors.textPrimary,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF4E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'dev',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const LanguagePicker(),
            ],
          ),

          const SizedBox(height: 32),

          // Title & Subtitle
          Text(
            loc.welcomeToStanomer,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: StanomerColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.loginToAccount,
            style: const TextStyle(
              fontSize: 14,
              color: StanomerColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // Label: E-posta
          Text(
            loc.email,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Email TextField
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, color: StanomerColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'ornek@email.com',
              hintStyle: TextStyle(fontSize: 13, color: StanomerColors.textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF155EEF), width: 1.8),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Label & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.password,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StanomerColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: _showForgotPasswordDialog,
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  loc.forgotPassword,
                  style: const TextStyle(
                    color: Color(0xFF155EEF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Password TextField
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signIn(),
            style: const TextStyle(fontSize: 14, color: StanomerColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(LucideIcons.lock, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: StanomerColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF155EEF), width: 1.8),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Login Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155EEF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loc.login,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Divider "veya"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  loc.orLabel,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 18),

          // Social Login Buttons
          GoogleSignInButton(
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _signInWithGoogle,
          ),

          if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) ...[
            const SizedBox(height: 12),
            AppleSignInButton(
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
          ],

          const SizedBox(height: 28),

          // Signup Footer Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.dontHaveAccount.contains('?')
                    ? loc.dontHaveAccount.split('?').first + '? '
                    : loc.dontHaveAccount + ' ',
                style: const TextStyle(
                  color: StanomerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              InkWell(
                onTap: () => context.go('/signup'),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  loc.dontHaveAccount.contains('?')
                      ? loc.dontHaveAccount.split('?').last.trim()
                      : loc.createAccount,
                  style: const TextStyle(
                    color: Color(0xFF155EEF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
