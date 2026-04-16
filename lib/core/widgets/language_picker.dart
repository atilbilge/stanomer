import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return PopupMenuButton<Locale>(
      onSelected: (Locale locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('sr'),
          child: Row(
            children: [
              Text('🇷🇸 '),
              Text('Srpski (Lat)'),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
          child: Row(
            children: [
              Text('🇷🇸 '),
              Text('Српски (Ћир)'),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Row(
            children: [
              Text('🇬🇧 '),
              Text('English'),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('tr'),
          child: Row(
            children: [
              Text('🇹🇷 '),
              Text('Türkçe'),
            ],
          ),
        ),
      ],
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getButtonLabel(currentLocale),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  String _getButtonLabel(Locale locale) {
    if (locale.languageCode == 'en') return '🇬🇧 EN';
    if (locale.languageCode == 'tr') return '🇹🇷 TR';
    if (locale.scriptCode == 'Cyrl') return '🇷🇸 СРП';
    return '🇷🇸 SRP';
  }
}
