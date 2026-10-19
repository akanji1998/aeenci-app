import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/core/design/app_theme.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/design_demo/presentation/design_demo_screen.dart';
import 'package:aeenci_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  EnvConfig? config,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  final container = await pumpAeenci(
    tester,
    token: MockPersona.member.token,
    env: config,
    size: size,
    textScale: textScale,
  );
  container.read(appRouterProvider).go(AppRoutes.devComponents);
  await tester.pumpAndSettle();
}

/// Fait défiler la page jusqu'à [finder] (les sections sont construites à la demande).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  // Pas de pumpAndSettle : l'indicateur du bouton « en chargement » tourne
  // sans fin dans la section États.
  await tester.pump(const Duration(milliseconds: 300));
}

/// Fait défiler toute la page pour construire chaque section.
Future<void> _scrollToEnd(WidgetTester tester) =>
    _scrollTo(tester, find.text('500'));

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(DesignDemoScreen))).brightness;

void main() {
  testWidgets('affiche la page de démonstration en français', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Composants'), findsOneWidget);
    expect(find.text('Saveur dev · données factices'), findsOneWidget);
    expect(find.bySemanticsLabel("Logo de l'AEENCI"), findsOneWidget);

    for (final text in [
      'Knowledge is Power',
      'green-soft',
      'Bouton principal',
      'Bouton secondaire',
      'Assemblée',
      'Titre de carte',
      'Ce champ est obligatoire.',
      'Recevoir les notifications',
      'Cotisations',
    ]) {
      await _scrollTo(tester, find.text(text));
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('indique l\'API quand les mocks sont coupés', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(
            EnvConfig.resolve(
              flavor: Flavor.prod,
              apiBaseUrl: 'https://api.aeenci.com/api/v1',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const DesignDemoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Saveur prod · API https://api.aeenci.com/api/v1'),
      findsOneWidget,
    );
    // Sans mocks, pas de réglage des mocks.
    await _scrollTo(tester, find.text('Icônes'));
    expect(find.text('Mocks'), findsNothing);
  });

  testWidgets('bascule entre thème clair et sombre', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);
    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(
      Theme.of(
        tester.element(find.byType(DesignDemoScreen)),
      ).scaffoldBackgroundColor,
      AppColors.dark.surface,
    );

    await tester.tap(find.text('Clair'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });

  testWidgets('le thème système est suivi par défaut', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);
    expect(_brightness(tester), Brightness.dark);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'aucun débordement à 200 % sur un petit écran (${brightness.name})',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _pumpApp(tester, size: const Size(320, 568), textScale: 2);
        await _scrollToEnd(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cibles tactiles d\'au moins 48 × 48', (tester) async {
    await _pumpApp(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
