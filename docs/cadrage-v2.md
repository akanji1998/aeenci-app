# Cadrage V2 — Application mobile AEENCI

Validé le 18 octobre 2026. Copie de travail du document de cadrage, pour Claude Code ; les routes et réponses de l'API sont dans `docs/contrat-api.md` (v3), qui fait foi.

L'application Flutter met l'espace membre dans la poche de chaque membre : carte de membre, cotisations, événements, profil et notifications, sur la même API que le site.

## 1. Objectifs et utilisateurs

- **Garder chaque membre informé** : notifications pour les événements, les assemblées, les cotisations et la vie de l'association.
- **Donner une identité de membre** : une carte de membre numérique, toujours disponible, même sans connexion.
- **Simplifier le suivi** : cotisations, reçus, inscriptions et profil en quelques gestes.

| Utilisateur | Ce qu'il fait dans l'application |
| --- | --- |
| Membre (actif, en sourdine, ancien, aîné) | Tout le périmètre ci-dessous |
| Candidat | Se connecter et suivre sa demande d'adhésion |
| Membre du bureau | Comme un membre ; scanner les cartes à l'entrée d'une assemblée pour enregistrer les présences |

La gestion de l'association reste sur la plateforme web : l'application ne remplace pas Filament.

## 2. Les écrans

Cinq onglets en bas de l'écran :

| Onglet | Écrans | Contenu |
| --- | --- | --- |
| Accueil | Tableau de bord | Salutation, cotisation de l'année, prochain événement et prochaine assemblée, opportunités reçues, dernières actualités, rappel pour compléter le profil |
| Carte | Carte de membre | Nom, photo, matricule, statut, catégorie, date d'adhésion, QR code signé ; hors connexion ; luminosité augmentée |
| Événements | Liste, détail, mes inscriptions | Filtre par type, inscription en un geste, annulation, ajout au calendrier, lieu dans l'application de cartes ; présences aux assemblées sur 12 mois |
| Cotisations | Situation, historique, reçu | Situation par année, paiements, reçus PDF à ouvrir ou partager, encart « Comment payer ? » avec les numéros Mobile Money |
| Profil | Ma fiche, parcours, profil pro, vitrine, réglages | Fiche, parcours scolaire, profil professionnel, expériences, compétences, CV, vitrine de talents ; notifications, mot de passe, déconnexion, suppression du compte |

Hors onglets : connexion, mot de passe oublié, activation d'un compte recensé ; suivi de l'adhésion (candidat) ; actualités ; centre de notifications ; opportunités ; scan des présences (bureau).

## 3. Notifications

Chaque catégorie peut être désactivée par le membre, sauf celles qui concernent son compte.

| Déclencheur | Message | Catégorie |
| --- | --- | --- |
| Adhésion validée ou refusée | « Bienvenue à l'AEENCI ! » ou motif du refus | Compte (toujours) |
| Paiement enregistré | Montant et reçu disponible | Compte (toujours) |
| Profil validé dans la vitrine | Profil visible des recruteurs | Compte (toujours) |
| Message d'un recruteur transmis | Un recruteur souhaite te contacter | Compte (toujours) |
| Nouvel événement publié | Titre et date | Événements |
| Veille d'un événement où le membre est inscrit | Rappel avec l'heure et le lieu | Événements |
| Assemblée mensuelle à venir | Rappel quelques jours avant | Assemblées |
| Année de cotisation ouverte, ou relance du trésorier | Montant restant et comment payer | Cotisations |
| Actualité marquée « à notifier » | Titre de l'actualité | Actualités |
| Opportunité correspondant au profil | Type, titre et date limite | Opportunités |
| Annonce ponctuelle du bureau | Titre et texte | Annonces du bureau |

Chaque notification est gardée dans le centre de notifications. Fréquence maîtrisée : pas plus d'une notification générale par jour (hors compte, rappels d'inscription et opportunités, qui ont leur propre plafond de deux par semaine).

## 3 bis. Opportunités ciblées

Le bureau relaie aux membres concernés des offres d'emploi, de stage, de bourse ou de formation, saisies par lui ou soumises par un recruteur depuis le site puis vérifiées. Le ciblage se fait sur le profil (domaines, compétences, villes, catégories, niveaux d'études). Le membre reçoit une notification, consulte l'offre, voit pourquoi il la reçoit, postule directement ou indique « Je suis intéressé » en autorisant, s'il le souhaite, la transmission de son CV pour cette offre seulement. Réglage « Recevoir des opportunités » activé par défaut, désactivable. Les offres ne sont jamais publiques.

## 4. Hors périmètre de la V2

- Paiement en ligne des cotisations (V3, Mobile Money).
- Demande d'adhésion : elle reste sur le site ; l'application y renvoie.
- Gestion de l'association : elle reste sur la plateforme web.
- Annuaire des membres et messagerie entre membres.
- Vitrine de talents côté recruteur : elle reste sur le site.

## 5. Choix techniques

Voir `CLAUDE.md` (stack). Appareils visés : Android 8 et plus, iOS 15 et plus, fluide sur un téléphone d'entrée de gamme et une connexion mobile modeste. Deux saveurs : `dev` (API locale ou mocks) et `prod` (`https://api.aeenci.com/api/v1`). Français, textes prêts pour une traduction anglaise. Mode clair et sombre.

## 6. Publication sur les stores

Comptes développeur Google Play et Apple **au nom de l'association**. À préparer : nom « AEENCI » et sous-titre « Knowledge is Power », descriptions, icône à partir du symbole, captures, politique de confidentialité publiée sur aeenci.com, formulaires sur les données collectées, compte de démonstration pour les vérificateurs, suppression du compte depuis l'application (fiche de membre conservée, compte de connexion supprimé, vitrine retirée).

## 7. Décisions validées

| Question | Décision |
| --- | --- |
| QR code sur la carte | Oui : code signé par le backend, impossible à falsifier, valable 30 jours, renouvelé automatiquement |
| Scan des cartes aux assemblées | Oui : le secrétaire général scanne avec l'application, la présence s'enregistre ; fonctionne sans réseau, envoi au retour de la connexion |
| Candidats dans l'application | Oui, seulement pour suivre leur demande |
| Notifications activées par défaut | Toutes, réglables par catégorie |
| Actualités notifiées | Seulement celles marquées « à notifier » |
| iOS dès le départ | Oui si l'abonnement Apple est budgété ; sinon Android d'abord, iOS ensuite sans rien redévelopper |
| Nom sur les stores | « AEENCI », sous-titre « Knowledge is Power » |
