import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

Future<bool> initializeTransportPush() async {
  if (_apiKey.isEmpty ||
      _appId.isEmpty ||
      _senderId.isEmpty ||
      _projectId.isEmpty) {
    return false;
  }
  try {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _senderId,
            projectId: _projectId));
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
    return true;
  } catch (e) {
    debugPrint('FCM no disponible: $e');
    return false;
  }
}
