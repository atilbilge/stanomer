import '../l10n/app_localizations.dart';

class ExpenseUtils {
  static String getLocalizedExpenseName(String name, AppLocalizations loc) {
    switch (name) {
      case 'Infostan':
        return loc.expenseInfostan;
      case 'Struja (Electricity)':
      case 'Struja':
        return loc.expenseElectricity;
      case 'Internet/TV':
        return loc.expenseInternetTV;
      case 'Održavanje zgrade (Maintenance)':
      case 'Održavanje zgrade':
        return loc.expenseMaintenance;
      case 'Porez (Tax)':
      case 'Porez':
      case 'Tax':
        return loc.expenseTax;
      case 'Rent':
      case 'Kira':
        return loc.rent;
      case 'Electricity':
        return loc.expenseElectricity;
      case 'Internet':
        return loc.expenseInternetTV;
      case 'Maintenance':
        return loc.expenseMaintenance;
      default:
        return name;
    }
  }

  static String getLocalizedTooltip(String name, AppLocalizations loc) {
    switch (name) {
      case 'Infostan':
        return loc.infoTooltip;
      case 'Struja (Electricity)':
      case 'Struja':
        return loc.electricityTooltip;
      case 'Internet/TV':
        return loc.internetTooltip;
      case 'Održavanje zgrade (Maintenance)':
      case 'Održavanje zgrade':
        return loc.maintenanceTooltip;
      default:
        return '';
    }
  }

  static const List<String> defaultExpenses = [
    'Infostan',
    'Struja (Electricity)',
    'Internet/TV',
    'Održavanje zgrade (Maintenance)',
  ];

  static bool isStandardExpense(String name) {
    final n = name.trim().toLowerCase();
    return n == 'infostan' ||
        n == 'struja (electricity)' ||
        n == 'struja' ||
        n == 'electricity' ||
        n == 'internet/tv' ||
        n == 'internet' ||
        n == 'održavanje zgrade (maintenance)' ||
        n == 'održavanje zgrade' ||
        n == 'održavanje' ||
        n == 'maintenance' ||
        n == 'porez (tax)' ||
        n == 'porez' ||
        n == 'tax';
  }
}
