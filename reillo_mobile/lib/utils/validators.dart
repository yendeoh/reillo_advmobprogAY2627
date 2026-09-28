// LAB ACT 5: Form validators shared by the sign-up and profile screens.
class Validators {
  static String? required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'Use at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value.trim())) {
      return 'Letters, numbers, _ and . only';
    }
    return null;
  }

  static String? age(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Age is required';
    if (age < 13 || age > 120) return 'Enter an age from 13 to 120';
    return null;
  }

  static String? contactNo(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s\-+()]'), '');
    if (digits.isEmpty) return 'Contact number is required';
    if (!RegExp(r'^\d{10,13}$').hasMatch(digits)) {
      return 'Enter a valid contact number';
    }
    return null;
  }

  /// Password rules: 8+ characters with an uppercase letter, a lowercase
  /// letter, a number and a symbol.
  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Use at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
    if (!password.contains(RegExp(r'\d'))) return 'Add a number';
    if (!password.contains(RegExp(r'[^A-Za-z0-9]'))) return 'Add a symbol';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    return value == password ? null : 'Passwords do not match';
  }
}
