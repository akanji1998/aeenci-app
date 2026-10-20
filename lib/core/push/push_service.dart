import 'dart:async';

import 'package:flutter/foundation.dart';

/// Une notification reçue : titre, texte et écran à ouvrir (`data.route`).
@immutable
class PushMessage {
  const PushMessage({this.title, this.body, this.route});

  final String? title;
  final String? body;
  final String? route;
}

/// Autorisation d'afficher les notifications sur ce téléphone.
enum PushPermission {
  /// Jamais demandée (iOS), ou inconnue (Android 13 avant la demande).
  notDetermined,
  granted,
  denied,
}

/// Notifications push, derrière une interface : Firebase en vrai, un
/// service manuel avec les mocks et dans les tests, et un service coupé
/// quand la configuration Firebase manque.
abstract interface class PushService {
  /// `false` : pas de notifications push sur cette installation.
  bool get available;

  Future<PushPermission> permission();

  /// Demande du système. N'est appelée qu'après l'écran d'explication.
  Future<PushPermission> requestPermission();

  /// Jeton Firebase Cloud Messaging du téléphone.
  Future<String?> token();

  /// Nouveau jeton : à enregistrer de nouveau auprès de l'API.
  Stream<String> get tokenRefresh;

  /// Notification reçue application ouverte (déjà affichée par le service).
  Stream<PushMessage> get foregroundMessages;

  /// Notification touchée, application ouverte ou en arrière-plan.
  Stream<PushMessage> get openedMessages;

  /// Notification qui a lancé l'application fermée, une seule fois.
  Future<PushMessage?> initialMessage();
}

/// Aucune notification push (configuration Firebase absente).
class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  bool get available => false;
  @override
  Future<PushPermission> permission() async => PushPermission.denied;
  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get tokenRefresh => const Stream.empty();
  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();
  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
}

/// Service piloté à la main : mocks (page des composants) et tests.
class ManualPushService implements PushService {
  ManualPushService({
    this.currentPermission = PushPermission.notDetermined,
    this.grantOnRequest = true,
    this.launchMessage,
    this.currentToken = 'jeton-fcm-de-test',
  });

  PushPermission currentPermission;

  /// Réponse de la personne à la demande du système.
  bool grantOnRequest;
  PushMessage? launchMessage;
  String currentToken;
  int requests = 0;

  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  @override
  bool get available => true;

  @override
  Future<PushPermission> permission() async => currentPermission;

  @override
  Future<PushPermission> requestPermission() async {
    requests++;
    return currentPermission = grantOnRequest
        ? PushPermission.granted
        : PushPermission.denied;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefresh => _refresh.stream;
  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;
  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    final message = launchMessage;
    launchMessage = null;
    return message;
  }

  void refreshToken(String token) {
    currentToken = token;
    _refresh.add(token);
  }

  void receive(PushMessage message) => _foreground.add(message);

  void open(PushMessage message) => _opened.add(message);
}
