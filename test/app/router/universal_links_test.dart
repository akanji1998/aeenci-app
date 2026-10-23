import 'dart:io';

import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/universal_links.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/auth/presentation/activate_account_screen.dart';
import 'package:aeenci_app/features/auth/presentation/login_screen.dart';
import 'package:aeenci_app/features/auth/presentation/reset_password_screen.dart';
import 'package:aeenci_app/features/events/presentation/event_detail_screen.dart';
import 'package:aeenci_app/features/home/presentation/home_screen.dart';
import 'package:aeenci_app/features/opportunities/presentation/opportunities_screens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

/// Le lien tel que le système le transmet à Flutter (canal
/// `flutter/navigation`), adresse complète comprise.
Future<void> openLink(WidgetTester tester, String url) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': url, 'state': null}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

String location(ProviderContainer c) =>
    c.read(appRouterProvider).state.uri.toString();

void main() {
  group('réécriture des adresses du site', () {
    String? rewrite(String url) => rewriteUniversalLink(Uri.parse(url));

    test('opportunités : /espace/opportunites → /opportunites', () {
      expect(
        rewrite('https://aeenci.com/espace/opportunites'),
        '/opportunites',
      );
      expect(
        rewrite('https://aeenci.com/espace/opportunites/'),
        '/opportunites',
      );
      expect(
        rewrite('https://aeenci.com/espace/opportunites/40'),
        '/opportunites/40',
      );
      expect(rewrite('https://aeenci.com/espace/opportunites/abc'), '/accueil');
    });

    test('mêmes chemins que l\'application : rien à réécrire', () {
      expect(rewrite('https://aeenci.com/activer-mon-compte?token=x'), isNull);
      expect(rewrite('https://aeenci.com/evenements/joe-2026'), isNull);
      expect(rewrite('/opportunites/40'), isNull);
    });
  });

  testWidgets('invitation reçue par e-mail : écran d\'activation', (
    tester,
  ) async {
    await pumpAeenci(tester);
    await openLink(
      tester,
      'https://aeenci.com/activer-mon-compte?token=invitation-valide',
    );
    final screen = tester.widget<ActivateAccountScreen>(
      find.byType(ActivateAccountScreen),
    );
    expect(screen.token, 'invitation-valide');
  });

  testWidgets('lien de réinitialisation : jeton et e-mail gardés', (
    tester,
  ) async {
    await pumpAeenci(tester);
    await openLink(
      tester,
      'https://aeenci.com/reinitialiser-mot-de-passe'
      '?token=jeton-reinit&email=membre.test%40exemple.com',
    );
    final screen = tester.widget<ResetPasswordScreen>(
      find.byType(ResetPasswordScreen),
    );
    expect(screen.token, 'jeton-reinit');
    expect(screen.email, 'membre.test@exemple.com');
  });

  testWidgets('déconnecté : connexion, puis l\'opportunité demandée', (
    tester,
  ) async {
    final container = await pumpAeenci(tester);
    await openLink(tester, 'https://aeenci.com/espace/opportunites/40');
    expect(find.byType(LoginScreen), findsOneWidget);

    await signInAs(tester, 'Membre');
    expect(location(container), '/opportunites/40');
    expect(find.byType(OpportunityDetailScreen), findsOneWidget);
  });

  testWidgets('connecté : un événement s\'ouvre dans son onglet', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openLink(
      tester,
      'https://aeenci.com/evenements/evenement-test-a-venir',
    );
    expect(find.byType(EventDetailScreen), findsOneWidget);
  });

  testWidgets('membre connecté et lien d\'activation : l\'accueil', (
    tester,
  ) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await openLink(tester, 'https://aeenci.com/activer-mon-compte?token=x');
    expect(location(container), '/accueil');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('adresse inconnue : l\'accueil, sans page d\'erreur', (
    tester,
  ) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await openLink(tester, 'https://aeenci.com/evenements-anciens/x/y');
    expect(location(container), '/accueil');
    await openLink(tester, 'https://aeenci.com/espace/opportunites/abc');
    expect(location(container), '/accueil');
    expect(tester.takeException(), isNull);
  });

  test('le manifeste Android (prod) déclare les mêmes chemins', () {
    final manifest = File(
      'android/app/src/prod/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:autoVerify="true"'));
    expect(manifest, contains('android:host="$universalLinkHost"'));
    final declared = RegExp(
      r'android:pathPrefix="([^"]+)"',
    ).allMatches(manifest).map((m) => m[1]).toSet();
    expect(declared, universalLinkPaths.toSet());
    // Et seulement en prod : rien dans le manifeste commun.
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      isNot(contains('autoVerify')),
    );
  });

  test('iOS : domaine associé dans les entitlements prod seulement', () {
    expect(
      File('ios/Runner/RunnerProd.entitlements').readAsStringSync(),
      contains('applinks:$universalLinkHost'),
    );
    expect(
      File('ios/Runner/Runner.entitlements').readAsStringSync(),
      isNot(contains('applinks:')),
    );
  });
}
