import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidChannel = AndroidNotificationChannel(
      'uploads',
      'Upload Status',
      description: 'Notifications for upload approval/rejection',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _local.initialize(initSettings);

    await _saveToken();

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null) return;

      _local.show(
        notif.hashCode,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'uploads',
            'Upload Status',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  static Future<void> _saveToken([String? token]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fcmToken = token ?? await _messaging.getToken();
    if (fcmToken == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(fcmToken);

    await ref.set({
      'token': fcmToken,
      'platform': Platform.operatingSystem,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
