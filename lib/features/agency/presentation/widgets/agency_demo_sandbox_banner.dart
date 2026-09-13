import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../auth/data/auth_providers.dart';
import '../../domain/agency_color_scheme.dart';

class AgencyDemoSandboxBanner extends ConsumerStatefulWidget {
  final String agencyId;
  final String companyName;
  final String? websiteUrl;
  final bool isDemo;
  final bool hasProperties;
  final VoidCallback onRefreshNeeded;

  const AgencyDemoSandboxBanner({
    super.key,
    required this.agencyId,
    required this.companyName,
    this.websiteUrl,
    required this.isDemo,
    required this.hasProperties,
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

    final locale = ref.watch(localeProvider);
    final isSR = locale.languageCode == 'sr';
    final isCyrl = locale.scriptCode == 'Cyrl';
    final isEN = locale.languageCode == 'en';
    final isRU = locale.languageCode == 'ru';

    final badgeText = isSR
        ? (isCyrl ? 'АГЕНЦИЈСКИ SANDBOX' : 'AGENCIJSKI SANDBOX')
        : isEN
        ? 'AGENCY SANDBOX'
        : isRU
        ? 'ПЕСОЧНИЦА АГЕНТСТВА'
        : 'ACENTE SANDBOX';

    final statusTitle = widget.hasProperties
        ? (isSR
            ? (isCyrl ? '3-Дневно Тест Окружење је Активно' : '3-Dnevno Test Okruženje je Aktivno')
            : isEN
            ? '3-Day Sandbox Environment Active'
            : isRU
            ? '3-дневный тестовый период активен'
            : '3 Günlük Test Ortamı Aktif')
        : (isSR
            ? (isCyrl ? 'Очекује се пример портфолија' : 'Očekuje se primer portfolija')
            : isEN
            ? 'Awaiting Sample Portfolio'
            : isRU
            ? 'Ожидание тестового портфолио'
            : 'Örnek Portföy Bekleniyor');

    final resetBtnLabel = isSR
        ? (isCyrl ? 'Ресетуј' : 'Resetuj')
        : isEN
        ? 'Reset'
        : isRU
        ? 'Сбросить'
        : 'Sıfırla';

    final descriptionText = widget.hasProperties
        ? (isSR
            ? (isCyrl
                ? 'Испорбајте панел са вашим брендом. Можете преузети лого са вашег сајта или ресетовати портфолио и поново га креирати.'
                : 'Isprobajte panel sa vašim brendom. Možete preuzeti logo sa vašeg sajta ili resetovati portfolio i ponovo ga kreirati.')
            : isEN
            ? 'Experience your cockpit with your brand. Fetch your logo from your website or reset and regenerate sample portfolio anytime.'
            : isRU
            ? 'Опробуйте панель с вашим брендом. Вы можете загрузить логотип со своего сайта или сбросить и заново создать портфолио.'
            : 'Panelinizi kendi markanızla deneyimleyin. Web sitenizden logonuzu alabilir veya portföyü sıfırlayıp yeniden üretebilirsiniz.')
        : (isSR
            ? (isCyrl
                ? 'Још увек немате пример портфолија (или је 3-дневни период истекао). Једним кликом можете одмах креирати 10 реалистичних тест некретнина.'
                : 'Još uvek nemate primer portfolija (ili je 3-dnevni period istekao). Jednim klikom možete odmah kreirati 10 realističnih test nekretnina.')
            : isEN
            ? 'No sample portfolio yet (or 3-day trial expired). Generate 10 realistic test properties with tenants and contracts in one click.'
            : isRU
            ? 'У вас пока нет тестового портфолио (или истек 3-дневный срок). Создайте 10 реалистичных объектов в один клик.'
            : 'Henüz örnek portföyünüz bulunmuyor (veya 3 günlük deneme süresi doldu). Tek tıkla 10 evlik gerçekçi test verisini hemen üretebilirsiniz.');

    final themeBtnLabel = _isLoadingTheme
        ? (isSR ? (isCyrl ? 'Преузимање...' : 'Preuzimanje...') : isEN ? 'Fetching...' : isRU ? 'Загрузка...' : 'Alınıyor...')
        : (isSR ? (isCyrl ? 'Преузми Тему' : 'Preuzmi Temu') : isEN ? 'Fetch Brand Theme' : isRU ? 'Загрузить тему' : 'Temayı Al');

    final portfolioBtnLabel = _isLoadingPortfolio
        ? (isSR ? (isCyrl ? 'Креирање...' : 'Kreiranje...') : isEN ? 'Generating...' : isRU ? 'Создание...' : 'Üretiliyor...')
        : (widget.hasProperties
            ? (isSR ? (isCyrl ? 'Поново Креирај' : 'Ponovo Generiši') : isEN ? 'Regenerate Portfolio' : isRU ? 'Сгенерировать заново' : 'Portföyü Yeniden Üret')
            : (isSR ? (isCyrl ? 'Генериши Пример Портфолија' : 'Generiši Primer Portfolija') : isEN ? 'Generate Sample Portfolio' : isRU ? 'Создать тестовое портфолио' : 'Örnek Portföy Üret'));

    final demoCtaBtnLabel = isSR
        ? (isCyrl ? 'Затражите Демо' : 'Zatražite Demo')
        : isEN
        ? 'Request Full Demo'
        : isRU
        ? 'Запросить демо'
        : 'Demo İste';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.08),
            const Color(0xFF4F46E5).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (widget.hasProperties)
                TextButton.icon(
                  onPressed: _isLoadingPortfolio ? null : _clearPortfolio,
                  icon: const Icon(LucideIcons.rotateCcw, size: 13, color: Color(0xFF64748B)),
                  label: Text(
                    resetBtnLabel,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descriptionText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),

          // Actions Row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // Button 1: Temayı Al
              OutlinedButton.icon(
                onPressed: _isLoadingTheme ? null : _fetchThemeAndLogo,
                icon: _isLoadingTheme
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.palette, size: 15, color: Color(0xFF2563EB)),
                label: Text(
                  themeBtnLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),

              // Button 2: Örnek Portföy Üret
              FilledButton.icon(
                onPressed: _isLoadingPortfolio ? null : _generateSamplePortfolio,
                icon: _isLoadingPortfolio
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.zap, size: 15, color: Colors.amber),
                label: Text(
                  portfolioBtnLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 2,
                ),
              ),

              // Button 3: Demo İste (Request Demo) CTA
              FilledButton.icon(
                onPressed: _onRequestDemo,
                icon: const Icon(LucideIcons.sparkles, size: 15, color: Colors.amberAccent),
                label: Text(
                  demoCtaBtnLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
