import 'package:dio/dio.dart';

/// Toute erreur d'un appel à l'API, convertie depuis Dio.
///
/// Les écrans l'affichent avec `ErrorState` (bouton « Réessayer ») et les
/// formulaires lisent [ValidationException.errorFor] sous chaque champ.
sealed class ApiException implements Exception {
  const ApiException({this.statusCode, this.message});

  final int? statusCode;

  /// Message du backend, s'il y en a un. Jamais affiché tel quel pour les
  /// erreurs techniques : les écrans ont leurs propres libellés.
  final String? message;

  /// Convertit une [DioException] en [ApiException].
  factory ApiException.fromDio(DioException error) {
    final inner = error.error;
    if (inner is ApiException) return inner;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.badCertificate:
        return const UnknownApiException();
      case DioExceptionType.unknown:
        // SocketException, HandshakeException… : sans réponse du serveur.
        return error.response == null
            ? const NetworkException()
            : ApiException.fromResponse(error.response!);
      case DioExceptionType.badResponse:
        final response = error.response;
        return response == null
            ? const UnknownApiException()
            : ApiException.fromResponse(response);
    }
  }

  /// Convertit une réponse HTTP en erreur, d'après son code.
  factory ApiException.fromResponse(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    final message = body is Map<String, Object?> && body['message'] is String
        ? body['message']! as String
        : null;

    return switch (status) {
      401 => UnauthorizedException(message: message),
      403 => ForbiddenException(message: message),
      404 => NotFoundException(message: message),
      410 => GoneException(message: message),
      422 => ValidationException(
        message: message,
        errors: _parseErrors(
          body is Map<String, Object?> ? body['errors'] : null,
        ),
      ),
      429 => TooManyRequestsException(
        message: message,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      ),
      >= 500 && < 600 => ServerException(statusCode: status, message: message),
      _ => UnknownApiException(statusCode: status, message: message),
    };
  }

  static Map<String, List<String>> _parseErrors(Object? raw) {
    if (raw is! Map<String, Object?>) return const {};
    return {
      for (final MapEntry(:key, :value) in raw.entries)
        key: switch (value) {
          final List<Object?> list => [
            for (final item in list)
              if (item is String) item,
          ],
          final String single => [single],
          _ => const <String>[],
        },
    };
  }

  static Duration? _parseRetryAfter(String? header) {
    final seconds = int.tryParse(header ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}

/// Pas de réseau, serveur injoignable ou délai dépassé.
final class NetworkException extends ApiException {
  const NetworkException();
}

/// 401 : jeton absent, expiré ou révoqué.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message}) : super(statusCode: 401);
}

/// 403 : action non permise (ex. scan sans `attendance.scan`).
final class ForbiddenException extends ApiException {
  const ForbiddenException({super.message}) : super(statusCode: 403);
}

/// 404 : ressource inexistante ou d'un autre membre.
final class NotFoundException extends ApiException {
  const NotFoundException({super.message}) : super(statusCode: 404);
}

/// 410 : lien expiré ou déjà utilisé (invitation).
final class GoneException extends ApiException {
  const GoneException({super.message}) : super(statusCode: 410);
}

/// 422 : erreurs de validation, par champ.
final class ValidationException extends ApiException {
  const ValidationException({super.message, this.errors = const {}})
    : super(statusCode: 422);

  final Map<String, List<String>> errors;

  /// Premier message d'erreur du champ, à afficher sous celui-ci.
  String? errorFor(String field) {
    final messages = errors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }
}

/// 429 : trop de requêtes.
final class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({super.message, this.retryAfter})
    : super(statusCode: 429);

  final Duration? retryAfter;
}

/// 5xx.
final class ServerException extends ApiException {
  const ServerException({required int super.statusCode, super.message});
}

/// Requête annulée par l'application.
final class CancelledException extends ApiException {
  const CancelledException();
}

/// Tout autre cas (réponse inattendue, JSON illisible…).
final class UnknownApiException extends ApiException {
  const UnknownApiException({super.statusCode, super.message});
}
