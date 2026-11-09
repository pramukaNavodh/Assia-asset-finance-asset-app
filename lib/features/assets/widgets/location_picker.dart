//support class for picking locations

//libraries
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

//internal resource files
import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

const kSriLankaCenter = LatLng(7.8731, 80.7718);
const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

// small map preview that opens the full-screen picker.
class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.location,
    required this.onChanged,
    this.branchPoint,
    this.branchName,
    this.showError = false,
  });

  final LatLng? location;
  final ValueChanged<LatLng> onChanged;
  final LatLng? branchPoint; // where the picker opens when nothing is chosen
  final String? branchName;
  final bool showError;

  Future<void> _open(BuildContext context) async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: location ?? branchPoint ?? kSriLankaCenter,
          branchPoint: branchPoint,
          branchName: branchName,
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = location;
    return GestureDetector(
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 150,
              child: loc == null
                  ? Container(
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: showError ? AppColors.error : AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_location_alt_outlined,
                        size: 36, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('Tap to pin the asset location',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
                  : IgnorePointer(
                child: FlutterMap(
                  key: ValueKey(loc),
                  options: MapOptions(initialCenter: loc, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: AppConfig.mapUserAgentPackage,
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: loc,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on,
                            color: AppColors.error, size: 40),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc == null
                      ? (showError ? 'Please pin the location' : 'No location chosen')
                      : '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: showError && loc == null ? AppColors.error : AppColors.textMuted),
                ),
              ),
              if (loc != null)
                const Text('Change',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// the pin stays in the middle, user has to move the map under it.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initial,
    this.branchPoint,
    this.branchName,
  });

  final LatLng initial;
  final LatLng? branchPoint;
  final String? branchName;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = MapController();
  late final ValueNotifier<LatLng> _center = ValueNotifier(widget.initial);

  @override
  void dispose() {
    _center.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = widget.initial == kSriLankaCenter ? 7.0 : 15.0;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) {
                // Deferred so it never fires while the map is still building.
                Future.microtask(() {
                  if (mounted) _center.value = camera.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: AppConfig.mapUserAgentPackage,
              ),
              const SimpleAttributionWidget(source: Text('© OpenStreetMap contributors')),
            ],
          ),
          // Fixed pin: its tip sits on the exact centre of the map.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(Icons.location_on, size: 44, color: AppColors.error),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Move the map to place the pin',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    ValueListenableBuilder<LatLng>(
                      valueListenable: _center,
                      builder: (_, c, __) => Text(
                        '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                    if (widget.branchPoint != null)
                      TextButton.icon(
                        onPressed: () => _controller.move(widget.branchPoint!, 15),
                        icon: const Icon(Icons.store_mall_directory_outlined, size: 18),
                        label: Text('Go to ${widget.branchName ?? 'branch'}'),
                      ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Confirm location',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(_center.value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}