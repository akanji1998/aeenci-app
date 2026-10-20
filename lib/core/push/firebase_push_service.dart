import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_service.dart';

/// Canal Android des notifications (même identifiant dans le manifeste).
const _channel = AndroidNotificationChannel(
  'aeenci_default',
  'Notifications AEENCI',
  description: 'Événements, cotisations, actualités et messages du bureau.',
  importance: Importance.high,
);

/// Initialise Firebase avec les fichiers natifs de la saveur
/// (`google-services.json`, `GoogleService-Info.plist`). `false` s'ils
/// manquent : l'application fonctionne alors sans notifications push.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (error) {
    debugPrint('Firebase non configuré : notifications push coupées ($error)');
    return false;
  }
}

/// Notifications par Firebase Cloud Messaging. Au premier plan, Android
/// n'affiche rien de lui-même : `flutter_local_notifications` s'en charge.
/// iOS les affiche grâce aux options de présentation.
class FirebasePushService implements PushService {
  FirebasePushService() {
    _ready = _setUp();
  }

  late final Future<void> _ready;

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  PushMessage? _launchedFromLocal;
  int _nextLocalId = 0;

  Future<void> _setUp() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // La permission est demandée par Firebase, après l'explication.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _opened.add(PushMessage(route: response.payload)),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchedFromLocal = PushMessage(
        route: launch?.notificationResponse?.payload,
      );
    }
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _opened.add(_toPush(message)),
    );
  }

  PushMessage _toPush(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    route: message.data['route'] as String?,
  );

  Future<void> _onForeground(RemoteMessage message) async {
    final push = _toPush(message);
    _foreground.add(push);
    if (!Platform.isAndroid || push.title == null) return;
    await _local.show(
      id: _nextLocalId++,
      title: push.title,
      body: push.body,
      payload: push.route,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );
  }

  static PushPermission _status(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  bool get available => true;

  @override
  Future<PushPermission> permission() async =>
      _status((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async =>
      _status((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() async {
    try {
      // Le contrat attend le jeton FCM (`POST /me/devices`), pas
      // l'identifiant d'installation (FID) de `register()` / `onRegistered`.
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Object catch (error) {
      // Pas de réseau, ou pas de clé APNs (simulateur) : pas de jeton.
      debugPrint('Jeton FCM indisponible : $error');
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;
  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;
  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    await _ready;
    final remote = await _messaging.getInitialMessage();
    if (remote != null) return _toPush(remote);
    final local = _launchedFromLocal;
    _launchedFromLocal = null;
    return local;
  }
}
