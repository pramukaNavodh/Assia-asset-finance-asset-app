//signup ui

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files and uis
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      await auth.signUp(
        email: _emailCtrl.text,
        username: _usernameCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      // AuthGate underneath is already showing "Register fingerprint";
      // close this screen to reveal it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Something went wrong. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'Create your account',
      subtitle: 'Takes less than a minute. Next, you will secure it with your fingerprint.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _emailCtrl,
              label: 'Email address',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onSubmitted: (_) => _usernameFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _usernameCtrl,
              focusNode: _usernameFocus,
              label: 'Username',
              icon: Icons.alternate_email,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              validator: Validators.username,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
              onChanged: (_) => setState(() {}), // refresh strength meter
              onSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            PasswordStrengthMeter(password: _passwordCtrl.text),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              label: 'Confirm password',
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordCtrl.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              isLoading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}