import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/utils/clock.dart';
import '../../contributions/data/contributions_repository.dart';
import '../../contributions/domain/contribution.dart';
import '../../events/data/events_repository.dart';
import '../../events/domain/event.dart';
import '../../news/data/news_repository.dart';
import '../../news/domain/news.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../opportunities/data/opportunities_repository.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/professional_profile.dart';
import '../domain/home_rules.dart';

// Chaque bloc de l'accueil se charge à part : une erreur n'en masque
// qu'un. Tous passent par le cache pour s'afficher hors connexion.

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Cotisation de l'année académique en cours.
final homeContributionProvider =
    FutureProvider.autoDispose<Cached<Contribution?>>((ref) async {
      final all = await fetchWithCache<List<Contribution>>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/contributions',
        fetch: ref.read(contributionsRepositoryProvider).fetchContributions,
        toJson: (list) => [for (final c in list) c.toJson()],
        fromJson: (json) => _maps(json).map(Contribution.fromJson).toList(),
      );
      return Cached(
        currentContribution(all.data, ref.read(clockProvider)()),
        offlineSince: all.offlineSince,
      );
    });

/// Prochain événement où le membre est inscrit.
final homeNextRegistrationProvider =
    FutureProvider.autoDispose<Cached<Registration?>>((ref) async {
      final all = await fetchWithCache<List<Registration>>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/registrations',
        fetch: ref.read(eventsRepositoryProvider).fetchRegistrations,
        toJson: (list) => [for (final r in list) r.toJson()],
        fromJson: (json) => _maps(json).map(Registration.fromJson).toList(),
      );
      return Cached(
        nextRegistration(all.data, ref.read(clockProvider)()),
        offlineSince: all.offlineSince,
      );
    });

/// Prochaine assemblée mensuelle (`null` s'il n'y en a pas).
final homeNextMeetingProvider =
    FutureProvider.autoDispose<Cached<NextMeeting?>>(
      (ref) => fetchWithCache<NextMeeting?>(
        cache: ref.read(cacheStoreProvider),
        key: 'meetings/next',
        fetch: ref.read(eventsRepositoryProvider).fetchNextMeeting,
        toJson: (meeting) => meeting?.toJson(),
        fromJson: (json) => json == null
            ? null
            : NextMeeting.fromJson(json as Map<String, dynamic>),
      ),
    );

/// Offres non vues : leur nombre et la plus récente.
@immutable
class HomeOpportunities {
  const HomeOpportunities({required this.unseenCount, this.latest});

  final int unseenCount;
  final Opportunity? latest;

  Map<String, Object?> toJson() => {
    'unseen_count': unseenCount,
    'latest': latest?.toJson(),
  };

  factory HomeOpportunities.fromJson(Map<String, dynamic> json) =>
      HomeOpportunities(
        unseenCount: json['unseen_count']! as int,
        latest: json['latest'] == null
            ? null
            : Opportunity.fromJson(json['latest'] as Map<String, dynamic>),
      );
}

final homeOpportunitiesProvider =
    FutureProvider.autoDispose<Cached<HomeOpportunities>>(
      (ref) => fetchWithCache<HomeOpportunities>(
        cache: ref.read(cacheStoreProvider),
        key: 'home/opportunities',
        fetch: () async {
          final page = await ref
              .read(opportunitiesRepositoryProvider)
              .fetchPage();
          return HomeOpportunities(
            unseenCount: page.count('unseen_count'),
            latest: page.items.firstOrNull,
          );
        },
        toJson: (data) => data.toJson(),
        fromJson: (json) =>
            HomeOpportunities.fromJson(json! as Map<String, dynamic>),
      ),
    );

/// Rappel « Complète ton profil pro ».
final homeProfileReminderProvider = FutureProvider.autoDispose<Cached<bool>>((
  ref,
) async {
  final profile = await fetchWithCache<ProfessionalProfile>(
    cache: ref.read(cacheStoreProvider),
    key: 'me/profile',
    fetch: ref.read(profileRepositoryProvider).fetchProfessionalProfile,
    toJson: (profile) => profile.toJson(),
    fromJson: (json) =>
        ProfessionalProfile.fromJson(json! as Map<String, dynamic>),
  );
  return Cached(
    profileNeedsCompletion(profile.data),
    offlineSince: profile.offlineSince,
  );
});

/// Les deux dernières actualités.
final homeNewsProvider = FutureProvider.autoDispose<Cached<List<News>>>(
  (ref) => fetchWithCache<List<News>>(
    cache: ref.read(cacheStoreProvider),
    key: 'home/news',
    fetch: () async => (await ref.read(newsRepositoryProvider).fetchPage())
        .items
        .take(2)
        .toList(),
    toJson: (list) => [for (final n in list) n.toJson()],
    fromJson: (json) => _maps(json).map(News.fromJson).toList(),
  ),
);

/// Nombre de notifications non lues (0 si inconnu).
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  try {
    final page = await ref.read(notificationsRepositoryProvider).fetchPage();
    return page.count('unread_count');
  } on ApiException {
    return 0;
  }
});

/// Tous les blocs, pour « tirer pour actualiser ».
final homeBlockProviders = <ProviderOrFamily>[
  homeContributionProvider,
  homeNextRegistrationProvider,
  homeNextMeetingProvider,
  homeOpportunitiesProvider,
  homeProfileReminderProvider,
  homeNewsProvider,
  unreadNotificationsProvider,
];
