//AR based scan feature for assets. Tried to implement.
//cannot deliver within the deadline.

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../theme/app_colors.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.showAppBar = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Icon(icon, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}