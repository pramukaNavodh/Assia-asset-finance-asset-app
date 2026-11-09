// Input formatters shared by money / whole-number fields.

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//internal resource files
import '../theme/app_colors.dart';
import '../utils/formatters.dart';


final amountFormatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
final digitsFormatters = [FilteringTextInputFormatter.digitsOnly];

OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: BorderSide(color: color, width: width),
);

// Same look as AppTextField, for dropdowns, date pickers and read-only fields.
InputDecoration appInputDecoration({
  required String label,
  IconData? icon,
  String? hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    prefixIcon:
    icon == null ? null : Icon(icon, size: 20, color: AppColors.textMuted),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: _border(Colors.transparent),
    enabledBorder: _border(Colors.transparent),
    disabledBorder: _border(Colors.transparent),
    focusedBorder: _border(AppColors.primary, 1.5),
    errorBorder: _border(AppColors.error),
    focusedErrorBorder: _border(AppColors.error, 1.5),
  );
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: appInputDecoration(label: label, icon: icon),
    );
  }
}

/// Tap-to-pick date field that works inside a Form (validates when required).
class AppDateField extends FormField<DateTime> {
  AppDateField({
    super.key,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    required DateTime firstDate,
    required DateTime lastDate,
    bool isRequired = false,
    IconData icon = Icons.event_outlined,
  }) : super(
    initialValue: value,
    validator: (v) => isRequired && v == null ? '$label is required' : null,
    builder: (state) {
      final current = state.value;

      Future<void> pick() async {
        var initial = current ?? DateTime.now();
        if (initial.isAfter(lastDate)) initial = lastDate;
        if (initial.isBefore(firstDate)) initial = firstDate;
        final picked = await showDatePicker(
          context: state.context,
          initialDate: initial,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) {
          state.didChange(picked);
          onChanged(picked);
        }
      }

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pick,
        child: InputDecorator(
          isEmpty: current == null,
          decoration: appInputDecoration(
            label: label,
            icon: icon,
            errorText: state.errorText,
            suffixIcon: current != null && !isRequired
                ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                state.didChange(null);
                onChanged(null);
              },
            )
                : const Icon(Icons.calendar_month_outlined, size: 18),
          ),
          child: Text(current == null ? '' : Formatters.shortDate(current)),
        ),
      );
    },
  );
}