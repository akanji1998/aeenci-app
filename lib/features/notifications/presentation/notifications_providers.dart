import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';
import '../../auth/presentation/session_controller.dart';
import '../../home/presentation/home_providers.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Notifications chargées jusqu'ici.
@immutable
class NotificationsState {
  const NotificationsState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.unreadCount,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final int unreadCount;
  final bool loadingMore;
  final ApiException? loadMoreError;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    int? unreadCount,
    bool? loadingMore,
    ApiException? loadMoreError,
  }) => NotificationsState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    unreadCount: unreadCount ?? this.unreadCount,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// Centre de notifications, page par page ; la première page est gardée
/// hors connexion. Marquer comme lu s'affiche tout de suite et revient en
/// arrière si l'API refuse.
class NotificationsController
    extends AsyncNotifier<Cached<NotificationsState>> {
  static const cacheKey = 'me/notifications';

  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<Cached<NotificationsState>> build() =>
      fetchWithCache<NotificationsState>(
        cache: ref.read(cacheStoreProvider),
        key: cacheKey,
        fetch: () async {
          final page = await _repo.fetchPage();
          return NotificationsState(
            items: page.items,
            page: page.currentPage,
            hasMore: page.hasMore,
            unreadCount: page.count('unread_count'),
          );
        },
        toJson: (state) => {
          'items': [for (final n in state.items) n.toJson()],
          'page': state.page,
          'has_more': state.hasMore,
          'unread_count': state.unreadCount,
        },
        fromJson: (json) {
          final map = json! as Map<String, dynamic>;
          return NotificationsState(
            items: _maps(map['items']).map(AppNotification.fromJson).toList(),
            page: map['page']! as int,
            hasMore: map['has_more']! as bool,
            unreadCount: map['unread_count']! as int,
          );
        },
      );

  void _emit(NotificationsState data, Cached<NotificationsState> from) =>
      state = AsyncData(Cached(data, offlineSince: from.offlineSince));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.data.hasMore || current.data.loadingMore) {
      return;
    }
    final data = current.data;
    _emit(data.copyWith(loadingMore: true), current);
    try {
      final next = await _repo.fetchPage(page: data.page + 1);
      _emit(
        data.copyWith(
          items: [...data.items, ...next.items],
          page: next.currentPage,
          hasMore: next.hasMore,
          unreadCount: next.count('unread_count'),
          loadingMore: false,
        ),
        current,
      );
    } on ApiException catch (error) {
      _emit(data.copyWith(loadingMore: false, loadMoreError: error), current);
    }
  }

  Future<void> _markRead(bool Function(AppNotification n) which) async {
    final current = state.value;
    if (current == null) return;
    final data = current.data;
    final now = DateTime.now();
    final ids = [
      for (final n in data.items)
        if (!n.isRead && which(n)) n.id,
    ];
    if (ids.isEmpty && data.unreadCount == 0) return;
    final all = identical(which, _everything);
    _emit(
      data.copyWith(
        items: [
          for (final n in data.items)
            ids.contains(n.id) ? n.copyWith(readAt: now) : n,
        ],
        unreadCount: all
            ? 0
            : (data.unreadCount - ids.length).clamp(0, 1 << 30),
      ),
      current,
    );
    try {
      await _repo.markRead(ids: ids, all: all);
      ref.invalidate(unreadNotificationsProvider);
    } on ApiException {
      state = AsyncData(current);
      rethrow;
    }
  }

  static bool _everything(AppNotification n) => true;

  /// Notification ouverte depuis le centre.
  Future<void> markRead(int id) => _markRead((n) => n.id == id);

  /// « Tout marquer lu » (`all` = `1`, y compris les pages non chargées).
  Future<void> markAllRead() => _markRead(_everything);
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsController,
      Cached<NotificationsState>
    >(NotificationsController.new);

/// Clé du cache : « Plus tard » sur l'écran d'explication. Le cache se vide
/// à la déconnexion : la question revient au compte suivant.
const pushPromptDismissedKey = 'push/prompt-dismissed';

/// `true` : montrer l'écran d'explication avant la demande du système
/// (membre connecté, notifications disponibles, jamais demandées, pas
/// repoussées).
final pushPromptProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (ref.watch(sessionControllerProvider) is! SessionMember) return false;
  final push = ref.watch(pushServiceProvider);
  if (!push.available) return false;
  if (await push.permission() != PushPermission.notDetermined) return false;
  return await ref.read(cacheStoreProvider).read(pushPromptDismissedKey) ==
      null;
});

/// Autorisation actuelle (encart du profil quand elle est refusée).
final pushPermissionProvider = FutureProvider.autoDispose<PushPermission?>((
  ref,
) async {
  final push = ref.watch(pushServiceProvider);
  return push.available ? push.permission() : null;
});
