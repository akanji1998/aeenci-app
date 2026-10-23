import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/app_config/presentation/app_gate_controller.dart';
import '../../features/app_config/presentation/gate_screens.dart';
import '../../features/auth/presentation/activate_account_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/membership_status_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/card/presentation/card_screen.dart';
import '../../features/contributions/presentation/contributions_screen.dart';
import '../../features/design_demo/presentation/design_demo_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/news/presentation/news_screens.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/notifications/presentation/push_prompt_screen.dart';
import '../../features/opportunities/presentation/opportunities_screens.dart';
import '../../features/profile/presentation/account_screens.dart';
import '../../features/profile/presentation/education_screen.dart';
import '../../features/profile/presentation/pro_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_sheet_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../config/env_config.dart';
import '../shell/app_shell.dart';
import 'app_routes.dart';
import 'route_guard.dart';
import 'universal_links.dart';

part 'app_router.g.dart';

/// Routeur : cinq onglets dans un `StatefulShellRoute`, écrans hors
/// onglets par-dessus, garde selon la session.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final devTools = ref.watch(envConfigProvider).isDev;
  final state = ValueNotifier<(AppGateState, SessionState)>((
    ref.read(appGateControllerProvider),
    ref.read(sessionControllerProvider),
  ));
  ref
    ..listen(
      appGateControllerProvider,
      (_, gate) => state.value = (gate, state.value.$2),
    )
    ..listen(
      sessionControllerProvider,
      (_, session) => state.value = (state.value.$1, session),
    );

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: state,
    // Lien universel (adresse du site) d'abord, puis la garde.
    redirect: (context, routerState) =>
        rewriteUniversalLink(routerState.uri) ??
        guardRedirect(
          gate: state.value.$1,
          session: state.value.$2,
          uri: routerState.uri,
          devTools: devTools,
        ),
    // Adresse inconnue (lien d'une ancienne version, faute de frappe) :
    // l'accueil plutôt qu'une page d'erreur.
    onException: (context, routerState, router) => router.go(AppRoutes.home),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.home),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.updateRequired,
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.activateAccount,
        builder: (context, state) =>
            ActivateAccountScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: AppRoutes.membershipStatus,
        builder: (context, state) => const MembershipStatusScreen(),
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
            routes: [
              GoRoute(
                path: AppRoutes.card,
                builder: (context, state) => const CardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) => const EventsScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    builder: (context, state) =>
                        EventDetailScreen(slug: state.pathParameters['slug']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contributions,
                builder: (context, state) => const ContributionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'fiche',
                    builder: (context, state) => const ProfileSheetScreen(),
                  ),
                  GoRoute(
                    path: 'parcours',
                    builder: (context, state) => const EducationScreen(),
                  ),
                  GoRoute(
                    path: 'pro',
                    builder: (context, state) => const ProProfileScreen(),
                  ),
                  // Le réglage de la vitrine est sur l'écran Profil.
                  GoRoute(
                    path: 'vitrine',
                    redirect: (context, state) => AppRoutes.profile,
                  ),
                  GoRoute(
                    path: 'mot-de-passe',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'supprimer-mon-compte',
                    builder: (context, state) => const DeleteAccountScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.news,
        builder: (context, state) => const NewsListScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) =>
                NewsDetailScreen(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.pushPrompt,
        builder: (context, state) => const PushPromptScreen(),
      ),
      GoRoute(
        path: AppRoutes.opportunities,
        builder: (context, state) => const OpportunitiesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => OpportunityDetailScreen(
              id: int.tryParse(state.pathParameters['id']!) ?? 0,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.devComponents,
        builder: (context, state) => const DesignDemoScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    state.dispose();
  });
  return router;
}
