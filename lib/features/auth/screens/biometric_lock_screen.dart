// the default fingerprint screen showing for the everytime after the first signup

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

//internal resource files and uis
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pulsing_fingerprint.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';

//handles by the auth gate
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Prompt automatically once the screen is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    setState(() {
      _authenticating = true;
      _message = null;
    });

    final result = await context.read<AuthProvider>().unlockWithBiometrics();
    if (!mounted) return; // success: AuthGate has moved on

    setState(() {
      _authenticating = false;
      _message = _messageFor(result);
    });
  }

  String? _messageFor(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return null;
      case BiometricResult.cancelled:
        return 'Tap the fingerprint to try again.';
      case BiometricResult.lockedOut:
        return 'Too many attempts. Wait a moment, or sign in with your password.';
      case BiometricResult.notAvailable:
      case BiometricResult.notEnrolled:
        return 'Fingerprint unlock is not available on this phone right now. Sign in with your password instead.';
      case BiometricResult.error:
        return 'We could not verify you. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((p) => p.displayName);
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    height: 72,
                    width: 72,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SafeAssetImage(
                      AppAssets.logo,
                      fallbackIcon: Icons.account_balance,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Welcome back,',
                      style: textTheme.bodyLarge
                          ?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  PulsingFingerprint(
                    size: 200,
                    onTap: _authenticating ? null : _unlock,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _message ?? 'Touch the sensor to unlock',
                      key: ValueKey(_message),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message == null
                            ? Colors.white70
                            : AppColors.accent,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  TextButton(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    child: const Text(
                      'Not you? Sign in with password',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}