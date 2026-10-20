import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/event.dart';

part 'events_repository.g.dart';

/// Inscriptions et assemblées. Liste et inscription arrivent au lot 4.
abstract interface class EventsRepository {
  /// `GET /me/registrations` : inscriptions à venir et passées.
  Future<List<Registration>> fetchRegistrations();

  /// `GET /meetings/next` : `null` s'il n'y a pas d'assemblée prévue (204).
  Future<NextMeeting?> fetchNextMeeting();
}

class ApiEventsRepository implements EventsRepository {
  const ApiEventsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Registration>> fetchRegistrations() =>
      _api.getList('/me/registrations', Registration.fromJson);

  @override
  Future<NextMeeting?> fetchNextMeeting() =>
      _api.getOptional('/meetings/next', NextMeeting.fromJson);
}

class MockEventsRepository implements EventsRepository {
  const MockEventsRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<List<Registration>> fetchRegistrations() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final data =
        persona.registrationsJson(DateTime.now())['data']! as List<Object?>;
    return [
      for (final item in data)
        Registration.fromJson(item! as Map<String, dynamic>),
    ];
  }

  @override
  Future<NextMeeting?> fetchNextMeeting() async {
    await _runtime.simulate();
    return NextMeeting.fromJson(
      mockNextMeetingJson(DateTime.now())['data']! as Map<String, dynamic>,
    );
  }
}

@Riverpod(keepAlive: true)
EventsRepository eventsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockEventsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiEventsRepository(ref.watch(apiClientProvider));
