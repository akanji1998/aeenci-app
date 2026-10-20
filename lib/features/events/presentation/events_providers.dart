import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/domain/enums.dart';
import '../../home/presentation/home_providers.dart';
import '../data/events_repository.dart';
import '../domain/event.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Filtre par type de la vue « À venir » (`null` : tous).
class EventTypeFilter extends Notifier<EventType?> {
  @override
  EventType? build() => null;

  void select(EventType? type) => state = type;
}

final eventTypeFilterProvider = NotifierProvider<EventTypeFilter, EventType?>(
  EventTypeFilter.new,
);

/// Événements à venir, éventuellement d'un seul type.
final upcomingEventsProvider = FutureProvider.autoDispose
    .family<Cached<List<Event>>, EventType?>(
      (ref, type) => fetchWithCache<List<Event>>(
        cache: ref.read(cacheStoreProvider),
        key: 'events/upcoming/${type?.name ?? 'all'}',
        fetch: () =>
            ref.read(eventsRepositoryProvider).fetchUpcomingEvents(type: type),
        toJson: (list) => [for (final e in list) e.toJson()],
        fromJson: (json) => _maps(json).map(Event.fromJson).toList(),
      ),
    );

/// Détail d'un événement.
final eventDetailProvider = FutureProvider.autoDispose
    .family<Cached<Event>, String>(
      (ref, slug) => fetchWithCache<Event>(
        cache: ref.read(cacheStoreProvider),
        key: 'events/$slug',
        fetch: () => ref.read(eventsRepositoryProvider).fetchEvent(slug),
        toJson: (event) => event.toJson(),
        fromJson: (json) => Event.fromJson(json! as Map<String, dynamic>),
      ),
    );

/// Inscriptions du membre (même cache que le bloc « Bientôt » de l'accueil).
final myRegistrationsProvider =
    FutureProvider.autoDispose<Cached<List<Registration>>>(
      (ref) => fetchWithCache<List<Registration>>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/registrations',
        fetch: ref.read(eventsRepositoryProvider).fetchRegistrations,
        toJson: (list) => [for (final r in list) r.toJson()],
        fromJson: (json) => _maps(json).map(Registration.fromJson).toList(),
      ),
    );

/// Présences aux assemblées des 12 derniers mois.
final attendancesProvider =
    FutureProvider.autoDispose<Cached<List<Attendance>>>(
      (ref) => fetchWithCache<List<Attendance>>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/attendances',
        fetch: ref.read(eventsRepositoryProvider).fetchAttendances,
        toJson: (list) => [for (final a in list) a.toJson()],
        fromJson: (json) => _maps(json).map(Attendance.fromJson).toList(),
      ),
    );

/// Inscription et annulation. Les erreurs (ApiException) remontent à
/// l'écran, qui les explique.
class RegistrationActions {
  const RegistrationActions(this._ref);

  final Ref _ref;

  Future<void> register(String eventSlug) async {
    await _ref.read(eventsRepositoryProvider).register(eventSlug);
    _refresh();
  }

  Future<void> cancel(Registration registration) async {
    await _ref.read(eventsRepositoryProvider).cancel(registration.id);
    _refresh();
  }

  void _refresh() {
    _ref
      ..invalidate(myRegistrationsProvider)
      ..invalidate(homeNextRegistrationProvider);
  }
}

final registrationActionsProvider = Provider<RegistrationActions>(
  RegistrationActions.new,
);
