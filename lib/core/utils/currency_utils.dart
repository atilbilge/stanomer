import 'package:intl/intl.dart';

class CurrencyUtils {
  static String formatCurrencyMap(Map<String, double> totals, {bool useSymbols = false}) {
    if (totals.isEmpty) return '0,00';

    final List<String> segments = [];
    final sortedKeys = totals.keys.toList()..sort();

    for (final currency in sortedKeys) {
      final amount = totals[currency]!;
      if (amount == 0 && totals.length > 1) continue;

      final formattedAmount = formatAmount(amount, currency, useSymbol: useSymbols);
      segments.add(formattedAmount);
    }

    return segments.isEmpty ? '0,00' : segments.join('\n');
  }

  static String formatAmount(double amount, String currency, {bool useSymbol = false}) {
    final formattedAmount = NumberFormat('#,##0.00', 'tr_TR').format(amount);
    final displayCurrency = useSymbol ? _getSymbol(currency) : currency;
    return '$formattedAmount $displayCurrency';
  }

  static String _getSymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'RSD':
        return 'RSD';
      case 'USD':
        return '\$';
      case 'TRY':
        return '₺';
      default:
        return currency;
    }
  }

  /// Helper to merge a new amount into a currency map
  static Map<String, double> addToMap(Map<String, double> map, double amount, String currency) {
    final newMap = Map<String, double>.from(map);
    newMap[currency] = (newMap[currency] ?? 0) + amount;
    return newMap;
  }
}
