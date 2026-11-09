//edit profile for changing basic profile info

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../core/utils/validators.dart';
import '../../core/widgets/app_form_fields.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/skeleton.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final profile = await auth.loadProfile();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = profile?.displayName ?? auth.displayName;
      _usernameCtrl.text = profile?.username ?? '';
      _email = profile?.email ?? auth.user?.email ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await auth.updateProfile(
        displayName: _nameCtrl.text,
        username: auth.isPasswordAccount ? _usernameCtrl.text : null,
      );
      if (!mounted) return;
      AppSnackBar.show(context, 'Profile updated.');
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
    final isPasswordAccount = context.read<AuthProvider>().isPasswordAccount;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          title: 'Your details',
          child: _loading
              ? const Column(children: [
            SkeletonBox(height: 58, radius: 16),
            SizedBox(height: 14),
            SkeletonBox(height: 58, radius: 16),
            SizedBox(height: 14),
            SkeletonBox(height: 58, radius: 16),
          ])
              : Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Full name',
                  icon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v, 'Name'),
                ),
                const SizedBox(height: 14),
                if (isPasswordAccount) ...[
                  AppTextField(
                    controller: _usernameCtrl,
                    label: 'Username',
                    icon: Icons.alternate_email,
                    textInputAction: TextInputAction.done,
                    validator: Validators.username,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  initialValue: _email,
                  enabled: false,
                  decoration: appInputDecoration(
                      label: 'Email (cannot be changed)', icon: Icons.mail_outline),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}