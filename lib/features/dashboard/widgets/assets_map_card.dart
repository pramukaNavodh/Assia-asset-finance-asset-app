//the mapview for showing branches

//libraries
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

//internal resource files
import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/safe_asset_image.dart';
import '../models/asset_model.dart';

class AssetsMapCard extends StatefulWidget {
  const AssetsMapCard({
    super.key,
    required this.assets,
    required this.onMarkerTap,
  });

  final List<Asset> assets;
  final ValueChanged<Asset> onMarkerTap;

  @override
  State<AssetsMapCard> createState() => _AssetsMapCardState();
}

class _AssetsMapCardState extends State<AssetsMapCard> {
  static const _sriLankaCenter = LatLng(7.8731, 80.7718);

  final _controller = MapController();
  bool _ready = false;
  String _lastKey = '';

  List<Asset> get _located =>
      widget.assets.where((a) => a.hasLocation).toList();

  String _keyOf(List<Asset> assets) => assets.map((a) => a.id).join(',');

  @override
  void didUpdateWidget(covariant AssetsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_keyOf(_located) != _lastKey) {
      // Move the camera after this frame (not during build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitCamera();
      });
    }
  }

  //Zoom the map to every visible asset fits on screen
  void _fitCamera() {
    if (!_ready) return;
    final located = _located;
    _lastKey = _keyOf(located);
    final points =
    located.map((a) => LatLng(a.latitude!, a.longitude!)).toList();

    if (points.isEmpty) {
      _controller.move(_sriLankaCenter, 7);
    } else if (points.length == 1) {
      _controller.move(points.first, 14);
    } else {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
          maxZoom: 15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = _located;

    return SectionCard(
      title: 'Assets on map',
      trailing: Text('${located.length} located',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _sriLankaCenter,
              initialZoom: 7,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _ready = true;
                _fitCamera();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: AppConfig.mapUserAgentPackage,
              ),
              MarkerLayer(
                markers: [
                  for (final asset in located)
                    Marker(
                      point: LatLng(asset.latitude!, asset.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => widget.onMarkerTap(asset),
                        child: _MapPin(category: asset.category),
                      ),
                    ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.category});

  final AssetCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: category.color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: SafeAssetImage(
          category.iconPath,
          size: 18,
          color: Colors.white,
          fallbackIcon: category.fallbackIcon,
        ),
      ),
    );
  }
}