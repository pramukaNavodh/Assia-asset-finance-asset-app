//snackbar conf

//libraries
import 'package:flutter/material.dart';

//internal asset file
import '../theme/app_colors.dart';

class AppSnackBar {
  AppSnackBar._();

  static void show(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        //snackbar style conf
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: isError ? AppColors.error : AppColors.primaryDark,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}