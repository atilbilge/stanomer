import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/data/auth_providers.dart';
import '../../domain/agency_color_scheme.dart';

class AgencyDemoSandboxBanner extends ConsumerStatefulWidget {
  final String agencyId;
  final String companyName;
  final String? websiteUrl;
  final bool isDemo;
  final bool hasProperties;
  final bool isSpotlight;
  final VoidCallback? onThemeApplied;
  final VoidCallback onRefreshNeeded;

  const AgencyDemoSandboxBanner({
    super.key,
    required this.agencyId,
    required this.companyName,
    this.websiteUrl,
    required this.isDemo,
    required this.hasProperties,
    this.isSpotlight = false,
    this.onThemeApplied,
    required this.onRefreshNeeded,
  });

  @override
  ConsumerState<AgencyDemoSandboxBanner> createState() =>
      _AgencyDemoSandboxBannerState();
}

class _AgencyDemoSandboxBannerState
    extends ConsumerState<AgencyDemoSandboxBanner> {
  bool _isLoadingPortfolio = false;
  bool _isLoadingTheme = false;

  bool get _isSR => ref.read(localeProvider).languageCode == 'sr';
  bool get _isCyrl => ref.read(localeProvider).scriptCode == 'Cyrl';
  bool get _isEN => ref.read(localeProvider).languageCode == 'en';
  bool get _isRU => ref.read(localeProvider).languageCode == 'ru';

  Future<void> _generateSamplePortfolio() async {
    setState(() => _isLoadingPortfolio = true);
    final isSR = _isSR;
    final isCyrl = _isCyrl;
    final isEN = _isEN;
    final isRU = _isRU;

    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc(
        'generate_agency_demo_data',
        params: {'p_agency_id': widget.agencyId},
      );

      if (mounted) {
        final successMsg = isSR
            ? (isCyrl
                ? 'Пример портфолија је успешно креиран (10 некретнина, закупци, уговори и одржавање).'
                : 'Primer portfolija je uspešno kreiran (10 nekretnina, zakupci, ugovori i održavanje).')
            : isEN
            ? 'Sample portfolio successfully generated (10 properties, tenants, contracts & maintenance).'
            : isRU
            ? 'Тестовое портфолио успешно создано (10 объектов, арендаторы, договоры и заявки).'
            : 'Örnek portföy başarıyla üretildi (10 ev, kiracılar, sözleşmeler ve bakımlar).';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    successMsg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        widget.onRefreshNeeded();
      }
    } catch (e) {
      if (mounted) {
        final errorPrefix = isSR
            ? (isCyrl ? 'Грешка приликом креирања портфолија: ' : 'Greška prilikom kreiranja portfolija: ')
            : isEN
            ? 'Error while generating portfolio: '
            : isRU
            ? 'Ошибка при создании портфолио: '
            : 'Portföy üretilirken hata oluştu: ';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$errorPrefix$e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPortfolio = false);
      }
    }
  }

  Future<void> _clearPortfolio() async {
    final isSR = _isSR;
    final isCyrl = _isCyrl;
    final isEN = _isEN;
    final isRU = _isRU;

    final dialogTitle = isSR
        ? (isCyrl ? 'Ресетуј Портфолио' : 'Resetuj Portfolio')
        : isEN
        ? 'Reset Portfolio'
        : isRU
        ? 'Сбросить портфолио'
        : 'Portföyü Sıfırla';

    final dialogContent = isSR
        ? (isCyrl
            ? 'Све демо некретнине и уговори биће обрисани. У сваком тренутку можете поново генерисати пример портфолија. Да ли желите да наставите?'
            : 'Sve demo nekretnine i ugovori biće obrisani. U svakom trenutku možete ponovo generisati primer portfolija. Da li želite da nastavite?')
        : isEN
        ? 'All demo properties and contracts will be cleared. You can regenerate the sample portfolio at any time. Do you want to proceed?'
        : isRU
        ? 'Все демо-объекты и договоры будут удалены. Вы можете заново создать тестовое портфолио в любой момент. Продолжить?'
        : 'Tüm demo mülkler ve sözleşmeler silinecektir. İstediğiniz an yeniden örnek portföy oluşturabilirsiniz. Devam edilsin mi?';

    final cancelText = isSR
        ? (isCyrl ? 'Одустани' : 'Odustani')
        : isEN
        ? 'Cancel'
        : isRU
        ? 'Отмена'
        : 'Vazgeç';

    final confirmText = isSR
        ? (isCyrl ? 'Ресетуј' : 'Resetuj')
        : isEN
        ? 'Reset'
        : isRU
        ? 'Сбросить'
        : 'Sıfırla';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPortfolio = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc(
        'clear_agency_demo_data',
        params: {'p_agency_id': widget.agencyId},
      );

      if (mounted) {
        final clearedMsg = isSR
            ? (isCyrl ? 'Демо подаци портфолија су очишћени.' : 'Demo podaci portfolija su očišćeni.')
            : isEN
            ? 'Demo portfolio data has been cleared.'
            : isRU
            ? 'Данные демо-портфолио очищены.'
            : 'Demo portföy verileri temizlendi.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(clearedMsg),
          ),
        );
        widget.onRefreshNeeded();
      }
    } catch (e) {
      if (mounted) {
        final resetErrorPrefix = isSR
            ? (isCyrl ? 'Грешка приликом ресетовања: ' : 'Greška prilikom resetovanja: ')
            : isEN
            ? 'Reset error: '
            : isRU
            ? 'Ошибка сброса: '
            : 'Sıfırlama hatası: ';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$resetErrorPrefix$e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPortfolio = false);
      }
    }
  }

  Future<void> _fetchThemeAndLogo() async {
    String? domain = widget.websiteUrl;
    final isSR = _isSR;
    final isCyrl = _isCyrl;
    final isEN = _isEN;
    final isRU = _isRU;

    if (domain == null || domain.trim().isEmpty) {
      final controller = TextEditingController();

      final inputTitle = isSR
          ? (isCyrl ? 'Унесите Ваш Веб-Сајт' : 'Unesite Vaš Veb-Sajt')
          : isEN
          ? 'Enter Your Website'
          : isRU
          ? 'Введите ваш веб-сайт'
          : 'Web Sitenizi Girin';

      final inputDesc = isSR
          ? (isCyrl
              ? 'Унесите адресу вашег веб-сајта како бисмо аутоматски преузели лого и боје вашег бренда:'
              : 'Unesite adresu vašeg veb-sajta kako bismo automatski preuzeli logo i boje vašeg brenda:')
          : isEN
          ? 'Enter your agency website URL to automatically extract your logo and brand colors:'
          : isRU
          ? 'Введите адрес вашего сайта для автоматической загрузки логотипа и фирменных цветов:'
          : 'Logonuzu ve marka renklerinizi otomatik çekmek için web site adresinizi girin:';

      final cancelBtn = isSR
          ? (isCyrl ? 'Откажи' : 'Otkaži')
          : isEN
          ? 'Cancel'
          : isRU
          ? 'Отмена'
          : 'İptal';

      final applyBtn = isSR
          ? (isCyrl ? 'Примени Тему' : 'Primeni Temu')
          : isEN
          ? 'Apply Theme'
          : isRU
          ? 'Применить тему'
          : 'Temayı Uygula';

      final entered = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(inputTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inputDesc,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'kulanekretnine.rs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.globe),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(cancelBtn),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(applyBtn),
            ),
          ],
        ),
      );

      if (entered == null || entered.isEmpty) return;
      domain = entered;
    }

    setState(() => _isLoadingTheme = true);

    try {
      final cleanDomain = domain
          .replaceAll(RegExp(r'^https?:\/\/'), '')
          .replaceAll(RegExp(r'\/.*$'), '')
          .trim();

      // Default fallback (Google favicon proxied via weserv to guarantee CORS)
      String logoUrl =
          'https://images.weserv.nl/?url=www.google.com/s2/favicons?domain=$cleanDomain%26sz=128';

      // Smart harmonious palette for real estate agencies
      Map<String, dynamic> colorScheme = {
        'primary': '#1E3A8A', // Classic Deep Blue
        'accent': '#D97706', // Warm Amber Gold
        'brand_gold': '#F59E0B',
        'bg_white': '#FFFFFF',
        'text_primary': '#0F172A',
        'border': '#E2E8F0',
      };

      // Try calling our scraper API to fetch real logo and theme colors
      try {
        final endpoint = kIsWeb
            ? '/api/scrape-agency-theme'
            : 'https://stanomer.com/api/scrape-agency-theme';
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'url': domain,
            'agency_id': widget.agencyId,
          }),
        );
        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['success'] == true) {
            if (resData['logo_url'] != null) {
              logoUrl = resData['logo_url'] as String;
            }
            if (resData['color_scheme'] != null) {
              colorScheme = Map<String, dynamic>.from(resData['color_scheme']);
            }
          }
        }
      } catch (scrapeErr) {
        debugPrint('Agency theme scraper note: $scrapeErr');
      }

      final supabase = Supabase.instance.client;
      await supabase.from('profiles').update({
        'logo_url': logoUrl,
        'website_url': 'https://$cleanDomain',
        'color_scheme': colorScheme,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.agencyId);

      if (mounted) {
        ref.invalidate(profileFutureProvider);
        ref.invalidate(agencyColorSchemeProvider);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('theme_applied_${widget.agencyId}', true);
        } catch (_) {}
        if (!mounted) return;
        widget.onThemeApplied?.call();

        final themeAppliedMsg = isSR
            ? (isCyrl
                ? 'Лого и боје бренда су примењени за $cleanDomain!'
                : 'Logo i boje brenda su primenjeni za $cleanDomain!')
            : isEN
            ? 'Logo and brand theme applied for $cleanDomain!'
            : isRU
            ? 'Логотип и фирменная тема применены для $cleanDomain!'
            : '$cleanDomain için logo ve kurumsal tema uygulandı!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(LucideIcons.palette, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    themeAppliedMsg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        widget.onRefreshNeeded();
      }
    } catch (e) {
      if (mounted) {
        final themeErrorPrefix = isSR
            ? (isCyrl ? 'Грешка приликом преузимања теме: ' : 'Greška prilikom preuzimanja teme: ')
            : isEN
            ? 'Theme error: '
            : isRU
            ? 'Ошибка загрузки темы: '
            : 'Tema çekilirken hata oluştu: ';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$themeErrorPrefix$e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTheme = false);
      }
    }
  }

  Future<void> _onRequestDemo() async {
    final isSR = _isSR;
    final isCyrl = _isCyrl;
    final isEN = _isEN;
    final isRU = _isRU;

    final dialogTitle = isSR
        ? (isCyrl ? 'Закажите Званичну Презентацију' : 'Zakažite Zvaničnu Prezentaciju')
        : isEN
        ? 'Request Official Agency Demo'
        : isRU
        ? 'Запросить официальную презентацию'
        : 'Acenteniz İçin Canlı Tanıtım & Demo';

    final dialogDesc = isSR
        ? (isCyrl
            ? 'Желите комплетно white-label подешавање са вашим доменом и пренос целокупног портфолија? Наш тим ће вам припремити персонализовану презентацију.'
            : 'Želite kompletno white-label podešavanje sa vašim domenom i prenos celokupnog portfolija? Naš tim će vam pripremiti personalizovanu prezentaciju.')
        : isEN
        ? 'Want a complete white-label rollout with your custom domain and full portfolio import? Our team will provide a personalized live walkthrough.'
        : isRU
        ? 'Хотите полноценный white-label запуск на вашем домене и перенос всех объектов? Наша команда проведет для вас персональную презентацию.'
        : 'Kendi alan adınızla eksiksiz white-label kurulumu ve tüm portföyünüzün sisteme aktarımı mı istiyorsunuz? Ekibimiz size özel canlı tanıtım hazırlayacaktır.';

    final openWebBtn = isSR
        ? (isCyrl ? 'Отвори Образац за Демо' : 'Otvori Obrazac za Demo')
        : isEN
        ? 'Open Demo Request Form'
        : isRU
        ? 'Открыть форму заявки'
        : 'Demo Talep Formunu Aç';

    final closeBtn = isSR
        ? (isCyrl ? 'Затвори' : 'Zatvori')
        : isEN
        ? 'Close'
        : isRU
        ? 'Закрыть'
        : 'Kapat';

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.sparkles, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dialogTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogDesc,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSR
                          ? (isCyrl ? 'Директан контакт са тимом • 1-на-1 презентација' : 'Direktan kontakt sa timom • 1-na-1 prezentacija')
                          : isEN
                          ? 'Direct contact with team • 1-on-1 walkthrough'
                          : isRU
                          ? 'Прямой контакт с командой • 1-на-1 презентация'
                          : 'Ekibimizle doğrudan iletişim • 1e1 canlı tanıtım',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(closeBtn),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(LucideIcons.externalLink, size: 14),
            label: Text(openWebBtn),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      final uri = Uri.parse(kIsWeb ? '/agency-demo' : 'https://stanomer.online/agency-demo');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        debugPrint('Launch agency-demo error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDemo) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final isSR = locale.languageCode == 'sr';
    final isCyrl = locale.scriptCode == 'Cyrl';
    final isEN = locale.languageCode == 'en';
    final isRU = locale.languageCode == 'ru';

    final badgeText = isSR
        ? (isCyrl ? 'SANDBOX' : 'SANDBOX')
        : isEN
        ? 'SANDBOX'
        : isRU
        ? 'SANDBOX'
        : 'SANDBOX';

    final subLabel = widget.hasProperties
        ? (isSR
            ? (isCyrl ? '3-дневно тест окружење' : '3-dnevno test okruženje')
            : isEN
            ? '3-day test sandbox'
            : isRU
            ? '3-дневная песочница'
            : '3 günlük test ortamı')
        : (isSR
            ? (isCyrl ? 'Очекује се портфолио' : 'Očekuje se portfolio')
            : isEN
            ? 'Portfolio awaiting'
            : isRU
            ? 'Ожидание портфолио'
            : 'Portföy bekleniyor');

    final themeLabel = _isLoadingTheme
        ? (isSR ? (isCyrl ? 'Преузимање...' : 'Preuzimanje...') : isEN ? 'Fetching...' : isRU ? 'Загрузка...' : 'Alınıyor...')
        : (isSR ? (isCyrl ? 'Тема' : 'Tema') : isEN ? 'Theme' : isRU ? 'Тема' : 'Temayı Al');

    final sampleDataLabel = _isLoadingPortfolio
        ? (isSR ? (isCyrl ? 'Радим...' : 'Radim...') : isEN ? 'Processing...' : isRU ? 'Создание...' : 'İşleniyor...')
        : (isSR ? (isCyrl ? 'Тест Подаци' : 'Test Podaci') : isEN ? 'Sample Data' : isRU ? 'Тест данные' : 'Test Verisi');

    final regenerateLabel = isSR
        ? (isCyrl ? 'Поново креирај (10 некретнина)' : 'Ponovo kreiraj (10 nekretnina)')
        : isEN
        ? 'Regenerate Portfolio (10 Properties)'
        : isRU
        ? 'Сгенерировать заново (10 объектов)'
        : 'Portföyü Yeniden Üret (10 Mülk)';

    final resetLabel = isSR
        ? (isCyrl ? 'Очисти портфолио (Ресетуј)' : 'Očisti portfolio (Resetuj)')
        : isEN
        ? 'Clear Portfolio (Reset)'
        : isRU
        ? 'Очистить портфолио (Сброс)'
        : 'Portföyü Sıfırla (Temizle)';

    final goLiveLabel = isSR
        ? (isCyrl ? 'Пређите на Про' : 'Pređite na Pro')
        : isEN
        ? 'Go Live'
        : isRU
        ? 'Перейти на Pro'
        : 'Canlıya Geç';

    final stepBadge = isSR
        ? (isCyrl ? '1. КОРАК: ИДЕНТИТЕТ БРЕНДА' : '1. KORAK: IDENTITET BRENDA')
        : isEN
        ? 'STEP 1: BRAND IDENTITY'
        : isRU
        ? 'ШАГ 1: ФИРМЕННЫЙ СТИЛЬ'
        : '1. ADIM: KURUMSAL KİMLİK';

    final spotlightTitle = isSR
        ? (isCyrl ? 'Преузмите Ваш Лого и Боје Бренда' : 'Preuzmite Vaš Logo i Boje Brenda')
        : isEN
        ? 'Fetch Your Agency Logo & Brand Colors'
        : isRU
        ? 'Загрузите логотип и цвета вашего агентства'
        : 'Acente Logonuzu ve Kurumsal Renklerinizi Çekin';

    final spotlightDesc = isSR
        ? (isCyrl
            ? 'Унесите адресу вашег веб-сајта да аутоматски примените лого и боје. Панел ће се тренутно прилагодити вашем бренду.'
            : 'Unesite adresu vašeg veb-sajta da automatski primenite logo i boje. Panel će se trenutno prilagoditi vašem brendu.')
        : isEN
        ? 'Enter your agency website URL to automatically extract your logo and colors. Your cockpit will personalize instantly.'
        : isRU
        ? 'Введите адрес вашего сайта, чтобы автоматически применить логотип и цвета. Панель адаптируется под ваш бренд.'
        : 'Web site adresinizi girerek logonuzu ve kurumsal renklerinizi tek tıkla uygulayın. Kokpit kendi markanızla özelleşsin.';

    final themeCtaLabel = isSR
        ? (isCyrl ? 'Преузми Тему' : 'Preuzmi Temu')
        : isEN
        ? 'Fetch Theme'
        : isRU
        ? 'Загрузить тему'
        : 'Temayı Al';

    final skipLabel = isSR
        ? (isCyrl ? 'Прескочи за сада ✕' : 'Preskoči za sada ✕')
        : isEN
        ? 'Skip for now ✕'
        : isRU
        ? 'Пропустить пока ✕'
        : 'Şimdilik Atla ✕';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSpotlight
                  ? const Color(0xFF2563EB).withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: widget.isSpotlight ? 1.5 : 1.2,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 620;

              final leftInfo = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, color: Color(0xFF2563EB), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${widget.companyName.isNotEmpty ? widget.companyName : "Stanomer Agency"} • $subLabel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );

              final rightActions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Theme Button (Spotlight glowing highlight if isSpotlight)
                  widget.isSpotlight
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: _isLoadingTheme ? null : _fetchThemeAndLogo,
                            icon: _isLoadingTheme
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(LucideIcons.sparkles, size: 14, color: Colors.amber),
                            label: Text(
                              themeLabel,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _isLoadingTheme ? null : _fetchThemeAndLogo,
                          icon: _isLoadingTheme
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.palette, size: 14),
                          label: Text(
                            themeLabel,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                  const SizedBox(width: 4),

                  // 2. Sample Data Dropdown Menu
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'regenerate') _generateSamplePortfolio();
                      if (val == 'reset') _clearPortfolio();
                    },
                    tooltip: sampleDataLabel,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'regenerate',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.refreshCw, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Text(
                              regenerateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              resetLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoadingPortfolio
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  LucideIcons.database,
                                  size: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                          const SizedBox(width: 5),
                          Text(
                            sampleDataLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 12,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Go Live CTA
                  FilledButton.icon(
                    onPressed: _onRequestDemo,
                    icon: const Icon(LucideIcons.sparkles, size: 12, color: Colors.amber),
                    label: Text(
                      goLiveLabel,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leftInfo,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: rightActions,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: leftInfo),
                  rightActions,
                ],
              );
            },
          ),
        ),

        // Spotlight Onboarding Card (Only shown when isSpotlight == true)
        if (widget.isSpotlight)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final isSmall = c.maxWidth < 640;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, color: Color(0xFF2563EB), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            stepBadge,
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      spotlightTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spotlightDesc,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                );

                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: _isLoadingTheme ? null : _fetchThemeAndLogo,
                      icon: _isLoadingTheme
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.palette, size: 16),
                      label: Text(
                        themeCtaLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('theme_applied_${widget.agencyId}', true);
                        } catch (_) {}
                        widget.onThemeApplied?.call();
                      },
                      child: Text(
                        skipLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );

                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 14),
                      actions,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}


