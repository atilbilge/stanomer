import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email Regex Validation Tests', () {
    final emailRegex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

    test('validates stanomer.online and modern TLDs correctly', () {
      expect(emailRegex.hasMatch('xxx@stanomer.online'), isTrue);
      expect(emailRegex.hasMatch('info@agency.estate'), isTrue);
      expect(emailRegex.hasMatch('hello@company.technology'), isTrue);
      expect(emailRegex.hasMatch('kiraci@stanomer.online'), isTrue);
      expect(emailRegex.hasMatch('evsahibi@sub.domain.co.uk'), isTrue);
      expect(emailRegex.hasMatch('user+tag@gmail.com'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(emailRegex.hasMatch('plainaddress'), isFalse);
      expect(emailRegex.hasMatch('@missingusername.com'), isFalse);
      expect(emailRegex.hasMatch('username@.com'), isFalse);
      expect(emailRegex.hasMatch('username@domain'), isFalse);
      expect(emailRegex.hasMatch('username@domain.c'), isFalse); // Single letter TLD
    });
  });
}
