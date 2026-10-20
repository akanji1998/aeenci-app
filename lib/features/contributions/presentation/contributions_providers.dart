import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/utils/device_services.dart';
import '../data/contact_repository.dart';
import '../data/contributions_repository.dart';
import '../domain/contact_info.dart';
import '../domain/contribution.dart';

List<Map<String, dynamic>> _maps(Object? json) => [
  for (final item in json! as List<Object?>) item! as Map<String, dynamic>,
];

/// Situation par année (même cache que l'accueil).
final contributionsProvider =
    FutureProvider.autoDispose<Cached<List<Contribution>>>(
      (ref) => fetchWithCache<List<Contribution>>(
        cache: ref.read(cacheStoreProvider),
        key: 'me/contributions',
        fetch: ref.read(contributionsRepositoryProvider).fetchContributions,
        toJson: (list) => [for (final c in list) c.toJson()],
        fromJson: (json) => _maps(json).map(Contribution.fromJson).toList(),
      ),
    );

/// Numéros Mobile Money de l'encart « Comment payer ? ».
final contactProvider = FutureProvider.autoDispose<Cached<ContactInfo>>(
  (ref) => fetchWithCache<ContactInfo>(
    cache: ref.read(cacheStoreProvider),
    key: 'site/contact',
    fetch: ref.read(contactRepositoryProvider).fetchContact,
    toJson: (contact) => contact.toJson(),
    fromJson: (json) => ContactInfo.fromJson(json! as Map<String, dynamic>),
  ),
);

/// Paiements chargés jusqu'ici.
@immutable
class PaymentsState {
  const PaymentsState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Payment> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? loadMoreError;

  PaymentsState copyWith({
    List<Payment>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    ApiException? loadMoreError,
  }) => PaymentsState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError,
  );
}

/// Historique des paiements, page par page. Seule la première page est
/// gardée hors connexion.
class PaymentsController extends AsyncNotifier<Cached<PaymentsState>> {
  @override
  Future<Cached<PaymentsState>> build() async {
    final first = await fetchWithCache<PaymentsState>(
      cache: ref.read(cacheStoreProvider),
      key: 'me/payments',
      fetch: () async {
        final page = await ref
            .read(contributionsRepositoryProvider)
            .fetchPayments();
        return PaymentsState(
          items: page.items,
          page: page.currentPage,
          hasMore: page.hasMore,
        );
      },
      toJson: (state) => {
        'items': [for (final p in state.items) p.toJson()],
        'page': state.page,
        'has_more': state.hasMore,
      },
      fromJson: (json) {
        final map = json! as Map<String, dynamic>;
        return PaymentsState(
          items: _maps(map['items']).map(Payment.fromJson).toList(),
          page: map['page']! as int,
          hasMore: map['has_more']! as bool,
        );
      },
    );
    return first;
  }

  /// Page suivante, en bas de la liste.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.data.hasMore || current.data.loadingMore) {
      return;
    }
    final data = current.data;
    state = AsyncData(
      Cached(
        data.copyWith(loadingMore: true),
        offlineSince: current.offlineSince,
      ),
    );
    try {
      final next = await ref
          .read(contributionsRepositoryProvider)
          .fetchPayments(page: data.page + 1);
      state = AsyncData(
        Cached(
          data.copyWith(
            items: [...data.items, ...next.items],
            page: next.currentPage,
            hasMore: next.hasMore,
            loadingMore: false,
          ),
          offlineSince: current.offlineSince,
        ),
      );
    } on ApiException catch (error) {
      state = AsyncData(
        Cached(
          data.copyWith(loadingMore: false, loadMoreError: error),
          offlineSince: current.offlineSince,
        ),
      );
    }
  }
}

final paymentsProvider =
    AsyncNotifierProvider.autoDispose<
      PaymentsController,
      Cached<PaymentsState>
    >(PaymentsController.new);

/// Reçu gardé hors connexion, ou téléchargé puis gardé.
class ReceiptActions {
  const ReceiptActions(this._ref);

  final Ref _ref;

  static String fileName(Payment payment) => '${payment.receiptNumber}.pdf';

  /// Le reçu est-il déjà sur le téléphone ?
  Future<bool> isStored(Payment payment) async =>
      await _ref.read(fileStoreProvider).pathFor(fileName(payment)) != null;

  /// Chemin du reçu : sans requête s'il est déjà gardé. Lève une
  /// [ApiException] si le téléchargement échoue (réseau, 404).
  Future<String> ensure(Payment payment) async {
    final files = _ref.read(fileStoreProvider);
    final stored = await files.pathFor(fileName(payment));
    if (stored != null) return stored;
    final bytes = await _ref
        .read(contributionsRepositoryProvider)
        .downloadReceipt(payment.id);
    if (bytes.isEmpty) throw const UnknownApiException();
    return files.write(fileName(payment), bytes);
  }

  /// Ouvre le reçu ; `false` si aucune application ne peut l'ouvrir.
  Future<bool> open(Payment payment) async =>
      _ref.read(deviceServicesProvider).openFile(await ensure(payment));

  Future<void> share(Payment payment, {String? text}) async => _ref
      .read(deviceServicesProvider)
      .shareFile(await ensure(payment), text: text);
}

final receiptActionsProvider = Provider<ReceiptActions>(ReceiptActions.new);
