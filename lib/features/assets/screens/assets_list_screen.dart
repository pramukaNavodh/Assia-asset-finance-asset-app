// the ui which represent assets as list

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/remote_image.dart';
import '../../../core/widgets/skeleton.dart';
import '../../dashboard/models/asset_model.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/branch_selector.dart';
import 'asset_detail_screen.dart';

//filter types
enum _Sort { newest, oldest, priceHigh, priceLow, name }

//sort options
extension on _Sort {
  String get label => switch (this) {
    _Sort.newest => 'Newest first',
    _Sort.oldest => 'Oldest first',
    _Sort.priceHigh => 'Price: high to low',
    _Sort.priceLow => 'Price: low to high',
    _Sort.name => 'Name (A-Z)',
  };

  int compare(Asset a, Asset b) => switch (this) {
    _Sort.newest => b.dateObtained.compareTo(a.dateObtained),
    _Sort.oldest => a.dateObtained.compareTo(b.dateObtained),
    _Sort.priceHigh => b.price.compareTo(a.price),
    _Sort.priceLow => a.price.compareTo(b.price),
    _Sort.name => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };
}

// the "Assets" tab: search, branch + category filters, sorting, asset cards.
class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key, required this.onAddAsset});

  final VoidCallback onAddAsset;

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _branchId;
  AssetCategory? _category;
  _Sort _sort = _Sort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Asset> _apply(List<Asset> all) {
    final list = all.where((a) {
      if (_branchId != null && a.branchId != _branchId) return false;
      if (_category != null && a.category != _category) return false;
      if (_query.isEmpty) return true;
      final branch = Branches.byId(a.branchId)?.name.toLowerCase() ?? '';
      return a.title.toLowerCase().contains(_query) ||
          a.category.label.toLowerCase().contains(_query) ||
          branch.contains(_query) ||
          (a.serialNumber ?? '').toLowerCase().contains(_query) ||
          (a.numberPlate ?? '').toLowerCase().contains(_query);
    }).toList();
    list.sort(_sort.compare);
    return list;
  }

  void _clearFilters() => setState(() {
    _branchId = null;
    _category = null;
    _query = '';
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final all = p.allAssets;
    final list = _apply(all);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Assets',
                          style: TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    PopupMenuButton<_Sort>(
                      tooltip: 'Sort',
                      icon: const Icon(Icons.sort_rounded, color: Colors.white),
                      initialValue: _sort,
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => [
                        for (final s in _Sort.values)
                          PopupMenuItem(value: s, child: Text(s.label)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search title, serial, plate, branch',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => setState(() {
                        _query = '';
                        _search.clear();
                      }),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BranchSelector(
            selectedId: _branchId,
            onSelected: (id) => setState(() => _branchId = id),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _typeChip('All types', null),
                for (final c in AssetCategory.values) _typeChip(c.label, c),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                Text(
                  '${list.length} of ${all.length} assets · ${Formatters.currencyCompact(list.fold<double>(0, (s, a) => s + a.price))}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(child: _body(p, all, list)),
        ],
      ),
    );
  }

  Widget _typeChip(String label, AssetCategory? category) {
    final selected = _category == category;
    final color = category?.color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _category = category),
        selectedColor: color.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? color : AppColors.textPrimary,
        ),
        side: BorderSide(color: selected ? color : AppColors.border),
        showCheckmark: false,
      ),
    );
  }

  Widget _body(DashboardProvider p, List<Asset> all, List<Asset> list) {
    if (p.status == DashboardStatus.loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 110, radius: 20),
            ),
        ],
      );
    }
    if (p.status == DashboardStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: p.load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      final noAssets = all.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(noAssets ? Icons.inventory_2_outlined : Icons.search_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(noAssets ? 'No assets yet' : 'No assets match your filters',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                noAssets
                    ? 'Add the first company asset to get started.'
                    : 'Try a different branch, type or search.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              if (noAssets)
                SizedBox(
                  width: 200,
                  child: PrimaryButton(label: 'Add asset', icon: Icons.add_rounded, onPressed: widget.onAddAsset),
                )
              else
                OutlinedButton(onPressed: _clearFilters, child: const Text('Clear filters')),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _AssetCard(asset: list[i]),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final branch = Branches.byId(asset.branchId)?.name ?? 'Unknown branch';
    final photo = asset.imageUrls.isEmpty ? null : asset.imageUrls.first;
    final depreciated = asset.depreciationMethod != DepreciationMethod.none;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openAssetDetail(context, asset.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(width: 86, height: 86, child: RemoteImage(photo, radius: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: asset.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(asset.category.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: asset.category.color)),
                      ),
                      const SizedBox(height: 6),
                      Text(asset.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('$branch · ${Formatters.shortDate(asset.dateObtained)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(
                        depreciated
                            ? '${Formatters.currencyCompact(asset.price)}  ·  now ${Formatters.currencyCompact(asset.currentValue)}'
                            : Formatters.currencyCompact(asset.price),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
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