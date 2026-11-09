//base notification class

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

//push messages for when the app is closed.
class PushService {
  PushService._();

  static const topic = 'asset-alerts';

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Push setup skipped: $e');
    }
  }

  static Future<void> unsubscribe() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }
}