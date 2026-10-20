import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/app/router/route_guard.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/app_config/domain/app_config.dart';
import 'package:aeenci_app/features/app_config/presentation/app_gate_controller.dart';
import 'package:aeenci_app/features/auth/presentation/session_controller.dart';
import 'package:aeenci_app/features/profile/domain/member.dart';
import 'package:flutter_test/flutter_test.dart';

final _member = SessionMember(Member.fromJson(MockPersona.member.meJson));
final _bureau = SessionMember(Member.fromJson(MockPersona.bureau.meJson));
final _candidate = SessionCandidate(
  Member.fromJson(MockPersona.candidate.meJson),
);
const _signedOut = SessionSignedOut();

String? go(
  SessionState session,
  String location, {
  bool devTools = true,
  AppGateState gate = const GateOpen(),
}) => guardRedirect(
  gate: gate,
  session: session,
  uri: Uri.parse(location),
  devTools: devTools,
);

final _config = AppConfig.fromJson(mockAppConfigJson());

void main() {
  group('pendant le chargement', () {
    for (final session in [
      const SessionLoading(),
      const SessionUnavailable(NetworkException()),
    ]) {
      test(
        '${session.runtimeType} → démarrage, en gardant l\'écran demandé',
        () {
          expect(go(session, '/carte'), '/demarrage?from=%2Fcarte');
          expect(go(session, '/demarrage?from=%2Fcarte'), isNull);
          expect(go(session, '/'), '/demarrage');
        },
      );
    }
  });

  group('déconnecté', () {
    test('écrans publics accessibles', () {
      for (final path in AppRoutes.public) {
        expect(go(_signedOut, path), isNull, reason: path);
      }
      expect(go(_signedOut, '/activer-mon-compte?token=abc'), isNull);
    });

    test('écran protégé → connexion avec from', () {
      expect(
        go(_signedOut, '/evenements/joe-2026'),
        '/connexion?from=%2Fevenements%2Fjoe-2026',
      );
      expect(go(_signedOut, '/'), '/connexion');
    });

    test('le from du démarrage passe à la connexion', () {
      expect(
        go(_signedOut, '/demarrage?from=%2Fcotisations'),
        '/connexion?from=%2Fcotisations',
      );
    });

    test('après une déconnexion volontaire, pas de from', () {
      expect(
        go(const SessionSignedOut(SignedOutReason.userRequest), '/profil'),
        '/connexion',
      );
    });

    test('l\'accueil n\'est pas retenu', () {
      expect(go(_signedOut, '/accueil'), '/connexion');
    });

    test('un from externe est ignoré', () {
      expect(
        go(_signedOut, '/demarrage?from=https%3A%2F%2Fpirate.test'),
        '/connexion',
      );
      expect(go(_signedOut, '/demarrage?from=%2F%2Fpirate.test'), '/connexion');
    });
  });

  group('candidat', () {
    test('seulement le suivi de l\'adhésion', () {
      expect(go(_candidate, '/adhesion/suivi'), isNull);
      for (final path in [
        '/accueil',
        '/carte',
        '/connexion',
        '/scan',
        '/demarrage',
        '/dev/composants',
      ]) {
        expect(go(_candidate, path), '/adhesion/suivi', reason: path);
      }
    });
  });

  group('membre', () {
    test('onglets et écrans hors onglets accessibles', () {
      for (final path in [
        '/accueil',
        '/carte',
        '/evenements',
        '/evenements/joe-2026',
        '/cotisations',
        '/profil',
        '/profil/vitrine',
        '/actualites/une-actualite',
        '/notifications',
        '/opportunites/40',
      ]) {
        expect(go(_member, path), isNull, reason: path);
      }
    });

    test('connexion, démarrage, racine et suivi → accueil', () {
      for (final path in [
        '/',
        '/connexion',
        '/demarrage',
        '/adhesion/suivi',
        '/activer-mon-compte?token=x',
      ]) {
        expect(go(_member, path), '/accueil', reason: path);
      }
    });

    test('après connexion, retour à l\'écran demandé', () {
      expect(go(_member, '/connexion?from=%2Fcarte'), '/carte');
      expect(
        go(_member, '/demarrage?from=%2Fopportunites%2F40'),
        '/opportunites/40',
      );
    });

    test('scan réservé à attendance.scan', () {
      expect(go(_member, '/scan'), '/accueil');
      expect(go(_bureau, '/scan'), isNull);
    });
  });

  group('outils de développement', () {
    test('accessibles en dev', () {
      expect(go(_member, '/dev/composants'), isNull);
      expect(go(_signedOut, '/dev/composants'), isNull);
    });

    test('jamais en prod', () {
      expect(go(_member, '/dev/composants', devTools: false), '/accueil');
      expect(go(_signedOut, '/dev/composants', devTools: false), '/accueil');
    });
  });

  group('configuration', () {
    test('lecture en cours → démarrage, en gardant l\'écran demandé', () {
      expect(
        go(_member, '/carte', gate: const GateChecking()),
        '/demarrage?from=%2Fcarte',
      );
      expect(go(_member, '/demarrage', gate: const GateChecking()), isNull);
    });

    test('mise à jour exigée → écran bloquant, quelle que soit la session', () {
      for (final session in [
        _member,
        _candidate,
        _signedOut,
        const SessionLoading(),
      ]) {
        expect(
          go(session, '/carte', gate: GateUpdateRequired(_config)),
          '/mise-a-jour',
        );
        expect(
          go(session, '/mise-a-jour', gate: GateUpdateRequired(_config)),
          isNull,
        );
      }
    });

    test('maintenance → écran bloquant', () {
      expect(
        go(_member, '/accueil', gate: GateMaintenance(_config)),
        '/maintenance',
      );
      expect(
        go(_member, '/maintenance', gate: GateMaintenance(_config)),
        isNull,
      );
    });

    test('fin de maintenance : on quitte l\'écran bloquant', () {
      expect(go(_member, '/maintenance'), '/accueil');
      expect(go(_signedOut, '/maintenance'), '/connexion');
      expect(go(_candidate, '/mise-a-jour'), '/adhesion/suivi');
    });
  });
}
