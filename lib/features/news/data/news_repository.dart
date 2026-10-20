import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../domain/news.dart';

part 'news_repository.g.dart';

/// Actualités publiées (public).
abstract interface class NewsRepository {
  /// `GET /news?page=`, de la plus récente à la plus ancienne.
  Future<Paginated<News>> fetchPage({int page = 1});

  /// `GET /news/{slug}` : 404 si elle n'existe pas, est un brouillon ou
  /// est programmée.
  Future<News> fetchBySlug(String slug);
}

class ApiNewsRepository implements NewsRepository {
  const ApiNewsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<News>> fetchPage({int page = 1}) =>
      _api.getPage('/news', News.fromJson, page: page);

  @override
  Future<News> fetchBySlug(String slug) =>
      _api.getData('/news/${Uri.encodeComponent(slug)}', News.fromJson);
}

class MockNewsRepository implements NewsRepository {
  const MockNewsRepository(this._runtime);

  final MockRuntime _runtime;

  /// Petites pages pour montrer le chargement des pages suivantes.
  static const _perPage = 3;

  @override
  Future<Paginated<News>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    final all = mockNewsJson(DateTime.now());
    return Paginated.fromJson({
      'data': all.skip((page - 1) * _perPage).take(_perPage).toList(),
      'meta': {
        'current_page': page,
        'last_page': (all.length / _perPage).ceil(),
        'per_page': _perPage,
        'total': all.length,
      },
    }, News.fromJson);
  }

  @override
  Future<News> fetchBySlug(String slug) async {
    await _runtime.simulate();
    final json = mockNewsJson(
      DateTime.now(),
    ).where((n) => n['slug'] == slug).firstOrNull;
    if (json == null) throw const NotFoundException();
    return News.fromJson(json);
  }
}

@Riverpod(keepAlive: true)
NewsRepository newsRepository(Ref ref) => ref.watch(envConfigProvider).useMocks
    ? MockNewsRepository(ref.watch(mockRuntimeProvider))
    : ApiNewsRepository(ref.watch(apiClientProvider));
