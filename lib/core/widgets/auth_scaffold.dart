//dynamic layout for handling both signin and signup

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//internal resource files
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'fade_slide_in.dart';
import 'safe_asset_image.dart';


class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  //layout conf
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // light status-bar icons
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _Header(showBack: showBack),
              // Pull the card up so it overlaps the header.
              Transform.translate(
                offset: const Offset(0, -40),
                child: FadeSlideIn(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
            ),
          ),
          const Positioned(
            top: -50,
            right: -40,
            child: _Bubble(size: 180, color: Colors.white, opacity: 0.07),
          ),
          const Positioned(
            bottom: -30,
            left: -30,
            child: _Bubble(size: 120, color: AppColors.accent, opacity: 0.12),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 72),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Container(
                    height: 72,
                    width: 72,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SafeAssetImage(
                      AppAssets.logo,
                      fallbackIcon: Icons.account_balance,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Asia Asset Finance PLC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ASSET MANAGEMENT',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}