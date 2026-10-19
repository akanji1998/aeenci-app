# Plan de développement — Application mobile AEENCI (V2)

Ce plan découpe l'application en lots, à réaliser dans l'ordre. Chaque lot est livrable et testable seul : on ne passe au suivant que lorsque ses critères de fin sont remplis.

Les lots 0 à 6 se font **sur les mocks** (`USE_MOCKS=true`) : ils n'attendent pas le backend. Les lots 7 à 9 demandent l'évolution « Application mobile » du backend, au moins en local. Le lot 10 branche tout sur l'API locale avant la publication.

## Comment l'utiliser avec Claude Code

Pour chaque lot, ouvrir une session Claude Code dans le dépôt et demander :

> Lis CLAUDE.md et docs/plan-developpement-app.md, puis réalise le lot N. Commence par me présenter ton plan, attends ma validation, puis code en écrivant les tests au fur et à mesure.

Relire ensuite le code, lancer l'application et les tests, et fusionner la branche avant le lot suivant.

---

## Lot 0 — Initialisation

- Projet Flutter `aeenci_app`, identifiant `com.aeenci.app`, nom affiché « AEENCI ».
- Deux saveurs `dev` et `prod` (Android `productFlavors`, schémas iOS), points d'entrée `main_dev.dart` et `main_prod.dart`, `--dart-define` pour `API_BASE_URL` et `USE_MOCKS`.
- Paquets de base du `CLAUDE.md`, `analysis_options.yaml` strict, `build_runner`.
- Polices embarquées (Bricolage Grotesque, Plus Jakarta Sans), logos SVG dans `assets/`.
- `tool/generate_theme.dart` : lit `docs/design/tokens.json` et génère `lib/core/design/tokens.g.dart` (couleurs clair et sombre, espacements, rayons, tailles de texte). `ThemeData` clair et sombre construits à partir de ces valeurs.
- Intégration continue GitHub Actions : `flutter analyze`, `dart format`, `flutter test` à chaque push.
- `.gitignore` des fichiers Firebase et de signature ; modèles `.example`.

**Fin** : l'application se lance dans les deux saveurs et affiche une page de démonstration des composants dans les deux thèmes ; la CI passe.

## Lot 1 — Fondations

- Client Dio : base URL, en-tête `Accept: application/json`, intercepteur du jeton `Bearer`, conversion des erreurs en `ApiException` (réseau, 401, 403, 404, 410, 422 avec `errors` par champ, 429, 5xx).
- Modèles freezed de **toutes** les ressources du contrat v3 utilisées par l'application, avec les énumérations et leurs libellés français (`core/l10n`).
- `CacheStore` (lecture, écriture, date de mise à jour, effacement total).
- Routeur go_router : `StatefulShellRoute` à cinq onglets (Accueil, Carte, Événements, Cotisations, Profil), routes hors onglets, garde d'authentification (connecté, candidat, membre admis).
- Composants de base du design system : boutons pilule (principal, secondaire, texte), badge, carte, champ de formulaire, interrupteur, état vide, état d'erreur avec « Réessayer », bandeau hors connexion, squelettes de chargement.
- Mocks : un jeu de données factices cohérent (un membre admis, un candidat, un membre du bureau), latence simulée, erreurs simulables.

**Fin** : navigation complète entre des écrans vides ; tests unitaires du client (chaque type d'erreur) et des modèles (désérialisation d'exemples du contrat).

## Lot 2 — Connexion, compte et configuration

Maquettes : `app-connexion`, `app-suivi`.

- Connexion (`/auth/login` avec `device_name`), mot de passe oublié (`/auth/forgot-password`), déconnexion (`/auth/logout`, effacement du jeton et du cache).
- Activation d'un compte recensé et nouveau mot de passe, depuis les liens `https://aeenci.com/activer-mon-compte?token=…` et `/reinitialiser-mot-de-passe?…` (routes prêtes ; l'ouverture depuis l'e-mail arrive au lot 9).
- Candidat : écran de suivi de l'adhésion (`/membership-application`), en attente ou refusée avec le motif, lien vers le site pour une nouvelle demande. Pas d'onglets pour un candidat.
- `/app/config` au démarrage : écran bloquant « Mise à jour nécessaire » si la version est inférieure à `min_version`, écran de maintenance, valeur mise en cache.
- Écran de démarrage (`flutter_native_splash`) et icône (`flutter_launcher_icons`) à partir du symbole AEENCI.

