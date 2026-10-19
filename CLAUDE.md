# CLAUDE.md — Application mobile AEENCI

Ce fichier donne le contexte du projet à Claude Code et à tout nouveau contributeur. Lis-le en entier avant toute modification.

## Le projet

L'AEENCI (Association des Élèves et Étudiants Nigérians en Côte d'Ivoire), fondée en 1972, se dote d'une plateforme numérique en trois dépôts :

- **Backend** (`aeenci-backend`, Laravel + Filament) : plateforme de gestion `gestion.aeenci.com` et API REST `api.aeenci.com`.
- **Site** (`aeenci-site`, Next.js) : site public `aeenci.com` et espace membre.
- **Ce dépôt (`aeenci-app`, Flutter)** : l'application des membres, V2. **Toutes ses données viennent de l'API**, la même que celle du site.

L'application met l'espace membre dans la poche de chaque membre : carte de membre avec QR code signé, notifications, événements, cotisations et reçus, profil, opportunités ; et pour le bureau, le scan des présences aux assemblées. La gestion de l'association reste sur la plateforme web.

Documents de référence, dans `docs/` :

- `docs/plan-developpement-app.md` — les lots de développement, dans l'ordre
- `docs/cadrage-v2.md` — périmètre, écrans, notifications, décisions validées
- `docs/contrat-api.md` — les routes de l'API (v3, **identique dans les trois dépôts**)
- `docs/cahier-des-charges.md` — rôles, statuts des membres, règles métier
- `docs/design-system.md` — le guide de marque : couleurs, typographie, ton, logo
- `docs/design/tokens.json` — les valeurs exactes des couleurs (clair et sombre), tailles, espacements et rayons
- `docs/maquettes/*.dc.html` — le code source des maquettes validées, un écran par fichier
- `docs/design/logos/` — logo complet, logo blanc et symbole, en SVG

## Stack

- Flutter stable, Dart à jour, `analysis_options.yaml` strict (`flutter_lints` + règles strictes, `strict-casts`, `strict-raw-types`)
- Gestion d'état : **Riverpod** (`flutter_riverpod`, `riverpod_annotation` + `riverpod_generator`)
- Navigation : **go_router**, avec un `StatefulShellRoute` pour les cinq onglets et les liens profonds
- API : **Dio** ; modèles **freezed** + **json_serializable**, écrits à partir de `docs/contrat-api.md`
- Stockage sécurisé : **flutter_secure_storage** (jeton d'accès uniquement)
- Cache hors connexion : fichiers JSON dans le répertoire de support de l'application, derrière une interface `CacheStore` ; PDF des reçus en fichiers
- Notifications : `firebase_core`, `firebase_messaging`, `flutter_local_notifications` (affichage au premier plan)
- Carte et scan : `qr_flutter` (affichage), `mobile_scanner` (scan), `cryptography` (vérification Ed25519 hors connexion), `screen_brightness`
- Divers : `url_launcher`, `share_plus`, `image_picker`, `file_picker`, `add_2_calendar`, `package_info_plus`, `connectivity_plus`, `flutter_svg`, `intl`
- Langue : `flutter_localizations` + fichiers ARB (`lib/l10n/app_fr.arb`), français seulement pour l'instant
- Tests : `flutter_test`, `mocktail`, tests de widgets ; `integration_test` pour les parcours principaux

Avant d'ajouter un paquet absent de cette liste : le justifier et demander.

## Commandes

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed, json, riverpod
flutter run --flavor dev -t lib/main_dev.dart                # API locale ou mocks
flutter run --flavor prod -t lib/main_prod.dart
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter test integration_test --flavor dev -t lib/main_dev.dart
```

Variables passées par `--dart-define` (jamais en dur) : `API_BASE_URL`, `USE_MOCKS` (`true` / `false`). En `dev` sur l'émulateur Android, l'API locale est `http://10.0.2.2:8000/api/v1` ; sur un téléphone réel, l'adresse IP du poste sur le réseau local.

## Organisation du code

```
lib/
  main_dev.dart, main_prod.dart   points d'entrée par saveur
  app/                            MaterialApp.router, thème, routeur, configuration
  core/
    api/                          client Dio, intercepteurs (jeton, erreurs, 401), ApiException
    cache/                        CacheStore et mise en cache hors connexion
    design/                       thème généré depuis tokens.json, composants de base (AppButton, AppBadge, AppCard…)
    l10n/                         libellés des énumérations (statut, catégorie, type d'événement…)
  features/
    auth/  home/  card/  events/  contributions/  profile/  notifications/  opportunities/  news/  scan/  app_config/
      data/                       dépôt (interface + implémentation API + implémentation mock)
      domain/                     modèles freezed
      presentation/               écrans, widgets, providers
  l10n/                           app_fr.arb
tool/                             scripts (génération du thème depuis tokens.json)
assets/                           polices, logos
```

Chaque fonctionnalité a un dépôt abstrait et deux implémentations : `Api…Repository` et `Mock…Repository` (données factices conformes au contrat). `USE_MOCKS=true` branche les mocks : l'application doit pouvoir se développer et se démontrer **sans backend**.

## Conventions

- **Langue** : code en anglais ; textes affichés en français, **tous dans `app_fr.arb`**, jamais en dur dans un widget (traduction anglaise prévue).
- **Ton** : tutoiement partout dans l'application (les membres sont des élèves et étudiants).
- **Design** : chaque couleur, taille, espacement et rayon vient du thème généré depuis `docs/design/tokens.json` (`tool/generate_theme.dart` produit `lib/core/design/tokens.g.dart`). **Jamais de `Color(0x…)` en dur dans un écran.** Mode clair et sombre (les tokens ont les deux valeurs). Boutons, badges et filtres en pilule. Polices Bricolage Grotesque (titres) et Plus Jakarta Sans (texte), **embarquées dans `assets/fonts/`** (fichiers de Google Fonts, licence OFL) pour fonctionner hors connexion.
- **Accessibilité** : `Semantics` sur les éléments non textuels, cibles tactiles d'au moins 48 × 48, contraste 4,5:1, texte qui s'adapte à la taille de police du système jusqu'à 200 % sans débordement.
- **Téléphones modestes** : Android 8 et plus, iOS 15 et plus ; listes paginées, images mises en cache et redimensionnées, pas d'animation lourde ; tester sur un émulateur d'entrée de gamme.
- **Erreurs** : toute erreur réseau donne un message clair et un bouton « Réessayer » ; hors connexion, afficher les données en cache avec la mention « Hors connexion · mis à jour le … ». Les erreurs 422 s'affichent sous le champ concerné.
- **Icônes** : au trait, type Lucide (`lucide_icons_flutter` ou SVG), pas d'emoji.

## Les maquettes

Les fichiers `docs/maquettes/*.dc.html` sont le code source des maquettes validées par le bureau, au format téléphone (390 × 844). Ils ne s'ouvrent pas tels quels dans un navigateur (ils dépendent de l'outil de maquettage), mais se lisent comme du HTML : structure, textes, couleurs, tailles, et dans le bloc `<script>` final, la logique des parties interactives. Reproduis leur structure, leurs contenus et leur hiérarchie avec des widgets Flutter et le thème ; leur code n'est pas à copier. Pour le rendu visuel, demande à la personne une capture.

