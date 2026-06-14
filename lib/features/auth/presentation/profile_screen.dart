import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../subscriptions/data/subscription_service.dart';
import '../../subscriptions/presentation/premium_mobile_only_sheet.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/services/document_storage_service.dart';

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
                        isGoogleUser
                            ? Image.asset(
                                'assets/images/google_logo.png',
                                width: 20,
                                height: 20,
                              )
                            : const Icon(
                                LucideIcons.apple,
                                color: StanomerColors.brandPrimary,
                                size: 20,
                              ),
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
    final role = user?.userMetadata?['role'] as String?;
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: StanomerColors.bgPage,
      appBar: AppBar(
        title: Text(loc.profile, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: StanomerColors.bgCard,
        elevation: 0,
        foregroundColor: StanomerColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UserInfoCard(user: user, role: role, loc: loc),
            const SizedBox(height: 16),
            _PremiumBanner(
              isPremium: isPremium,
              onTap: () {
                if (isPurchaseSupported) {
                  ref.read(subscriptionServiceProvider).presentPaywall();
                } else {
                  showPremiumMobileOnlySheet(context);
                }
              },
              loc: loc,
            ),
            const SizedBox(height: 32),
            
            _SectionHeader(title: loc.updateName.toUpperCase()),
            const SizedBox(height: 12),
            _NameUpdateCard(
              controller: _nameController,
              isLoading: _isLoading,
              onSave: _updateProfile,
              loc: loc,
            ),
            
            const SizedBox(height: 32),
            _SectionHeader(title: loc.settingsHeader.toUpperCase()), // Using custom key or loc
            const SizedBox(height: 12),
            _SettingsGroup(
              onLanguageTap: _showLanguageSwitcher,
              onSupportTap: () => context.push('/support'),
              onTermsTap: () => context.push('/terms'),
              currentLocale: ref.watch(localeProvider),
              loc: loc,
            ),
            
            const SizedBox(height: 32),
            _SectionHeader(title: loc.accountHeader.toUpperCase()), // Using custom key or loc
            const SizedBox(height: 12),
            _AccountGroup(
              onLogoutTap: () => ref.read(authRepositoryProvider).signOut(),
              onDeleteTap: _showDeleteConfirmDialog,
              loc: loc,
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Stanomer v1.1.0',
                style: TextStyle(
                  color: StanomerColors.textTertiary.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLanguageSwitcher() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: StanomerRadius.xl)),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(loc.appLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
              title: Text(loc.english),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇷🇸', style: TextStyle(fontSize: 20)),
              title: Text(loc.serbianLatin),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇷🇸', style: TextStyle(fontSize: 20)),
              title: Text(loc.serbianCyrillic),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 20)),
              title: Text(loc.turkish),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('tr'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 20)),
              title: Text(loc.russian),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('ru'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final User? user;
  final String? role;
  final AppLocalizations loc;

  const _UserInfoCard({required this.user, required this.role, required this.loc});

  @override
  Widget build(BuildContext context) {
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'User';
    final initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    final roleColor = StanomerColors.getRoleColor(role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StanomerShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: roleColor.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: StanomerColors.textTertiary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (role == 'landlord' ? loc.roleLandlord : loc.roleTenant).toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _PremiumBanner({required this.isPremium, required this.onTap, required this.loc});

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StanomerColors.brandPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: StanomerColors.brandPrimary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.crown, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.discoverPremium,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    loc.unlimitedLeaseContracts,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: StanomerColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NameUpdateCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSave;
  final AppLocalizations loc;

  const _NameUpdateCard({
    required this.controller,
    required this.isLoading,
    required this.onSave,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StanomerShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: loc.fullName.toUpperCase(),
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                prefixIcon: const Icon(LucideIcons.user, size: 20),
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StanomerColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(loc.saveChanges, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends ConsumerWidget {
  final VoidCallback onLanguageTap;
  final VoidCallback onSupportTap;
  final VoidCallback onTermsTap;
  final Locale currentLocale;
  final AppLocalizations loc;

  const _SettingsGroup({
    required this.onLanguageTap,
    required this.onSupportTap,
    required this.onTermsTap,
    required this.currentLocale,
    required this.loc,
  });

  String _getCloudTitle(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    switch (code) {
      case 'tr': return 'BULUT YÜKLEMELERİ';
      case 'sr': return 'OTPREMANJE U OBLAK';
      case 'ru': return 'ОБЛАЧНАЯ ЗАГРУЗКА';
      default: return 'CLOUD UPLOADS';
    }
  }

  String _getCloudSubtitle(BuildContext context, bool isCloudAllowed) {
    final code = Localizations.localeOf(context).languageCode;
    if (isCloudAllowed) {
      switch (code) {
        case 'tr': return 'Belgeler (sözleşmeler, faturalar) bulutta yedeklenir.';
        case 'sr': return 'Dokumenti (ugovori, fature) se čuvaju u oblaku.';
        case 'ru': return 'Документы сохраняются в облаке.';
        default: return 'Documents (contracts, invoices) are backed up to the cloud.';
      }
    } else {
      switch (code) {
        case 'tr': return 'Gizlilik Modu: Belgeler sadece bu cihazda saklanır.';
        case 'sr': return 'Režim privatnosti: Dokumenti se čuvaju samo na uređaju.';
        case 'ru': return 'Приватность: Документы сохраняются на устройстве.';
        default: return 'Privacy Mode: Documents are stored offline on this device.';
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCloudAllowed = ref.watch(cloudUploadAllowedProvider);

    String getLanguageName() {
      if (currentLocale.languageCode == 'tr') return loc.turkish;
      if (currentLocale.languageCode == 'en') return loc.english;
      if (currentLocale.languageCode == 'sr') {
        return currentLocale.scriptCode == 'Cyrl' ? loc.serbianCyrillic : loc.serbianLatin;
      }
      return currentLocale.languageCode;
    }

    String getFlag() {
      if (currentLocale.languageCode == 'tr') return '🇹🇷';
      if (currentLocale.languageCode == 'en') return '🇬🇧';
      return '🇷🇸';
    }

    return Container(
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StanomerShadows.card,
      ),
      child: Column(
        children: [
          _ListTile(
            icon: LucideIcons.globe,
            title: loc.appLanguage.toUpperCase(),
            subtitle: '${getFlag()} ${getLanguageName()}',
            onTap: onLanguageTap,
            showChevron: true,
          ),
          const Divider(height: 1, indent: 56),
          _SwitchListTile(
            icon: isCloudAllowed ? LucideIcons.cloudUpload : LucideIcons.shieldAlert,
            title: _getCloudTitle(context),
            subtitle: _getCloudSubtitle(context, isCloudAllowed),
            value: isCloudAllowed,
            onChanged: (val) {
              ref.read(cloudUploadAllowedProvider.notifier).toggle(val);
            },
          ),
          const Divider(height: 1, indent: 56),
          _ListTile(
            icon: LucideIcons.helpCircle,
            title: loc.support_title,
            onTap: onSupportTap,
            showChevron: true,
          ),
          const Divider(height: 1, indent: 56),
          _ListTile(
            icon: LucideIcons.fileText,
            title: loc.termsOfService,
            onTap: onTermsTap,
            showChevron: true,
          ),
        ],
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final VoidCallback onLogoutTap;
  final VoidCallback onDeleteTap;
  final AppLocalizations loc;

  const _AccountGroup({required this.onLogoutTap, required this.onDeleteTap, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StanomerColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: StanomerShadows.card,
      ),
      child: Column(
        children: [
          _ListTile(
            icon: LucideIcons.logOut,
            title: loc.logout,
            titleColor: StanomerColors.alertPrimary,
            onTap: onLogoutTap,
          ),
          const Divider(height: 1, indent: 56),
          _ListTile(
            icon: LucideIcons.userX,
            title: loc.deleteAccount,
            subtitle: loc.deleteAccountWarning.split('.')[0], // Short version
            titleColor: StanomerColors.alertPrimary,
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool showChevron;

  const _ListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: titleColor ?? StanomerColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: StanomerColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  Text(
                    subtitle ?? title,
                    style: TextStyle(
                      fontWeight: subtitle != null ? FontWeight.w900 : FontWeight.bold,
                      fontSize: subtitle != null ? 15 : 15,
                      color: titleColor ?? StanomerColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(LucideIcons.chevronRight, size: 18, color: StanomerColors.borderInput),
          ],
        ),
      ),
    );
  }
}

class _SwitchListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: StanomerColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: StanomerColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: StanomerColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: StanomerColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}