**Fin** : parcours connexion → accueil, connexion candidat → suivi, mise à jour forcée et maintenance testés en widget.

## Lot 3 — Accueil et carte de membre

Maquettes : `app-accueil`, `app-carte`.

- Accueil : salutation, situation de la cotisation de l'année, prochain événement où le membre est inscrit et prochaine assemblée (`/meetings/next`), opportunités nouvelles (`meta.unseen_count`), deux dernières actualités, rappel pour compléter le profil pro ; tirer pour actualiser.
- Carte (`/me/card`) : photo, nom, matricule, statut, catégorie, date d'adhésion, QR code de `qr_payload` ; **disponible hors connexion** (dernière carte en cache) ; luminosité au maximum pendant l'affichage, restaurée en quittant ; renouvellement automatique quand `qr_expires_at` approche et que le réseau est là.
- Bouton « Scanner les présences » sur la carte, visible seulement avec `attendance.scan` (écran au lot 8).

**Fin** : la carte s'affiche en mode avion après un premier chargement ; test de la règle de renouvellement.

## Lot 4 — Événements

Maquette : `app-evenements`.

- Liste des événements à venir, filtre par type ; détail (description, lieu, date) ; badge « Tu es inscrit » à partir de `/me/registrations`.
- Inscription en un geste (`POST /me/registrations`), annulation (`DELETE /me/registrations/{id}` si `can_cancel`), erreurs 422 expliquées (déjà inscrit, inscriptions fermées).
- Ajout au calendrier du téléphone, lieu ouvert dans l'application de cartes.
- « Mes présences » aux assemblées sur 12 mois (`/me/attendances?months=12`).

**Fin** : inscription puis annulation sur les mocks ; tests de widgets de la liste filtrée.

## Lot 5 — Cotisations et reçus

Maquette : `app-cotisations`.

- Situation par année (`/me/contributions`) avec l'état, historique des paiements (`/me/payments`), libellés des moyens de paiement.
- Reçu PDF : téléchargement authentifié, ouverture et partage ; reçus déjà ouverts gardés hors connexion.
- Encart « Comment payer ? » avec les numéros Mobile Money de `/site/contact` (copie du numéro en un geste).

**Fin** : un reçu s'ouvre et se partage ; un reçu déjà ouvert s'ouvre en mode avion.

## Lot 6 — Profil

Maquettes : `app-profil`, `app-fiche`, `app-parcours`, `app-profilpro`.

- Profil et réglages : en-tête membre, état de la vitrine, liens vers les sous-écrans.
- Ma fiche : identité et contacts modifiables (`PATCH /me`, photo par `image_picker`, envoi `multipart` avec `_method=PATCH`).
- Parcours scolaire : liste, ajout, modification, suppression (`/me/educations`, niveaux de `/education-levels`).
- Profil professionnel : titre, domaine, ville, présentation, compétences, langues, LinkedIn, CV (PDF par `file_picker`), expériences et réalisations ; taux de complétion ; interrupteur de la vitrine avec consentement explicite (`PATCH /me/profile/visibility`) et état `pending` / `published`.
- Compte : changer de mot de passe (`PUT /me/password`), se déconnecter, **supprimer mon compte** (`DELETE /me/account`, confirmation avec mot de passe et texte de la maquette), puis retour à la connexion et cache vidé.

**Fin** : toutes les modifications fonctionnent sur les mocks, erreurs 422 sous les champs ; tests de widgets des formulaires.

## Lot 7 — Notifications et actualités

Maquette : `app-notifications`. Demande l'évolution « Application mobile » du backend.

