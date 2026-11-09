import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';

//live notifications from the last 7 days
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({required this.userId, this.enabled = true}) {
    if (enabled && userId.isNotEmpty) {
      _start();
    } else {
      _loading = false;
    }
  }

  final String userId;
  final bool enabled;

  final _db = FirebaseFirestore.instance;
  final _incoming = StreamController<AppNotification>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _readSub;

  List<AppNotification> _all = const [];
  DateTime? _readAt;
  bool _loading = true;
  bool _firstSnapshot = true;

  // fires when a NEW notification arrives while the app is open (for banners).
  Stream<AppNotification> get incoming => _incoming.stream;
  bool get isLoading => _loading;

  List<AppNotification> get items {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _all.where((n) => n.createdAt.isAfter(cutoff)).toList();
  }

  bool isUnread(AppNotification n) => _readAt == null || n.createdAt.isAfter(_readAt!);

  int get unreadCount => items.where(isUnread).length;

  void _start() {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));

    _notificationsSub = _db
        .collection('notifications')
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      // Do not notify people about their own actions.
      _all = snap.docs
          .map((d) => AppNotification.fromMap(d.id, d.data()))
          .where((n) => n.createdBy != userId)
          .toList();

      if (!_firstSnapshot) {
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final n = AppNotification.fromMap(change.doc.id, change.doc.data() ?? {});
          if (n.createdBy != userId) _incoming.add(n);
        }
      }
      _firstSnapshot = false;
      _loading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Notifications error: $e');
      _loading = false;
      notifyListeners();
    });

    _readSub = _db.collection('users').doc(userId).snapshots().listen((doc) {
      final ts = doc.data()?['notificationsReadAt'];
      _readAt = ts is Timestamp ? ts.toDate() : null;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Read-state error: $e'));
  }

  Future<void> markAllRead() async {
    if (!enabled || userId.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .set({'notificationsReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not mark notifications read: $e');
    }
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _readSub?.cancel();
    _incoming.close();
    super.dispose();
  }
}