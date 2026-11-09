//the major asset detail ui

//libraries
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/remote_image.dart';
import '../../../core/widgets/section_card.dart';
import '../../dashboard/data/asset_repository.dart';
import '../../dashboard/models/asset_model.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'add_asset_screen.dart';

//opens the detail page. Pushed pages sit above the providers, so hand them over.
Future<void> openAssetDetail(BuildContext context, String assetId) {
  final dashboard = context.read<DashboardProvider>();
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: dashboard,
        child: AssetDetailScreen(assetId: assetId),
      ),
    ),
  );
}

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  Future<void> _edit(BuildContext context, Asset asset) async {
    final dashboard = context.read<DashboardProvider>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: dashboard,
          child: AddAssetScreen(initial: asset),
        ),
      ),
    );
    if (saved == true && context.mounted) AppSnackBar.show(context, 'Changes saved.');
  }

  Future<void> _delete(BuildContext context, Asset asset) async {
    final dashboard = context.read<DashboardProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete this asset?'),
        content: Text('"${asset.title}" and its photos will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dashboard.deleteAsset(asset);
      if (!context.mounted) return;
      AppSnackBar.show(context, 'Asset deleted.');
      Navigator.of(context).pop();
    } on AssetSaveFailure catch (e) {
      if (context.mounted) AppSnackBar.show(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = context.select<DashboardProvider, Asset?>((p) => p.assetById(assetId));
    if (asset == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('This asset is no longer available.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final branch = Branches.byId(asset.branchId);
    final style = IconButton.styleFrom(
        backgroundColor: Colors.black38, foregroundColor: Colors.white);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(asset.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Edit',
                style: style,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, asset),
              ),
              IconButton(
                tooltip: 'Delete',
                style: style,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, asset),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Gallery(urls: asset.imageUrls, category: asset.category),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(asset.category.label, asset.category.color),
                      _Pill(branch?.name ?? 'Unknown branch', AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ValuationCard(asset: asset),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Overview',
                    child: _rows([
                      ('Description', asset.description),
                      ('Category', asset.category.label),
                      ('Branch', branch?.name),
                      ('Date obtained', Formatters.shortDate(asset.dateObtained)),
                    ]),
                  ),
                  if (asset.depreciationMethod != DepreciationMethod.none) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Depreciation',
                      child: _rows([
                        ('Method', asset.depreciationMethod.label),
                        ('Useful life', asset.usefulLifeYears == null ? null : '${asset.usefulLifeYears} years'),
                        ('Salvage value', Formatters.currencyFull(asset.salvageValue)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Warranty',
                    child: (asset.warrantyExpiry == null && asset.warrantyProvider == null)
                        ? const Text('No warranty recorded.',
                        style: TextStyle(color: AppColors.textMuted))
                        : Column(children: [
                      _rows([
                        ('Provider', asset.warrantyProvider),
                        ('Notes', asset.warrantyNotes),
                      ]),
                      if (asset.warrantyExpiry != null)
                        _ExpiryRow('Expires', asset.warrantyExpiry!),
                    ]),
                  ),
                  if (asset.category.isDevice) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Device details',
                      child: _rows([
                        ('Serial number', asset.serialNumber),
                        ('Manufacturer', asset.manufacturer),
                        ('Additional info', asset.additionalInfo),
                      ]),
                    ),
                  ],
                  if (asset.category == AssetCategory.vehicle) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Vehicle details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rows([
                            ('Number plate', asset.numberPlate),
                            ('Insurer', asset.insuranceProvider),
                            ('Policy number', asset.insurancePolicyNumber),
                          ]),
                          if (asset.insuranceExpiry != null)
                            _ExpiryRow('Insurance expires', asset.insuranceExpiry!),
                          const SizedBox(height: 14),
                          const Text('Service records',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (asset.serviceRecords.isEmpty)
                            const Text('No service records.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                          else
                            for (final r in ([...asset.serviceRecords]
                              ..sort((a, b) => b.date.compareTo(a.date))))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.build_circle_outlined,
                                        size: 20, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${r.description}\n${Formatters.shortDate(r.date)}',
                                        style: const TextStyle(fontSize: 13, height: 1.4),
                                      ),
                                    ),
                                    if (r.cost > 0)
                                      Text(Formatters.currencyFull(r.cost),
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  if (asset.hasLocation) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Location',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              height: 200,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(asset.latitude!, asset.longitude!),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: AppConfig.mapUserAgentPackage,
                                  ),
                                  MarkerLayer(markers: [
                                    Marker(
                                      point: LatLng(asset.latitude!, asset.longitude!),
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(Icons.location_on,
                                          color: AppColors.error, size: 40),
                                    ),
                                  ]),
                                  const SimpleAttributionWidget(
                                      source: Text('© OpenStreetMap contributors')),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${asset.latitude!.toStringAsFixed(5)}, ${asset.longitude!.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Label/value rows; rows with no value are skipped.
  Widget _rows(List<(String, String?)> rows) => Column(
    children: [
      for (final (label, value) in rows)
        if (value != null && value.isNotEmpty) _InfoRow(label, value),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    ),
  );
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow(this.label, this.date);

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final days = date.difference(DateTime.now()).inDays;
    final (status, color) = days < 0
        ? ('Expired', AppColors.error)
        : days <= 30
        ? ('Due in $days days', const Color(0xFFB77900))
        : ('Active', AppColors.success);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Text(Formatters.shortDate(date),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 8),
          _Pill(status, color),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final depreciated = asset.depreciationMethod != DepreciationMethod.none;
    final remaining = asset.price <= 0 ? 0.0 : (asset.currentValue / asset.price).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _money('Purchase price', asset.price, Colors.white)),
              Expanded(
                child: _money('Current value', asset.currentValue, AppColors.accent),
              ),
            ],
          ),
          if (depreciated) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: remaining,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.white24,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            Text('${(remaining * 100).round()}% of the original value remains',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _money(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(Formatters.currencyCompact(value),
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
    ],
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls, required this.category});

  final List<String> urls;
  final AssetCategory category;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  void _openViewer(int start) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: start),
              itemCount: widget.urls.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(child: Image.network(widget.urls[i], fit: BoxFit.contain)),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (urls.isEmpty)
          ColoredBox(
            color: widget.category.color.withValues(alpha: 0.15),
            child: Center(
              child: Icon(widget.category.fallbackIcon, size: 72, color: widget.category.color),
            ),
          )
        else
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openViewer(i),
              child: RemoteImage(urls[i]),
            ),
          ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 110,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: i == _page ? 20 : 7,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}