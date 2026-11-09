//support class for holding icon for categories

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../../../core/widgets/safe_asset_image.dart';
import '../models/asset_model.dart';


class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 44});

  final AssetCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: SafeAssetImage(
          category.iconPath,
          size: size * 0.5,
          color: category.color,
          fallbackIcon: category.fallbackIcon,
        ),
      ),
    );
  }
}