//custom conf for text fields and other inputs

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//internal color asset file
import '../theme/app_colors.dart';

// Rounded and show hide passwords
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.isPassword = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      autocorrect: false,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      enableSuggestions: !widget.isPassword,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textMuted),
        suffixIcon: widget.isPassword
            ? IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),
    );
  }
}