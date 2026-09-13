import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/colors.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';

class AgencyDemoLoginScreen extends ConsumerStatefulWidget {
  final String token;
  final String? lang;

  const AgencyDemoLoginScreen({
    super.key,
    required this.token,
    this.lang,
  });

  @override
  ConsumerState<AgencyDemoLoginScreen> createState() => _AgencyDemoLoginScreenState();
}

class _AgencyDemoLoginScreenState extends ConsumerState<AgencyDemoLoginScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _agencyName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyLanguage();
      _processMagicLink();
    });
  }

  void _applyLanguage() {
    final langStr = widget.lang ?? (kIsWeb ? Uri.base.queryParameters['lang'] ?? Uri.base.queryParameters['locale'] : null);
    if (langStr != null && langStr.isNotEmpty) {
      final parsed = LocaleNotifier.parseLocale(langStr);
      if (parsed != null) {
        ref.read(localeProvider.notifier).setLocale(parsed);
      }
    }
  }

  Future<void> _processMagicLink() async {
    final token = widget.token.trim();
    final locale = ref.read(localeProvider);
    final isSR = locale.languageCode == 'sr';
    final isEN = locale.languageCode == 'en';
    final isRU = locale.languageCode == 'ru';

    if (token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = isSR
              ? 'Nevažeći ili nepotpun link za demo nalog.'
              : isEN
              ? 'Invalid or missing demo access link.'
              : isRU
              ? 'Недействительная или отсутствующая ссылка на демо-версию.'
              : 'Geçersiz veya eksik demo bağlantısı.';
        });
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // 1. Verify demo token and provision/retrieve demo credentials via RPC
      final dynamic rpcResponse = await supabase.rpc(
        'verify_agency_demo_token',
        params: {'p_token': token},
      );

      final Map<String, dynamic> data = (rpcResponse is Map<String, dynamic>)
          ? rpcResponse
          : Map<String, dynamic>.from(rpcResponse as Map);

      if (data['success'] == true) {
        final email = data['email'] as String?;
        final tempPassword = (data['temp_password'] as String?) ?? 'Stanomer2026!';
        _agencyName = data['agency_name'] as String?;

        if (email == null || email.isEmpty) {
          throw Exception(
            isSR
                ? 'Korisnički nalog nije pronađen.'
                : isEN
                ? 'User account not found.'
                : isRU
                ? 'Учетная запись пользователя не найдена.'
                : 'Kullanıcı hesabı bulunamadı.',
          );
        }

        // 2. Direct automatic authentication with Dev Supabase
        await ref.read(authRepositoryProvider).signIn(email, tempPassword);

        // 3. Refresh user role so GoRouter redirects immediately to agency dashboard
        ref.invalidate(profileFutureProvider);
        ref.invalidate(authStateProvider);

        if (mounted) {
          context.go('/agency-dashboard');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] as String? ??
                (isSR
                    ? 'Link je istekao ili je nevažeći.'
                    : isEN
                    ? 'Access link has expired or is invalid.'
                    : isRU
                    ? 'Срок действия ссылки истек или она недействительна.'
                    : 'Bağlantı süresi dolmuş veya geçersiz.');
          });
        }
      }
    } catch (e) {
      debugPrint('[AgencyDemoLoginScreen Error] $e');
      if (mounted) {
        final locale = ref.read(localeProvider);
        final isSR = locale.languageCode == 'sr';
        final isEN = locale.languageCode == 'en';
        final isRU = locale.languageCode == 'ru';

        setState(() {
          _isLoading = false;
          _errorMessage = isSR
              ? 'Došlo je do greške prilikom prijave ($e). Pokušajte ponovo.'
              : isEN
              ? 'An error occurred during sign in ($e). Please try again.'
              : isRU
              ? 'Произошла ошибка при входе ($e). Пожалуйста, повторите попытку.'
              : 'Giriş yapılırken bir sorun oluştu ($e). Lütfen tekrar deneyiniz.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: _isLoading ? _buildLoadingState(isDark) : _buildErrorState(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final locale = ref.watch(localeProvider);
    final isSR = locale.languageCode == 'sr';
    final isEN = locale.languageCode == 'en';
    final isRU = locale.languageCode == 'ru';

    final title = _agencyName != null && _agencyName!.isNotEmpty
        ? (isSR
            ? 'Otvaranje kokpita za $_agencyName...'
            : isEN
            ? 'Opening $_agencyName Cockpit...'
            : isRU
            ? 'Открытие панели $_agencyName...'
            : '$_agencyName Kokpiti Açılıyor...')
        : (isSR
            ? 'Priprema agencijskog panela...'
            : isEN
            ? 'Preparing Agency Panel...'
            : isRU
            ? 'Подготовка панели агентства...'
            : 'Acente Paneli Hazırlanıyor...');

    final subtitle = isSR
        ? 'Prijava jednim klikom je u toku. Molimo sačekajte...'
        : isEN
        ? 'Secure one-click login in progress. Please wait...'
        : isRU
        ? 'Выполняется безопасный вход в один клик. Пожалуйста, подождите...'
        : 'Tek tıkla güvenli giriş yapılıyor. Lütfen bekleyiniz...';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: StanomerColors.brandPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(StanomerColors.brandPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    final locale = ref.watch(localeProvider);
    final isSR = locale.languageCode == 'sr';
    final isEN = locale.languageCode == 'en';
    final isRU = locale.languageCode == 'ru';

    final errorTitle = isSR
        ? 'Prijava Nije Uspela'
        : isEN
        ? 'Sign In Failed'
        : isRU
        ? 'Вход не удался'
        : 'Giriş Yapılamadı';

    final loginBtnText = isSR
        ? 'Ekran za prijavu'
        : isEN
        ? 'Sign In Screen'
        : isRU
        ? 'Экран входа'
        : 'Giriş Ekranı';

    final retryBtnText = isSR
        ? 'Pokušaj ponovo'
        : isEN
        ? 'Try Again'
        : isRU
        ? 'Повторить попытку'
        : 'Tekrar Dene';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 28),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          errorTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ??
              (isSR
                  ? 'Link je istekao ili su test podaci obrisani.'
                  : isEN
                  ? 'Access link has expired or test data was cleared.'
                  : isRU
                  ? 'Срок действия ссылки истек или данные были удалены.'
                  : 'Bağlantı süresi dolmuş veya test verileri silinmiş olabilir.'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(loginBtnText),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _processMagicLink();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StanomerColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    retryBtnText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
