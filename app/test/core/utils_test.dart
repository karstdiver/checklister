import 'package:flutter_test/flutter_test.dart';

// Example utility functions to test
class ValidationUtils {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static int calculateChecklistProgress(int completed, int total) {
    if (total == 0) return 0;
    return ((completed / total) * 100).round();
  }
}

void main() {
  group('ValidationUtils', () {
    group('isValidEmail', () {
      test('should validate correct email addresses', () {
        expect(ValidationUtils.isValidEmail('test@example.com'), isTrue);
        expect(ValidationUtils.isValidEmail('user.name@domain.co.uk'), isTrue);
        expect(ValidationUtils.isValidEmail('user+tag@example.org'), isTrue);
      });

      test('should reject invalid email addresses', () {
        expect(ValidationUtils.isValidEmail('invalid-email'), isFalse);
        expect(ValidationUtils.isValidEmail('test@'), isFalse);
        expect(ValidationUtils.isValidEmail('@example.com'), isFalse);
        expect(ValidationUtils.isValidEmail(''), isFalse);
      });
    });

    group('isValidPassword', () {
      test('should validate passwords with 6 or more characters', () {
        expect(ValidationUtils.isValidPassword('password123'), isTrue);
        expect(ValidationUtils.isValidPassword('123456'), isTrue);
        expect(ValidationUtils.isValidPassword('abcdef'), isTrue);
      });

      test('should reject passwords with less than 6 characters', () {
        expect(ValidationUtils.isValidPassword('12345'), isFalse);
        expect(ValidationUtils.isValidPassword('abc'), isFalse);
        expect(ValidationUtils.isValidPassword(''), isFalse);
      });
    });

    group('capitalizeFirst', () {
      test('should capitalize first letter of string', () {
        expect(ValidationUtils.capitalizeFirst('hello'), equals('Hello'));
        expect(ValidationUtils.capitalizeFirst('world'), equals('World'));
        expect(ValidationUtils.capitalizeFirst('flutter'), equals('Flutter'));
      });

      test('should handle edge cases', () {
        expect(ValidationUtils.capitalizeFirst(''), equals(''));
        expect(ValidationUtils.capitalizeFirst('a'), equals('A'));
        expect(ValidationUtils.capitalizeFirst('123'), equals('123'));
      });
    });

    group('calculateChecklistProgress', () {
      test('should calculate correct progress percentages', () {
        expect(ValidationUtils.calculateChecklistProgress(5, 10), equals(50));
        expect(ValidationUtils.calculateChecklistProgress(0, 10), equals(0));
        expect(ValidationUtils.calculateChecklistProgress(10, 10), equals(100));
        expect(ValidationUtils.calculateChecklistProgress(3, 4), equals(75));
      });

      test('should handle edge cases', () {
        expect(ValidationUtils.calculateChecklistProgress(0, 0), equals(0));
        expect(ValidationUtils.calculateChecklistProgress(5, 0), equals(0));
      });

      test('should round progress correctly', () {
        expect(ValidationUtils.calculateChecklistProgress(1, 3), equals(33));
        expect(ValidationUtils.calculateChecklistProgress(2, 3), equals(67));
      });
    });
  });
}
