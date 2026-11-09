//sign in ui

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files amd uis
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/social_auth_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _emailLoading = false;
  bool _googleLoading = false;

  bool get _busy => _emailLoading || _googleLoading;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() => _emailLoading = true);
    try {
      await auth.signIn(_identifierCtrl.text, _passwordCtrl.text);
    } on AuthFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Something went wrong. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() => _googleLoading = true);
    try {
      await auth.signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Something went wrong. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final auth = context.read<AuthProvider>();
    final emailCtrl = TextEditingController(
      text: _identifierCtrl.text.contains('@') ? _identifierCtrl.text.trim() : '',
    );

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your account email and we will send you a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'name@company.com'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (email == null || !mounted) return; // cancelled
    if (Validators.email(email) != null) {
      AppSnackBar.show(context, 'Enter a valid email address.', isError: true);
      return;
    }

    try {
      await auth.resetPassword(email);
      if (mounted) {
        AppSnackBar.show(
            context, 'If that email has an account, a reset link is on its way.');
      }
    } on AuthFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    }
  }
//layout
  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to manage your company assets.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _identifierCtrl,
              label: 'Username or email',
              icon: Icons.person_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (v) => Validators.notEmpty(v, 'Username or email'),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) => Validators.notEmpty(v, 'Password'),
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Sign in',
              isLoading: _emailLoading,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 22),
            const OrDivider(),
            const SizedBox(height: 22),
            GoogleButton(
              isLoading: _googleLoading,
              onPressed: _busy ? null : _googleSignIn,
            ),
            const SizedBox(height: 24),
            //direct for signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?",
                    style: TextStyle(color: AppColors.textMuted)),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text('Sign up',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}