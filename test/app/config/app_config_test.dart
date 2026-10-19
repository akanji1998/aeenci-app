import 'package:aeenci_app/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('saveur dev', () {
    test('mocks activés par défaut, URL facultative', () {
      final config = AppConfig.resolve(flavor: Flavor.dev, apiBaseUrl: '');
      expect(config.useMocks, isTrue);
      expect(config.apiBaseUrl, isEmpty);
      expect(config.isDev, isTrue);
    });

    test('API locale en HTTP acceptée, barre finale retirée', () {
      final config = AppConfig.resolve(
        flavor: Flavor.dev,
        apiBaseUrl: 'http://10.0.2.2:8000/api/v1/',
        useMocks: false,
      );
      expect(config.useMocks, isFalse);
      expect(config.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
    });

    test('sans mocks, l\'URL est obligatoire', () {
      expect(
        () => AppConfig.resolve(
          flavor: Flavor.dev,
          apiBaseUrl: ' ',
          useMocks: false,
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('URL invalide refusée', () {
      for (final url in ['api.aeenci.com', 'ftp://api.aeenci.com', 'http://']) {
        expect(
          () => AppConfig.resolve(flavor: Flavor.dev, apiBaseUrl: url),
          throwsA(isA<AppConfigException>()),
          reason: url,
        );
      }
    });
  });

  group('saveur prod', () {
    test('mocks désactivés par défaut, HTTPS accepté', () {
      final config = AppConfig.resolve(
        flavor: Flavor.prod,
        apiBaseUrl: 'https://api.aeenci.com/api/v1',
      );
      expect(config.useMocks, isFalse);
      expect(config.isDev, isFalse);
    });

    test('URL obligatoire', () {
      expect(
        () => AppConfig.resolve(flavor: Flavor.prod, apiBaseUrl: ''),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('HTTP refusé', () {
      expect(
        () => AppConfig.resolve(
          flavor: Flavor.prod,
          apiBaseUrl: 'http://api.aeenci.com/api/v1',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('mocks interdits', () {
      expect(
        () => AppConfig.resolve(
          flavor: Flavor.prod,
          apiBaseUrl: 'https://api.aeenci.com/api/v1',
          useMocks: true,
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
