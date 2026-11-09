//the preview layout for asset data

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/asset_model.dart';
import '../models/branch_model.dart';
import 'category_badge.dart';
import '../../assets/screens/asset_detail_screen.dart';
import '../../../core/widgets/primary_button.dart';

//Quick look at an asset
void showAssetPreview(BuildContext context, Asset asset) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(category: asset.category, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  asset.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow('Category', asset.category.label),
          _InfoRow('Branch', Branches.byId(asset.branchId)?.name ?? 'Unknown'),
          _InfoRow('Value', Formatters.currencyFull(asset.price)),
          _InfoRow('Acquired', Formatters.shortDate(asset.dateObtained)),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'View full details',
            icon: Icons.open_in_new_rounded,
            onPressed: () {
              Navigator.pop(sheetContext);
              openAssetDetail(context, asset.id); // outer context has the providers
            },
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}