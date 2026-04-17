import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
  }

  Future<void> _updateProfile() async {
    final loc = AppLocalizations.of(context)!;
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(fullName: _nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.profileUpdatedSuccess),
          backgroundColor: StanomerColors.successPrimary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: StanomerColors.alertPrimary,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final loc = AppLocalizations.of(context)!;
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.fieldRequired)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      
      // 1. Re-authenticate to verify old password
      await repo.reauthenticate(_oldPasswordController.text);
      
      // 2. Update to new password
      await repo.updatePassword(_newPasswordController.text);
      
      _oldPasswordController.clear();
      _newPasswordController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.passwordChangedSuccess),
          backgroundColor: StanomerColors.successPrimary,
        ));
      }
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

  Future<void> _showDeleteConfirmDialog() async {
    final loc = AppLocalizations.of(context)!;
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    final List<String> providers = [];
    if (user?.appMetadata['provider'] != null) {
      providers.add(user!.appMetadata['provider'].toString());
    }
    if (user?.appMetadata['providers'] is List) {
      providers.addAll((user!.appMetadata['providers'] as List).map((e) => e.toString()));
    }

    // Determine the most likely provider, prioritizing Apple if present and user says so, 
    // or simply checking what's actually there.
    final bool isAppleUser = providers.contains('apple');
    final bool isGoogleUser = !isAppleUser && providers.contains('google');
    final bool isEmailUser = !isAppleUser && !isGoogleUser;

    final passwordController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canDelete = isEmailUser ? passwordController.text.isNotEmpty : true;

          return AlertDialog(
            title: Text(loc.deleteAccount, style: const TextStyle(color: StanomerColors.alertPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.deleteAccountWarning),
                const SizedBox(height: 24),
                
                if (isEmailUser) ...[
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.password,
                      prefixIcon: const Icon(LucideIcons.lock),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ] else ...[
                  // OAuth users don't need a separate field, they will verify during the final click
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StanomerColors.brandPrimarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(isGoogleUser ? LucideIcons.chrome : LucideIcons.apple, color: StanomerColors.brandPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isGoogleUser ? loc.continueWithGoogle : loc.continueWithApple,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(context),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: (isVerifying || !canDelete) ? null : () async {
                  setDialogState(() => isVerifying = true);
                  repo.isDeletingAccount = true; // Block redirects during this sensitive flow
                  try {
                    if (isEmailUser) {
                      // 1. Re-authenticate with password
                      await repo.reauthenticate(passwordController.text);
                    } else {
                      // 1. Re-authenticate via OAuth (this will refresh session)
                      if (isGoogleUser) {
                        await repo.signInWithGoogle();
                      } else {
                        await repo.signInWithApple();
                      }
                    }

                    // 2. Immediately delete account before router can redirect
                    await repo.deleteAccount();
                    
                    // Note: We don't reset isDeletingAccount here because we want the 
                    // final sign-out redirect to /login to happen naturally once the session is gone.
                    // But we actually should reset it so the "final" sign out can redirect.
                    repo.isDeletingAccount = false;

                    if (context.mounted) {
                      Navigator.of(context).pop(); // close dialog
                      context.go('/login'); // Redirect to welcome/login screen
                    }
                  } on AuthException catch (e) {
                    repo.isDeletingAccount = false;
                    setDialogState(() => isVerifying = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.message),
                        backgroundColor: StanomerColors.alertPrimary,
                      ));
                    }
                  } catch (e) {
                    repo.isDeletingAccount = false;
                    setDialogState(() => isVerifying = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: StanomerColors.alertPrimary,
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.alertPrimary,
                  foregroundColor: Colors.white,
                ),
                child: isVerifying 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(loc.deleteButtonLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final isEmailUser = user?.appMetadata['provider'] == 'email';
    final role = user?.userMetadata?['role'] ?? '';
    final roleText = role == 'landlord' ? loc.roleLandlord : (role == 'tenant' ? loc.roleTenant : role);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StanomerColors.brandPrimarySurface,
                borderRadius: const BorderRadius.all(StanomerRadius.lg),
                border: Border.all(color: StanomerColors.brandPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: StanomerColors.brandPrimary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.role, style: Theme.of(context).textTheme.labelLarge),
                      Text(roleText, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: StanomerColors.brandPrimary)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name update
            Text(loc.updateName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.fullName,
                prefixIcon: const Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: Text(loc.saveChanges),
            ),

            // Password update
            if (isEmailUser) ...[
              const SizedBox(height: 48),
              Text(loc.updatePassword, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.oldPassword,
                  prefixIcon: const Icon(LucideIcons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.newPassword,
                  prefixIcon: const Icon(LucideIcons.key),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _updatePassword,
                child: Text(loc.updatePassword),
              ),
            ],

            const SizedBox(height: 48),
            
            // Language selection
            Text(loc.appLanguage, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: StanomerColors.borderDefault),
                borderRadius: const BorderRadius.all(StanomerRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: ref.watch(localeProvider),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.globe, size: 20),
                    items: [
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text('🇬🇧 ${loc.english}'),
                      ),
                      DropdownMenuItem(
                        value: const Locale('sr'),
                        child: Text('🇷🇸 ${loc.serbianLatin}'),
                      ),
                      DropdownMenuItem(
                        value: const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
                        child: Text('🇷🇸 ${loc.serbianCyrillic}'),
                      ),
                      DropdownMenuItem(
                        value: const Locale('tr'),
                        child: Text('🇹🇷 ${loc.turkish}'),
                      ),
                    ],
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        ref.read(localeProvider.notifier).setLocale(newLocale);
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),

            // Logout
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
              },
              icon: const Icon(LucideIcons.logOut),
              label: Text(loc.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: StanomerColors.alertPrimary,
                side: const BorderSide(color: StanomerColors.alertPrimary),
              ),
            ),

            const SizedBox(height: 16),

            // Delete Account
            TextButton.icon(
              onPressed: _showDeleteConfirmDialog,
              icon: const Icon(LucideIcons.userX, size: 20),
              label: Text(loc.deleteAccount),
              style: TextButton.styleFrom(
                foregroundColor: StanomerColors.alertPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
