import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/auth/presentation/sign_out_button.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/design_demo/presentation/design_demo_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../config/env_config.dart';
import '../shell/app_shell.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';
import 'route_guard.dart';

part 'app_router.g.dart';

/// Routeur : cinq onglets dans un `StatefulShellRoute`, écrans hors
/// onglets par-dessus, garde selon la session.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final devTools = ref.watch(envConfigProvider).isDev;
  final session = ValueNotifier<SessionState>(
    ref.read(sessionControllerProvider),
  );
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => guardRedirect(
      session: session.value,
      uri: state.uri,
      devTools: devTools,
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      _placeholder(AppRoutes.forgotPassword, (l) => l.screenForgotPassword),
      _placeholder(AppRoutes.activateAccount, (l) => l.screenActivateAccount),
      _placeholder(AppRoutes.resetPassword, (l) => l.screenResetPassword),
      GoRoute(
        path: AppRoutes.membershipStatus,
        builder: (context, state) => PlaceholderScreen(
          title: AppLocalizations.of(context).screenMembershipStatus,
          footer: const SignOutButton(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.card, (l) => l.screenCard)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) {
                  final l10n = AppLocalizations.of(context);
                  return PlaceholderScreen(
                    title: l10n.screenEvents,
                    links: [
                      PlaceholderLink(
                        l10n.placeholderEventExample,
                        AppRoutes.eventDetail('exemple'),
                      ),
                    ],
                  );
                },
                routes: [_placeholder(':slug', (l) => l.screenEventDetail)],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _placeholder(
                AppRoutes.contributions,
                (l) => l.screenContributions,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  _placeholder('fiche', (l) => l.screenProfileSheet),
                  _placeholder('parcours', (l) => l.screenEducation),
                  _placeholder('pro', (l) => l.screenProfessionalProfile),
                  _placeholder('vitrine', (l) => l.screenShowcase),
                  _placeholder('reglages', (l) => l.screenSettings),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.news,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return PlaceholderScreen(
            title: l10n.screenNews,
            links: [
              PlaceholderLink(
                l10n.placeholderNewsExample,
                AppRoutes.newsDetail('exemple'),
                push: true,
              ),
            ],
          );
        },
      ),
      _placeholder('${AppRoutes.news}/:slug', (l) => l.screenNewsDetail),
      _placeholder(AppRoutes.notifications, (l) => l.screenNotifications),
      GoRoute(
        path: AppRoutes.opportunities,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return PlaceholderScreen(
            title: l10n.screenOpportunities,
            links: [
              PlaceholderLink(
                l10n.placeholderOpportunityExample,
                AppRoutes.opportunityDetail(1),
                push: true,
              ),
            ],
          );
        },
      ),
      _placeholder(
        '${AppRoutes.opportunities}/:id',
        (l) => l.screenOpportunityDetail,
      ),
      _placeholder(AppRoutes.scan, (l) => l.screenScan),
      GoRoute(
        path: AppRoutes.devComponents,
        builder: (context, state) => const DesignDemoScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
}

GoRoute _placeholder(String path, String Function(AppLocalizations) title) =>
    GoRoute(
      path: path,
      builder: (context, state) =>
          PlaceholderScreen(title: title(AppLocalizations.of(context))),
    );
