import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/auth/presentation/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_container.dart';

void main() {
  late MemoryTokenStore tokens;
  late MemoryCacheStore cache;
  late ProviderContainer container;

  Future<SessionState> start({String? token}) async {
    tokens = MemoryTokenStore(token);
    container = ProviderContainer(
      overrides: testOverrides(tokens: tokens, cache: cache),
    );
    addTearDown(container.dispose);
    container.read(sessionControllerProvider);
    await pumpEventQueue();
    return container.read(sessionControllerProvider);
  }

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);

  void failNext(MockFailure failure, {bool once = true}) => container
      .read(mockBehaviorControllerProvider.notifier)
      .set(MockBehavior.instant.copyWith(failure: failure, failOnce: once));

  setUp(() => cache = MemoryCacheStore());

  group('démarrage', () {
    test('sans jeton → déconnecté', () async {
      expect(await start(), isA<SessionSignedOut>());
    });

    test('membre admis → SessionMember', () async {
      final state = await start(token: MockPersona.member.token);
      expect(state, isA<SessionMember>());
      expect((state as SessionMember).member.memberNumber, 'TEST-0001');
      expect(state.can(Abilities.attendanceScan), isFalse);
      expect(state.offlineSince, isNull);
    });

    test('membre du bureau → peut scanner', () async {
      final state = await start(token: MockPersona.bureau.token);
      expect((state as SessionMember).can(Abilities.attendanceScan), isTrue);
    });

    test('candidat → SessionCandidate', () async {
      expect(
        await start(token: MockPersona.candidate.token),
        isA<SessionCandidate>(),
      );
    });

    test('jeton refusé (401) → déconnecté, jeton et cache effacés', () async {
      await cache.write('autre', 1);
      final state = await start(token: 'jeton-inconnu');
      expect(
        state,
        isA<SessionSignedOut>().having(
          (s) => s.reason,
          'reason',
          SignedOutReason.expired,
        ),
      );
      expect(await tokens.read(), isNull);
      expect(cache.isEmpty, isTrue);
    });
  });

  group('hors connexion', () {
    test('fiche en cache → membre, avec la date', () async {
      await start(token: MockPersona.member.token);
      failNext(MockFailure.network);
      await controller().restore();
      final state = container.read(sessionControllerProvider);
      expect(state, isA<SessionMember>());
      expect((state as SessionMember).offlineSince, isNotNull);
    });

    test('sans cache → indisponible, puis Réessayer', () async {
      tokens = MemoryTokenStore(MockPersona.member.token);
      container = ProviderContainer(
        overrides: testOverrides(tokens: tokens, cache: cache),
      );
      addTearDown(container.dispose);
      failNext(MockFailure.network);
      container.read(sessionControllerProvider);
      await pumpEventQueue();
      expect(
        container.read(sessionControllerProvider),
        isA<SessionUnavailable>().having(
          (s) => s.error,
          'error',
          isA<NetworkException>(),
        ),
      );

      await controller().restore();
      expect(container.read(sessionControllerProvider), isA<SessionMember>());
    });
  });

  group('connexion', () {
    test('identifiants valides → membre, jeton enregistré', () async {
      await start();
      await controller().signIn(
        email: ' Membre.Test@exemple.com ',
        password: mockPassword,
      );
      expect(container.read(sessionControllerProvider), isA<SessionMember>());
      expect(await tokens.read(), MockPersona.member.token);
    });

    test('identifiants faux → 422 sous email, toujours déconnecté', () async {
      await start();
      await expectLater(
        controller().signIn(email: MockPersona.member.email, password: 'faux'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.errorFor('email'),
            'email',
            isNotNull,
          ),
        ),
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionSignedOut>(),
      );
      expect(await tokens.read(), isNull);
    });

    test('compte sans fiche de membre → déconnecté avec le motif', () async {
      await start();
      await controller().signIn(
        email: mockNoMemberEmail,
        password: mockPassword,
      );
      expect(
        container.read(sessionControllerProvider),
        isA<SessionSignedOut>().having(
          (s) => s.reason,
          'reason',
          SignedOutReason.noMemberProfile,
        ),
      );
      expect(await tokens.read(), isNull);
    });

    test('le cache d\'un compte précédent est vidé', () async {
      await start();
      await cache.write('me/card', {'member_number': 'AUTRE'});
      await controller().signIn(
        email: MockPersona.candidate.email,
        password: mockPassword,
      );
      expect(await cache.read('me/card'), isNull);
      expect(
        container.read(sessionControllerProvider),
        isA<SessionCandidate>(),
      );
    });
  });

  test('déconnexion : jeton et cache effacés, même hors connexion', () async {
    await start(token: MockPersona.member.token);
    expect(await cache.read('me'), isNotNull);
    failNext(MockFailure.network);
    await controller().signOut();
    expect(container.read(sessionControllerProvider), isA<SessionSignedOut>());
    expect(await tokens.read(), isNull);
    expect(cache.isEmpty, isTrue);
  });

  test('un 401 pendant la session déconnecte', () async {
    await start(token: MockPersona.member.token);
    await container.read(apiClientProvider).signalUnauthorized();
    await pumpEventQueue();
    expect(
      container.read(sessionControllerProvider),
      isA<SessionSignedOut>().having(
        (s) => s.reason,
        'reason',
        SignedOutReason.expired,
      ),
    );
    expect(cache.isEmpty, isTrue);
  });
}
