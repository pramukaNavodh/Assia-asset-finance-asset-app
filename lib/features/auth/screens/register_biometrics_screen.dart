//to register biometrics

//libraris
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

//internal resources and uis
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/pulsing_fingerprint.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';

class RegisterBiometricsScreen extends StatefulWidget {
  const RegisterBiometricsScreen({super.key});

  @override
  State<RegisterBiometricsScreen> createState() =>
      _RegisterBiometricsScreenState();
}

class _RegisterBiometricsScreenState extends State<RegisterBiometricsScreen> {
  bool _loading = false;
  bool? _supported; // null while we check the phone

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final ok = await context.read<AuthProvider>().isBiometricSupported();
    if (mounted) setState(() => _supported = ok);
  }

  Future<void> _recheck() async {
    setState(() => _supported = null);
    await _checkSupport();
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    final result = await context.read<AuthProvider>().registerBiometrics();
    if (!mounted) return; // success: AuthGate has already moved on
    setState(() => _loading = false);

    switch (result) {
      case BiometricResult.success:
        break;
      case BiometricResult.cancelled:
        AppSnackBar.show(context, 'Fingerprint not confirmed. Please try again.',
            isError: true);
      case BiometricResult.notAvailable:
      case BiometricResult.notEnrolled:
        setState(() => _supported = false);
      case BiometricResult.lockedOut:
        AppSnackBar.show(
            context, 'Too many attempts. Wait a moment and try again.',
            isError: true);
      case BiometricResult.error:
        AppSnackBar.show(context, 'Something went wrong. Please try again.',
            isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.read<AuthProvider>().signOut(),
                      child: const Text('Sign out',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const PulsingFingerprint(size: 220),
                  const SizedBox(height: 24),
                  Text(
                    'Secure your account',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Register your fingerprint so only you can open your company assets next time.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  const _BenefitsCard(),
                  const SizedBox(height: 28),
                  if (_supported == false) ...[
                    const _NoBiometricsNotice(),
                    const SizedBox(height: 16),
                    PrimaryButton(label: 'Check again', onPressed: _recheck),
                    TextButton(
                      onPressed: () =>
                          context.read<AuthProvider>().skipBiometricSetup(),
                      child: const Text('Skip for now',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ] else
                    PrimaryButton(
                      label: 'Register fingerprint',
                      icon: Icons.fingerprint,
                      isLoading: _loading || _supported == null,
                      onPressed: _register,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          _BenefitRow(
              icon: Icons.verified_user_outlined,
              text: 'Only you can open the app'),
          _BenefitRow(
              icon: Icons.phonelink_lock_outlined,
              text: 'Your fingerprint never leaves this phone'),
          _BenefitRow(
              icon: Icons.bolt_outlined, text: 'Unlock in a second, every time'),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _NoBiometricsNotice extends StatelessWidget {
  const _NoBiometricsNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No fingerprint is set up on this phone. Add one in Settings > Security, then tap "Check again".',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}