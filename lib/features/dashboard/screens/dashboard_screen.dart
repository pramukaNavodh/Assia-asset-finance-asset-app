//main dashboard view for the application

//libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/asset_preview_sheet.dart';
import '../widgets/assets_map_card.dart';
import '../widgets/branch_bars_card.dart';
import '../widgets/branch_selector.dart';
import '../widgets/category_donut_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/recent_assets_list.dart';
import '../widgets/stat_cards.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onSeeAllAssets,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;
  final VoidCallback onSeeAllAssets;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final name = context.select<AuthProvider, String>((a) => a.displayName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              name: name,
              onProfileTap: onOpenProfile,
              onNotificationsTap: onOpenNotifications,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (p.status == DashboardStatus.loading)
            const SliverToBoxAdapter(child: DashboardSkeleton())
          else if (p.status == DashboardStatus.error)
            SliverToBoxAdapter(
              child: _ErrorState(
                message: p.errorMessage ?? 'Something went wrong',
                onRetry: p.load,
              ),
            )
          else ...[
              SliverToBoxAdapter(
                child: BranchSelector(
                  selectedId: p.selectedBranchId,
                  onSelected: p.selectBranch,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(
                      child: HeroValueCard(
                        totalValue: p.totalValue,
                        totalCount: p.totalCount,
                        scopeLabel: p.scopeLabel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Row(
                        children: [
                          Expanded(
                            child: MiniStatCard(
                              label: 'Vehicles',
                              value: p.vehicleCount,
                              icon: Icons.directions_car_outlined,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: MiniStatCard(
                              label: 'Added in 30 days',
                              value: p.recentCount,
                              icon: Icons.add_chart_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: CategoryDonutCard(counts: p.categoryCounts),
                    ),
                    const SizedBox(height: 16),
                    if (p.selectedBranchId == null &&
                        p.branchCounts.isNotEmpty) ...[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: BranchBarsCard(counts: p.branchCounts),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: AssetsMapCard(
                        assets: p.scopedAssets,
                        onMarkerTap: (asset) => showAssetPreview(context, asset),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RecentAssetsList(
                      assets: p.results,
                      isSearching: p.isSearching,
                      onSeeAll: onSeeAllAssets,
                    ),
                  ]),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;          // ← add this
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Could not load assets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(                          // ← changed from const Text
            message,                     // ← shows the real error
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
