//notification base class

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.assetId,
    this.createdBy,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? assetId;
  final String? createdBy;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    String? text(String key) {
      final v = map[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    final created = map['createdAt'];
    return AppNotification(
      id: id,
      type: text('type') ?? 'general',
      title: text('title') ?? 'Notification',
      body: text('body') ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      assetId: text('assetId'),
      createdBy: text('createdBy'),
    );
  }
}