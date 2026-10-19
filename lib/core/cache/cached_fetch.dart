import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import 'cache_store.dart';

/// Données affichées, et leur provenance.
@immutable
class Cached<T> {
  const Cached(this.data, {this.offlineSince});

  final T data;

  /// Date de la dernière mise à jour si les données viennent du cache faute
  /// de réseau (« Hors connexion · mis à jour le … »), `null` sinon.
  final DateTime? offlineSince;

  bool get isOffline => offlineSince != null;
}

/// Appelle l'API et met la réponse en cache ; sans réseau, renvoie la
/// dernière valeur en cache. Toute autre erreur est relancée.
Future<Cached<T>> fetchWithCache<T>({
  required CacheStore cache,
  required String key,
  required Future<T> Function() fetch,
  required Object? Function(T data) toJson,
  required T Function(Object? json) fromJson,
}) async {
  try {
    final data = await fetch();
    await cache.write(key, toJson(data));
    return Cached(data);
  } on NetworkException catch (networkError, stack) {
    final entry = await cache.read(key);
    if (entry == null) rethrow;
    try {
      return Cached(fromJson(entry.json), offlineSince: entry.updatedAt);
    } on Object {
      // Format d'une ancienne version : on l'oublie.
      await cache.remove(key);
      Error.throwWithStackTrace(networkError, stack);
    }
  }
}
