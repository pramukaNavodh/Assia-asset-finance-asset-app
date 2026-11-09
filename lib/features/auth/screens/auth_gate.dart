//centralized auth ui management
//reason - I got multiple errors when handling user UI providing even though
//         used go router. so to resolve that error, this strat applied

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal UIs
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../../home/home_placeholder_screen.dart';
import '../providers/auth_provider.dart';
import 'biometric_lock_screen.dart';
import 'register_biometrics_screen.dart';
import 'sign_in_screen.dart';

// decides which screen to show based on authStatus.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    final Widget page = switch (status) {
      AuthStatus.loading => const _SplashScreen(key: ValueKey('splash')),
      AuthStatus.signedOut => const SignInScreen(key: ValueKey('sign-in')),
      AuthStatus.needsBiometricSetup =>
      const RegisterBiometricsScreen(key: ValueKey('register-bio')),
      AuthStatus.locked => const BiometricLockScreen(key: ValueKey('lock')),
      AuthStatus.unlocked =>
      const HomePlaceholderScreen(key: ValueKey('home')),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: page,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 96,
                width: 96,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const SafeAssetImage(
                  AppAssets.logo,
                  fallbackIcon: Icons.account_balance,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}