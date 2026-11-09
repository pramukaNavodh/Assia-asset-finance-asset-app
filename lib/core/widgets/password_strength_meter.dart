// UX feature for indicating password strength

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const _labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    AppColors.error,
    AppColors.error,
    AppColors.accent,
    AppColors.success,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
  //color based indicator conf
    final score = Validators.passwordStrength(password);
    final color = _colors[score];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i < score ? color : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _labels[score],
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}