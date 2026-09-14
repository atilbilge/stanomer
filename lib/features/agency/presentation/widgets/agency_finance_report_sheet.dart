import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../property/domain/property.dart';
import '../../domain/agency_color_scheme.dart';

class AgencyFinanceReportSheet extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, Property> propertiesMap;
  final AgencyColorScheme colors;
  final String periodTitle;
  final String segmentTitle;
  final String? agencyName;

  const AgencyFinanceReportSheet({
    super.key,
    required this.items,
    required this.propertiesMap,
    required this.colors,
    required this.periodTitle,
    required this.segmentTitle,
    this.agencyName,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
    required Map<String, Property> propertiesMap,
    required AgencyColorScheme colors,
    required String periodTitle,
    required String segmentTitle,
    String? agencyName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgencyFinanceReportSheet(
        items: items,
        propertiesMap: propertiesMap,
        colors: colors,
        periodTitle: periodTitle,
        segmentTitle: segmentTitle,
        agencyName: agencyName,
      ),
    );
  }

  _ReportI18n _getI18n(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeName = loc?.localeName ?? Localizations.localeOf(context).languageCode;
    return _ReportI18n(localeName);
  }

  // Helper: Calculate totals by currency
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    for (final item in items) {
      final amt = (item['amount'] as num?)?.toDouble() ??
          (item['total_amount'] as num?)?.toDouble() ??
          (item['cost_amount'] as num?)?.toDouble() ??
          0.0;
      final cur = (item['currency'] as String? ?? 'EUR').toUpperCase();
      totals[cur] = (totals[cur] ?? 0.0) + amt;
    }
    return totals;
  }

  String _formatTotalsString(Map<String, double> totals, _ReportI18n i18n) {
    if (totals.isEmpty) return '0 €';
    return totals.entries.map((e) {
      final sym = e.key == 'EUR' ? '€' : (e.key == 'RSD' ? 'RSD' : e.key);
      final formatted = NumberFormat('#,##0.##', i18n.numberLocale).format(e.value);
      return '$formatted $sym';
    }).join(' + ');
  }

  // Generate plain text report
  String _generatePlainText(BuildContext context) {
    final i18n = _getI18n(context);
    final totals = _calculateTotals();
    final totalsStr = _formatTotalsString(totals, i18n);
    final nowFormatted = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final displayAgency = (agencyName != null && agencyName!.isNotEmpty)
        ? agencyName!
        : 'Stanomer';

    final buffer = StringBuffer();
    buffer.writeln(i18n.plainHeader);
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('${i18n.agencyLabel}: $displayAgency');
    buffer.writeln('${i18n.periodLabel}: $periodTitle');
    buffer.writeln('${i18n.filterTypeLabel}: $segmentTitle');
    buffer.writeln('${i18n.reportDateLabel}: $nowFormatted');
    buffer.writeln('');
    buffer.writeln(i18n.summaryOverview);
    buffer.writeln('${i18n.countBullet}: ${items.length}');
    buffer.writeln('${i18n.totalBullet}: $totalsStr');
    buffer.writeln('');
    buffer.writeln(i18n.itemsSection);

    if (items.isEmpty) {
      buffer.writeln(i18n.noTransactions);
    } else {
      int idx = 1;
      for (final item in items) {
        final pObj = propertiesMap[item['property_id']];
        final propMap = item['property'] as Map<String, dynamic>?;

        final propName = propMap?['name'] as String? ?? pObj?.name ?? i18n.defaultProperty;
        final propAddress = propMap?['address'] as String? ?? pObj?.address ?? '';

        final title = item['title'] as String? ?? i18n.defaultRentTitle;
        final amt = (item['amount'] as num?)?.toDouble() ??
            (item['total_amount'] as num?)?.toDouble() ??
            (item['cost_amount'] as num?)?.toDouble() ??
            0.0;
        final cur = (item['currency'] as String? ?? 'EUR').toUpperCase();
        final sym = cur == 'EUR' ? '€' : (cur == 'RSD' ? 'RSD' : cur);
        final amtStr = '${NumberFormat('#,##0.##', i18n.numberLocale).format(amt)} $sym';

        final landlordMap = propMap?['landlord'] as Map<String, dynamic>?;
        final landlord = landlordMap?['full_name'] as String? ?? pObj?.landlordName ?? '-';

        final tenantMap = item['tenant'] as Map<String, dynamic>?;
        final tenant = tenantMap?['full_name'] as String? ?? pObj?.tenantName ?? '-';

        final statusRaw = item['status'] as String? ?? 'pending';
        final statusLabel = i18n.statusPlainText(statusRaw);

        final dueStr = item['due_date'] as String? ?? item['created_at'] as String?;
        final dueDateFormatted = dueStr != null
            ? DateFormat('dd.MM.yyyy').format(DateTime.tryParse(dueStr) ?? DateTime.now())
            : '-';

        buffer.writeln('$idx. $propName ($propAddress)');
        buffer.writeln('   • $title: $amtStr | ${i18n.dueLabel}: $dueDateFormatted');
        buffer.writeln('   • ${i18n.landlordLabel}: $landlord | ${i18n.tenantLabel}: $tenant');
        buffer.writeln('   • ${i18n.statusLabelPrefix}: $statusLabel');
        buffer.writeln('');
        idx++;
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(i18n.plainFooter);
    return buffer.toString();
  }

  // Generate HTML for Print and PDF saving
  String _generateHtmlReport(BuildContext context) {
    final i18n = _getI18n(context);
    final totals = _calculateTotals();
    final totalsStr = _formatTotalsString(totals, i18n);
    final nowFormatted = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final displayAgency = (agencyName != null && agencyName!.isNotEmpty)
        ? agencyName!
        : 'Stanomer';

    final hexPrimary = '#${colors.primary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final rowsBuffer = StringBuffer();
    if (items.isEmpty) {
      rowsBuffer.writeln('''
        <tr>
          <td colspan="8" style="text-align:center; padding: 24px; color:#64748b;">${i18n.htmlEmptyRow}</td>
        </tr>
      ''');
    } else {
      int idx = 1;
      for (final item in items) {
        final pObj = propertiesMap[item['property_id']];
        final propMap = item['property'] as Map<String, dynamic>?;

        final propName = propMap?['name'] as String? ?? pObj?.name ?? i18n.defaultProperty;
        final propAddress = propMap?['address'] as String? ?? pObj?.address ?? '';

        final title = item['title'] as String? ?? i18n.defaultRentTitle;
        final amt = (item['amount'] as num?)?.toDouble() ??
            (item['total_amount'] as num?)?.toDouble() ??
            (item['cost_amount'] as num?)?.toDouble() ??
            0.0;
        final cur = (item['currency'] as String? ?? 'EUR').toUpperCase();
        final sym = cur == 'EUR' ? '€' : (cur == 'RSD' ? 'RSD' : cur);
        final amtStr = '${NumberFormat('#,##0.##', i18n.numberLocale).format(amt)} $sym';

        final landlordMap = propMap?['landlord'] as Map<String, dynamic>?;
        final landlord = landlordMap?['full_name'] as String? ?? pObj?.landlordName ?? '-';

        final tenantMap = item['tenant'] as Map<String, dynamic>?;
        final tenant = tenantMap?['full_name'] as String? ?? pObj?.tenantName ?? '-';

        final statusRaw = item['status'] as String? ?? 'pending';
        final String badgeClass;
        if (statusRaw == 'paid') {
          badgeClass = 'badge-paid';
        } else if (statusRaw == 'declared') {
          badgeClass = 'badge-declared';
        } else if (statusRaw == 'disputed') {
          badgeClass = 'badge-disputed';
        } else {
          badgeClass = 'badge-pending';
        }
        final statusLabel = i18n.statusHtmlBadgeText(statusRaw);

        final dueStr = item['due_date'] as String? ?? item['created_at'] as String?;
        final dueDateFormatted = dueStr != null
            ? DateFormat('dd.MM.yyyy').format(DateTime.tryParse(dueStr) ?? DateTime.now())
            : '-';

        rowsBuffer.writeln('''
          <tr>
            <td style="text-align:center; color:#64748b;">$idx</td>
            <td><strong>$propName</strong><br><span style="font-size:11px; color:#64748b;">$propAddress</span></td>
            <td>$title</td>
            <td>$landlord</td>
            <td>$tenant</td>
            <td style="text-align:center;">$dueDateFormatted</td>
            <td style="text-align:right; font-weight:700;">$amtStr</td>
            <td style="text-align:center;"><span class="badge $badgeClass">$statusLabel</span></td>
          </tr>
        ''');
        idx++;
      }
    }

    final htmlTitle = i18n.htmlReportTitle(displayAgency, periodTitle);
    final htmlSubtitle = i18n.htmlSubtitle(segmentTitle);

    return '''<!DOCTYPE html>
<html lang="${i18n.htmlLang}">
<head>
  <meta charset="UTF-8">
  <title>$htmlTitle</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 32px 40px;
      color: #0f172a;
      background-color: #ffffff;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid $hexPrimary;
      padding-bottom: 16px;
      margin-bottom: 24px;
    }
    .agency-title {
      font-size: 24px;
      font-weight: 800;
      color: $hexPrimary;
      margin: 0;
    }
    .report-subtitle {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }
    .kpi-row {
      display: flex;
      gap: 16px;
      margin-bottom: 24px;
    }
    .kpi-box {
      flex: 1;
      background-color: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 14px 18px;
    }
    .kpi-label {
      font-size: 11px;
      font-weight: 700;
      color: #64748b;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .kpi-value {
      font-size: 20px;
      font-weight: 800;
      color: #0f172a;
      margin-top: 6px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 12.5px;
      margin-bottom: 30px;
    }
    th {
      background-color: #f1f5f9;
      color: #334155;
      font-weight: 700;
      padding: 10px 12px;
      text-align: left;
      border-bottom: 1px solid #cbd5e1;
    }
    td {
      padding: 10px 12px;
      border-bottom: 1px solid #f1f5f9;
      vertical-align: middle;
    }
    tr:nth-child(even) {
      background-color: #fbfcfe;
    }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
    }
    .badge-paid {
      background-color: #dcfce7;
      color: #166534;
    }
    .badge-pending {
      background-color: #fef3c7;
      color: #92400e;
    }
    .badge-declared {
      background-color: #e0e7ff;
      color: #3730a3;
    }
    .badge-disputed {
      background-color: #fee2e2;
      color: #991b1b;
    }
    .footer {
      border-top: 1px solid #e2e8f0;
      padding-top: 14px;
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      color: #94a3b8;
    }
    @media print {
      body {
        padding: 15mm 15mm;
      }
      .no-print {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1 class="agency-title">$displayAgency</h1>
      <div class="report-subtitle">$htmlSubtitle</div>
    </div>
    <div style="text-align:right;">
      <div style="font-size:13px; font-weight:700; color:#0f172a;">${i18n.htmlPeriod}: $periodTitle</div>
      <div style="font-size:11px; color:#64748b; margin-top:3px;">${i18n.htmlGenerated}: $nowFormatted</div>
    </div>
  </div>

  <div class="kpi-row">
    <div class="kpi-box">
      <div class="kpi-label">${i18n.htmlKpiCount}</div>
      <div class="kpi-value">${items.length}</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-label">${i18n.htmlKpiTotal}</div>
      <div class="kpi-value">$totalsStr</div>
    </div>
    <div class="kpi-box">
      <div class="kpi-label">${i18n.htmlKpiFilter}</div>
      <div class="kpi-value" style="font-size:16px;">$segmentTitle</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th style="text-align:center; width:30px;">${i18n.htmlColHash}</th>
        <th>${i18n.htmlColProperty}</th>
        <th>${i18n.htmlColItem}</th>
        <th>${i18n.htmlColLandlord}</th>
        <th>${i18n.htmlColTenant}</th>
        <th style="text-align:center;">${i18n.htmlColDue}</th>
        <th style="text-align:right;">${i18n.htmlColAmount}</th>
        <th style="text-align:center;">${i18n.htmlColStatus}</th>
      </tr>
    </thead>
    <tbody>
      ${rowsBuffer.toString()}
    </tbody>
  </table>

  <div class="footer">
    <div>${i18n.htmlFooterBrand}</div>
    <div>${i18n.htmlFooterPage}</div>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 250);
    };
  </script>
</body>
</html>''';
  }

  Future<void> _handlePrintOrPdf(BuildContext context) async {
    final i18n = _getI18n(context);
    final htmlContent = _generateHtmlReport(context);
    final uri = Uri.dataFromString(
      htmlContent,
      mimeType: 'text/html',
      encoding: utf8,
    );

    try {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(i18n.errorOpeningReport(e)),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    }
  }

  Future<void> _handleCopyToClipboard(BuildContext context) async {
    final i18n = _getI18n(context);
    final text = _generatePlainText(context);
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCheck, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(i18n.copySuccessSnack),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleNativeShare(BuildContext context) async {
    final i18n = _getI18n(context);
    final text = _generatePlainText(context);
    await Share.share(
      text,
      subject: '${i18n.sheetTitle} - $periodTitle',
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _getI18n(context);
    final totals = _calculateTotals();
    final totalsStr = _formatTotalsString(totals, i18n);
    final displayAgency = (agencyName != null && agencyName!.isNotEmpty)
        ? agencyName!
        : 'Stanomer';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.fileSpreadsheet, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.sheetTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$displayAgency • $periodTitle',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // KPI Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.totalAmountLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalsStr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.filteredItemsLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.transactionCount(items.length),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons Row
          Row(
            children: [
              // 1. Print / PDF Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePrintOrPdf(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.printer, size: 16),
                  label: Text(
                    i18n.printPdfButton,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Copy Text Button (WhatsApp & Viber)
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCopyToClipboard(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.copy, size: 15, color: Color(0xFF16A34A)),
                  label: Text(
                    i18n.copyTextButton,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // 3. Share icon button (for mobile / native sharing)
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleNativeShare(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(LucideIcons.share2, size: 16, color: Color(0xFF475569)),
                  tooltip: i18n.shareButton,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Internal helper for localized strings in the report sheet and generated reports.
class _ReportI18n {
  final String locale;
  _ReportI18n(this.locale);

  bool get isTr => locale == 'tr';
  bool get isSr => locale.startsWith('sr');
  bool get isRu => locale == 'ru';

  String get numberLocale => isTr ? 'tr_TR' : (isSr ? 'sr_RS' : (isRu ? 'ru_RU' : 'en_US'));

  // Sheet UI
  String get sheetTitle => isTr
      ? 'Finansal Rapor'
      : (isSr
          ? 'Finansijski izveštaj'
          : (isRu ? 'Финансовый отчет' : 'Financial Report'));

  String get totalAmountLabel => isTr
      ? 'TOPLAM TUTAR'
      : (isSr
          ? 'UKUPAN IZNOS'
          : (isRu ? 'ОБЩАЯ СУММА' : 'TOTAL AMOUNT'));

  String get filteredItemsLabel => isTr
      ? 'FİLTRELENEN KAYIT'
      : (isSr
          ? 'FILTERISANO STAVKI'
          : (isRu ? 'ОТФИЛЬТРОВАНО' : 'FILTERED ITEMS'));

  String transactionCount(int count) => isTr
      ? '$count işlem'
      : (isSr
          ? '$count transakcija'
          : (isRu ? '$count транзакций' : '$count transactions'));

  String get printPdfButton => isTr
      ? 'Yazdır / PDF'
      : (isSr
          ? 'Štampaj / PDF'
          : (isRu ? 'Печать / PDF' : 'Print / PDF'));

  String get copyTextButton => isTr
      ? 'Metni Kopyala'
      : (isSr
          ? 'Kopiraj tekst'
          : (isRu ? 'Копировать текст' : 'Copy Text'));

  String get shareButton => isTr
      ? 'Paylaş'
      : (isSr ? 'Podeli' : (isRu ? 'Поделиться' : 'Share'));

  String get copySuccessSnack => isTr
      ? 'Rapor panoya başarıyla kopyalandı!'
      : (isSr
          ? 'Izveštaj je uspešno kopiran u privremenu memoriju!'
          : (isRu
              ? 'Отчет успешно скопирован в буфер обмена!'
              : 'Report successfully copied to clipboard!'));

  String errorOpeningReport(dynamic e) => isTr
      ? 'Rapor açılırken hata oluştu: $e'
      : (isSr
          ? 'Greška prilikom otvaranja izveštaja: $e'
          : (isRu
              ? 'Ошибка при открытии отчета: $e'
              : 'Error opening report: $e'));

  // Plain Text Report
  String get plainHeader => isTr
      ? '📊 STANOMER | FİNANSAL RAPOR'
      : (isSr
          ? '📊 STANOMER | FINANSIJSKI IZVEŠTAJ'
          : (isRu
              ? '📊 STANOMER | ФИНАНСОВЫЙ ОТЧЕТ'
              : '📊 STANOMER | FINANCIAL REPORT'));

  String get agencyLabel => isTr
      ? '🏢 Acente'
      : (isSr ? '🏢 Agencija' : (isRu ? '🏢 Агентство' : '🏢 Agency'));

  String get periodLabel => isTr
      ? '📅 Dönem'
      : (isSr ? '📅 Period' : (isRu ? '📅 Период' : '📅 Period'));

  String get filterTypeLabel => isTr
      ? '📂 Filtre / Tür'
      : (isSr ? '📂 Filter / Tip' : (isRu ? '📂 Фильтр / Тип' : '📂 Filter / Type'));

  String get reportDateLabel => isTr
      ? '🕒 Rapor Tarihi'
      : (isSr ? '🕒 Datum izveštaja' : (isRu ? '🕒 Дата отчета' : '🕒 Report Date'));

  String get summaryOverview => isTr
      ? '📈 GENEL ÖZET:'
      : (isSr
          ? '📈 UKUPAN PREGLED:'
          : (isRu ? '📈 ОБЩИЙ ОБЗОР:' : '📈 SUMMARY OVERVIEW:'));

  String get countBullet => isTr
      ? '• İşlem sayısı'
      : (isSr
          ? '• Broj transakcija'
          : (isRu ? '• Количество транзакций' : '• Number of transactions'));

  String get totalBullet => isTr
      ? '• Toplam tutar'
      : (isSr
          ? '• Ukupan iznos'
          : (isRu ? '• Общая сумма' : '• Total amount'));

  String get itemsSection => isTr
      ? '📋 KALEMLER / İŞLEMLER:'
      : (isSr
          ? '📋 STAVKE / TRANSAKCIJE:'
          : (isRu ? '📋 СТАТЬИ / ТРАНЗАКЦИИ:' : '📋 ITEMS / TRANSACTIONS:'));

  String get noTransactions => isTr
      ? 'Seçilen filtre için kayıtlı işlem bulunamadı.'
      : (isSr
          ? 'Nema evidentiranih transakcija za izabrani filter.'
          : (isRu
              ? 'Нет транзакций для выбранного фильтра.'
              : 'No transactions recorded for the selected filter.'));

  String get defaultProperty => isTr
      ? 'Mülk'
      : (isSr ? 'Nekretnina' : (isRu ? 'Недвижимость' : 'Property'));

  String get defaultRentTitle => isTr
      ? 'Kira'
      : (isSr ? 'Kirija' : (isRu ? 'Аренда' : 'Rent'));

  String get dueLabel => isTr
      ? 'Vade'
      : (isSr ? 'Rok' : (isRu ? 'Срок' : 'Due'));

  String get landlordLabel => isTr
      ? 'Ev Sahibi'
      : (isSr ? 'Vlasnik' : (isRu ? 'Собственник' : 'Landlord'));

  String get tenantLabel => isTr
      ? 'Kiracı'
      : (isSr ? 'Zakupac' : (isRu ? 'Арендатор' : 'Tenant'));

  String get statusLabelPrefix => isTr
      ? 'Durum'
      : (isSr ? 'Status' : (isRu ? 'Статус' : 'Status'));

  String statusPlainText(String statusRaw) {
    if (statusRaw == 'paid') {
      return isTr
          ? '✅ ÖDENDİ'
          : (isSr ? '✅ PLAĆENO' : (isRu ? '✅ ОПЛАЧЕНО' : '✅ PAID'));
    } else if (statusRaw == 'declared') {
      return isTr
          ? '⏳ BİLDİRİLDİ'
          : (isSr ? '⏳ PRIJAVLJENO' : (isRu ? '⏳ ЗАЯВЛЕНО' : '⏳ DECLARED'));
    } else if (statusRaw == 'disputed') {
      return isTr
          ? '⚠️ İTİRAZLI'
          : (isSr ? '⚠️ SPORNO' : (isRu ? '⚠️ СПОРНО' : '⚠️ DISPUTED'));
    } else {
      return isTr
          ? '🕒 BEKLEMEDE'
          : (isSr ? '🕒 NA ČEKANJU' : (isRu ? '🕒 В ОЖИДАНИИ' : '🕒 PENDING'));
    }
  }

  String statusHtmlBadgeText(String statusRaw) {
    if (statusRaw == 'paid') {
      return isTr
          ? 'Ödendi'
          : (isSr ? 'Plaćeno' : (isRu ? 'Оплачено' : 'Paid'));
    } else if (statusRaw == 'declared') {
      return isTr
          ? 'Bildirildi'
          : (isSr ? 'Prijavljeno' : (isRu ? 'Заявлено' : 'Declared'));
    } else if (statusRaw == 'disputed') {
      return isTr
          ? 'İtirazlı'
          : (isSr ? 'Sporno' : (isRu ? 'Спорно' : 'Disputed'));
    } else {
      return isTr
          ? 'Beklemede'
          : (isSr ? 'Na čekanju' : (isRu ? 'В ожидании' : 'Pending'));
    }
  }

  String get plainFooter => isTr
      ? 'stanomer.online aracılığıyla oluşturulmuştur'
      : (isSr
          ? 'Generisano putem stanomer.online'
          : (isRu
              ? 'Сгенерировано через stanomer.online'
              : 'Generated via stanomer.online'));

  // HTML Report
  String get htmlLang => isTr ? 'tr' : (isSr ? 'sr' : (isRu ? 'ru' : 'en'));

  String htmlReportTitle(String agency, String period) => isTr
      ? 'Rapor - $agency ($period)'
      : (isSr
          ? 'Izveštaj - $agency ($period)'
          : (isRu
              ? 'Отчет - $agency ($period)'
              : 'Report - $agency ($period)'));

  String htmlSubtitle(String segment) => isTr
      ? 'Finansal Rapor • $segment'
      : (isSr
          ? 'Finansijski Izveštaj • $segment'
          : (isRu
              ? 'Финансовый отчет • $segment'
              : 'Financial Report • $segment'));

  String get htmlPeriod => isTr
      ? 'Dönem'
      : (isSr ? 'Period' : (isRu ? 'Период' : 'Period'));

  String get htmlGenerated => isTr
      ? 'Oluşturulma'
      : (isSr ? 'Generisano' : (isRu ? 'Создано' : 'Generated'));

  String get htmlKpiCount => isTr
      ? 'İşlem Sayısı'
      : (isSr
          ? 'Broj Transakcija'
          : (isRu ? 'Транзакции' : 'Transactions'));

  String get htmlKpiTotal => isTr
      ? 'Toplam Tutar'
      : (isSr
          ? 'Ukupan Iznos'
          : (isRu ? 'Общая Сумма' : 'Total Amount'));

  String get htmlKpiFilter => isTr
      ? 'Filtre / Kategori'
      : (isSr
          ? 'Filter / Status'
          : (isRu ? 'Фильтр / Категория' : 'Filter / Category'));

  String get htmlColHash => '#';
  String get htmlColProperty => isTr
      ? 'Mülk'
      : (isSr ? 'Nekretnina' : (isRu ? 'Недвижимость' : 'Property'));
  String get htmlColItem => isTr
      ? 'Kalem'
      : (isSr ? 'Stavka' : (isRu ? 'Статья' : 'Item'));
  String get htmlColLandlord => isTr
      ? 'Ev Sahibi'
      : (isSr ? 'Vlasnik' : (isRu ? 'Собственник' : 'Landlord'));
  String get htmlColTenant => isTr
      ? 'Kiracı'
      : (isSr ? 'Zakupac' : (isRu ? 'Арендатор' : 'Tenant'));
  String get htmlColDue => isTr
      ? 'Vade'
      : (isSr ? 'Rok' : (isRu ? 'Срок' : 'Due Date'));
  String get htmlColAmount => isTr
      ? 'Tutar'
      : (isSr ? 'Iznos' : (isRu ? 'Сумма' : 'Amount'));
  String get htmlColStatus => isTr
      ? 'Durum'
      : (isSr ? 'Status' : (isRu ? 'Статус' : 'Status'));

  String get htmlFooterBrand => isTr
      ? 'Stanomer Gayrimenkul Teknolojileri • www.stanomer.online'
      : (isSr
          ? 'Stanomer Tehnologije za Nekretnine • www.stanomer.online'
          : (isRu
              ? 'Stanomer Технологии Недвижимости • www.stanomer.online'
              : 'Stanomer Property Technologies • www.stanomer.online'));

  String get htmlFooterPage => isTr
      ? 'Sayfa 1 / 1'
      : (isSr
          ? 'Stranica 1 / 1'
          : (isRu ? 'Страница 1 / 1' : 'Page 1 / 1'));

  String get htmlEmptyRow => isTr
      ? 'Seçili dönem için kayıt bulunamadı.'
      : (isSr
          ? 'Nema evidentiranih transakcija za izabrani period.'
          : (isRu
              ? 'Нет транзакций за выбранный период.'
              : 'No transactions recorded for the selected period.'));
}