- Firebase : projet de l'association, une configuration par saveur (`flutterfire configure`), fichiers hors de Git.
- Permission de notification (Android 13 et plus, iOS) demandée au bon moment (après la première connexion, avec un écran d'explication), pas au lancement.
- Enregistrement du téléphone (`POST /me/devices`) à la connexion et au renouvellement du jeton Firebase ; retrait (`DELETE /me/devices/{token}`) à la déconnexion.
- Affichage au premier plan (`flutter_local_notifications`) ; ouverture d'une notification → écran de `data.route` (table des routes du contrat), y compris application fermée.
- Centre de notifications (`/me/notifications`, groupé par jour, « Tout marquer lu »), pastille du nombre non lu.
- Réglages : catégories de `/me/notification-preferences`, `account` verrouillée avec l'explication de la maquette.
- Actualités : liste (`/news`) et article (`/news/{slug}`).

**Fin** : sur un téléphone réel et le backend local, une annonce envoyée depuis Filament arrive, s'ouvre sur le bon écran et apparaît dans le centre.

## Lot 8 — Opportunités et scan des présences

Maquettes : `app-opportunites`, `app-scan`.

- Opportunités : liste (badge « Nouvelle »), détail avec « Pourquoi tu la reçois » construit depuis `matched_on`, façon de postuler (lien, e-mail, via le bureau), fiche de poste si jointe ; « Je suis intéressé » avec la case non cochée « J'autorise le bureau à transmettre mon CV au recruteur, pour cette offre uniquement » (désactivée sans CV, avec un lien vers le profil pro) ; « Retirer mon intérêt » ; réglage « Recevoir des opportunités ».
- Scan (avec `attendance.scan`) : choix de l'assemblée (`/attendance/meetings`), caméra (`mobile_scanner`), **vérification locale** de la signature et de l'expiration avec `card_public_key`, retour immédiat (son ou vibration, nom du membre), file d'attente persistante des scans, envoi groupé (`POST /attendance/scans`) dès que le réseau est là, résultat par carte (`recorded`, `already_recorded`, `invalid`, `expired`, `not_member`), compteur de la séance.

**Fin** : un scan hors connexion est envoyé au retour du réseau sans doublon ; tests unitaires de la vérification Ed25519 (carte valide, signature fausse, expirée) avec des vecteurs générés par le backend.

## Lot 9 — Liens universels

- Android App Links et iOS Universal Links pour `aeenci.com` : `/activer-mon-compte*`, `/reinitialiser-mot-de-passe*`, `/espace/opportunites/*`, `/evenements/*` (fichiers `.well-known` servis par le site).
- Correspondance de ces adresses vers les écrans de l'application ; lien reçu sans être connecté → connexion, puis l'écran demandé.

**Fin** : un lien d'invitation reçu par e-mail ouvre l'écran d'activation de l'application installée, et le site sinon.

## Lot 10 — Intégration, qualité et publication

- Branchement complet sur l'API locale (`USE_MOCKS=false`) avec les comptes de démonstration du backend ; correction des écarts, signalés et reportés dans le contrat si besoin.
- Tests d'intégration des parcours : connexion, carte hors connexion, inscription à un événement, reçu, opportunité, scan.
- Revue d'accessibilité (TalkBack, VoiceOver, texte agrandi), thème sombre, téléphone d'entrée de gamme, connexion lente (profil réseau de l'émulateur).
- Signature Android (clé de téléversement hors de Git), App Bundle ; version iOS par Codemagic si pas de Mac ; numéros de version.
- Fiches des stores : textes, captures, politique de confidentialité (`https://aeenci.com/confidentialite`), page de suppression de compte (`https://aeenci.com/supprimer-mon-compte`), formulaires de sécurité des données, compte de démonstration pour les vérificateurs.
- Test fermé (test interne Google Play, TestFlight) avec le bureau et des membres volontaires, puis publication.

**Fin** : l'application est en test fermé sur les deux stores (ou Android seul si l'abonnement Apple n'est pas encore pris).
