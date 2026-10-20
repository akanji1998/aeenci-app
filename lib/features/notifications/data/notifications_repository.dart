import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/app_notification.dart';

part 'notifications_repository.g.dart';

/// Centre de notifications. Lecture et réglages arrivent au lot 7.
abstract interface class NotificationsRepository {
  /// `GET /me/notifications?page=` ; `meta.unread_count` : non lues.
  Future<Paginated<AppNotification>> fetchPage({int page = 1});
}

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<AppNotification>> fetchPage({int page = 1}) =>
      _api.getPage('/me/notifications', AppNotification.fromJson, page: page);
}

class MockNotificationsRepository implements NotificationsRepository {
  const MockNotificationsRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<Paginated<AppNotification>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    return Paginated.fromJson(
      persona.notificationsPageJson(DateTime.now()),
      AppNotification.fromJson,
    );
  }
}

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockNotificationsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiNotificationsRepository(ref.watch(apiClientProvider));
