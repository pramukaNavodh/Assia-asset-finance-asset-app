//the view to show recently added assets in the dashboard

//libraries
import 'package:flutter/material.dart';

//internal resource files
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../../assets/screens/asset_detail_screen.dart';
import '../models/asset_model.dart';
import '../models/branch_model.dart';
import 'asset_preview_sheet.dart';
import 'category_badge.dart';

class RecentAssetsList extends StatelessWidget {
  const RecentAssetsList({
    super.key,
    required this.assets,
    required this.isSearching,
    required this.onSeeAll,
  });

  final List<Asset> assets; // already sorted newest first
  final bool isSearching;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final shown = assets.take(isSearching ? 10 : 5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isSearching ? 'Results (${assets.length})' : 'Recently added',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (!isSearching)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          const _EmptyState()
        else
          for (final asset in shown) _AssetTile(asset: asset),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final branch = Branches.byId(asset.branchId)?.name ?? 'Unknown branch';

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => openAssetDetail(context, asset.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CategoryBadge(category: asset.category, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            '$branch · ${Formatters.shortDate(asset.dateObtained)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.currencyCompact(asset.price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
    }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            SafeAssetImage(AppAssets.emptyState,
                size: 96, fallbackIcon: Icons.search_off_rounded),
            SizedBox(height: 12),
            Text('No assets found',
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Try another branch or search term.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}