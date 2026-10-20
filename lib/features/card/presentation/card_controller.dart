import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/connectivity.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/card_repository.dart';
import '../domain/card_rules.dart';
import '../domain/member_card.dart';

part 'card_controller.g.dart';

/// Carte de membre, disponible hors connexion.
///
/// - La dernière carte reçue est gardée dans le cache (fichier) et
///   s'affiche sans réseau, même après un redémarrage.
/// - Elle est redemandée quand `qr_expires_at` est à moins de 7 jours et
///   que le réseau est là : à l'ouverture, au retour du réseau, au retour
///   dans l'application ([renewIfNeeded]).
@Riverpod(keepAlive: true)
class CardController extends _$CardController {
  static const cacheKey = 'me/card';

  @override
  Future<Cached<MemberCard>> build() async {
    // Une autre personne se connecte : on repart de zéro.
    ref.watch(
      sessionControllerProvider.select(
        (session) => session is SessionMember ? session.member.id : null,
      ),
    );
    ref.listen(connectivityProvider, (_, online) {
      if (online.value ?? false) unawaited(renewIfNeeded());
    });

    final entry = await ref.read(cacheStoreProvider).read(cacheKey);
    final cached = _decode(entry?.json);
    if (cached != null && !shouldRenewCard(cached, _now())) {
      // Carte encore valide : pas de requête.
      return Cached(cached);
    }
    return _fetch();
  }

  /// Renouvelle la carte si elle approche de son expiration.
  Future<void> renewIfNeeded() async {
    final current = state.value;
    if (current != null && !shouldRenewCard(current.data, _now())) return;
    await refresh();
  }

  /// Redemande la carte (tirer pour actualiser). Sans réseau, la carte
  /// affichée reste en place.
  Future<void> refresh() async {
    try {
      state = AsyncData(await _fetch());
    } on ApiException catch (error, stack) {
      if (!state.hasValue) state = AsyncError(error, stack);
    }
  }

  Future<Cached<MemberCard>> _fetch() => fetchWithCache<MemberCard>(
    cache: ref.read(cacheStoreProvider),
    key: cacheKey,
    fetch: ref.read(cardRepositoryProvider).fetchCard,
    toJson: (card) => card.toJson(),
    fromJson: (json) => MemberCard.fromJson(json! as Map<String, dynamic>),
  );

  MemberCard? _decode(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return MemberCard.fromJson(json);
    } on Object {
      return null;
    }
  }

  DateTime _now() => ref.read(clockProvider)();
}
