import 'package:flutter_test/flutter_test.dart';

import 'package:reillo_mobile/models/user.dart';
import 'package:reillo_mobile/utils/validators.dart';

// The full app needs a configured Firebase project to boot, so these tests
// cover the pieces that run without it: sign-up validation and the User model.
void main() {
  group('Validators.password', () {
    test('accepts a strong password', () {
      expect(Validators.password('Str0ng!pass'), isNull);
    });

    test('rejects each missing rule', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('Sh0rt!'), 'Use at least 8 characters');
      expect(Validators.password('lower0!case'), 'Add an uppercase letter');
      expect(Validators.password('UPPER0!CASE'), 'Add a lowercase letter');
      expect(Validators.password('NoDigits!!'), 'Add a number');
      expect(Validators.password('NoSymb0ls'), 'Add a symbol');
    });
  });

  group('sign-up validators', () {
    test('email', () {
      expect(Validators.email('juan@example.com'), isNull);
      expect(Validators.email('juan@'), 'Enter a valid email');
    });

    test('age', () {
      expect(Validators.age('21'), isNull);
      expect(Validators.age('abc'), 'Age is required');
      expect(Validators.age('5'), 'Enter an age from 13 to 120');
    });

    test('contact number', () {
      expect(Validators.contactNo('0917 123 4567'), isNull);
      expect(Validators.contactNo('+63 917-123-4567'), isNull);
      expect(Validators.contactNo('12345'), 'Enter a valid contact number');
    });

    test('confirm password', () {
      expect(Validators.confirmPassword('Abc123!x', 'Abc123!x'), isNull);
      expect(
        Validators.confirmPassword('Abc123!y', 'Abc123!x'),
        'Passwords do not match',
      );
    });
  });

  group('User', () {
    test('defaults to DummyJSON when loginType is missing', () {
      final user = User.fromJson({'id': 1, 'username': 'emilys'});
      expect(user.loginType, LoginType.dummyJson);
    });

    test('round-trips a Firebase user through JSON', () {
      final user = User.fromJson({
        'uid': 'abc123',
        'username': 'juan',
        'email': 'juan@example.com',
        'firstName': 'Juan',
        'lastName': 'Dela Cruz',
        'age': 21,
        'phone': '09171234567',
        'loginType': 'firebase',
      });

      final copy = User.fromJson(user.toJson());
      expect(copy.loginType, LoginType.firebase);
      expect(copy.uid, 'abc123');
      expect(copy.age, 21);
      expect(copy.fullName, 'Juan Dela Cruz');
    });
  });
}
