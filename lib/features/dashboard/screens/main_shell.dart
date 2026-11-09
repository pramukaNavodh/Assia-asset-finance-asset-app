import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../assets/screens/add_asset_screen.dart';
import '../../assets/screens/assets_list_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/push_service.dart';
import '../../profile/profile_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/asset_repository.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';

/// App frame after sign-in: bottom navigation + docked "Add asset" button.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final AssetRepository repository = AppConfig.useDemoData
        ? DemoAssetRepository()
        : FirestoreAssetRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider(repository)),
        ChangeNotifierProvider(
          create: (ctx) => NotificationsProvider(
            userId: ctx.read<AuthProvider>().user?.uid ?? '',
            enabled: !AppConfig.useDemoData,
          ),
        ),
      ],
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatefulWidget {
  const _ShellView();

  @override
  State<_ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<_ShellView> {
  int _index = 0;
  StreamSubscription<AppNotification>? _incoming;

  @override
  void initState() {
    super.initState();
    // Banner when a colleague's activity arrives while the app is open.
    _incoming = context.read<NotificationsProvider>().incoming.listen((n) {
      if (mounted) AppSnackBar.show(context, '${n.title}: ${n.body}');
    });
    PushService.init();
  }

  @override
  void dispose() {
    _incoming?.cancel();
    super.dispose();
  }

  void _go(int index) => setState(() => _index = index);

  Future<void> _openAddAsset() async {
    final dashboard = context.read<DashboardProvider>();
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: dashboard,
          child: const AddAssetScreen(),
        ),
      ),
    );
    if (added == true && mounted) {
      AppSnackBar.show(context, 'Asset added successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onOpenProfile: () => _go(3),
            onSeeAllAssets: () => _go(1),
            onOpenNotifications: () => openNotifications(context),
          ),
          AssetsListScreen(onAddAsset: _openAddAsset),
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAsset,
        tooltip: 'Add asset',
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        height: 64,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _NavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              selected: _index == 0,
              onTap: () => _go(0),
            ),
            _NavItem(
              label: 'Assets',
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              selected: _index == 1,
              onTap: () => _go(1),
            ),
            const SizedBox(width: 72),
            _NavItem(
              label: 'Reports',
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              selected: _index == 2,
              onTap: () => _go(2),
            ),
            _NavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              selected: _index == 3,
              onTap: () => _go(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}