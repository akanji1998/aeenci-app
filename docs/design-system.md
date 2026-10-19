# AEENCI

Le design system de la plateforme numérique de l'AEENCI (Association des Élèves et Étudiants Nigérians en Côte d'Ivoire) : le site aeenci.com, l'espace membre, la plateforme de gestion et, en V2, l'application mobile. Il traduit l'identité historique de l'association, fondée en 1972, dans un registre **jeune et dynamique**, tourné vers les élèves et les étudiants.

Cette première version part du logo actuel (rubans verts, nom en rouge, devise « Knowledge is Power » en bleu). Elle est volontairement courte : couleurs, typographie, espacements et rayons. Les composants viendront avec les maquettes du site.

## Principes

1. **Énergie, pas agitation.** Des aplats francs, de grands titres, des formes arrondies ; une seule idée forte par écran.
2. **Le vert mène.** Le vert est la couleur de l'association. Le bleu structure, le rouge ponctue. Jamais les trois à parts égales.
3. **La forme ruban.** Les rubans du logo deviennent la signature visuelle : boutons, badges et filtres en pilule (`radius-pill`), blocs aux coins généreux (`radius-lg`).
4. **Les membres au premier plan.** Photos réelles des membres, des lauréats et des événements plutôt qu'illustrations génériques.
5. **Léger et lisible sur mobile.** La majorité des visiteurs viennent d'un smartphone, souvent en connexion mobile : peu d'effets, images compressées, texte d'au moins 16px.

## Ton et rédaction

- **Direct et chaleureux.** Phrases courtes, verbes d'action : « Adhère », « Découvre la JOE 2026 », « Mets ton profil en avant ».
- **Tutoiement** sur les pages tournées vers les élèves et étudiants (accueil, adhésion, événements) ; **vouvoiement** dans les échanges officiels (recruteurs, partenaires, reçus).
- **Fierté sans emphase.** On montre les réussites (lauréats, aînés, parcours) par des faits et des chiffres plutôt que par des superlatifs.
- **La devise** « Knowledge is Power » reste en anglais, telle qu'elle figure sur le logo ; elle peut porter l'accroche de l'accueil.
- **Bilingue à terme.** Les textes sont en français en V1 ; prévoir la place pour l'anglais (libellés courts, pas de texte dans les images).

## Couleurs

| Token | Rôle |
| --- | --- |
| `green` | Couleur principale : boutons d'action, en-tête, liens forts de marque. |
| `green-soft` | Fond teinté des sections et badges verts. |
| `blue` | Titres d'accroche, liens (`link`), navigation, focus (`focus`). |
| `blue-soft` | Encarts et étiquettes de catégorie. |
| `red` | Accent rare : chiffres clés, badge « Nouveau », erreurs (`danger`). |
| `red-soft` | Fond des badges et alertes rouges. |
| `ink`, `ink-muted` | Texte principal et secondaire. |
| `surface`, `surface-raised`, `line` | Fonds, cartes, filets. |

Règles :

- **Proportions indicatives d'un écran** : neutres environ 70 %, vert 20 %, bleu 8 %, rouge 2 %.
- Un bouton principal est **toujours** `green` avec un libellé `on-green`. Un seul bouton principal par zone.
- Le rouge ne sert jamais de fond de section ni de bouton principal : il signalerait une erreur.
- Texte sur fond teinté : `green` sur `green-soft`, `blue` sur `blue-soft`, `red` sur `red-soft`, ou `ink` sur n'importe lequel.
- Tous les couples texte/fond listés ici respectent un contraste d'au moins 4,5:1 dans les deux thèmes.

## Typographie

- **Bricolage Grotesque** (`display`) pour les titres : un caractère expressif et contemporain, qui donne l'énergie « jeune » sans perdre en sérieux. Graisses 600 à 800.
- **Plus Jakarta Sans** (`sans`) pour le texte : très lisible sur mobile, chaleureux, avec des chiffres nets pour les statistiques et les montants.
- Les deux sont des polices Google Fonts, gratuites, à charger en `display=swap`.
- Styles : `display-xl` (titre du héros), `display` (titres de grandes sections), `h1` à `h3`, `body-lg` (chapeaux), `body` (texte courant), `small` (métadonnées), `label` (boutons, badges, étiquettes).
- Un titre `display-xl` par page au plus ; le texte courant ne descend jamais sous `body` (16px).

## Espacements et rayons

- Grille de 4px : `space-1` à `space-20`. Marges de page `space-4` sur mobile, `space-6` et plus sur grand écran ; sections séparées par `space-12` (mobile) à `space-20` (grand écran).
- `radius-pill` pour tout ce qui est cliquable et court (boutons, badges, filtres) : c'est la forme ruban.
- `radius-md` pour les cartes et les images, `radius-lg` pour les grands blocs (héros, visuels d'événements), `radius-sm` pour les champs de formulaire.
- Peu d'ombres : on sépare par des aplats de couleur et des filets `line` plutôt que par des ombres portées.

## Logo

Le logo a fait l'objet d'une **modernisation légère**, validée par le bureau. La composition historique est conservée : deux rubans verts, le nom AEENCI en rouge, la devise « Knowledge is Power » en bleu, et au centre une personne qui étudie, simplifiée en quelques formes pleines (une tête, des épaules, un livre ouvert). Les traits sont nets et réguliers, les textes composés en Bricolage Grotesque et Plus Jakarta Sans puis vectorisés, et les couleurs alignées sur `green`, `red` et `blue`.

Trois déclinaisons, dans le groupe **Logos** :

- **Logo complet** (`aeenci-logo.svg`), sur fond clair.
- **Version blanche** (`aeenci-logo-blanc.svg`), sur fond `green` ou sombre.
- **Symbole seul** (`aeenci-symbole.svg`), carré et sans texte : icône du site, de l'application, des réseaux sociaux, et tout usage sous 120px de large.

Dans l'en-tête du site, le symbole est suivi du nom **AEENCI** composé en `display` 800, couleur `green` : la devise serait illisible à cette taille. L'ancien logo (`logo-actuel.jpg`) est conservé pour mémoire seulement.

## Iconographie et images

- Icônes **au trait**, 1,75px, coins arrondis, une seule couleur (`ink`, `ink-muted` ou la couleur du contexte). Une bibliothèque libre comme Lucide convient.
- Photos : membres, lauréats, événements, en situation réelle, recadrées dans `radius-md` ou `radius-lg`. Pas de photos de banque d'images génériques.
- Aucun texte incrusté dans les images (traduction et accessibilité).
