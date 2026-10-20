import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/domain/enums.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/event.dart';

part 'events_repository.g.dart';

/// Événements, inscriptions du membre et présences aux assemblées.
abstract interface class EventsRepository {
  /// `GET /events?upcoming=1&type=` : à venir, du plus proche au plus loin.
  Future<List<Event>> fetchUpcomingEvents({EventType? type});

  /// `GET /events/{slug}` : 404 si l'événement n'existe pas.
  Future<Event> fetchEvent(String slug);

  /// `POST /me/registrations` : 422 sous `event_slug` (déjà inscrit) ou
  /// sous `event` (inscriptions fermées).
  Future<Registration> register(String eventSlug);

  /// `DELETE /me/registrations/{id}` (si `can_cancel`).
  Future<void> cancel(int registrationId);

  /// `GET /me/attendances?months=` : présences aux assemblées.
  Future<List<Attendance>> fetchAttendances({int months = 12});

  /// `GET /me/registrations` : inscriptions à venir et passées.
  Future<List<Registration>> fetchRegistrations();

  /// `GET /meetings/next` : `null` s'il n'y a pas d'assemblée prévue (204).
  Future<NextMeeting?> fetchNextMeeting();
}

class ApiEventsRepository implements EventsRepository {
  const ApiEventsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Event>> fetchUpcomingEvents({EventType? type}) => _api.getList(
    '/events',
    Event.fromJson,
    query: {
      'upcoming': 1,
      'type': type == null ? null : eventTypeApiValue(type),
    },
  );

  @override
  Future<Event> fetchEvent(String slug) =>
      _api.getData('/events/${Uri.encodeComponent(slug)}', Event.fromJson);

  @override
  Future<Registration> register(String eventSlug) => _api.sendData(
    'POST',
    '/me/registrations',
    Registration.fromJson,
    data: {'event_slug': eventSlug},
  );

  @override
  Future<void> cancel(int registrationId) =>
      _api.send('DELETE', '/me/registrations/$registrationId');

  @override
  Future<List<Attendance>> fetchAttendances({int months = 12}) => _api.getList(
    '/me/attendances',
    Attendance.fromJson,
    query: {'months': months},
  );

  @override
  Future<List<Registration>> fetchRegistrations() =>
      _api.getList('/me/registrations', Registration.fromJson);

  @override
  Future<NextMeeting?> fetchNextMeeting() =>
      _api.getOptional('/meetings/next', NextMeeting.fromJson);
}

/// Mock avec un état : les inscriptions et annulations sont gardées en
/// mémoire (par compte) le temps de la session de l'application.
class MockEventsRepository implements EventsRepository {
  MockEventsRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;
  final _registrations = <MockPersona, List<Map<String, Object?>>>{};
  var _nextId = 100;

  Future<List<Map<String, Object?>>> _mine() async {
    final persona = await currentMockPersona(_tokens);
    return _registrations.putIfAbsent(persona, () {
      final data =
          persona.registrationsJson(DateTime.now())['data']! as List<Object?>;
      return [for (final item in data) item! as Map<String, Object?>];
    });
  }

  List<Map<String, Object?>> get _events =>
      mockUpcomingEventsJson(DateTime.now());

  @override
  Future<List<Event>> fetchUpcomingEvents({EventType? type}) async {
    await _runtime.simulate();
    return [
      for (final json in _events)
        if (type == null || json['type'] == eventTypeApiValue(type))
          Event.fromJson(json),
    ];
  }

  @override
  Future<Event> fetchEvent(String slug) async {
    await _runtime.simulate();
    final json = _events.where((e) => e['slug'] == slug).firstOrNull;
    if (json == null) throw const NotFoundException();
    return Event.fromJson(json);
  }

  @override
  Future<Registration> register(String eventSlug) async {
    await _runtime.simulate();
    final mine = await _mine();
    final event = _events.where((e) => e['slug'] == eventSlug).firstOrNull;
    if (event == null) throw const NotFoundException();
    if (mine.any(
      (r) => (r['event']! as Map<String, Object?>)['slug'] == eventSlug,
    )) {
      throw const ValidationException(
        errors: {
          'event_slug': ['Tu es déjà inscrit à cet événement.'],
        },
      );
    }
    if (event['registration_open'] != true) {
      throw const ValidationException(
        errors: {
          'event': ['Les inscriptions à cet événement sont fermées.'],
        },
      );
    }
    final registration = <String, Object?>{
      'id': _nextId++,
      'event': {
        'slug': event['slug'],
        'type': event['type'],
        'title': event['title'],
        'starts_at': event['starts_at'],
        'location': event['location'],
      },
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'can_cancel': true,
    };
    mine.add(registration);
    return Registration.fromJson(registration);
  }

  @override
  Future<void> cancel(int registrationId) async {
    await _runtime.simulate();
    final mine = await _mine();
    final registration = mine
        .where((r) => r['id'] == registrationId)
        .firstOrNull;
    if (registration == null) throw const NotFoundException();
    if (registration['can_cancel'] != true) {
      throw const ValidationException(
        errors: {
          'registration': ['Cette inscription ne peut plus être annulée.'],
        },
      );
    }
    mine.remove(registration);
  }

  @override
  Future<List<Attendance>> fetchAttendances({int months = 12}) async {
    await _runtime.simulate();
    await currentMockPersona(_tokens);
    return mockAttendancesJson(
      DateTime.now(),
    ).map(Attendance.fromJson).toList();
  }

  @override
  Future<List<Registration>> fetchRegistrations() async {
    await _runtime.simulate();
    return [for (final json in await _mine()) Registration.fromJson(json)];
  }

  @override
  Future<NextMeeting?> fetchNextMeeting() async {
    await _runtime.simulate();
    return NextMeeting.fromJson(
      mockNextMeetingJson(DateTime.now())['data']! as Map<String, dynamic>,
    );
  }
}

/// Valeur de `type` attendue par l'API.
String eventTypeApiValue(EventType type) => switch (type) {
  EventType.joe => 'joe',
  EventType.employmentDay => 'employment_day',
  EventType.impact => 'impact',
  EventType.other || EventType.unknown => 'other',
};

@Riverpod(keepAlive: true)
EventsRepository eventsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockEventsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiEventsRepository(ref.watch(apiClientProvider));
