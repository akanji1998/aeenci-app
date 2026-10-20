import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/paginated.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/mock/mock_profile_store.dart';
import 'package:aeenci_app/core/push/push_service.dart';
import 'package:aeenci_app/features/events/presentation/event_detail_screen.dart';
import 'package:aeenci_app/features/notifications/data/devices_repository.dart';
import 'package:aeenci_app/features/notifications/data/notifications_repository.dart';
import 'package:aeenci_app/features/notifications/domain/app_notification.dart';
import 'package:aeenci_app/features/notifications/presentation/notifications_screen.dart';
import 'package:aeenci_app/features/notifications/presentation/push_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/pump_aeenci.dart';

Future<void> openCenter(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.bell));
  await tester.pumpAndSettle();
}

/// Pastille rouge de la cloche de l'accueil.
bool badgeVisible(WidgetTester tester) => tester
    .widget<Badge>(
      find.ancestor(
        of: find.byIcon(LucideIcons.bell),
        matching: find.byType(Badge),
      ),
    )
    .isLabelVisible;

String location(ProviderContainer container) => container
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

MockDevicesRepository devices(ProviderContainer container) =>
    container.read(devicesRepositoryProvider) as MockDevicesRepository;

/// Marquer comme lu échoue toujours (hors connexion).
class _MarkReadFails implements NotificationsRepository {
  _MarkReadFails(this._inner);

  final NotificationsRepository _inner;

  @override
  Future<Paginated<AppNotification>> fetchPage({int page = 1}) =>
      _inner.fetchPage(page: page);
  @override
  Future<void> markRead({List<int> ids = const [], bool all = false}) async =>
      throw const NetworkException();
  @override
  Future<List<NotificationPreference>> fetchPreferences() =>
      _inner.fetchPreferences();
  @override
  Future<List<NotificationPreference>> updatePreferences(
    Map<NotificationCategory, bool> changes,
  ) => _inner.updatePreferences(changes);
}

void main() {
  testWidgets('centre : groupes par jour, pastille, page suivante', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    expect(badgeVisible(tester), isTrue);
    await openCenter(tester);

    expect(find.text('AUJOURD\'HUI'), findsOneWidget);
    expect(find.text('HIER'), findsOneWidget);
    expect(find.text('CETTE SEMAINE'), findsOneWidget);
    expect(find.text('Tout marquer lu'), findsOneWidget);

    await scrollTo(tester, find.text('Voir les notifications précédentes'));
    await tester.tap(find.text('Voir les notifications précédentes'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('PLUS TÔT'));
    expect(find.text('Profil de test validé'), findsOneWidget);
    expect(find.text('Voir les notifications précédentes'), findsNothing);
  });

  testWidgets('toucher une notification la marque lue et ouvre l\'écran', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openCenter(tester);
    final unread = find.bySemanticsLabel(
      RegExp(r'^Non lue\. Événements\. Notification de test'),
    );
    expect(unread, findsOneWidget);
    await tester.tap(unread);
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Accueil'),
      ),
    );
    await tester.pumpAndSettle();
    await openCenter(tester);
    expect(unread, findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Événements\. Notification de test')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('tout marquer lu, et la pastille de l\'accueil suit', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openCenter(tester);
    await tester.tap(find.text('Tout marquer lu'));
    await tester.pumpAndSettle();
    expect(find.text('Tout marquer lu'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(badgeVisible(tester), isFalse);
  });

  testWidgets('tout marquer lu hors connexion : retour en arrière', (
    tester,
  ) async {
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [
        notificationsRepositoryProvider.overrideWith(
          (ref) => _MarkReadFails(
            MockNotificationsRepository(
              ref.watch(mockRuntimeProvider),
              ref.watch(tokenStoreProvider),
              ref.watch(mockProfileStoreProvider),
            ),
          ),
        ),
      ],
    );
    await openCenter(tester);
    await tester.tap(find.text('Tout marquer lu'));
    await tester.pumpAndSettle();
    expect(find.text('Tout marquer lu'), findsOneWidget);
    expect(find.textContaining('connexion'), findsWidgets);
  });

  testWidgets('écran d\'explication après la connexion, puis autorisation', (
    tester,
  ) async {
    final push = ManualPushService();
    final container = await pumpAeenci(tester, push: push);
    await signInAs(tester, 'Membre');

    expect(find.byType(PushPromptScreen), findsOneWidget);
    // Rien n'est demandé au système avant le choix.
    expect(push.requests, 0);
    await tester.tap(find.text('Activer les notifications'));
    await tester.pumpAndSettle();

    expect(push.requests, 1);
    expect(find.byType(PushPromptScreen), findsNothing);
    expect(devices(container).registered.keys, ['jeton-fcm-de-test']);
    final device = devices(container).registered.values.single;
    expect(device.appVersion, '1.0.0');
    expect(device.locale, 'fr');

    // Nouveau jeton Firebase : enregistré à son tour.
    push.refreshToken('nouveau-jeton');
    await tester.pumpAndSettle();
    expect(devices(container).registered.keys, contains('nouveau-jeton'));
  });

  testWidgets('« Plus tard » : pas de demande, pas de nouvel écran', (
    tester,
  ) async {
    final push = ManualPushService();
    final container = await pumpAeenci(tester, push: push);
    await signInAs(tester, 'Membre');
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(push.requests, 0);
    expect(find.byType(PushPromptScreen), findsNothing);
    expect(devices(container).registered, isEmpty);

    // Le profil propose de les autoriser.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Autoriser les notifications'));
    await tester.tap(find.text('Autoriser les notifications'));
    await tester.pumpAndSettle();
    expect(push.requests, 1);
    expect(find.text('Autoriser les notifications'), findsNothing);
    expect(devices(container).registered, isNotEmpty);
  });

  testWidgets('déconnexion : le téléphone est retiré', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    expect(devices(container).registered.keys, ['jeton-fcm-de-test']);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Se déconnecter'));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(devices(container).unregistered, ['jeton-fcm-de-test']);
    expect(devices(container).registered, isEmpty);
  });

  testWidgets('notification touchée : écran de sa route', (tester) async {
    final push = ManualPushService(currentPermission: PushPermission.granted);
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      push: push,
    );

    push.open(const PushMessage(route: '/cotisations'));
    await tester.pumpAndSettle();
    expect(location(container), '/cotisations');

    // Route inconnue : centre de notifications.
    push.open(const PushMessage(route: '/profil/supprimer-mon-compte'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    // Au premier plan : la pastille se met à jour.
    push.receive(const PushMessage(title: 'Test'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('application lancée par une notification, puis connexion', (
    tester,
  ) async {
    final push = ManualPushService(
      currentPermission: PushPermission.granted,
      launchMessage: const PushMessage(route: '/actualites/actualite-test-2'),
    );
    final container = await pumpAeenci(tester, push: push);
    // Déconnecté : connexion d'abord, puis l'article demandé.
    await signInAs(tester, 'Membre');
    expect(location(container), '/actualites/actualite-test-2');
    expect(find.text('Actualité de test n° 2'), findsOneWidget);
  });

  testWidgets('centre à 200 % sur un petit écran', (tester) async {
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      size: const Size(320, 640),
      textScale: 2,
    );
    await openCenter(tester);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
