import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/cache/cached_fetch.dart';
import 'package:aeenci_app/core/design/app_theme.dart';
import 'package:aeenci_app/core/design/components/app_button.dart';
import 'package:aeenci_app/core/design/components/app_card.dart';
import 'package:aeenci_app/core/design/components/app_switch_tile.dart';
import 'package:aeenci_app/core/design/components/app_text_field.dart';
import 'package:aeenci_app/core/design/components/async_view.dart';
import 'package:aeenci_app/core/design/components/empty_state.dart';
import 'package:aeenci_app/core/design/components/error_state.dart';
import 'package:aeenci_app/core/design/components/offline_banner.dart';
import 'package:aeenci_app/core/design/components/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('trois variantes en pilule, action appelée', (tester) async {
      var taps = 0;
      await pumpLocalized(
        tester,
        Column(
          children: [
            AppButton(label: 'Principal', onPressed: () => taps++),
            AppButton.secondary(label: 'Secondaire', onPressed: () => taps++),
            AppButton.text(
              label: 'Texte',
              onPressed: () => taps++,
              icon: LucideIcons.copy,
            ),
          ],
        ),
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      for (final label in ['Principal', 'Secondaire', 'Texte']) {
        await tester.tap(find.text(label));
      }
      expect(taps, 3);
    });

    testWidgets('en chargement : inactif, indicateur, libellé conservé', (
      tester,
    ) async {
      var taps = 0;
      await pumpLocalized(
        tester,
        AppButton(label: 'Envoyer', loading: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Envoyer'), findsOneWidget);
      await tester.tap(find.text('Envoyer'));
      expect(taps, 0);
    });

    testWidgets('expand prend toute la largeur', (tester) async {
      await pumpLocalized(
        tester,
        AppButton(label: 'Large', expand: true, onPressed: () {}),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 390);
    });
  });

  testWidgets('AppCard cliquable', (tester) async {
    var taps = 0;
    await pumpLocalized(
      tester,
      AppCard(onTap: () => taps++, child: const Text('Carte')),
    );
    await tester.tap(find.text('Carte'));
    expect(taps, 1);
  });

  group('AppTextField', () {
    testWidgets('libellé au-dessus, erreur 422 dessous', (tester) async {
      await pumpLocalized(
        tester,
        const AppTextField(
          label: 'E-mail',
          hint: 'ton.adresse@exemple.com',
          errorText: 'Adresse inconnue.',
        ),
      );
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Adresse inconnue.'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('E-mail')), findsWidgets);
    });

    testWidgets('mot de passe masqué, puis affiché', (tester) async {
      await pumpLocalized(
        tester,
        const AppTextField(label: 'Mot de passe', obscure: true),
      );
      bool obscured() =>
          tester.widget<TextField>(find.byType(TextField)).obscureText;
      expect(obscured(), isTrue);
      await tester.tap(find.byTooltip('Afficher le mot de passe'));
      await tester.pump();
      expect(obscured(), isFalse);
      expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
    });
  });

  testWidgets('AppSwitchTile : verrouillé si onChanged est nul', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      const AppSwitchTile(title: 'Mon compte', value: true, onChanged: null),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('EmptyState avec action', (tester) async {
    var taps = 0;
    await pumpLocalized(
      tester,
      EmptyState(
        icon: LucideIcons.inbox,
        title: 'Vide',
        message: 'Rien ici.',
        actionLabel: 'Actualiser',
        onAction: () => taps++,
      ),
    );
    await tester.tap(find.text('Actualiser'));
    expect(taps, 1);
  });

  group('ErrorState', () {
    final cases = <ApiException, String>{
      const NetworkException(): 'Pas de connexion',
      const ServerException(statusCode: 503): 'momentanément indisponible',
      const ForbiddenException(): 'pas accès',
      const NotFoundException(): 'n\'existe pas',
      const GoneException(): 'expiré',
      const TooManyRequestsException(): 'Trop de tentatives',
      const UnknownApiException(): 'Une erreur est survenue',
    };
    for (final MapEntry(key: error, value: text) in cases.entries) {
      testWidgets('${error.runtimeType}', (tester) async {
        await pumpLocalized(tester, ErrorState(error: error));
        expect(find.textContaining(text), findsOneWidget);
        expect(find.text('Réessayer'), findsNothing);
      });
    }

    testWidgets('« Réessayer » appelle onRetry', (tester) async {
      var retries = 0;
      await pumpLocalized(
        tester,
        ErrorState(error: const NetworkException(), onRetry: () => retries++),
      );
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });
  });

  testWidgets('OfflineBanner affiche la date de mise à jour', (tester) async {
    await pumpLocalized(
      tester,
      OfflineBanner(updatedAt: DateTime(2026, 10, 18, 10, 2)),
    );
    expect(
      find.text('Hors connexion · mis à jour le 18 oct. à 10:02'),
      findsOneWidget,
    );
  });

  testWidgets('SkeletonList est annoncée « Chargement… »', (tester) async {
    await pumpLocalized(tester, const SkeletonList());
    expect(find.bySemanticsLabel('Chargement…'), findsOneWidget);
  });

  group('AsyncView', () {
    Widget view(AsyncValue<Cached<String>> value, {VoidCallback? onRetry}) =>
        AsyncView<String>(
          value: value,
          onRetry: onRetry,
          builder: (context, data) => Text(data),
        );

    testWidgets('chargement → squelette', (tester) async {
      await pumpLocalized(tester, view(const AsyncLoading()));
      expect(find.byType(SkeletonList), findsOneWidget);
    });

    testWidgets('données fraîches, sans bandeau', (tester) async {
      await pumpLocalized(tester, view(const AsyncData(Cached('Bonjour'))));
      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.byType(OfflineBanner), findsNothing);
    });

    testWidgets('données en cache → bandeau hors connexion', (tester) async {
      await pumpLocalized(
        tester,
        view(
          AsyncData(
            Cached('Bonjour', offlineSince: DateTime(2026, 10, 18, 10, 2)),
          ),
        ),
      );
      expect(find.text('Bonjour'), findsOneWidget);
      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('erreur → ErrorState avec Réessayer', (tester) async {
      var retries = 0;
      await pumpLocalized(
        tester,
        view(
          const AsyncError(NetworkException(), StackTrace.empty),
          onRetry: () => retries++,
        ),
      );
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });
  });

  for (final (name, theme) in [
    ('clair', AppTheme.light),
    ('sombre', AppTheme.dark),
  ]) {
    testWidgets('à 200 % sans débordement, cibles de 48 px ($name)', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(label: 'Bouton principal assez long', onPressed: () {}),
              AppButton.secondary(label: 'Secondaire', onPressed: () {}),
              AppButton.text(label: 'Texte', onPressed: () {}),
              const AppTextField(
                label: 'Mot de passe',
                obscure: true,
                errorText: 'Erreur assez longue sous le champ.',
              ),
              AppSwitchTile(
                title: 'Recevoir les notifications',
                subtitle: 'Explication',
                value: true,
                onChanged: (_) {},
              ),
              OfflineBanner(updatedAt: DateTime(2026, 10, 18, 10, 2)),
              ErrorState(error: const NetworkException(), onRetry: () {}),
            ],
          ),
        ),
        theme: theme,
        textScale: 2,
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  }
}
