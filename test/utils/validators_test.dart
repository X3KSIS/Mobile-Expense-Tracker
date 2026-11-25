import 'package:flutter_expensetracker/utils/phone.dart';
import 'package:flutter_expensetracker/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed emails', () {
      expect(Validators.email(''), 'Enter your email');
      expect(Validators.email('   '), 'Enter your email');
      expect(Validators.email('paul'), 'Enter a valid email address');
      expect(Validators.email('paul@mail'), 'Enter a valid email address');
      expect(Validators.email('pa ul@mail.com'), 'Enter a valid email address');
    });

    test('accepts valid emails, ignoring surrounding spaces', () {
      expect(Validators.email('paul@example.com'), isNull);
      expect(Validators.email('  mwila.banda@zm.co.zm '), isNull);
    });
  });

  group('Validators.name', () {
    test('requires at least two characters', () {
      expect(Validators.name(''), 'Enter your name');
      expect(Validators.name('A'), 'Name is too short');
      expect(Validators.name('Mwila Banda'), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('needs 8 characters with a letter and a number', () {
      expect(Validators.newPassword(''), 'Enter a password');
      expect(Validators.newPassword('abc12'), 'Use at least 8 characters');
      expect(
        Validators.newPassword('abcdefgh'),
        'Include at least one letter and one number',
      );
      expect(
        Validators.newPassword('12345678'),
        'Include at least one letter and one number',
      );
      expect(Validators.newPassword('kwacha2026'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('must match the password', () {
      expect(Validators.confirmPassword('', 'abc'), 'Confirm your password');
      expect(Validators.confirmPassword('abd', 'abc'), "Passwords don't match");
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });

  group('Validators.optionalPhone', () {
    test('allows empty', () {
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone(null), isNull);
    });

    test('accepts local and international Zambian mobiles', () {
      expect(Validators.optionalPhone('0971234567'), isNull);
      expect(Validators.optionalPhone('097 123 4567'), isNull);
      expect(Validators.optionalPhone('0761-234-567'), isNull);
      expect(Validators.optionalPhone('+260971234567'), isNull);
    });

    test('rejects other numbers', () {
      const message = 'Enter a valid number, e.g. 097 123 4567';
      expect(Validators.optionalPhone('12345'), message);
      expect(Validators.optionalPhone('0211234567'), message);
      expect(Validators.optionalPhone('09712345678'), message);
    });
  });

  group('formatPhone', () {
    test('groups local and international numbers', () {
      expect(formatPhone('0971234567'), '097 123 4567');
      expect(formatPhone('+260971234567'), '+260 97 123 4567');
      expect(formatPhone('12345'), '12345');
    });
  });
}
