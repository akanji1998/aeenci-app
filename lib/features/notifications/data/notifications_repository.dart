import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/token_store.dart';
import '../../../core/domain/enums.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_profile_store.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/app_notification.dart';

part 'notifications_repository.g.dart';

/// Centre de notifications et réglages par catégorie.
abstract interface class NotificationsRepository {
  /// `GET /me/notifications?page=` ; `meta.unread_count` : non lues.
  Future<Paginated<AppNotification>> fetchPage({int page = 1});

  /// `POST /me/notifications/read` : `ids[]`, ou `all` = `1` ; 204.
  Future<void> markRead({List<int> ids = const [], bool all = false});

  /// `GET /me/notification-preferences`.
  Future<List<NotificationPreference>> fetchPreferences();

  /// `PATCH /me/notification-preferences` : `{"events": false, …}`. Une
  /// catégorie verrouillée (`account`) est ignorée. Renvoie la liste à jour.
  Future<List<NotificationPreference>> updatePreferences(
    Map<NotificationCategory, bool> changes,
  );
}

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<AppNotification>> fetchPage({int page = 1}) =>
      _api.getPage('/me/notifications', AppNotification.fromJson, page: page);

  @override
  Future<void> markRead({List<int> ids = const [], bool all = false}) =>
      _api.send(
        'POST',
        '/me/notifications/read',
        data: all ? {'all': 1} : {'ids': ids},
      );

  @override
  Future<List<NotificationPreference>> fetchPreferences() => _api.getList(
    '/me/notification-preferences',
    NotificationPreference.fromJson,
  );

  @override
  Future<List<NotificationPreference>> updatePreferences(
    Map<NotificationCategory, bool> changes,
  ) async {
    final body = await _api.send(
      'PATCH',
      '/me/notification-preferences',
      data: {
        for (final MapEntry(:key, :value) in changes.entries) key.name: value,
      },
    );
    final data = body is Map<String, Object?> ? body['data'] : null;
    if (data is! List<Object?>) throw const UnknownApiException();
    return [
      for (final item in data)
        NotificationPreference.fromJson(item! as Map<String, dynamic>),
    ];
  }
}

class MockNotificationsRepository implements NotificationsRepository {
  const MockNotificationsRepository(this._runtime, this._tokens, this._store);

  final MockRuntime _runtime;
  final TokenStore _tokens;
  final MockProfileStore _store;

  /// Petites pages pour montrer le chargement des pages suivantes.
  static const _perPage = 5;

  @override
  Future<Paginated<AppNotification>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    final all = _store.notifications(await currentMockPersona(_tokens));
    return Paginated.fromJson({
      'data': all.skip((page - 1) * _perPage).take(_perPage).toList(),
      'meta': {
        'current_page': page,
        'last_page': (all.length / _perPage).ceil(),
        'per_page': _perPage,
        'total': all.length,
        'unread_count': all.where((n) => n['read_at'] == null).length,
      },
    }, AppNotification.fromJson);
  }

  @override
  Future<void> markRead({List<int> ids = const [], bool all = false}) async {
    await _runtime.simulate();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final n in _store.notifications(await currentMockPersona(_tokens))) {
      if (n['read_at'] == null && (all || ids.contains(n['id']))) {
        n['read_at'] = now;
      }
    }
  }

  List<NotificationPreference> _list(Map<String, bool> prefs) => [
    const NotificationPreference(
      category: NotificationCategory.account,
      enabled: true,
      locked: true,
    ),
    for (final MapEntry(:key, :value) in prefs.entries)
      NotificationPreference.fromJson({
        'category': key,
        'enabled': value,
        'locked': false,
      }),
  ];

  @override
  Future<List<NotificationPreference>> fetchPreferences() async {
    await _runtime.simulate();
    return _list(_store.preferences(await currentMockPersona(_tokens)));
  }

  @override
  Future<List<NotificationPreference>> updatePreferences(
    Map<NotificationCategory, bool> changes,
  ) async {
    await _runtime.simulate();
    final prefs = _store.preferences(await currentMockPersona(_tokens));
    for (final MapEntry(:key, :value) in changes.entries) {
      // `account` est verrouillée : ignorée, comme côté backend.
      if (prefs.containsKey(key.name)) prefs[key.name] = value;
    }
    return _list(prefs);
  }
}

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockNotificationsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
        ref.watch(mockProfileStoreProvider),
      )
    : ApiNotificationsRepository(ref.watch(apiClientProvider));
