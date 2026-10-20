import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/domain/enums.dart';
import '../../home/presentation/home_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/domain/app_notification.dart';
import '../data/profile_repository.dart';
import '../domain/education.dart';
import '../domain/professional_profile.dart';
import '../domain/profile_inputs.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Profil professionnel (même cache que le rappel de l'accueil). Chaque
/// modification renvoie le profil à jour ; les erreurs remontent à l'écran.
class ProfessionalProfileController
    extends AsyncNotifier<Cached<ProfessionalProfile>> {
  static const cacheKey = 'me/profile';

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<Cached<ProfessionalProfile>> build() =>
      fetchWithCache<ProfessionalProfile>(
        cache: ref.read(cacheStoreProvider),
        key: cacheKey,
        fetch: _repo.fetchProfessionalProfile,
        toJson: (profile) => profile.toJson(),
        fromJson: (json) =>
            ProfessionalProfile.fromJson(json! as Map<String, dynamic>),
      );

  Future<void> _set(ProfessionalProfile profile) async {
    await ref.read(cacheStoreProvider).write(cacheKey, profile.toJson());
    state = AsyncData(Cached(profile));
    ref.invalidate(homeProfileReminderProvider);
  }

  Future<void> _refetch() async => _set(await _repo.fetchProfessionalProfile());

  Future<void> updateFields(Map<String, Object?> fields) async =>
      _set(await _repo.updateProfessionalProfile(fields));

  Future<void> uploadCv(String path) async => _set(await _repo.uploadCv(path));

  Future<void> setShowcase({required bool isPublic}) async =>
      _set(await _repo.setShowcase(isPublic: isPublic));

  Future<void> saveExperience(ExperienceInput input, {int? id}) async {
    if (id == null) {
      await _repo.createExperience(input);
    } else {
      await _repo.updateExperience(id, input);
    }
    await _refetch();
  }

  Future<void> deleteExperience(int id) async {
    await _repo.deleteExperience(id);
    await _refetch();
  }

  Future<void> savePortfolioItem(PortfolioInput input, {int? id}) async {
    if (id == null) {
      await _repo.createPortfolioItem(input);
    } else {
      await _repo.updatePortfolioItem(id, input);
    }
    await _refetch();
  }

  Future<void> deletePortfolioItem(int id) async {
    await _repo.deletePortfolioItem(id);
    await _refetch();
  }
}

final professionalProfileProvider =
    AsyncNotifierProvider.autoDispose<
      ProfessionalProfileController,
      Cached<ProfessionalProfile>
    >(ProfessionalProfileController.new);

/// Parcours scolaire, du plus récent au plus ancien.
class EducationsController extends AsyncNotifier<Cached<List<Education>>> {
  static const cacheKey = 'me/educations';

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  static List<Education> _sorted(List<Education> list) =>
      [...list]..sort((a, b) {
        // En cours d'abord, puis par année de fin puis de début décroissantes.
        final endA = a.endYear ?? 9999;
        final endB = b.endYear ?? 9999;
        if (endA != endB) return endB.compareTo(endA);
        return (b.startYear ?? 0).compareTo(a.startYear ?? 0);
      });

  @override
  Future<Cached<List<Education>>> build() async {
    final result = await fetchWithCache<List<Education>>(
      cache: ref.read(cacheStoreProvider),
      key: cacheKey,
      fetch: _repo.fetchEducations,
      toJson: (list) => [for (final e in list) e.toJson()],
      fromJson: (json) => _maps(json).map(Education.fromJson).toList(),
    );
    return Cached(_sorted(result.data), offlineSince: result.offlineSince);
  }

  Future<void> _reload() async {
    final list = _sorted(await _repo.fetchEducations());
    await ref.read(cacheStoreProvider).write(cacheKey, [
      for (final e in list) e.toJson(),
    ]);
    state = AsyncData(Cached(list));
  }

  Future<void> save(EducationInput input, {int? id}) async {
    if (id == null) {
      await _repo.createEducation(input);
    } else {
      await _repo.updateEducation(id, input);
    }
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.deleteEducation(id);
    await _reload();
  }
}

final educationsProvider =
    AsyncNotifierProvider.autoDispose<
      EducationsController,
      Cached<List<Education>>
    >(EducationsController.new);

/// Niveaux d'études proposés (liste tenue par le bureau).
final educationLevelsProvider =
    FutureProvider.autoDispose<Cached<List<EducationLevel>>>(
      (ref) => fetchWithCache<List<EducationLevel>>(
        cache: ref.read(cacheStoreProvider),
        key: 'education-levels',
        fetch: ref.read(profileRepositoryProvider).fetchEducationLevels,
        toJson: (list) => [for (final l in list) l.toJson()],
        fromJson: (json) => _maps(json).map(EducationLevel.fromJson).toList(),
      ),
    );

/// Réglages de notifications par catégorie. Un changement s'affiche tout
/// de suite et revient en arrière si l'API le refuse.
class NotificationPreferencesController
    extends AsyncNotifier<Cached<List<NotificationPreference>>> {
  static const cacheKey = 'me/notification-preferences';

  @override
  Future<Cached<List<NotificationPreference>>> build() =>
      fetchWithCache<List<NotificationPreference>>(
        cache: ref.read(cacheStoreProvider),
        key: cacheKey,
        fetch: ref.read(notificationsRepositoryProvider).fetchPreferences,
        toJson: (list) => [for (final p in list) p.toJson()],
        fromJson: (json) =>
            _maps(json).map(NotificationPreference.fromJson).toList(),
      );

  Future<void> toggle(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    final previous = state.value;
    if (previous == null) return;
    state = AsyncData(
      Cached([
        for (final p in previous.data)
          p.category == category ? p.copyWith(enabled: enabled) : p,
      ], offlineSince: previous.offlineSince),
    );
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updatePreferences({category: enabled});
      await ref.read(cacheStoreProvider).write(cacheKey, [
        for (final p in updated) p.toJson(),
      ]);
      state = AsyncData(Cached(updated));
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationPreferencesController,
      Cached<List<NotificationPreference>>
    >(NotificationPreferencesController.new);
