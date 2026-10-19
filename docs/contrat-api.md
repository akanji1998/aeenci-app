# Contrat d'API — backend, site web et application mobile AEENCI

**Version 3 — 18 octobre 2026 — validée.** Elle reprend la version 2.1 (18 octobre 2026 : détail d'une actualité, précisions sur la liste des actualités) sans rien en retirer, et ajoute les opportunités ciblées, les offres soumises par les recruteurs et les routes de l'application mobile (voir « Nouveautés de la version 3 » en fin de document). Ce document est **identique dans les trois dépôts** (`aeenci-backend`, `aeenci-site`, `aeenci-app`) : toute modification se fait d'abord ici, dans les trois dépôts à la fois.

Il liste les routes de l'API Laravel (`https://api.aeenci.com/api/v1`, sauf l'authentification par cookie, à la racine) et la forme de chaque ressource. Le backend les implémente ; le site et l'application les consomment et en tirent leurs types et leurs mocks.

## Conventions

- Réponses en JSON, ressources Laravel : `{"data": …}` ; listes paginées : `{"data": […], "meta": {"current_page", "last_page", "per_page", "total"}}`.
- Dans les tableaux de champs, `?` marque un champ qui peut valoir `null` ; `[]` une liste.
- Dates en ISO 8601 (`2026-10-13`, `2026-10-13T15:00:00+00:00`) ; années en entiers ; montants en entiers F CFA.
- Les noms de champs de l'API sont en anglais et **peuvent différer des colonnes en base** : c'est la ressource Laravel qui fait la correspondance (ex. `member_number` ↔ `members.matricule`).
- Les valeurs d'énumération sont celles du backend (`app/Enums`), listées ici à chaque fois. Le site les traduit en libellés français.
- Erreurs de validation : HTTP 422, `{"message", "errors": {"champ": ["…"]}}`. Non connecté : 401. Interdit : 403. Ressource d'un autre membre ou inexistante : **404**.
- Création (`POST`) : 201 avec `{"data": {"id", "created_at"}}`, sauf mention contraire. Action sans contenu : 204.
- **Envois avec fichier** : `multipart/form-data`, booléens en `1` / `0`, listes en `champ[]`. Pour un `PATCH` avec fichier, le client envoie un `POST` avec `_method=PATCH`.
- **Fichiers** : toutes les URL (`*_url`) sont absolues. Les images publiques sont servies par `https://api.aeenci.com/storage/…`. Les fichiers privés ou soumis à consentement (CV, reçus) passent par une route de l'API, jamais par un chemin de stockage.
- Les routes publiques ne renvoient **jamais** de téléphone, d'e-mail ni d'adresse de membre, d'aîné ou de donateur.
- Les routes publiques qui reçoivent un formulaire sont limitées en débit (429 au-delà).

## Authentification

### Par cookie de session (site web)

À la racine de `https://api.aeenci.com`, pas sous `/api/v1` (convention Sanctum).

