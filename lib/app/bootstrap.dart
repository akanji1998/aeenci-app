import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/env_config.dart';

/// Point de départ commun aux saveurs.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = EnvConfig.fromEnvironment(flavor);

  runApp(
    ProviderScope(
      overrides: [envConfigProvider.overrideWithValue(config)],
      child: const AeenciApp(),
    ),
  );
}
