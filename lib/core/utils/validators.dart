//my strategy for handling centralized errors or nulls

class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9._]{3,20}$');

  static String? notEmpty(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
  //email validation
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }
  //username validation
  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Username is required';
    if (!_usernameRegex.hasMatch(v)) {
      return '3-20 characters: letters, numbers, dot or underscore';
    }
    return null;
  }
  //password validation
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }
  //confirm password validation
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // password strength measurement
  static int passwordStrength(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }
  static String? amount(String? v, {String field = 'Amount', bool required = true}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return required ? '$field is required' : null;
    final n = double.tryParse(t);
    if (n == null || n < 0) return 'Enter a valid amount';
    return null;
  }

  static String? wholeNumber(String? v,
      {required String field, int min = 1, int max = 50}) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return '$field is required';
    if (n < min || n > max) return 'Use $min to $max';
    return null;
  }
}