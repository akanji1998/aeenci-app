import '../../core/domain/enums.dart';
import '../../features/app_config/presentation/app_gate_controller.dart';
import '../../features/auth/presentation/session_controller.dart';
import 'app_routes.dart';

/// Redirection du routeur selon la configuration et la session : `null`
/// pour rester sur [uri].
///
/// - `/app/config` en cours de lecture : écran de démarrage.
/// - Mise à jour exigée ou maintenance : écran bloquant, rien d'autre.
/// - Chargement ou fiche indisponible : écran de démarrage.
/// - Déconnecté : écrans publics seulement ; sinon connexion, en gardant
///   l'écran demandé dans `from`.
/// - Candidat : suivi de l'adhésion seulement.
/// - Membre : les onglets ; le scan exige `attendance.scan`.
String? guardRedirect({
  required AppGateState gate,
  required SessionState session,
  required Uri uri,
  required bool devTools,
}) {
  final path = uri.path;

  switch (gate) {
    case GateUpdateRequired():
      return path == AppRoutes.updateRequired ? null : AppRoutes.updateRequired;
    case GateMaintenance():
      return path == AppRoutes.maintenance ? null : AppRoutes.maintenance;
    case GateChecking():
      if (path == AppRoutes.splash) return null;
      return _withFrom(AppRoutes.splash, _wantedLocation(uri));
    case GateOpen():
      break;
  }

  if (path.startsWith(AppRoutes.devPrefix)) {
    if (!devTools) return AppRoutes.home;
    // Outils de dev : seulement une fois la session résolue.
    if (session is SessionSignedOut || session is SessionMember) return null;
  }

  // Écran demandé : celui qu'on garde de redirection en redirection. Après
  // une déconnexion volontaire, on n'y revient pas (autre compte possible).
  final from =
      session is SessionSignedOut &&
          session.reason == SignedOutReason.userRequest
      ? null
      : _wantedLocation(uri);

  switch (session) {
    case SessionLoading() || SessionUnavailable():
      if (path == AppRoutes.splash) return null;
      return _withFrom(AppRoutes.splash, from);

    case SessionSignedOut():
      if (AppRoutes.public.contains(path)) return null;
      if (_isGateScreen(path)) return AppRoutes.login;
      if (path.startsWith(AppRoutes.devPrefix)) return null;
      return _withFrom(AppRoutes.login, from);

    case SessionCandidate():
      return path == AppRoutes.membershipStatus
          ? null
          : AppRoutes.membershipStatus;

    case SessionMember():
      if (path == '/' ||
          path == AppRoutes.splash ||
          _isGateScreen(path) ||
          path == AppRoutes.membershipStatus ||
          AppRoutes.public.contains(path)) {
        return from ?? AppRoutes.home;
      }
      if (path == AppRoutes.scan && !session.can(Abilities.attendanceScan)) {
        return AppRoutes.home;
      }
      return null;
  }
}

bool _isGateScreen(String path) =>
    path == AppRoutes.updateRequired || path == AppRoutes.maintenance;

/// L'écran que la personne voulait ouvrir : `from` sur le démarrage et la
/// connexion, sinon l'adresse elle-même si c'est un écran de l'application.
String? _wantedLocation(Uri uri) {
  final path = uri.path;
  if (path == AppRoutes.splash || AppRoutes.public.contains(path)) {
    final from = uri.queryParameters[AppRoutes.fromParam];
    return _isSafeTarget(from) ? from : null;
  }
  if (path == '/' ||
      path == AppRoutes.membershipStatus ||
      _isGateScreen(path)) {
    return null;
  }
  final location = uri.toString();
  return _isSafeTarget(location) ? location : null;
}

/// Un chemin interne de l'application, jamais une adresse externe.
bool _isSafeTarget(String? location) {
  if (location == null || !location.startsWith('/')) return false;
  if (location.startsWith('//')) return false;
  final path = Uri.tryParse(location)?.path;
  if (path == null) return false;
  // L'accueil est la destination par défaut : inutile de le retenir.
  return path != AppRoutes.splash &&
      path != '/' &&
      path != AppRoutes.home &&
      !AppRoutes.public.contains(path);
}

String _withFrom(String target, String? from) => from == null
    ? target
    : Uri(
        path: target,
        queryParameters: {AppRoutes.fromParam: from},
      ).toString();