| Méthode | Route | Rôle | Réponse |
| --- | --- | --- | --- |
| GET | `/sanctum/csrf-cookie` | Initialise le cookie CSRF avant toute requête qui modifie des données | 204 |
| POST | `/login` | Connexion : `email`, `password`, `remember` (facultatif) | 204, ou 422 avec l'erreur sous `email` |
| POST | `/logout` | Déconnexion | 204 |
| POST | `/forgot-password` | Demande de réinitialisation : `email` | 204 (même si l'adresse est inconnue) |
| POST | `/reset-password` | Nouveau mot de passe : `token`, `email`, `password`, `password_confirmation` | 204, ou 422 |

Côté backend : `SANCTUM_STATEFUL_DOMAINS=aeenci.com`, `SESSION_DOMAIN=.aeenci.com`, CORS avec `supports_credentials` pour `https://aeenci.com`. Le lien de l'e-mail de réinitialisation pointe vers `https://aeenci.com/reinitialiser-mot-de-passe?token=…&email=…`.

### Par jeton (application mobile, V2)

Le site n'en a pas besoin. Une route authentifiée accepte indifféremment le cookie de session ou l'en-tête `Authorization: Bearer <token>`.

| Méthode | Route | Rôle |
| --- | --- | --- |
| POST | `/api/v1/auth/login` | `email`, `password`, `device_name` (facultatif) ; renvoie `token` et `user` |
| POST | `/api/v1/auth/logout` | Révoque le jeton utilisé pour l'appel |
| POST | `/api/v1/auth/forgot-password` | *(v3)* `email` ; 204 même si l'adresse est inconnue. Même e-mail que pour le site |
| POST | `/api/v1/auth/reset-password` | *(v3)* `token`, `email`, `password`, `password_confirmation`, `device_name` ; 200 avec `token` et `user` (la session de l'application est ouverte), ou 422 |

`user` (réponse de connexion) : `id`, `email`, `roles[]`, `abilities[]` (voir `GET /me`), `member_id?`.

### Activation d'un compte recensé

Le membre recensé reçoit une invitation dont le lien pointe vers `https://aeenci.com/activer-mon-compte?token=…`. Le site appelle :

| Méthode | Route | Rôle | Réponse |
| --- | --- | --- | --- |
| GET | `/invitations/{token}` | Vérifie l'invitation | `first_names`, `expires_at` ; 404 si inconnue, 410 si expirée ou déjà utilisée |
| POST | `/invitations/{token}/accept` | `password`, `password_confirmation` ; crée le compte, le relie à la fiche et ouvre la session | 204 ; *(v3)* si `device_name` est envoyé (application), 200 avec `token` et `user` au lieu d'ouvrir une session par cookie |

## Routes publiques

| Méthode | Route | Page | Contenu |
| --- | --- | --- | --- |
| GET | `/site/sections?group=` | Accueil, Association, Événements, Talents, Adhésion, Partager son parcours | Rubriques publiées, dans l'ordre d'affichage, filtrables par groupe |
| GET | `/site/stats` | Accueil | Chiffres clés |
| GET | `/site/contact` | Pied de page, Contact, espace membre | Coordonnées de l'association et numéros Mobile Money |
| GET | `/news` | Accueil, Actualités | Actualités publiées, de la plus récente à la plus ancienne, paginées (`?page=`) |
| GET | `/news/{slug}` | Actualités | Détail d'une actualité publiée ; 404 si elle n'existe pas, est un brouillon ou est programmée |
| GET | `/events?type=&upcoming=1` ou `&past=1` | Accueil, Événements | Événements publiés ; `upcoming` : à venir, du plus proche au plus lointain ; `past` : passés, du plus récent au plus ancien |
| GET | `/events/{slug}` | Événements | Détail d'un événement |
| POST | `/events/{slug}/registrations` | Événements | Inscription, membre ou non |
| GET | `/meetings/next` | Événements | Prochaine assemblée mensuelle : date et lieu seulement ; 204 s'il n'y en a pas |
| GET | `/laureates?edition=&exam=` | Événements | Lauréats de la JOE |
| GET | `/bureau/current` | Association | Bureau du mandat en cours |
| GET | `/presidents` | Association | Galerie des présidents, du plus ancien au plus récent |
| GET | `/elders` | Accueil, Association | Aînés publiés et non retirés |
| POST | `/elder-submissions` | Partager son parcours | Témoignage d'un aîné |
| GET | `/talents?q=&domain=&city=&page=` | Talents | Profils publics validés |
| GET | `/talents/{id}` | Talents | Détail d'un profil public |
| GET | `/talents/{id}/cv` | Talents | CV en PDF d'un profil publié ; 404 sinon |
| POST | `/talents/{id}/contact` | Talents | Message d'un recruteur ; 204 |
| GET | `/membership-fees` | Accueil, Adhésion | Droit d'adhésion en vigueur par catégorie |
| GET | `/education-levels` | Adhésion, Ma fiche | Niveaux d'études proposés (liste tenue par le bureau) |
| POST | `/membership-applications` | Adhésion | Demande d'adhésion complète, avec création du compte |
| POST | `/recruiter-offers` | Talents · Publier une offre *(v3)* | Offre soumise par un recruteur, sans compte |
| GET | `/recruiter-offers/confirm/{token}` | Confirmation de l'e-mail du recruteur *(v3)* | Lien signé de l'e-mail |
| GET | `/recruiter-offers/status/{status_token}` | Suivi privé de l'offre *(v3)* | État de l'offre pour le recruteur |
| GET | `/app/config` | Application *(v3)* | Versions exigées, maintenance, clé publique des cartes |

## Routes authentifiées

| Méthode | Route | Section | Contenu |
| --- | --- | --- | --- |
| GET | `/me` | Tableau de bord, Ma fiche | Fiche du membre connecté |
| PATCH | `/me` | Ma fiche | Identité, contacts, photo |
| GET | `/membership-application` | Suivi de l'adhésion | Dernière demande du candidat connecté, avec le motif en cas de refus |
| POST | `/membership-application` | Suivi de l'adhésion | Nouvelle demande après un refus (mêmes champs que la demande initiale, sans le compte) |
| GET | `/me/educations` | Ma fiche | Parcours scolaire |
| POST | `/me/educations` | Ma fiche | Ajouter une formation |
| PATCH | `/me/educations/{id}` | Ma fiche | Modifier une formation |
| DELETE | `/me/educations/{id}` | Ma fiche | Supprimer une formation ; 204 |
| GET | `/me/profile` | Profil pro | Profil professionnel complet |
| PATCH | `/me/profile` | Profil pro | Titre, domaine, ville, présentation, compétences, langues, CV, LinkedIn |
| PATCH | `/me/profile/visibility` | Profil pro | Activer ou retirer la vitrine |
| POST | `/me/experiences` | Profil pro | Ajouter une expérience |
| PATCH | `/me/experiences/{id}` | Profil pro | Modifier une expérience |
| DELETE | `/me/experiences/{id}` | Profil pro | Supprimer une expérience ; 204 |
| POST | `/me/portfolio-items` | Profil pro | Ajouter une réalisation |
| PATCH | `/me/portfolio-items/{id}` | Profil pro | Modifier une réalisation |
| DELETE | `/me/portfolio-items/{id}` | Profil pro | Supprimer une réalisation ; 204 |
| GET | `/me/contributions` | Cotisations | Situation par année |
| GET | `/me/payments` | Cotisations | Historique des paiements non annulés |
| GET | `/me/payments/{id}/receipt` | Cotisations | Reçu PDF ; **404** si le paiement n'appartient pas au membre connecté |
| GET | `/me/registrations` | Mes événements | Inscriptions à venir et passées |
| DELETE | `/me/registrations/{id}` | Mes événements | Annuler une inscription à venir ; 204 |
| GET | `/me/attendances?months=12` | Mes événements | Présences aux assemblées de la période |
| PUT | `/me/password` | Compte *(v3)* | `current_password`, `password`, `password_confirmation` ; 204. Révoque les autres jetons et sessions du compte |
| DELETE | `/me/account` | Compte *(v3)* | `password` ; 204. Supprime le compte de connexion (voir « Suppression du compte ») |
| POST | `/me/registrations` | Mes événements *(v3)* | `event_slug` ; inscription du membre connecté, sans ressaisie |
| GET | `/me/card` | Carte *(v3)* | Carte de membre et contenu signé du QR code |
| POST | `/me/devices` | Notifications *(v3)* | Enregistrer le téléphone pour les notifications |
| DELETE | `/me/devices/{token}` | Notifications *(v3)* | Retirer le téléphone ; 204 |
| GET | `/me/notifications?page=` | Notifications *(v3)* | Centre de notifications |
| POST | `/me/notifications/read` | Notifications *(v3)* | Marquer comme lues ; 204 |
| GET | `/me/notification-preferences` | Réglages *(v3)* | Catégories et leur état |
| PATCH | `/me/notification-preferences` | Réglages *(v3)* | Activer ou désactiver des catégories |
| GET | `/me/opportunities` | Opportunités *(v3)* | Opportunités reçues et non clôturées |
| GET | `/me/opportunities/{id}` | Opportunités *(v3)* | Détail ; marque l'offre comme vue ; 404 si non reçue |
| POST | `/me/opportunities/{id}/interest` | Opportunités *(v3)* | Se dire intéressé ; 204 |
| DELETE | `/me/opportunities/{id}/interest` | Opportunités *(v3)* | Retirer son intérêt et l'accord CV ; 204 |
| GET | `/attendance/meetings` | Scan (bureau) *(v3)* | Assemblées du jour et de la veille, pour choisir celle qu'on scanne |
| POST | `/attendance/scans` | Scan (bureau) *(v3)* | Envoi groupé des présences scannées |

Une route authentifiée ne renvoie jamais les données d'un autre membre : le backend le vérifie par Policy, et chacun des deux dépôts le teste.

---

## Formes des ressources

### Contenus du site

**Rubrique** — `GET /site/sections`

| Champ | Notes |
| --- | --- |
| `key` | Identifiant stable de la rubrique (ex. `home_hero`) |
| `group` | Groupe d'affichage (liste ci-dessous) |
| `label?` | Surtitre court : année, repère, durée |
| `title` | |
| `body?` | Texte |
| `image_url?` | |

Groupes utilisés par le site, créés d'avance dans la plateforme de gestion pour que la communication n'ait qu'à les remplir. Un groupe vide masque son bloc.

| Groupe | Page | Utilisation |
| --- | --- | --- |
| `home_hero` | Accueil | `body` : texte d'accroche ; `image_url` : photo du haut de page |
| `home_join` | Accueil | `image_url` : photo de l'appel à l'adhésion |
| `association_hero` | Association | 1re rubrique : texte d'accroche et photo d'archive ; 2e : photo récente |
| `association_history` | Association | Étapes de l'histoire ; `label` : année ou repère |
| `association_history_photo` | Association | `image_url` |
| `association_mission` | Association | Piliers de la mission |
| `association_rubrics` | Association | Rubriques des assemblées |
| `association_rubrics_photo` | Association | `image_url` |
| `association_generations` | Association | Statuts ; `label` : ancienneté, pour ne pas écrire les seuils en dur |
| `association_generations_photo` | Association | `image_url` |
| `events_hero` | Événements | `body` : texte d'accroche ; `image_url` |
| `events_assemblies` | Événements | `image_url` |
| `events_laureates` | Événements | `image_url` |
| `talents_hero` | Talents | `image_url` |
| `membership_intro` | Adhésion | `image_url` |
| `elder_story_intro` | Partager son parcours | `image_url` |
| `privacy_policy` | Confidentialité *(v3)* | Une rubrique par partie : `title` (titre de la partie), `body` (texte fourni par le bureau) |

Pour les groupes `*_photo`, `events_assemblies`, `events_laureates`, `talents_hero`, `membership_intro` et `elder_story_intro`, seule l'image de la première rubrique est lue. Les formats attendus sont dans `docs/photos-a-fournir.md`.

**Chiffre clé** — `GET /site/stats` : `key`, `value` (texte, saisi par la communication : « ≈ 200 »), `label`. Pas de calcul automatique tant que le recensement n'est pas terminé.

**Coordonnées** — `GET /site/contact` : `email?`, `phone?`, `whatsapp?`, `address?`, `mobile_money[]` (`operator` : `orange_money`, `mtn_momo`, `moov_money`, `wave` ; `number` ; `account_name`), `social_links[]` (`network`, `url`). Tous les champs sont modifiables par le bureau.

**Actualité** — `GET /news`, `GET /news/{slug}` : `id`, `slug`, `title`, `excerpt`, `body`, `image_url?`, `published_at`. Même ressource dans la liste et le détail. `body` est du texte Markdown, tel que saisi dans la plateforme de gestion ; le site l'affiche sans interpréter de HTML brut. Seules sortent les actualités dont la date de publication est passée : ni brouillon, ni actualité programmée.

### Événements

**Événement** — `GET /events`, `GET /events/{slug}`

| Champ | Notes |
| --- | --- |
| `id`, `slug` | |
| `type` | `joe`, `employment_day`, `impact`, `other` |
| `title`, `summary` | `summary` : une ou deux phrases pour les cartes |
| `description` | Texte complet |
| `edition?` | Année de l'édition |
| `starts_at`, `ends_at?` | |
| `location?`, `audience?` | `audience` : public visé (« Ouvert à tous ») |
| `image_url?` | |
| `registration_open` | |
| `attendees_count?` | Événements passés seulement : valeur saisie, sinon nombre de présents enregistrés |

**Inscription** — `POST /events/{slug}/registrations` : envoi `full_name`, `email`, `phone`, `school` (facultatif) ; réponse 201 `id`, `event_slug`, `created_at`. Une deuxième inscription avec le même e-mail renvoie 422 sous `email`. Inscriptions fermées : 422 sous `event`.

**Assemblée** — `GET /meetings/next` : `date`, `location?`.

**Lauréat** — `GET /laureates` : `id`, `edition` (année), `exam` (`bepc`, `bac`), `rank?` (1, 2, 3…), `full_name`, `school`, `distinction?`, `photo_url?`. **Jamais de moyenne.** `photo_url` vaut `null` tant que l'accord pour la photo n'est pas enregistré (accord d'un parent pour un mineur).

### Association

**Bureau** — `GET /bureau/current` : `mandate` (« 2026-2027 »), `members[]` : `id`, `full_name`, `position`, `photo_url?`.

**Président** — `GET /presidents` : `id`, `full_name`, `mandate_start` (année), `mandate_end?` (`null` : en exercice), `photo_url?`. Une entrée par mandat : une personne réélue apparaît plusieurs fois.

**Aîné** — `GET /elders` : `id`, `full_name`, `photo_url?`, `headline?` (titre de la fiche), `current_role?`, `quote?`, `story?`, `member_since?` (année). Jamais de coordonnées.

**Témoignage** — `POST /elder-submissions` (`multipart/form-data`)

| Champ | Règle |
| --- | --- |
| `full_name` | obligatoire |
| `is_registered_member` | booléen, obligatoire |
| `member_number` | facultatif (matricule) |
| `member_since` | année, obligatoire |
| `bureau_positions` | facultatif |
| `current_role` | obligatoire |
| `organization` | facultatif |
| `domain`, `location` | obligatoires |
| `story` | obligatoire |
| `quote` | obligatoire, 200 caractères au plus |
| `advice` | facultatif |
| `photo` | obligatoire, image JPEG ou PNG, 5 Mo au plus |
| `email`, `phone` | obligatoires, jamais publiés |
| `available_to_speak` | booléen |
| `publication_consent` | doit valoir `1` |

### Talents

**Profil (liste)** — `GET /talents` : `id`, `full_name`, `headline`, `domain`, `city`, `skills[]` (textes), `photo_url?`. Dans `meta`, en plus de la pagination : `filters` = `{"domains": […], "cities": […]}`, les domaines et villes des profils publiés.

**Profil (détail)** — `GET /talents/{id}` : ceux de la liste, plus `summary?`, `experiences[]` (`id`, `title`, `organization`, `location?`, `started_on`, `ended_on?`, `description?`), `languages[]` (`name`, `level?`), `portfolio[]` (`id`, `title`, `description?`, `url?`, `file_url?`), `cv_url?` (pointe vers `/talents/{id}/cv`), `linkedin_url?`. Jamais de téléphone, d'e-mail ni d'adresse.

**Message** — `POST /talents/{id}/contact` : `sender_name`, `sender_email`, `company`, `message` ; 204.

### Adhésion

**Droit d'adhésion** — `GET /membership-fees` : `category` (`student`, `young_professional`, `professional`), `amount`.

**Niveau d'études** — `GET /education-levels` : `value` (envoyé dans `education_level`), `label` (affiché).

**Demande** — `POST /membership-applications` (`multipart/form-data`)

| Bloc | Champs |
| --- | --- |
| Éligibilité | `is_nigerian`, `has_required_level` : doivent valoir `1` |
| Identité | `last_name`, `first_names`, `gender` (`female`, `male`), `birth_date`, `birth_place`, `phone`, `whatsapp` (facultatif), `email`, `city`, `photo` (facultatif) |
| Parcours | `category` (`student`, `young_professional`, `professional`), `education_level`, `school`, `field_of_study` |
| Profil pro (facultatif) | `headline`, `domain`, `skills[]`, `cv` (PDF, 5 Mo au plus), `linkedin_url`, `showcase_consent` |
| Compte | `password`, `password_confirmation` |
| Consentement | `data_consent` : doit valoir `1` |

Réponse 201. Le compte est créé avec le rôle candidat et **la session est ouverte** : le site peut afficher aussitôt le suivi de la demande. `showcase_consent` enregistre le consentement daté ; le profil n'est visible qu'après validation de l'adhésion puis du profil par le bureau.

**Suivi** — `GET /membership-application` : `id`, `state` (`pending`, `approved`, `rejected`), `submitted_at`, `reviewed_at?`, `decision_reason?`.

### Espace membre

**Fiche** — `GET /me`

| Champ | Notes |
| --- | --- |
| `id`, `member_number?` | Matricule, `null` tant que l'adhésion n'est pas validée |
| `last_name`, `first_names`, `gender`, `birth_date`, `birth_place`, `nationality` | |
| `photo_url?`, `phone`, `whatsapp?`, `email`, `address?`, `city` | Visibles par le membre lui-même uniquement |
| `admission_state` | `pending`, `approved`, `rejected` |
| `status?` | `member`, `former`, `elder` (`null` avant validation) |
| `engagement?` | `active`, `dormant` |
| `category` | `student`, `young_professional`, `professional` |
| `joined_at?` | Date de validation de l'adhésion |
| `abilities[]` | *(v3)* Actions permises dans les applications, ex. `attendance.scan`. Liste vide pour un membre sans rôle au bureau |

**Parcours scolaire** — `/me/educations` : `id`, `level` (une `value` de `/education-levels`), `school`, `field_of_study`, `diploma?`, `start_year?`, `end_year?`.

**Profil pro** — `GET /me/profile` : `headline?`, `domain?`, `city?`, `summary?`, `skills[]`, `languages[]` (`name`, `level?`), `experiences[]`, `portfolio[]`, `cv_url?`, `linkedin_url?`, `is_public`, `showcase_status` (`private` : vitrine désactivée ; `pending` : en attente de validation ; `published`), `consented_at?`. `PATCH /me/profile` accepte les mêmes champs modifiables, `skills[]` et `languages[]` remplaçant les listes existantes, et `cv` en fichier.

**Vitrine** — `PATCH /me/profile/visibility` : envoi `is_public` ; réponse : le profil pro. Activer enregistre la date du consentement ; retirer dépublie immédiatement.

**Expérience** — `/me/experiences` : `id`, `title`, `organization`, `location?`, `started_on`, `ended_on?`, `description?`.

**Réalisation** — `/me/portfolio-items` : `id`, `title`, `description?`, `url?`, `file_url?` (envoi : `file`).

**Cotisation** — `GET /me/contributions` : `year` (« 2026-2027 »), `due_amount`, `paid_amount`, `state` (`unpaid`, `partial`, `paid`, `exempt`).

**Paiement** — `GET /me/payments` : `id`, `receipt_number`, `paid_on` (date), `purpose` (`admission`, `contribution`), `contribution_year?` (« 2026-2027 »), `amount`, `method` (`cash`, `orange_money`, `mtn_momo`, `moov_money`, `wave`, `bank_transfer`, `other`).

**Inscription** — `GET /me/registrations` : `id`, `event` (`slug`, `type`, `title`, `starts_at`, `location?`), `created_at`, `can_cancel`.

**Présence** — `GET /me/attendances` : `date` (de l'assemblée), `state` (`present`, `excused`, `absent`). Seules les assemblées de la période figurent.

### Compte *(v3)*

**Mot de passe** — `PUT /me/password` : 422 sous `current_password` si l'ancien mot de passe est faux. Le jeton ou la session qui fait l'appel reste valide ; tous les autres sont révoqués.

**Suppression du compte** — `DELETE /me/account` : 422 sous `password` si le mot de passe est faux. Le compte de connexion est supprimé et tous ses jetons révoqués ; la vitrine est retirée ; les appareils sont retirés. **La fiche de membre, les cotisations, les paiements et les présences sont conservés** par l'association (règle de conservation du cahier des charges). Un nouveau compte pourra être relié à la fiche plus tard par une invitation du bureau. Exigée par Google Play et l'App Store.

---

## Nouveautés de la version 3

### Opportunités ciblées (membres)

**Opportunité (liste)** — `GET /me/opportunities` (paginée, la plus récente d'abord) : `id`, `type` (`job`, `internship`, `scholarship`, `training`, `other`), `title`, `organization`, `location?`, `deadline?` (date), `received_at`, `seen` (booléen), `interested` (booléen). Dans `meta`, en plus de la pagination : `unseen_count`.

**Opportunité (détail)** — `GET /me/opportunities/{id}` : ceux de la liste, plus `description`, `apply_method` (`url`, `email`, `via_bureau`), `apply_url?`, `apply_email?`, `apply_note?`, `job_description_url?` (fiche de poste jointe, servie par une route authentifiée), `matched_on` (`domains[]`, `skills[]`, `cities[]`, `categories[]`, `education_levels[]` : seulement les critères qui ont fait correspondre ce membre), `cv_shared` (booléen). Ne renvoie jamais la note interne du bureau, les critères de ciblage complets ni la provenance de l'offre.

**Intérêt** — `POST /me/opportunities/{id}/interest` : envoi `share_cv` (booléen) ; 204. `share_cv` à `1` exige un CV dans le profil pro, sinon 422 sous `share_cv`. Offre clôturée : 422 sous `opportunity`.

### Offres soumises par les recruteurs (public)

**Soumission** — `POST /recruiter-offers` (`multipart/form-data`) :

| Bloc | Champs |
| --- | --- |
| Organisation | `organization`, `sector`, `website` (facultatif, URL), `city` |
| Contact | `contact_name`, `contact_role`, `email` (professionnel), `phone` |
| Offre | `type` (`job`, `internship`, `scholarship`, `training`, `other`), `title`, `location`, `deadline` (facultatif, date future), `description`, `domain` (facultatif), `skills` (facultatif, texte libre), `education_level` (facultatif, une `value` de `/education-levels`) |
| Fiche de poste | `job_description` : facultatif, PDF, DOC ou DOCX, 5 Mo au plus |
| Candidature | `apply_method` (`url`, `email`, `via_bureau`) ; `apply_url` obligatoire si `url` ; `apply_email` obligatoire si `email` |
| Engagements | `accept_real`, `accept_free`, `accept_privacy` : doivent valoir `1` |
| Anti-abus | `website_confirm` : champ piège, doit rester vide |

Réponse **202 sans corps** dans tous les cas où la validation passe (y compris recruteur ou domaine bloqué, champ piège rempli : rien n'est alors créé). 422 en cas d'erreur de validation ; 429 au-delà de 3 envois par heure et par adresse IP.

**Confirmation** — `GET /recruiter-offers/confirm/{token}` : 200 avec `status_url` (adresse de la page de suivi sur le site) ; 410 si le lien a expiré (48 heures) ou a déjà servi ; 404 si inconnu. Le lien de l'e-mail pointe vers `https://aeenci.com/talents/offre/confirmation/{token}`, page du site qui appelle cette route.

**Suivi** — `GET /recruiter-offers/status/{status_token}` : `title`, `organization`, `submitted_at`, `state` (`pending` : en cours d'examen ; `sent` : transmise ; `rejected` ; `closed`), `recipients_count?` (si `sent` ou `closed`), `rejection_reason?` (si `rejected`). Jamais de donnée de membre. Le site affiche ce suivi à `https://aeenci.com/talents/offre/suivi/{status_token}`.

### Application mobile

**Configuration** — `GET /app/config` (public, mis en cache) : `min_version` (ex. `1.0.0` : en dessous, mise à jour obligatoire), `latest_version`, `store_urls` (`android`, `ios`), `maintenance` (booléen), `maintenance_message?`, `card_public_key` (clé publique Ed25519 des cartes, en base64), `support_email?`.

**Appareil** — `POST /me/devices` : `token` (jeton Firebase Cloud Messaging), `platform` (`android`, `ios`), `app_version`, `locale` (`fr`) ; 204. Un même jeton déjà connu est rattaché au compte qui appelle (changement d'utilisateur sur le téléphone). `DELETE /me/devices/{token}` : 204, à appeler à la déconnexion.

**Notification** — `GET /me/notifications` (paginée, la plus récente d'abord) : `id`, `category` (`account`, `events`, `meetings`, `contributions`, `news`, `opportunities`, `announcements`), `title`, `body`, `route?` (écran à ouvrir dans les applications, voir ci-dessous), `read_at?`, `created_at`. Dans `meta` : `unread_count`.

`POST /me/notifications/read` : `ids[]`, ou `all` = `1` ; 204.

Valeurs de `route` (identiques dans la charge des notifications push, champ `route`) : `/evenements/{slug}`, `/cotisations`, `/opportunites/{id}`, `/actualites/{slug}`, `/adhesion/suivi`, `/profil/vitrine`, `/carte`, `/notifications`. Le site traduit ces chemins vers ses propres adresses (`/espace/...`).

**Préférences** — `GET /me/notification-preferences` : liste de `category`, `enabled` (booléen), `locked` (booléen : `account` est toujours activée et `locked`). `PATCH /me/notification-preferences` : objet `{"events": false, "news": true, …}` ; une catégorie `locked` est ignorée ; réponse : la liste à jour. Catégories modifiables : `events`, `meetings`, `contributions`, `news`, `opportunities`, `announcements`. Toutes activées par défaut.

**Inscription d'un membre** — `POST /me/registrations` : `event_slug` ; 201 avec l'inscription (forme de `GET /me/registrations`). Déjà inscrit : 422 sous `event_slug`. Inscriptions fermées : 422 sous `event`. Les coordonnées viennent de la fiche du membre.

**Carte de membre** — `GET /me/card` (membre admis seulement ; 403 pour un candidat) :

| Champ | Notes |
| --- | --- |
| `member_number` | Matricule |
| `full_name`, `photo_url?` | |
| `status`, `engagement?`, `category` | Mêmes valeurs que `GET /me` |
| `joined_at` | |
| `qr_payload` | Texte à encoder dans le QR code (format ci-dessous) |
| `qr_expires_at` | L'application redemande la carte dès qu'elle est en ligne et que l'expiration approche (moins de 7 jours) |

Format de `qr_payload` : `AEENCI1.<données>.<signature>`, où `<données>` est le JSON `{"mid": <id du membre>, "num": "<matricule>", "iat": <horodatage>, "exp": <horodatage>}` encodé en base64url, et `<signature>` la signature **Ed25519** de la chaîne `AEENCI1.<données>`, en base64url, par la clé privée du backend. Validité : 30 jours. Toute application qui connaît `card_public_key` peut vérifier une carte sans réseau ; le backend revérifie toujours à la réception.

**Scan des présences** (permission `attendance.scan`, sinon 403)

`GET /attendance/meetings` : assemblées dont la date est aujourd'hui ou hier : `id`, `date`, `location?`, `scanned_count`.

`POST /attendance/scans` : envoi groupé, pour fonctionner sans réseau puis synchroniser :

```json
{ "meeting_id": 12, "scans": [ { "qr_payload": "AEENCI1....", "scanned_at": "2026-10-18T10:02:11+00:00" } ] }
```

Réponse 200 : `results[]`, un par scan, dans le même ordre : `qr_payload`, `outcome` (`recorded` : présence enregistrée ; `already_recorded` ; `invalid` : signature fausse ou format inconnu ; `expired` ; `not_member` : fiche non admise ou archivée), `member?` (`full_name`, `member_number`, `photo_url?`) sauf si `invalid`. Au plus 200 scans par envoi. Un scan enregistre une présence `present` ; il ne remplace jamais une présence déjà saisie à la main.
