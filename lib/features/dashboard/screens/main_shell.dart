//base layer for the dashboard

//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../profile/profile_screen.dart';
import '../data/asset_repository.dart';
import '../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';


class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final AssetRepository repository = AppConfig.useDemoData
        ? DemoAssetRepository()
        : FirestoreAssetRepository();

    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(repository),
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

  void _go(int index) => setState(() => _index = index);

  void _push(IconData icon, String title, String message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceholderScreen(
          icon: icon,
          title: title,
          message: message,
          showAppBar: true,
        ),
      ),
    );
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
            onOpenNotifications: () => _push(
              Icons.notifications_none_rounded,
              'Notifications',
              'Alerts for new assets and vehicle tracking will appear here and are kept for 7 days. Coming in Phase 8.',
            ),
          ),
          const PlaceholderScreen(
            icon: Icons.inventory_2_outlined,
            title: 'All assets',
            message: 'Browse, search and edit every asset here. Coming in Phase 5.',
          ),
          const PlaceholderScreen(
            icon: Icons.bar_chart_rounded,
            title: 'Reports',
            message: 'Generate and export asset reports. Coming in Phase 6.',
          ),
          const ProfileScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _push(
          Icons.add_box_outlined,
          'Add asset',
          'The Add Asset form (details, photos and map location) arrives in Phase 4.',
        ),
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
            const SizedBox(width: 72), // space for the docked button
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