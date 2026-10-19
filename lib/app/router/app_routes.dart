/// Chemins de l'application. Ils reprennent les valeurs `route` du contrat
/// (notifications) : `/evenements/{slug}`, `/cotisations`,
/// `/opportunites/{id}`, `/actualites/{slug}`, `/adhesion/suivi`,
/// `/profil/vitrine`, `/carte`, `/notifications`.
abstract final class AppRoutes {
  // Démarrage et écrans publics.
  static const splash = '/demarrage';
  static const login = '/connexion';
  static const forgotPassword = '/mot-de-passe-oublie';
  static const activateAccount = '/activer-mon-compte';
  static const resetPassword = '/reinitialiser-mot-de-passe';

  /// Accessibles sans être connecté.
  static const public = {login, forgotPassword, activateAccount, resetPassword};

  // Candidat.
  static const membershipStatus = '/adhesion/suivi';

  // Onglets.
  static const home = '/accueil';
  static const card = '/carte';
  static const events = '/evenements';
  static const contributions = '/cotisations';
  static const profile = '/profil';

  // Sous-écrans des onglets.
  static String eventDetail(String slug) => '$events/$slug';
  static const profileSheet = '$profile/fiche';
  static const profileEducation = '$profile/parcours';
  static const profilePro = '$profile/pro';
  static const profileShowcase = '$profile/vitrine';
  static const profileSettings = '$profile/reglages';

  // Hors onglets.
  static const news = '/actualites';
  static String newsDetail(String slug) => '$news/$slug';
  static const notifications = '/notifications';
  static const opportunities = '/opportunites';
  static String opportunityDetail(int id) => '$opportunities/$id';
  static const scan = '/scan';

  // Outils de développement (saveur dev).
  static const devPrefix = '/dev/';
  static const devComponents = '/dev/composants';

  /// Paramètre qui garde l'écran demandé pendant la connexion.
  static const fromParam = 'from';
}
