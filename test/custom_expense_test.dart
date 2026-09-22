import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/core/utils/expense_utils.dart';
import 'package:stanomer/features/property/domain/contract.dart';

void main() {
  group('Custom Expense Types and ExpenseUtils Tests', () {
    test('Standard expenses are correctly identified', () {
      expect(ExpenseUtils.isStandardExpense('Infostan'), isTrue);
      expect(ExpenseUtils.isStandardExpense('Struja (Electricity)'), isTrue);
      expect(ExpenseUtils.isStandardExpense('struja'), isTrue);
      expect(ExpenseUtils.isStandardExpense('Internet/TV'), isTrue);
      expect(ExpenseUtils.isStandardExpense('Održavanje zgrade (Maintenance)'), isTrue);
      expect(ExpenseUtils.isStandardExpense('Porez (Tax)'), isTrue);
    });

    test('Custom expenses are correctly identified as non-standard', () {
      expect(ExpenseUtils.isStandardExpense('Garaj Aidatı'), isFalse);
      expect(ExpenseUtils.isStandardExpense('Doğalgaz'), isFalse);
      expect(ExpenseUtils.isStandardExpense('Temizlik Hizmeti'), isFalse);
      expect(ExpenseUtils.isStandardExpense('Depo Kirası'), isFalse);
    });

    test('Custom ExpenseItem serialization and deserialization', () {
      const customExpense = ExpenseItem(
        name: 'Garaj Aidatı',
        receiver: PaymentReceiver.owner,
        amount: 25.0,
        paymentMethod: 'cash',
      );

      final json = customExpense.toJson();
      expect(json['name'], 'Garaj Aidatı');
      expect(json['receiver'], 'owner');
      expect(json['amount'], 25.0);
      expect(json['payment_method'], 'cash');

      final fromJson = ExpenseItem.fromJson(json);
      expect(fromJson.name, 'Garaj Aidatı');
      expect(fromJson.receiver, PaymentReceiver.owner);
      expect(fromJson.amount, 25.0);
      expect(fromJson.paymentMethod, 'cash');
      expect(fromJson.isIncluded, isFalse);
      expect(fromJson.isCash, isTrue);
    });

    test('Custom ExpenseItem with included receiver', () {
      const includedExpense = ExpenseItem(
        name: 'Havuz Bakımı',
        receiver: PaymentReceiver.included,
      );

      expect(includedExpense.isIncluded, isTrue);
      final json = includedExpense.toJson();
      expect(json['name'], 'Havuz Bakımı');
      expect(json['receiver'], 'included');

      final fromJson = ExpenseItem.fromJson(json);
      expect(fromJson.name, 'Havuz Bakımı');
      expect(fromJson.isIncluded, isTrue);
      expect(fromJson.receiver, PaymentReceiver.included);
    });

    test('Contract with custom expenses preserves all items', () {
      final expenses = [
        const ExpenseItem(name: 'Infostan', receiver: PaymentReceiver.included),
        const ExpenseItem(name: 'Struja (Electricity)', receiver: PaymentReceiver.owner),
        const ExpenseItem(name: 'Garaj Aidatı', receiver: PaymentReceiver.owner),
      ];

      final contract = Contract(
        id: 'c1',
        propertyId: 'p1',
        landlordId: 'l1',
        inviteeEmail: 'tenant@example.com',
        token: 'tok123',
        monthlyRent: 500,
        currency: 'EUR',
        expensesConfig: expenses,
      );

      final json = contract.toJson();
      final restored = Contract.fromJson(json);

      expect(restored.expensesConfig.length, 3);
      expect(restored.expensesConfig[2].name, 'Garaj Aidatı');
      expect(restored.expensesConfig[2].receiver, PaymentReceiver.owner);
      expect(ExpenseUtils.isStandardExpense(restored.expensesConfig[2].name), isFalse);
    });
  });
}
