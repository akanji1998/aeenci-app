import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../domain/news.dart';

part 'news_repository.g.dart';

/// Actualités publiées (public). L'article arrive au lot 7.
abstract interface class NewsRepository {
  /// `GET /news?page=`, de la plus récente à la plus ancienne.
  Future<Paginated<News>> fetchPage({int page = 1});
}

class ApiNewsRepository implements NewsRepository {
  const ApiNewsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<News>> fetchPage({int page = 1}) =>
      _api.getPage('/news', News.fromJson, page: page);
}

class MockNewsRepository implements NewsRepository {
  const MockNewsRepository(this._runtime);

  final MockRuntime _runtime;

  @override
  Future<Paginated<News>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    return Paginated.fromJson(mockNewsPageJson(DateTime.now()), News.fromJson);
  }
}

@Riverpod(keepAlive: true)
NewsRepository newsRepository(Ref ref) => ref.watch(envConfigProvider).useMocks
    ? MockNewsRepository(ref.watch(mockRuntimeProvider))
    : ApiNewsRepository(ref.watch(apiClientProvider));
