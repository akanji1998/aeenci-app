import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/utils/device_services.dart';
import '../../home/presentation/home_providers.dart';
import '../data/opportunities_repository.dart';
import '../domain/opportunity.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Offres chargées jusqu'ici.
@immutable
class OpportunitiesState {
  const OpportunitiesState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Opportunity> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? loadMoreError;

  OpportunitiesState copyWith({
    List<Opportunity>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    ApiException? loadMoreError,
  }) => OpportunitiesState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// Liste des offres reçues, page par page ; la première est gardée hors
/// connexion.
class OpportunitiesController
    extends AsyncNotifier<Cached<OpportunitiesState>> {
  @override
  Future<Cached<OpportunitiesState>> build() =>
      fetchWithCache<OpportunitiesState>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/opportunities',
        fetch: () async {
          final page = await ref
              .read(opportunitiesRepositoryProvider)
              .fetchPage();
          return OpportunitiesState(
            items: page.items,
            page: page.currentPage,
            hasMore: page.hasMore,
          );
        },
        toJson: (state) => {
          'items': [for (final o in state.items) o.toJson()],
          'page': state.page,
          'has_more': state.hasMore,
        },
        fromJson: (json) {
          final map = json! as Map<String, dynamic>;
          return OpportunitiesState(
            items: _maps(map['items']).map(Opportunity.fromJson).toList(),
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
    void emit(OpportunitiesState next) =>
        state = AsyncData(Cached(next, offlineSince: current.offlineSince));
    emit(data.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(opportunitiesRepositoryProvider)
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

final opportunitiesProvider =
    AsyncNotifierProvider.autoDispose<
      OpportunitiesController,
      Cached<OpportunitiesState>
    >(OpportunitiesController.new);

/// Détail d'une offre (l'ouvrir la marque comme vue côté API), gardé hors
/// connexion une fois lu.
final opportunityDetailProvider = FutureProvider.autoDispose
    .family<Cached<OpportunityDetail>, int>((ref, id) async {
      final result = await fetchWithCache<OpportunityDetail>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/opportunities/$id',
        fetch: () => ref.read(opportunitiesRepositoryProvider).fetchDetail(id),
        toJson: (o) => o.toJson(),
        fromJson: (json) =>
            OpportunityDetail.fromJson(json! as Map<String, dynamic>),
      );
      // Vue : la liste et l'accueil perdent le badge « Nouvelle ».
      // Hors de la construction : pas de modification d'un autre provider
      // pendant celle-ci.
      if (result.offlineSince == null) {
        unawaited(
          Future.microtask(() {
            if (!ref.mounted) return;
            ref
              ..invalidate(opportunitiesProvider)
              ..invalidate(homeOpportunitiesProvider);
          }),
        );
      }
      return result;
    });

/// Intérêt et fiche de poste. Les erreurs (422 sous `share_cv` ou
/// `opportunity`, réseau) remontent à l'écran.
class OpportunityActions {
  const OpportunityActions(this._ref);

  final Ref _ref;

  OpportunitiesRepository get _repo =>
      _ref.read(opportunitiesRepositoryProvider);

  void _refresh(int id) => _ref
    ..invalidate(opportunityDetailProvider(id))
    ..invalidate(opportunitiesProvider)
    ..invalidate(homeOpportunitiesProvider);

  Future<void> expressInterest(int id, {required bool shareCv}) async {
    await _repo.expressInterest(id, shareCv: shareCv);
    _refresh(id);
  }

  Future<void> withdrawInterest(int id) async {
    await _repo.withdrawInterest(id);
    _refresh(id);
  }

  static String _fileName(OpportunityDetail o) => 'fiche-de-poste-${o.id}.pdf';

  Future<String> _ensureJobDescription(OpportunityDetail o) async {
    final files = _ref.read(fileStoreProvider);
    final stored = await files.pathFor(_fileName(o));
    if (stored != null) return stored;
    final bytes = await _repo.downloadJobDescription(o);
    if (bytes.isEmpty) throw const UnknownApiException();
    return files.write(_fileName(o), bytes);
  }

  /// `false` si aucune application ne peut ouvrir la fiche.
  Future<bool> openJobDescription(OpportunityDetail o) async => _ref
      .read(deviceServicesProvider)
      .openFile(await _ensureJobDescription(o));
}

final opportunityActionsProvider = Provider<OpportunityActions>(
  OpportunityActions.new,
);
