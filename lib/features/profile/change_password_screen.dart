//profile password change ui

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/password_strength_meter.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_card.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.changePassword(currentPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      AppSnackBar.show(context, 'Password changed.');
      Navigator.of(context).pop();
    } on AuthFailure catch (e) {
      if (mounted) AppSnackBar.show(context, e.message, isError: true);
    } catch (_) {
      if (mounted) AppSnackBar.show(context, 'Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          title: 'Update your password',
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _current,
                  label: 'Current password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v, 'Current password'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _new,
                  label: 'New password',
                  icon: Icons.lock_reset_outlined,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                  v == _current.text ? 'Choose a different password' : Validators.password(v),
                ),
                PasswordStrengthMeter(password: _new.text),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  icon: Icons.check_circle_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _new.text),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Update password', isLoading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}