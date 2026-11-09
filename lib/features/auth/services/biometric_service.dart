//backend conf for biometrics

//import libraries
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

//status
enum BiometricResult {
  success,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

// Wraps the phone's fingerprint prompt and remembers (per account) whether
// the user switched on biometric unlock.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth, FlutterSecureStorage? storage})
      : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  static const _keyPrefix = 'biometric_enabled_';

  // True when the phone has biometric hardware AND an enrolled fingerprint.
  Future<bool> isDeviceSupported() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  // Shows the system fingerprint prompt (no PIN/pattern fallback).
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      print('====== ABOUT TO CALL AUTHENTICATE ======');

      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      print('====== AUTHENTICATE RETURNED: $ok ======');
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on PlatformException catch (e) {
      // Temporary – remove after we find the real error
      print('====== BIOMETRIC ERROR ======');
      print('code   : ${e.code}');
      print('message: ${e.message}');
      print('details: ${e.details}');
      print('=============================');

      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        case auth_error.notEnrolled:
          return BiometricResult.notEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricResult.lockedOut;
        default:
          return BiometricResult.error;
      }
    }
  }

  Future<bool> isEnabledFor(String uid) async {
    try {
      return await _storage.read(key: '$_keyPrefix$uid') == 'true';
    } on PlatformException {
      return false; // unreadable storage -> treat as not registered
    }
  }

  Future<void> setEnabled(String uid, bool enabled) =>
      _storage.write(key: '$_keyPrefix$uid', value: enabled ? 'true' : 'false');
}