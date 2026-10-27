import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../agency/domain/agency_color_scheme.dart';
import '../../../core/providers/locale_provider.dart';
import '../../subscriptions/data/subscription_service.dart';
import '../../subscriptions/presentation/premium_mobile_only_sheet.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/services/document_storage_service.dart';
import '../../../core/widgets/bottom_sheet_wrapper.dart';
import '../../property/data/property_repository.dart';
import '../../property/presentation/join_property_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isEmailUser(User? user) {
    if (user == null || user.email == null || user.email!.isEmpty) return false;
    final List<String> providers = [];
    if (user.appMetadata['provider'] != null) {
      providers.add(user.appMetadata['provider'].toString());
    }
    if (user.appMetadata['providers'] is List) {
      providers.addAll((user.appMetadata['providers'] as List).map((e) => e.toString()));
    }
    final bool isAppleUser = providers.contains('apple');
    final bool isGoogleUser = !isAppleUser && providers.contains('google');
    return !isAppleUser && !isGoogleUser;
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ChangePasswordSheet(),
    );
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
        leading: Navigator.canPop(context)
            ? BackButton(onPressed: () => Navigator.maybePop(context))
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
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
            
            if (role != 'agency') ...[
              const SizedBox(height: 32),
              _AgencyReferralCard(loc: loc),
            ],
            
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
              isEmailUser: _isEmailUser(user),
              onChangePasswordTap: _showChangePasswordSheet,
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
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: StanomerRadius.xl)),
      builder: (context) => ResilientBottomSheetWrapper(
        child: SafeArea(
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

class _PremiumBanner extends ConsumerWidget {
  final bool isPremium;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _PremiumBanner({required this.isPremium, required this.onTap, required this.loc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPremium) return const SizedBox.shrink();
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
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

class _NameUpdateCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.userCheck, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loc.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: loc.fullName,
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                ),
              ],
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
                  backgroundColor: primaryColor,
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
    if (kIsWeb) {
      switch (code) {
        case 'tr': return 'Web uygulamasında belgeler bulutta saklanır (iOS ve Android uygulamalarında bu ayar kullanılabilir).';
        case 'sr': return 'Na vebu se dokumenti čuvaju u oblaku (ova opcija je dostupna u iOS i Android aplikacijama).';
        case 'ru': return 'В веб-приложении документы сохраняются в облаке (эта настройка доступна в приложениях для iOS и Android).';
        default: return 'Web app requires cloud storage (this setting is configurable in iOS and Android apps).';
      }
    }
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

    final role = ref.watch(userRoleProvider);
    final isAgency = role == 'agency';

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
          if (!isAgency) ...[
            const Divider(height: 1, indent: 56),
            _SwitchListTile(
              icon: isCloudAllowed ? LucideIcons.cloudUpload : LucideIcons.shieldAlert,
              title: _getCloudTitle(context),
              subtitle: _getCloudSubtitle(context, isCloudAllowed),
              value: isCloudAllowed,
              onChanged: kIsWeb ? null : (val) {
                ref.read(cloudUploadAllowedProvider.notifier).toggle(val);
              },
            ),
          ],
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
  final bool isEmailUser;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onLogoutTap;
  final VoidCallback onDeleteTap;
  final AppLocalizations loc;

  const _AccountGroup({
    required this.isEmailUser,
    required this.onChangePasswordTap,
    required this.onLogoutTap,
    required this.onDeleteTap,
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
          if (isEmailUser) ...[
            _ListTile(
              icon: LucideIcons.keyRound,
              title: loc.updatePassword,
              showChevron: true,
              onTap: onChangePasswordTap,
            ),
            const Divider(height: 1, indent: 56),
          ],
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

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getConfirmPasswordLabel(String lang) {
    if (lang == 'tr') return 'Yeni Şifre Tekrarı';
    if (lang == 'sr') return 'Potvrdite novu lozinku';
    if (lang == 'ru') return 'Повторите новый пароль';
    return 'Confirm New Password';
  }

  String _getMismatchError(String lang) {
    if (lang == 'tr') return 'Yeni şifreler eşleşmiyor';
    if (lang == 'sr') return 'Nove lozinke se ne podudaraju';
    if (lang == 'ru') return 'Новые пароли не совпадают';
    return 'Passwords do not match';
  }

  String _getWrongOldPasswordError(String lang) {
    if (lang == 'tr') return 'Mevcut şifreniz hatalı';
    if (lang == 'sr') return 'Trenutna lozinka nije ispravna';
    if (lang == 'ru') return 'Текущий пароль неверен';
    return 'Current password is incorrect';
  }

  String _getSamePasswordError(String lang) {
    if (lang == 'tr') return 'Yeni şifre mevcut şifre ile aynı olamaz';
    if (lang == 'sr') return 'Nova lozinka ne može biti ista kao trenutna';
    if (lang == 'ru') return 'Новый пароль не должен совпадать с текущим';
    return 'New password cannot be the same as current password';
  }

  String _getSubtitle(String lang) {
    if (lang == 'tr') return 'Hesap güvenliğiniz için yeni bir şifre belirleyin.';
    if (lang == 'sr') return 'Postavite novu sigurnu lozinku za svoj nalog.';
    if (lang == 'ru') return 'Установите новый надежный пароль для вашей учетной записи.';
    return 'Set a new secure password for your account.';
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context)!;
    final lang = ref.read(localeProvider).languageCode;
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = loc.fieldRequired);
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = loc.passwordTooShort);
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = _getMismatchError(lang));
      return;
    }
    if (oldPass == newPass) {
      setState(() => _errorMessage = _getSamePasswordError(lang));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      // 1. Re-authenticate to verify old password
      await repo.reauthenticate(oldPass);

      // 2. Update to new password
      await repo.updatePassword(newPass);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.passwordChangedSuccess),
        backgroundColor: StanomerColors.successPrimary,
      ));
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credential')) {
        setState(() => _errorMessage = _getWrongOldPasswordError(lang));
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = ref.watch(localeProvider).languageCode;
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          decoration: const BoxDecoration(
            color: StanomerColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: bottomInset + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StanomerColors.borderDefault,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.keyRound,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.updatePassword,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: StanomerColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSubtitle(lang),
                              style: const TextStyle(
                                fontSize: 12,
                                color: StanomerColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: StanomerColors.textTertiary, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StanomerColors.alertPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: StanomerColors.alertPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: StanomerColors.alertPrimary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: StanomerColors.alertPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current Password
                  TextField(
                    controller: _oldPasswordController,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      labelText: loc.oldPassword,
                      prefixIcon: const Icon(LucideIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld ? LucideIcons.eyeOff : LucideIcons.eye),
                        onPressed: () => setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // New Password
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: loc.newPassword,
                      prefixIcon: const Icon(LucideIcons.lockKeyhole),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? LucideIcons.eyeOff : LucideIcons.eye),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm New Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: _getConfirmPasswordLabel(lang),
                      prefixIcon: const Icon(LucideIcons.shieldCheck),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              loc.updatePassword,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        loc.cancel,
                        style: const TextStyle(color: StanomerColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _SwitchListTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;
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
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}

class _AgencyReferralCard extends ConsumerWidget {
  final AppLocalizations loc;

  const _AgencyReferralCard({required this.loc});

  Future<void> _openWebsite(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final uri = Uri.parse(formattedUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching URL $formattedUrl: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyInfoAsync = ref.watch(agencyReferralFutureProvider);
    final propertiesAsync = ref.watch(propertiesFutureProvider);
    final primaryColor = ref.watch(agencyColorSchemeProvider).primary;

    // Check if user has any property managed by an agency
    final properties = propertiesAsync.value ?? [];
    final hasAgencyManagedProperty = properties.any((p) => p.agencyId != null && p.agencyId!.isNotEmpty);

    if (hasAgencyManagedProperty) {
      return const SizedBox.shrink();
    }

    return agencyInfoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (agencyInfo) {
        // If user belongs to an agency-managed property, hide referral section completely
        if (agencyInfo != null && agencyInfo['is_managed'] == true) {
          return const SizedBox.shrink();
        }

        final hasExplicitReferral = agencyInfo != null &&
            agencyInfo['agency_name'] != null &&
            agencyInfo['is_managed'] != true;

        if (hasExplicitReferral) {
          final agencyName = agencyInfo['agency_name'].toString();
          final code = agencyInfo['referral_code']?.toString() ?? '';
          final website = agencyInfo['website']?.toString();
          final hasWebsite = website != null && website.trim().isNotEmpty;

          final cardContent = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StanomerColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(LucideIcons.building2, size: 20, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.referringAgency.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  agencyName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hasWebsite ? primaryColor : StanomerColors.textPrimary,
                                    decoration: hasWebsite ? TextDecoration.underline : TextDecoration.none,
                                    decorationColor: primaryColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              if (hasWebsite) ...[
                                const SizedBox(width: 6),
                                Icon(LucideIcons.externalLink, size: 14, color: primaryColor),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: StanomerColors.successPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.shieldCheck, size: 12, color: StanomerColors.successPrimary),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: StanomerColors.successPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (code.isNotEmpty && code != 'Acente Yönetiminde Mülk') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: StanomerColors.bgPage,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.qrCode, size: 14, color: StanomerColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${loc.referralCodeLabel}: $code',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: StanomerColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );

          if (hasWebsite) {
            return InkWell(
              onTap: () => _openWebsite(website),
              borderRadius: BorderRadius.circular(16),
              child: cardContent,
            );
          }

          return cardContent;
        }

        // User has NO agency referral -> Show shortcut button to scan agency QR code
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StanomerColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StanomerColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StanomerColors.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.building2, size: 20, color: StanomerColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.referringAgency.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: StanomerColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.noReferringAgency,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: StanomerColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                loc.noReferringAgencyDesc,
                style: const TextStyle(
                  fontSize: 12,
                  color: StanomerColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => JoinPropertySheet.show(context),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: Text(loc.scanAgencyReferralQrBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
