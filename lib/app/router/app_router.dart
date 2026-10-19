import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/design_demo/presentation/design_demo_screen.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const demo = '/';
}

/// Routeur de l'application. Le shell à cinq onglets arrive au lot 1.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.demo,
    routes: [
      GoRoute(
        path: AppRoutes.demo,
        builder: (context, state) => const DesignDemoScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
