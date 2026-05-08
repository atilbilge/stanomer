import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class WebLanguageSwitcher extends ConsumerWidget {
  const WebLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLangCode(ref, 'TR', const Locale('tr'), currentLocale),
        _buildDivider(),
        _buildLangCode(ref, 'EN', const Locale('en'), currentLocale),
        _buildDivider(),
        _buildLangCode(ref, 'SR', const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'), currentLocale),
        _buildDivider(),
        _buildLangCode(ref, 'СР', const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'), currentLocale),
        _buildDivider(),
        _buildLangCode(ref, 'RU', const Locale('ru'), currentLocale),
      ],
    );
  }

  Widget _buildLangCode(WidgetRef ref, String label, Locale locale, Locale currentLocale) {
    final bool isSelected = _isSameLocale(locale, currentLocale);

    return InkWell(
      onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Text(
      '|',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[300],
      ),
    );
  }

  bool _isSameLocale(Locale l1, Locale l2) {
    return l1.languageCode == l2.languageCode && l1.scriptCode == l2.scriptCode;
  }
}
