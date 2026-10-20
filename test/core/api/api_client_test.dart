import 'dart:io';

import 'package:aeenci_app/core/api/api_client.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late MemoryTokenStore tokens;
  late ApiClient client;

  ApiClient build({void Function(String)? log}) => ApiClient(
    baseUrl: 'https://api.test/api/v1',
    tokens: tokens,
    adapter: adapter,
    log: log,
  );

  setUp(() {
    adapter = FakeHttpAdapter(
      (_) => const FakeResponse(200, {'data': <String, Object?>{}}),
    );
    tokens = MemoryTokenStore();
    client = build();
  });

  tearDown(() => client.dispose());

  void respond(
    int status, [
    Object? body,
    Map<String, List<String>> headers = const {},
  ]) {
    adapter.handler = (_) => FakeResponse(status, body, headers);
  }

  Future<ApiException> failure(Future<Object?> call) async {
    try {
      await call;
    } on ApiException catch (e) {
      return e;
    }
    fail('ApiException attendue');
  }

  group('requêtes', () {
    test('envoie Accept: application/json et le jeton Bearer', () async {
      await tokens.write('secret-token');
      await client.getData('/me', (json) => json);
      final request = adapter.requests.single;
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['Authorization'], 'Bearer secret-token');
      expect(request.uri.toString(), 'https://api.test/api/v1/me');
    });

    test('sans jeton, pas d\'en-tête Authorization', () async {
      await client.getData('/app/config', (json) => json);
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('getData déballe data', () async {
      respond(200, {
        'data': {'id': 7},
      });
      expect(await client.getData('/me', (json) => json['id']), 7);
    });

    test('getPage lit la pagination et les compteurs de meta', () async {
      respond(200, {
        'data': [
          {'id': 1},
          {'id': 2},
        ],
        'meta': {
          'current_page': 1,
          'last_page': 3,
          'per_page': 2,
          'total': 6,
          'unread_count': 4,
        },
      });
      final page = await client.getPage(
        '/me/notifications',
        (json) => json['id'],
      );
      expect(page.items, [1, 2]);
      expect(page.hasMore, isTrue);
      expect(page.total, 6);
      expect(page.count('unread_count'), 4);
      expect(page.count('absent'), 0);
      expect(adapter.requests.single.queryParameters['page'], 1);
    });

    test('les paramètres null ne sont pas envoyés', () async {
      respond(200, {'data': <Object?>[]});
      await client.getList(
        '/events',
        (json) => json,
        query: {'type': null, 'upcoming': 1},
      );
      expect(adapter.requests.single.queryParameters, {'upcoming': 1});
    });

    test('getOptional renvoie null sur 204', () async {
      respond(204);
      expect(
        await client.getOptional('/meetings/next', (json) => json),
        isNull,
      );
    });

    test('sendObject accepte une réponse avec ou sans data', () async {
      respond(200, {'token': 't', 'user': <String, Object?>{}});
      expect((await client.sendObject('POST', '/auth/login'))['token'], 't');
      respond(200, {
        'data': {'token': 'u'},
      });
      expect((await client.sendObject('POST', '/auth/login'))['token'], 'u');
    });

    test('send renvoie null sur 204', () async {
      respond(204);
      expect(await client.send('DELETE', '/me/registrations/3'), isNull);
    });

    test('corps inattendu → UnknownApiException', () async {
      respond(200, {'oops': true});
      expect(
        await failure(client.getData('/me', (json) => json)),
        isA<UnknownApiException>(),
      );
    });
  });

  group('erreurs', () {
    test('réseau injoignable → NetworkException', () async {
      adapter.handler = (_) =>
          throw const SocketException('Network is unreachable');
      expect(
        await failure(client.getData('/me', (json) => json)),
        isA<NetworkException>(),
      );
    });

    final cases = <int, Matcher>{
      403: isA<ForbiddenException>(),
      404: isA<NotFoundException>(),
      410: isA<GoneException>(),
      500: isA<ServerException>().having(
        (e) => e.statusCode,
        'statusCode',
        500,
      ),
      503: isA<ServerException>(),
      418: isA<UnknownApiException>().having(
        (e) => e.statusCode,
        'statusCode',
        418,
      ),
    };
    for (final MapEntry(key: status, value: matcher) in cases.entries) {
      test('$status', () async {
        respond(status, {'message': 'Erreur'});
        final error = await failure(client.getData('/me', (json) => json));
        expect(error, matcher);
        expect(error.message, 'Erreur');
      });
    }

    test('422 → erreurs par champ', () async {
      respond(422, {
        'message': 'Les données sont invalides.',
        'errors': {
          'email': ['Adresse déjà utilisée.', 'Autre message'],
          'event': 'Inscriptions fermées.',
        },
      });
      final error = await failure(client.send('POST', '/me/registrations'));
      expect(error, isA<ValidationException>());
      final validation = error as ValidationException;
      expect(validation.errorFor('email'), 'Adresse déjà utilisée.');
      expect(validation.errorFor('event'), 'Inscriptions fermées.');
      expect(validation.errorFor('password'), isNull);
    });

    test('429 → TooManyRequestsException avec Retry-After', () async {
      respond(
        429,
        {'message': 'Trop de requêtes'},
        {
          'retry-after': ['60'],
        },
      );
      final error = await failure(client.send('POST', '/auth/forgot-password'));
      expect(
        error,
        isA<TooManyRequestsException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 60),
        ),
      );
    });
  });

  group('401', () {
    test('efface le jeton et prévient la session', () async {
      await tokens.write('expired');
      respond(401, {'message': 'Unauthenticated.'});
      var notified = 0;
      final sub = client.unauthorized.listen((_) => notified++);
      addTearDown(sub.cancel);

      expect(
        await failure(client.getData('/me', (json) => json)),
        isA<UnauthorizedException>(),
      );
      await pumpEventQueue();
      expect(await tokens.read(), isNull);
      expect(notified, 1);
    });

    test('pas de déconnexion sur la route de connexion', () async {
      await tokens.write('kept');
      respond(401);
      var notified = 0;
      final sub = client.unauthorized.listen((_) => notified++);
      addTearDown(sub.cancel);

      await failure(client.sendObject('POST', '/auth/login'));
      await pumpEventQueue();
      expect(await tokens.read(), 'kept');
      expect(notified, 0);
    });
  });

  test(
    'le journal de dev ne contient ni jeton, ni paramètre, ni corps',
    () async {
      final logs = <String>[];
      client.dispose();
      client = build(log: logs.add);
      await tokens.write('secret-token');
      respond(200, {
        'data': [
          {'email': 'membre.test@exemple.com'},
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'per_page': 20, 'total': 1},
      });
      await client.getPage(
        '/me/notifications',
        (json) => json,
        query: {'q': 'privé'},
      );
      respond(422, {
        'message': 'Mot de passe incorrect',
        'errors': {
          'password': ['x'],
        },
      });
      await failure(
        client.send('DELETE', '/me/account', data: {'password': 'motdepasse'}),
      );

      expect(logs, ['GET /me/notifications → 200', 'DELETE /me/account → 422']);
    },
  );
}
