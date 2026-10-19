# Cahier des charges V1 — Plateforme numérique AEENCI

12 octobre 2026

La V1 dote l'AEENCI d'une base de données fiable de ses membres, d'une plateforme de gestion pour le bureau, d'un espace membre et d'un site web public sur aeenci.com.

## 1. Contexte et objectifs

L'AEENCI (Association des Élèves et Étudiants Nigérians en Côte d'Ivoire), fondée en 1972, compte des milliers de membres depuis sa création, dont environ 200 membres actifs. Elle n'a pas aujourd'hui de base de données fiable de ses membres.

L'association tient des assemblées mensuelles et organise trois événements annuels : la JOE (Journée d'Orientation et d'Excellence), la Journée de l'emploi et de l'entrepreneuriat, et AEENCI Impact (cohortes de formation au numérique). Ses ressources proviennent des droits d'adhésion, des cotisations annuelles, des dons extérieurs et des recettes de ses événements.

Objectifs de la V1 :

- constituer une base de données fiable et durable des membres ;
- outiller le bureau pour gérer membres, statuts, cotisations, réunions, événements et trésorerie, en sachant toujours d'où viennent les fonds ;
- donner à chaque membre un espace pour tenir sa fiche à jour ;
- renforcer la notoriété de l'association avec un site web et valoriser les talents de ses membres auprès des recruteurs.

## 2. Périmètre

La V1 couvre la gestion, l'espace membre et le site web. Le projet privilégie une base solide plutôt qu'une date de livraison.

