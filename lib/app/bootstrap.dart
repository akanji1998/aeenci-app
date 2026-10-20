import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/env_config.dart';

/// Pas de nouvelle tentative automatique quand un provider échoue
/// (comportement par défaut de Riverpod 3) : une erreur 404 ou 410 doit
/// s'afficher tout de suite, et les écrans ont leur bouton « Réessayer ».
Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Point de départ commun aux saveurs.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EnvConfig.fromEnvironment(flavor);

  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [envConfigProvider.overrideWithValue(config)],
      child: const AeenciApp(),
    ),
  );
}
