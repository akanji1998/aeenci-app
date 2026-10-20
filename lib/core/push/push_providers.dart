import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/env_config.dart';
import 'firebase_push_service.dart';
import 'push_service.dart';

/// `true` si Firebase a démarré (fichiers de configuration présents).
/// Remplacé au démarrage par `bootstrap`.
final firebaseReadyProvider = Provider<bool>((ref) => false);

/// Notifications push : service manuel avec les mocks, Firebase sinon,
/// coupé si Firebase n'est pas configuré.
final pushServiceProvider = Provider<PushService>((ref) {
  if (ref.watch(envConfigProvider).useMocks) return ManualPushService();
  return ref.watch(firebaseReadyProvider)
      ? FirebasePushService()
      : const DisabledPushService();
});

/// Écrans que peut ouvrir une notification (`route`, table du contrat).
final _pushRoutes = [
  RegExp(r'^/evenements/[A-Za-z0-9_-]+$'),
  RegExp(r'^/cotisations$'),
  RegExp(r'^/opportunites/\d+$'),
  RegExp(r'^/actualites/[A-Za-z0-9_-]+$'),
  RegExp(r'^/adhesion/suivi$'),
  RegExp(r'^/profil/vitrine$'),
  RegExp(r'^/carte$'),
  RegExp(r'^/notifications$'),
];

/// La route d'une notification si elle est dans la table du contrat,
/// sinon le centre de notifications.
String safePushRoute(String? route) =>
    route != null && _pushRoutes.any((r) => r.hasMatch(route))
    ? route
    : '/notifications';