| Version | Contenu |
| --- | --- |
| **V1** | Plateforme de gestion (membres, statuts, cotisations, paiements enregistrés, dons, recettes d'événements, trésorerie, réunions, événements, rôles, contenus du site) · espace membre · site web (présentation, rubriques, aînés, présidents, événements, vitrine de talents) |
| **V2** | Application mobile Flutter « vie de l'association » : profil, actualités, événements, notifications push, carte de membre numérique, suivi de cotisation |
| **V3 et au-delà** | Paiement en ligne (Mobile Money) · espace entreprises, offres, candidatures et recommandations d'offres, si des entreprises partenaires s'engagent |

Hors périmètre V1 : paiement en ligne, publication d'offres d'emploi par des entreprises, matching automatique.

## 3. Architecture technique

Un seul backend Laravel alimente le site, la gestion et l'application :

```
Site web (Next.js, aeenci.com)        ──┐
Application mobile (Flutter, V2)      ──┴──> API REST (api.aeenci.com) ──┐
                                                                         ├── Backend Laravel unique
Bureau (navigateur) ──> Plateforme de gestion (Laravel + Filament,      ─┘        │
                        gestion.aeenci.com)                                        ├──> Base de données (PostgreSQL)
                                                                                   └──> Stockage des fichiers
```

Le site et l'application passent uniquement par l'API ; seul le backend Laravel accède à la base de données et aux fichiers.

- **Backend et gestion** : Laravel, avec Filament pour l'interface d'administration et Laravel Sanctum pour l'authentification de l'API.
- **Site web** : React avec Next.js, rendu côté serveur pour le référencement. L'espace membre y est intégré et passe par l'API.
- **Base de données** : PostgreSQL (retenu dans le modèle de données).
- **Application mobile (V2)** : Flutter, branchée sur la même API.
- **Domaines** : aeenci.com (site), gestion.aeenci.com (plateforme), api.aeenci.com (API).
- **Hébergement** : à choisir, un serveur compatible Laravel et Next.js.

## 4. Acteurs et rôles

Chaque utilisateur reçoit un ou plusieurs rôles, et chaque rôle donne des droits précis.

| Rôle | Accès | Peut faire |
| --- | --- | --- |
| Super-administrateur | Plateforme de gestion | Tout, y compris la gestion des rôles et les paramètres (barèmes, années de cotisation) |
| Président / bureau | Plateforme de gestion | Consulter l'ensemble, valider les adhésions, modifier les statuts |
| Secrétaire général | Plateforme de gestion | Gérer les fiches membres, les réunions et les présences |
| Trésorier | Plateforme de gestion | Enregistrer les paiements, les dons, les recettes et les dépenses, émettre les reçus, suivre les cotisations et la trésorerie |
| Commissaire aux comptes | Plateforme de gestion | Consulter toute la trésorerie, ses justificatifs et ses exports, sans rien modifier |
| Responsable communication | Plateforme de gestion | Gérer les contenus du site : rubriques, aînés, présidents, événements |
| Responsable événements | Plateforme de gestion | Gérer les événements, inscriptions et lauréats |
| Membre | Espace membre | Tenir sa fiche à jour, choisir ce qui est public, consulter ses cotisations et reçus, s'inscrire aux événements |
| Candidat | Espace membre | Remplir sa demande d'adhésion et suivre sa validation |
| Visiteur / recruteur | Site web | Consulter le site et la vitrine de talents, contacter un membre via un formulaire |

## 5. Règles métier

Ces règles structurent le modèle de données. Les montants et seuils sont des **paramètres modifiables** dans la plateforme, jamais écrits en dur dans le code.

### 5.1 Adhésion

- Conditions : nationalité nigériane et niveau Bac (admission dès la classe de terminale).
- Le candidat remplit sa demande en ligne ; le secrétaire général la valide ou la refuse, le président peut revenir sur la décision.
- La date de validation devient la **date d'adhésion**, point de départ de l'ancienneté.
- Le statut de membre est **à vie** : un membre n'est jamais supprimé, il peut seulement changer de statut.

### 5.2 Statuts

Le statut dépend de l'ancienneté, comptée en mandats d'un an (une année de cotisation depuis l'adhésion). Il est calculé automatiquement, et le bureau peut le corriger manuellement avec un motif.

1. **Membre** : jusqu'à 2 mandats d'ancienneté.
2. **Ancien membre** : au-delà de 2 mandats (2 ans).
3. **Aîné** : au-delà de 3 mandats.

Indépendamment du statut, chaque membre est **actif** (au moins 3 présences aux assemblées mensuelles sur les 12 derniers mois) ou **en sourdine**. Un ancien membre ou un aîné peut aussi être actif.

### 5.3 Catégorie

Indépendamment du statut, chaque membre a une catégorie qui détermine son droit d'adhésion : **élève ou étudiant**, **jeune professionnel** ou **professionnel confirmé**. Elle évolue avec sa situation.

### 5.4 Droit d'adhésion et cotisations

| Élément | Règle |
| --- | --- |
| Droit d'adhésion | Payé une fois : 2 000 F CFA (élève ou étudiant), 5 000 F CFA (jeune professionnel), 5 000 F CFA par défaut (professionnel confirmé) |
| Cotisation | Annuelle, sur l'année académique (septembre à août), montant selon le statut d'après un barème fixé chaque année |
| Paiement | En une ou plusieurs fois ; exonération possible au cas par cas, décidée par le bureau avec motif |
| Situation | Pour chaque année : à jour, partiel, en retard ou exonéré, calculé à partir des paiements |

### 5.5 Paiements

- La V1 **enregistre** les paiements ; elle n'encaisse rien en ligne.
- Tous les modes sont acceptés : espèces, Mobile Money (Orange, MTN, Moov, Wave), virement, autre.
- Chaque paiement porte : membre, objet (adhésion ou cotisation de l'année X), montant, date, mode, référence de transaction, agent qui l'a saisi.
- Chaque paiement génère un **reçu numéroté** en PDF, consultable par le membre.
- Un paiement enregistré n'est jamais supprimé : une erreur se corrige par une annulation tracée.

### 5.6 Réunions et événements

- **Assemblées mensuelles** : date, lieu, ordre du jour, compte rendu, liste de présence.
- **Événements** (JOE, Journée de l'emploi et de l'entrepreneuriat, AEENCI Impact) : description, dates, inscriptions des participants, présences.
- **Lauréats de la JOE** : enregistrés par édition, avec l'examen (BEPC, BAC) et la distinction, publiables sur le site.

### 5.7 Dons, recettes d'événements et trésorerie

Toutes les ressources passent par un **journal de trésorerie** unique, où chaque opération porte sa provenance.

| Provenance | Comment elle est enregistrée |
| --- | --- |
| Droits d'adhésion et cotisations | Automatiquement, à chaque paiement de membre enregistré (5.5) |
| Dons extérieurs | Par le trésorier, rattachés à un donateur (personne, entreprise, organisation, institution, aîné ou membre) ; reçu de don numéroté |
| Sponsoring | Comme un don, rattaché au donateur et, le cas échéant, à l'événement soutenu |
| Recettes d'événements | Rattachées à l'événement (billetterie, ventes, participations…) |
| Autres recettes | Catégorie « autre », avec un libellé obligatoire |

- Les **dépenses** des événements et de fonctionnement sont aussi enregistrées, avec un justificatif : c'est ce qui permet de connaître la recette réellement disponible après un événement (recettes moins dépenses de l'événement).
- Un **don en nature** (matériel, salle, prestation) est enregistré à sa valeur estimée, mais n'entre pas dans le solde de caisse.
- L'exercice comptable est l'année académique, de septembre à août, comme les cotisations.
- Rapports : solde de caisse de l'exercice, ressources par provenance, résultat de chaque événement, liste des dons par donateur ; exports Excel.
- Une opération n'est jamais supprimée : une erreur se corrige par une annulation tracée.
- Les coordonnées des donateurs restent internes ; un donateur peut demander l'anonymat s'il est un jour remercié publiquement.

## 6. Fonctionnalités

### 6.1 Plateforme de gestion (gestion.aeenci.com)

1. **Tableau de bord** : nombre de membres par statut et catégorie, taux de cotisation de l'année, ressources de l'exercice par provenance et solde de caisse, adhésions en attente, prochains événements.
2. **Membres** : liste filtrable (statut, catégorie, année d'adhésion, situation de cotisation), fiche complète, historique, export Excel.
3. **Adhésions** : file des demandes, validation ou refus avec motif.
4. **Recensement** : import d'une liste existante et envoi d'invitations pour que chaque membre active son compte et complète sa fiche.
5. **Cotisations et paiements** : saisie des paiements, reçus PDF, suivi des retards par année, paramétrage des barèmes et des droits d'adhésion.
6. **Trésorerie** : donateurs, dons et reçus de dons, recettes et dépenses d'événements, journal de trésorerie, résultat par événement, provenance des fonds, exports.
7. **Réunions** : création, ordre du jour, compte rendu, feuille de présence.
8. **Événements** : création, inscriptions, présences, lauréats de la JOE.
9. **Contenus du site** : rubriques, aînés mis en avant, galerie des présidents, événements publiés, actualités, validation des profils de la vitrine de talents, relecture et publication des témoignages d'aînés.
10. **Administration** : utilisateurs, rôles et droits, journal des actions.

### 6.2 Espace membre

1. Inscription, connexion sécurisée, mot de passe oublié.
2. Demande d'adhésion et suivi de sa validation.
3. Fiche personnelle et profil professionnel : formation, expérience, compétences, photo, CV, portfolio.
4. Choix de ce qui apparaît publiquement dans la vitrine de talents.
5. Consultation de ses cotisations, paiements et reçus.
6. Inscription aux événements.

### 6.3 Site web (aeenci.com)

1. **Accueil** : présentation, chiffres clés, prochains événements, appel à l'adhésion.
2. **L'association** : histoire depuis 1972, mission, rubriques, bureau actuel.
3. **Nos aînés** : parcours des aînés qui font la fierté de l'association, et un formulaire « Partager votre parcours » ouvert aux aînés, membres inscrits ou non. Un témoignage n'est publié qu'avec le consentement de l'aîné et après validation de la version finale avec lui ; ses coordonnées ne sont jamais publiées.
4. **Nos présidents** : galerie des présidents successifs avec leurs mandats.
5. **Événements** : JOE, Journée de l'emploi, AEENCI Impact, éditions passées, lauréats.
6. **Talents** : profils professionnels publics, recherche par domaine, compétence et localisation, contact via formulaire.
7. **Adhérer** et **Contact**.

Tous les contenus du site sont gérés depuis la plateforme de gestion, sans toucher au code.

## 7. Fiche membre et confidentialité

La fiche collecte toutes les informations utiles ; chaque bloc a une visibilité par défaut, et le membre décide de ce qui devient public.

| Bloc | Champs | Visible par défaut |
| --- | --- | --- |
| Identité | Nom, prénoms, sexe, date et lieu de naissance, nationalité, photo | Bureau |
| Contacts | Téléphone, WhatsApp, e-mail, adresse, ville | Bureau |
| Parcours scolaire | Niveau, établissement, filière, diplômes et années | Bureau |
| Profil professionnel | Profession, employeur, domaine, compétences, expériences, langues, CV, portfolio, LinkedIn | Public si le membre l'active |
| Association | Date d'adhésion, statut, catégorie, postes occupés au bureau | Bureau |
| Cotisations | Paiements, reçus, situation par année | Membre et trésorier |

Règles de confidentialité :

- La vitrine de talents est en **opt-in** : un profil n'est publié qu'avec le consentement explicite du membre, enregistré et daté.
- Le téléphone et l'e-mail ne sont jamais affichés publiquement ; les recruteurs passent par un formulaire de contact.
- Le membre peut retirer son profil public à tout moment.
- Le traitement respecte la loi ivoirienne n° 2013-450 relative à la protection des données à caractère personnel ; les formalités auprès de l'ARTCI sont à vérifier.

## 8. Exigences non fonctionnelles

- **Sécurité** : HTTPS partout, mots de passe chiffrés, droits vérifiés côté serveur pour chaque action, double authentification pour les comptes du bureau.
- **Traçabilité** : journal de toutes les modifications sensibles (statuts, paiements, rôles), avec auteur et date.
- **Sauvegardes** : sauvegarde quotidienne automatique de la base de données et des fichiers, conservée hors du serveur principal, avec un test de restauration régulier.
- **Accessibilité mobile** : site et plateforme utilisables sur smartphone, et rapides sur une connexion mobile modeste.
- **Référencement** : site rendu côté serveur, pages indexées par Google, partage propre sur WhatsApp et les réseaux sociaux.
- **Langue** : français en V1 ; structure prête pour l'anglais.
- **Évolutivité** : API documentée, réutilisable par l'application mobile en V2 et par le paiement en ligne plus tard.
- **Qualité du code** : dépôt Git, tests automatisés sur les règles métier (statuts, cotisations), conventions écrites pour les futurs contributeurs.

## 9. Points restant à décider par le bureau

- Montants du barème des cotisations par statut.
- Liste définitive des postes du bureau (postes par défaut : président, vice-président, secrétaire général, trésorier, commissaire aux comptes, responsable communication, responsable événements, responsable orientation ; mandat d'un an).
- Historique des présidents depuis 1972 et aînés à mettre en avant, avec photos.
- Membre du bureau chargé de vérifier les formalités ARTCI, de la politique de confidentialité et des mentions légales.
