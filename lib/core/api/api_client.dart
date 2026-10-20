import 'dart:async';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'paginated.dart';
import 'token_store.dart';

typedef JsonMap = Map<String, dynamic>;

/// Client de l'API REST (`/api/v1`).
///
/// Chaque méthode lève une [ApiException] en cas d'échec, jamais une
/// DioException. Un 401 efface le jeton et émet sur [unauthorized].
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokens,
    void Function(String line)? log,
    HttpClientAdapter? adapter,
  }) : _tokens = tokens,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           headers: const {'Accept': 'application/json'},
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 30),
           sendTimeout: const Duration(seconds: 60),
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(_AuthInterceptor(tokens, _onUnauthorized));
    if (log != null) _dio.interceptors.add(_SafeLogInterceptor(log));
  }

  /// Routes où un 401/422 fait partie du parcours normal : on ne
  /// déconnecte pas sur une erreur de ces routes.
  static const _authPaths = {'/auth/login', '/auth/reset-password'};

  final Dio _dio;
  final TokenStore _tokens;
  final _unauthorized = StreamController<void>.broadcast();

  /// Émet quand l'API répond 401 : le jeton est déjà effacé.
  Stream<void> get unauthorized => _unauthorized.stream;

  TokenStore get tokens => _tokens;

  Future<void> _onUnauthorized(RequestOptions options) async {
    if (_authPaths.contains(options.path)) return;
    await signalUnauthorized();
  }

  /// Efface le jeton et prévient la session (401, ou 401 simulé).
  Future<void> signalUnauthorized() async {
    await _tokens.clear();
    _unauthorized.add(null);
  }

  /// `GET` d'une ressource `{"data": {…}}`.
  Future<T> getData<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?>? query,
  }) async {
    final body = await _request('GET', path, query: query);
    return fromJson(_dataObject(body));
  }

  /// `GET` d'une liste non paginée `{"data": […]}`.
  Future<List<T>> getList<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?>? query,
  }) async {
    final body = await _request('GET', path, query: query);
    final data = body is Map<String, Object?> ? body['data'] : null;
    if (data is! List<Object?>) throw const UnknownApiException();
    return [for (final item in data) fromJson(item! as JsonMap)];
  }

  /// `GET` d'une liste paginée.
  Future<Paginated<T>> getPage<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    int page = 1,
    Map<String, Object?>? query,
  }) async {
    final body = await _request('GET', path, query: {...?query, 'page': page});
    if (body is! Map<String, Object?>) throw const UnknownApiException();
    try {
      return Paginated.fromJson(body, fromJson);
    } on FormatException {
      throw const UnknownApiException();
    }
  }

  /// `GET` qui peut répondre 204 (ex. `/meetings/next`) : `null` dans ce cas.
  Future<T?> getOptional<T>(
    String path,
    T Function(JsonMap json) fromJson,
  ) async {
    final body = await _request('GET', path);
    if (body == null || body == '') return null;
    return fromJson(_dataObject(body));
  }

  /// Requête qui modifie des données. Renvoie le corps décodé, ou `null`
  /// pour une réponse 202/204 sans contenu.
  Future<Object?> send(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? query,
  }) => _request(method, path, data: data, query: query);

  /// Comme [send], pour une réponse `{"data": {…}}`.
  Future<T> sendData<T>(
    String method,
    String path,
    T Function(JsonMap json) fromJson, {
    Object? data,
  }) async {
    final body = await _request(method, path, data: data);
    return fromJson(_dataObject(body));
  }

  /// Objet JSON avec ou sans enveloppe `data` : le contrat ne précise pas
  /// la forme des réponses d'authentification (connexion, activation,
  /// réinitialisation) ni de `/invitations/{token}`.
  Future<JsonMap> sendObject(
    String method,
    String path, {
    Object? data,
  }) async => _objectOrData(await _request(method, path, data: data));

  /// `GET` d'un objet, avec ou sans enveloppe `data`.
  Future<JsonMap> getObject(String path) async =>
      _objectOrData(await _request('GET', path));

  /// Téléchargement authentifié d'un fichier (reçu PDF…).
  Future<List<int>> download(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Object?> _request(
    String method,
    String path, {
    Object? data,
    Map<String, Object?>? query,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: query == null
            ? null
            : {for (final MapEntry(:key, :value) in query.entries) key: ?value},
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  JsonMap _objectOrData(Object? body) {
    if (body is! JsonMap) throw const UnknownApiException();
    final data = body['data'];
    return data is JsonMap ? data : body;
  }

  JsonMap _dataObject(Object? body) {
    final data = body is Map<String, Object?> ? body['data'] : null;
    if (data is! JsonMap) throw const UnknownApiException();
    return data;
  }

  void dispose() {
    _dio.close(force: true);
    unawaited(_unauthorized.close());
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokens, this._onUnauthorized);

  final TokenStore _tokens;
  final Future<void> Function(RequestOptions options) _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _onUnauthorized(err.requestOptions);
    }
    handler.next(err);
  }
}

/// Journal de développement : méthode, chemin et code seulement.
/// Jamais d'en-tête (jeton), de paramètre ni de corps (données personnelles).
class _SafeLogInterceptor extends Interceptor {
  _SafeLogInterceptor(this._log);

  final void Function(String line) _log;

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _write(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write(err.requestOptions, err.response?.statusCode, err.type.name);
    handler.next(err);
  }

  void _write(RequestOptions options, int? status, [String? error]) {
    _log('${options.method} ${options.path} → ${status ?? error}');
  }
}
