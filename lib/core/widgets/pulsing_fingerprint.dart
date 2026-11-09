// Fingerprint button with two rings

//libraries
import 'package:flutter/material.dart';

//internal asset files
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'safe_asset_image.dart';


class PulsingFingerprint extends StatefulWidget {
  const PulsingFingerprint({super.key, this.size = 220, this.onTap});

 //ring outer params
  final double size;
  final VoidCallback? onTap;

  @override
  State<PulsingFingerprint> createState() => _PulsingFingerprintState();
}

class _PulsingFingerprintState extends State<PulsingFingerprint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double t, double core) {
    final diameter = core + (widget.size - core) * t;
    return Opacity(
      opacity: (1 - t) * 0.55,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = widget.size / 2;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              _ring(_controller.value, core),
              _ring((_controller.value + 0.5) % 1.0, core),
              Container(
                width: core,
                height: core,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFC83D), AppColors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SafeAssetImage(
                    AppAssets.fingerprint,
                    size: core * 0.5,
                    color: AppColors.primaryDark,
                    fallbackIcon: Icons.fingerprint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}