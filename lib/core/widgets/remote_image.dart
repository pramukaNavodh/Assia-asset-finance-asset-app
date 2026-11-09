// network image with a soft placeholder while loading and on errors

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../theme/app_colors.dart';


class RemoteImage extends StatelessWidget {
  const RemoteImage(this.url, {super.key, this.fit = BoxFit.cover, this.radius = 0});

  final String? url;
  final BoxFit fit;
  final double radius;

  static const _placeholder = ColoredBox(
    color: AppColors.fieldFill,
    child: Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted)),
  );

  @override
  Widget build(BuildContext context) {
    final link = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (link == null || link.isEmpty)
          ? _placeholder
          : Image.network(
        link,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) =>
        progress == null ? child : const ColoredBox(color: AppColors.fieldFill),
        errorBuilder: (_, __, ___) => _placeholder,
      ),
    );
  }
}