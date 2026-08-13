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
import '../../../core/widgets/bottom_sheet_wrapper.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/apple_sign_in_button.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/utm_tracker.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _consentGiven = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final loc = AppLocalizations.of(context)!;
    
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fieldRequired)));
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.consentRequired),
        backgroundColor: StanomerColors.alertPrimary,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UtmTracker.captureFromUri();
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(
        _emailController.text.trim(), 
        _passwordController.text.trim(), 
        '127.0.0.1', 
        _nameController.text.trim(),
        utmSource: UtmTracker.utmSource,
        utmMedium: UtmTracker.utmMedium,
        utmCampaign: UtmTracker.utmCampaign,
      );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final loc = AppLocalizations.of(context)!;

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.consentRequired),
        backgroundColor: StanomerColors.alertPrimary,
      ));
      return;
    }

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    final loc = AppLocalizations.of(context)!;

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.consentRequired),
        backgroundColor: StanomerColors.alertPrimary,
      ));
      return;
    }

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConsentModal() {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: StanomerColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: StanomerRadius.xl)),
      builder: (ctx) => ResilientBottomSheetWrapper(
        child: Container(
          padding: const EdgeInsets.all(24.0).copyWith(bottom: MediaQuery.of(ctx).padding.bottom + 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.consentTextFullTitle, 
                style: theme.textTheme.headlineLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    loc.consentTextFullBody, 
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(loc.ok),
              ),
            ],
          ),
        ),
      ),
    );
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
                      minHeight: 640,
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
                    LucideIcons.userPlus,
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
              Text(
                loc.heroHeadline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.5,
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
    final theme = Theme.of(context);

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
                  if (EnvConfig.isDev) ...[
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

          const SizedBox(height: 28),

          // Title & Subtitle
          Text(
            loc.createAccount,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: StanomerColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.welcomeToStanomer,
            style: const TextStyle(
              fontSize: 14,
              color: StanomerColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Label: Ad Soyad
          Text(
            loc.fullName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Full Name TextField
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, color: StanomerColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ad Soyad',
              hintStyle: TextStyle(fontSize: 13, color: StanomerColors.textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(LucideIcons.user, size: 18),
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

          const SizedBox(height: 16),

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

          const SizedBox(height: 16),

          // Label: Şifre
          Text(
            loc.password,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: StanomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Password TextField
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
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

          const SizedBox(height: 16),

          // ZZPL / Terms Consent Checkbox Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _consentGiven,
                  onChanged: (val) => setState(() => _consentGiven = val ?? false),
                  activeColor: const Color(0xFF155EEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _showConsentModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      loc.zzplConsent,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: const Color(0xFF155EEF),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF155EEF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Primary Sign Up Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
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
                      loc.signup,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 18),

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

          const SizedBox(height: 16),

          // Social Sign In Buttons
          GoogleSignInButton(
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _signInWithGoogle,
          ),

          if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) ...[
            const SizedBox(height: 10),
            AppleSignInButton(
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signInWithApple,
            ),
          ],

          const SizedBox(height: 24),

          // Login Footer Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.alreadyHaveAccount.contains('?')
                    ? loc.alreadyHaveAccount.split('?').first + '? '
                    : loc.alreadyHaveAccount + ' ',
                style: const TextStyle(
                  color: StanomerColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              InkWell(
                onTap: () => context.go('/login'),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  loc.alreadyHaveAccount.contains('?')
                      ? loc.alreadyHaveAccount.split('?').last.trim()
                      : loc.login,
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
