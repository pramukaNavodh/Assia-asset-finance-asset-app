//button conf

//libraries
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//internal asset file
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.primaryDark,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
          GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
            key: ValueKey('loading'),
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryDark,
            ),
          )
              : Row(
            key: const ValueKey('label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22),
                const SizedBox(width: 10),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}