Les textes entre crochets (`[DATE]`, `[PHOTO]`, `[Nom et prénoms]`…) sont des emplacements de contenu : ils viennent de l'API. Ne les remplace jamais par des contenus inventés, sauf dans les mocks, avec des données manifestement factices.

## Règles impératives

1. **Jeton** : uniquement dans `flutter_secure_storage`. Jamais dans les journaux, jamais dans `SharedPreferences`. Une réponse 401 efface le jeton et renvoie à la connexion.
2. **Données personnelles** : rien dans les journaux en production (pas de corps de requête ni de réponse). Le cache hors connexion se vide à la déconnexion et à la suppression du compte.
3. **Carte de membre** : le QR code affiche `qr_payload` tel que reçu. L'application ne fabrique ni ne modifie jamais un QR code. Le scan du bureau vérifie la signature Ed25519 avec `card_public_key` de `/app/config`, mais c'est le backend qui enregistre la présence.
4. **Consentements** : les cases (vitrine de talents, transmission du CV pour une opportunité) ne sont jamais pré-cochées.
5. **Paiements** : l'application n'encaisse rien. Elle affiche les cotisations, paiements et reçus enregistrés par le trésorier, et l'encart « Comment payer ? ».
6. **Droits** : l'onglet ou l'action de scan n'apparaît que si `abilities` contient `attendance.scan`. Le backend vérifie de toute façon.
7. **Pas de clé ni de secret** dans le dépôt : `google-services.json`, `GoogleService-Info.plist`, fichiers de signature et `key.properties` restent hors de Git (modèles `.example` à la place).
8. Avant de déclarer une tâche terminée : `flutter analyze` sans avertissement, `dart format` sans changement, `flutter test` au vert.

## Méthode de travail

- Un lot par branche (`feature/app-<lot>-<sujet>`), petits commits explicites.
- Suivre l'ordre de `docs/plan-developpement-app.md`. Présenter le plan du lot, attendre la validation, puis coder avec les tests.
- Une route manque ou diffère du contrat d'API : **ne l'invente pas côté application**. Signale-le ; le contrat se modifie d'abord, dans les trois dépôts.
- Une règle métier est ambiguë : poser la question plutôt que d'inventer.
