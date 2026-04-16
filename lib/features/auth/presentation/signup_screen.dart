import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/foundation.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/language_picker.dart';
import '../../../core/theme/colors.dart';
import 'widgets/role_card.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/apple_sign_in_button.dart';
import '../data/auth_repository.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // String? _selectedRole; // Role selection removed from signup
  bool _consentGiven = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    final loc = AppLocalizations.of(context)!;
    
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fieldRequired)));
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.consentRequired)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(_emailController.text, _passwordController.text, '127.0.0.1', _nameController.text);
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: LanguagePicker(),
              ),
              const SizedBox(height: 12),
              Image.asset(
                'assets/images/logo_no_bg.png',
                height: 80,
              ),
              const SizedBox(height: 12),
              Text(
                loc.welcomeToStanomer,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                loc.createAccount,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Role selection Row removed
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StanomerColors.bgCard,
                  borderRadius: const BorderRadius.all(StanomerRadius.xl),
                  boxShadow: StanomerShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.fullName,
                        prefixIcon: const Icon(LucideIcons.user, size: 20),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: loc.email,
                        prefixIcon: const Icon(LucideIcons.mail, size: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: loc.password,
                        prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _consentGiven,
                            onChanged: (val) => setState(() => _consentGiven = val ?? false),
                            activeColor: StanomerColors.brandPrimary,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(StanomerRadius.xs)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: StanomerColors.bgCard,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: StanomerRadius.xl)),
                                builder: (ctx) => Container(
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
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                loc.zzplConsent,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                  color: StanomerColors.brandPrimary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: StanomerColors.brandPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(loc.signup),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(loc.signup.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(loc.alreadyHaveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
