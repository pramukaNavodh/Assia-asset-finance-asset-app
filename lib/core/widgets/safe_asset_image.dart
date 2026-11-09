//image fallback strategy

//library
import 'package:flutter/material.dart';

//internal asset file
import '../theme/app_colors.dart';

// Pass [color] to tint single-colour icons
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage(
      this.path, {
        super.key,
        this.size,
        this.color,
        this.fallbackIcon = Icons.image_outlined,
      });

  final String path;
  final double? size;
  final Color? color;
  final IconData fallbackIcon;

  //placeholder
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: size,
      height: size,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(fallbackIcon, size: size, color: color ?? AppColors.primary),
    );
  }
}