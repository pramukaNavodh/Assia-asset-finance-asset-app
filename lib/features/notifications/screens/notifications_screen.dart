
//libraries
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//internal resource files
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../assets/screens/asset_detail_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../reports/models/report_models.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

// Pushed pages sit above the providers, so hand them over.
Future<void> openNotifications(BuildContext context) {
  final dashboard = context.read<DashboardProvider>();
  final notifications = context.read<NotificationsProvider>();
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dashboard),
          ChangeNotifierProvider.value(value: notifications),
        ],
        child: const NotificationsScreen(),
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsProvider _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationsProvider>();
  }

  @override
  void dispose() {
    // Leaving the screen counts as "seen" (unread dots stay visible while open).
    _notifications.markAllRead();
    super.dispose();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return Formatters.shortDate(d);
  }

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  void _openAsset(String? assetId) {
    final dashboard = context.read<DashboardProvider>();
    if (assetId == null || dashboard.assetById(assetId) == null) {
      AppSnackBar.show(context, 'This asset is no longer available.', isError: true);
      return;
    }
    openAssetDetail(context, assetId);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final reminders = findExpiries(dashboard.allAssets, withinDays: 30, pastDays: 30);

    // Group by day, newest first (the list is already sorted).
    final groups = <String, List<AppNotification>>{};
    for (final n in notifications.items) {
      groups.putIfAbsent(_dayLabel(n.createdAt), () => []).add(n);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: notifications.unreadCount == 0 ? null : notifications.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (reminders.isNotEmpty) ...[
            SectionCard(
              title: 'Reminders',
              child: Column(
                children: [
                  for (final r in reminders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openAsset(r.asset.id),
                      leading: CircleAvatar(
                        backgroundColor: (r.daysLeft < 0 ? AppColors.error : const Color(0xFFB77900))
                            .withValues(alpha: 0.12),
                        child: Icon(
                          r.kind == 'Insurance' ? Icons.shield_outlined : Icons.verified_outlined,
                          color: r.daysLeft < 0 ? AppColors.error : const Color(0xFFB77900),
                        ),
                      ),
                      title: Text('${r.asset.title} - ${r.kind}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        r.daysLeft < 0
                            ? 'Expired ${-r.daysLeft} days ago'
                            : 'Expires in ${r.daysLeft} days (${Formatters.shortDate(r.date)})',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (notifications.isLoading)
            const Column(children: [
              SkeletonBox(height: 72, radius: 18),
              SizedBox(height: 10),
              SkeletonBox(height: 72, radius: 18),
              SizedBox(height: 10),
              SkeletonBox(height: 72, radius: 18),
            ])
          else if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('You are all caught up',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Nothing new in the last 7 days.',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          else
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                child: Text(entry.key,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textMuted)),
              ),
              for (final n in entry.value) _tile(notifications, n),
            ],
          const SizedBox(height: 16),
          const Center(
            child: Text('Notifications are kept for 7 days.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _tile(NotificationsProvider provider, AppNotification n) {
    final unread = provider.isUnread(n);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unread ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border),
      ),
      child: ListTile(
        onTap: () => _openAsset(n.assetId),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            n.type == 'vehicle_sharing' ? Icons.my_location_rounded : Icons.add_box_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(n.title,
            style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w700 : FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('${n.body}\n${_time(n.createdAt)}', style: const TextStyle(height: 1.4)),
        ),
        isThreeLine: true,
        trailing: unread
            ? const CircleAvatar(radius: 5, backgroundColor: AppColors.accent)
            : null,
      ),
    );
  }
}