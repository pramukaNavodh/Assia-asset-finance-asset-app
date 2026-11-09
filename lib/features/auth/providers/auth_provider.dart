// firebase and physical auth pro conf

//libraries
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';


enum AuthStatus {
  loading, // checking saved session
  signedOut, // show Sign In
  needsBiometricSetup, // signed in, fingerprint not registered yet
  locked, // signed in, waiting for fingerprint (the "gate")
  unlocked, // inside the app
}

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  AuthProvider({
    required AuthService authService,
    required BiometricService biometricService,
  })  : _authService = authService,
        _biometric = biometricService {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  // auto app lock for inactivity - background time 30s
  static const Duration _relockAfter = Duration(seconds: 30);

  final AuthService _authService;
  final BiometricService _biometric;

  StreamSubscription<User?>? _subscription;
  AuthStatus _status = AuthStatus.loading;
  bool _busy = false; // an explicit sign-in/sign-up is running
  bool _biometricEnabled = false;
  DateTime? _pausedAt;

  AuthStatus get status => _status;
  User? get user => _authService.currentUser;

  String get displayName {
    final u = user;
    if (u?.displayName != null && u!.displayName!.isNotEmpty) {
      return u.displayName!;
    }
    return u?.email?.split('@').first ?? 'there';
  }



  Future<void> signIn(String identifier, String password) => _runAuthAction(
        () => _authService.signInWithIdentifier(
        identifier: identifier, password: password),
  );

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
  }) =>
      _runAuthAction(
            () => _authService.signUp(
            email: email, username: username, password: password),
      );

  // Returns false when the user dismissed the Google picker.
  Future<bool> signInWithGoogle() async {
    var completed = false;
    await _runAuthAction(() async {
      completed = await _authService.signInWithGoogle();
    });
    return completed;
  }

  Future<void> resetPassword(String email) =>
      _authService.sendPasswordReset(email);

  Future<void> signOut() async {
    await _authService.signOut();
    _biometricEnabled = false;
    _setStatus(AuthStatus.signedOut);
  }

  //biometrics

  Future<bool> isBiometricSupported() => _biometric.isDeviceSupported();

  // "Register fingerprint": confirms the user's fingerprint once, then turns
  // biometric unlock on for this account on this phone.
  Future<BiometricResult> registerBiometrics() async {
    final uid = user?.uid;
    if (uid == null) return BiometricResult.error;

    final result = await _biometric.authenticate(
      reason: 'Confirm your fingerprint to enable biometric unlock',
    );
    if (result == BiometricResult.success) {
      await _biometric.setEnabled(uid, true);
      _biometricEnabled = true;
      _setStatus(AuthStatus.unlocked);
    }
    return result;
  }

  // Only for phones with no fingerprint. Applies to this session only
  void skipBiometricSetup() => _setStatus(AuthStatus.unlocked);

  Future<BiometricResult> unlockWithBiometrics() async {
    final result = await _biometric.authenticate(
      reason: 'Unlock Asia Asset Finance',
    );
    if (result == BiometricResult.success) _setStatus(AuthStatus.unlocked);
    return result;
  }


  // Runs a credentials-based action, then decides the next screen.
  Future<void> _runAuthAction(Future<void> Function() action) async {
    _busy = true;
    try {
      await action();
      final u = _authService.currentUser;
      if (u == null) {
        _setStatus(AuthStatus.signedOut);
        return;
      }
      // Just proved who they are with credentials, so no lock screen now.
      _biometricEnabled = await _biometric.isEnabledFor(u.uid);
      _setStatus(_biometricEnabled
          ? AuthStatus.unlocked
          : AuthStatus.needsBiometricSetup);
    } finally {
      _busy = false;
    }
  }

  // Handles app start (saved session) and sign-outs from elsewhere.
  Future<void> _onAuthChanged(User? user) async {
    if (_busy) return; // _runAuthAction decides the status itself
    if (user == null) {
      _setStatus(AuthStatus.signedOut);
      return;
    }
    if (_status == AuthStatus.unlocked) return; // already inside

    _biometricEnabled = await _biometric.isEnabledFor(user.uid);
    // Saved session: fingerprint gate if registered, otherwise registration.
    _setStatus(_biometricEnabled
        ? AuthStatus.locked
        : AuthStatus.needsBiometricSetup);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (_status == AuthStatus.unlocked &&
          _biometricEnabled &&
          pausedAt != null &&
          DateTime.now().difference(pausedAt) > _relockAfter) {
        _setStatus(AuthStatus.locked);
      }
    }
  }

  void _setStatus(AuthStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}