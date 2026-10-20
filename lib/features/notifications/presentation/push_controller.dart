import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';
import '../../auth/presentation/session_controller.dart';
import '../../home/presentation/home_providers.dart';
import '../data/devices_repository.dart';
import 'notifications_providers.dart';

/// Branche les notifications push sur l'application : ouverture de l'écran
/// de `route` (y compris application fermée), mise à jour de la pastille,
/// enregistrement du téléphone quand un membre est connecté.
class PushController extends Notifier<void> {
  @override
  void build() {
    final push = ref.watch(pushServiceProvider);
    if (!push.available) return;

    final subscriptions = [
      push.openedMessages.listen((message) => _open(message.route)),
      push.foregroundMessages.listen((_) => _refreshCounters()),
      push.tokenRefresh.listen((token) {
        if (ref.read(sessionControllerProvider) is SessionMember) {
          unawaited(ref.read(deviceRegistrarProvider).register(token));
        }
      }),
    ];
    ref.onDispose(() {
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
    });

    // Application lancée par une notification : la garde de navigation
    // garde l'écran demandé pendant le démarrage et la connexion.
    unawaited(
      push.initialMessage().then((message) {
        if (message != null) _open(message.route);
      }),
    );

    ref.listen(sessionControllerProvider, (previous, next) {
      if (next is SessionMember && previous is! SessionMember) {
        unawaited(registerIfAllowed());
      }
    }, fireImmediately: true);
  }

  void _open(String? route) {
    _refreshCounters();
    ref.read(appRouterProvider).go(safePushRoute(route));
  }

  void _refreshCounters() {
    ref
      ..invalidate(unreadNotificationsProvider)
      ..invalidate(notificationsProvider);
  }

  /// Enregistre le jeton si la personne a autorisé les notifications.
  Future<void> registerIfAllowed() async {
    final push = ref.read(pushServiceProvider);
    if (!push.available) return;
    if (await push.permission() != PushPermission.granted) return;
    final token = await push.token();
    if (token != null) await ref.read(deviceRegistrarProvider).register(token);
  }
}

final pushControllerProvider = NotifierProvider<PushController, void>(
  PushController.new,
);
