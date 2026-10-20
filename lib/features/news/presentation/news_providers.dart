import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../data/news_repository.dart';
import '../domain/news.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Actualités chargées jusqu'ici.
@immutable
class NewsListState {
  const NewsListState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<News> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? loadMoreError;

  NewsListState copyWith({
    List<News>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    ApiException? loadMoreError,
  }) => NewsListState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// Liste des actualités, page par page ; la première est gardée hors
/// connexion.
class NewsListController extends AsyncNotifier<Cached<NewsListState>> {
  @override
  Future<Cached<NewsListState>> build() => fetchWithCache<NewsListState>(
    cache: ref.read(cacheStoreProvider),
    key: 'news',
    fetch: () async {
      final page = await ref.read(newsRepositoryProvider).fetchPage();
      return NewsListState(
        items: page.items,
        page: page.currentPage,
        hasMore: page.hasMore,
      );
    },
    toJson: (state) => {
      'items': [for (final n in state.items) n.toJson()],
      'page': state.page,
      'has_more': state.hasMore,
    },
    fromJson: (json) {
      final map = json! as Map<String, dynamic>;
      return NewsListState(
        items: _maps(map['items']).map(News.fromJson).toList(),
        page: map['page']! as int,
        hasMore: map['has_more']! as bool,
      );
    },
  );

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.data.hasMore || current.data.loadingMore) {
      return;
    }
    final data = current.data;
    void emit(NewsListState next) =>
        state = AsyncData(Cached(next, offlineSince: current.offlineSince));
    emit(data.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(newsRepositoryProvider)
          .fetchPage(page: data.page + 1);
      emit(
        data.copyWith(
          items: [...data.items, ...next.items],
          page: next.currentPage,
          hasMore: next.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException catch (error) {
      emit(data.copyWith(loadingMore: false, loadMoreError: error));
    }
  }
}

final newsListProvider =
    AsyncNotifierProvider.autoDispose<
      NewsListController,
      Cached<NewsListState>
    >(NewsListController.new);

/// Un article, gardé hors connexion une fois lu.
final newsDetailProvider = FutureProvider.autoDispose
    .family<Cached<News>, String>(
      (ref, slug) => fetchWithCache<News>(
        cache: ref.read(cacheStoreProvider),
        key: 'news/$slug',
        fetch: () => ref.read(newsRepositoryProvider).fetchBySlug(slug),
        toJson: (news) => news.toJson(),
        fromJson: (json) => News.fromJson(json! as Map<String, dynamic>),
      ),
    );
