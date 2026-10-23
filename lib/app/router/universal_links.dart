import 'app_routes.dart';

/// Hôte des liens universels (saveur `prod` seulement : voir
/// `docs/liens-universels.md`).
const universalLinkHost = 'aeenci.com';

/// Chemins du site ouverts par l'application. Même liste dans
/// `android/app/src/prod/AndroidManifest.xml` et dans les fichiers
/// `.well-known` du site ; un test vérifie le manifeste.
const universalLinkPaths = [
  '/activer-mon-compte',
  '/reinitialiser-mot-de-passe',
  '/espace/opportunites',
  '/evenements',
];

final _siteOpportunity = RegExp(r'^/espace/opportunites(/[^/]*)?/?$');

/// Adresse du site à réécrire en écran de l'application, ou `null` si le
/// chemin est déjà celui de l'application (activation, réinitialisation,
/// événements). La requête (`token`, `email`) est gardée.
String? rewriteUniversalLink(Uri uri) {
  final match = _siteOpportunity.firstMatch(uri.path);
  if (match == null) return null;
  final id = match[1]?.substring(1) ?? '';
  final target = id.isEmpty
      ? AppRoutes.opportunities
      : int.tryParse(id) == null
      // Adresse de la famille, mais inconnue : l'accueil, sans erreur.
      ? AppRoutes.home
      : AppRoutes.opportunityDetail(int.parse(id));
  return Uri(
    path: target,
    queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
  ).toString();
}
