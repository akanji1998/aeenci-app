import 'package:flutter/foundation.dart';

/// Une page d'une liste paginée : `{"data": […], "meta": {…}}`.
@immutable
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.meta = const {},
  });

  factory Paginated.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final data = json['data'];
    final meta = json['meta'];
    if (data is! List<Object?> || meta is! Map<String, Object?>) {
      throw const FormatException('Liste paginée attendue : data et meta.');
    }
    int field(String key) => switch (meta[key]) {
      final int value => value,
      _ => throw FormatException('meta.$key manquant'),
    };
    return Paginated(
      items: [for (final item in data) fromJson(item! as Map<String, dynamic>)],
      currentPage: field('current_page'),
      lastPage: field('last_page'),
      perPage: field('per_page'),
      total: field('total'),
      meta: Map.unmodifiable(meta),
    );
  }

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  /// `meta` complet, pour les compteurs (`unseen_count`, `unread_count`).
  final Map<String, Object?> meta;

  bool get hasMore => currentPage < lastPage;

  /// Compteur entier de `meta` (ex. `unread_count`), 0 s'il est absent.
  int count(String key) => switch (meta[key]) {
    final int value => value,
    _ => 0,
  };
}
