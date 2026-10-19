import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saveur de l'application, choisie par le point d'entrée.
enum Flavor { dev, prod }

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Configuration lue depuis `--dart-define` (`API_BASE_URL`, `USE_MOCKS`).
@immutable
class AppConfig {
  const AppConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.useMocks,
  });

  /// Lit les `--dart-define` de la compilation.
  factory AppConfig.fromEnvironment(Flavor flavor) {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const hasUseMocks = bool.hasEnvironment('USE_MOCKS');
    const useMocks = bool.fromEnvironment('USE_MOCKS');
    return AppConfig.resolve(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      useMocks: hasUseMocks ? useMocks : null,
    );
  }

  /// Applique les valeurs par défaut et vérifie la cohérence.
  ///
  /// - `dev` : mocks activés par défaut.
  /// - `prod` : mocks interdits, URL HTTPS obligatoire.
  /// - Sans mocks, `API_BASE_URL` est obligatoire.
  factory AppConfig.resolve({
    required Flavor flavor,
    required String apiBaseUrl,
    bool? useMocks,
  }) {
    final mocks = useMocks ?? flavor == Flavor.dev;
    final url = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

    if (flavor == Flavor.prod && mocks) {
      throw const AppConfigException(
        'USE_MOCKS=true est interdit dans la saveur prod.',
      );
    }
    if (url.isEmpty) {
      if (!mocks) {
        throw const AppConfigException(
          'API_BASE_URL est obligatoire quand USE_MOCKS=false.',
        );
      }
    } else {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          !(uri.isScheme('http') || uri.isScheme('https'))) {
        throw AppConfigException('API_BASE_URL invalide : "$url".');
      }
      if (flavor == Flavor.prod && !uri.isScheme('https')) {
        throw const AppConfigException(
          'API_BASE_URL doit être en HTTPS dans la saveur prod.',
        );
      }
    }

    return AppConfig._(flavor: flavor, apiBaseUrl: url, useMocks: mocks);
  }

  final Flavor flavor;

  /// Sans barre oblique finale ; vide si les mocks sont actifs sans API.
  final String apiBaseUrl;
  final bool useMocks;

  bool get isDev => flavor == Flavor.dev;

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.flavor == flavor &&
      other.apiBaseUrl == apiBaseUrl &&
      other.useMocks == useMocks;

  @override
  int get hashCode => Object.hash(flavor, apiBaseUrl, useMocks);
}

/// Fourni par `bootstrap` (et par les tests) via un override.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider doit être surchargé.'),
);
