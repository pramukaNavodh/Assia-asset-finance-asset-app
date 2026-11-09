//profile ui

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/settings_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/services/auth_service.dart';
import '../auth/services/biometric_service.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _reRegister(BuildContext context) async {
    final result = await context.read<AuthProvider>().reRegisterBiometrics();
    if (!context.mounted) return;
    switch (result) {
      case BiometricResult.success:
        AppSnackBar.show(context, 'Fingerprint unlock refreshed.');
      case BiometricResult.cancelled:
        AppSnackBar.show(context, 'Fingerprint not confirmed.', isError: true);
      case BiometricResult.notAvailable:
      case BiometricResult.notEnrolled:
        AppSnackBar.show(context, 'Add a fingerprint in your phone settings first.',
            isError: true);
      case BiometricResult.lockedOut:
        AppSnackBar.show(context, 'Too many attempts. Try again shortly.', isError: true);
      case BiometricResult.error:
        AppSnackBar.show(context, 'Something went wrong. Please try again.',
            isError: true);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign out?'),
        content: const Text('You will need your username and password (or Google) to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.displayName;
    final photo = auth.photoUrl;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.accent,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  onBackgroundImageError: photo != null ? (_, __) {} : null,
                  child: photo == null
                      ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 34,
                          fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(height: 14),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    auth.isPasswordAccount ? 'Email account' : 'Google account',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                SettingsGroup(title: 'Account', children: [
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit profile',
                    subtitle: 'Name and username',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  ),
                ]),
                const SizedBox(height: 20),
                SettingsGroup(title: 'Security', children: [
                  SettingsTile(
                    icon: Icons.fingerprint,
                    color: AppColors.success,
                    title: 'Biometric unlock',
                    subtitle: auth.biometricEnabled
                        ? 'Fingerprint registered on this phone. Tap to refresh.'
                        : 'Not registered on this phone',
                    onTap: () => _reRegister(context),
                  ),
                  if (auth.isPasswordAccount)
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change password',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen())),
                    ),
                  SettingsTile(
                    icon: Icons.screen_lock_portrait_outlined,
                    title: 'Lock app now',
                    subtitle: 'Ask for your fingerprint again',
                    onTap: auth.lockNow,
                  ),
                ]),
                const SizedBox(height: 20),
                SettingsGroup(title: 'Session', children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    onTap: () => _confirmSignOut(context),
                  ),
                  SettingsTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete account',
                    subtitle: 'Permanently remove your account',
                    isDestructive: true,
                    onTap: () => showDialog<void>(
                        context: context, builder: (_) => const _DeleteAccountDialog()),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().deleteAccount(password: _password.text);
      if (mounted) Navigator.of(context).pop();
    } on AuthFailure catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Something went wrong. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsPassword = context.read<AuthProvider>().isPasswordAccount;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently removes your account and sign-in details. Assets you added stay in the company records.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          if (needsPassword)
            AppTextField(
              controller: _password,
              label: 'Confirm your password',
              icon: Icons.lock_outline,
              isPassword: true,
            )
          else
            const Text('You will be asked to confirm with Google.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _loading
              ? const SizedBox(
              height: 18, width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Delete'),
        ),
      ],
    );
  }
}