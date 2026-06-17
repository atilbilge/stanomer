import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations loads correct translations for supported locales', (WidgetTester tester) async {
    final localesToTest = [
      const Locale('en'),
      const Locale('tr'),
      const Locale('sr'),
      const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl'),
      const Locale('ru'),
    ];

    for (final locale in localesToTest) {
      String? resolvedAppTitle;
      String? resolvedSelectRole;

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                resolvedAppTitle = l10n.appTitle;
                resolvedSelectRole = l10n.selectRole;
                return Text(l10n.appTitle);
              },
            ),
          ),
        ),
      );

      // Trigger a frame to settle the UI
      await tester.pumpAndSettle();

      expect(resolvedAppTitle, isNotNull);
      expect(resolvedAppTitle!.isNotEmpty, true);
      expect(resolvedSelectRole, isNotNull);
      expect(resolvedSelectRole!.isNotEmpty, true);

      // Verify specific translations match expectations for key locales
      if (locale.languageCode == 'tr') {
        expect(resolvedAppTitle, 'Stanomer');
        expect(resolvedSelectRole, 'Rolünüzü seçin');
      } else if (locale.languageCode == 'sr' && locale.scriptCode == 'Cyrl') {
        expect(resolvedAppTitle, 'Станомер');
        expect(resolvedSelectRole, 'Изаберите своју улогу');
      } else if (locale.languageCode == 'sr' && locale.scriptCode == null) {
        expect(resolvedAppTitle, 'Stanomer');
        expect(resolvedSelectRole, 'Izaberi svoju ulogu');
      } else if (locale.languageCode == 'ru') {
        expect(resolvedAppTitle, 'Stanomer');
        expect(resolvedSelectRole, 'Выберите вашу роль');
      }
    }
  });
}
