# AEENCI — application mobile

Application Flutter des membres de l'AEENCI (V2). Le contexte, les conventions et les règles du projet sont dans [CLAUDE.md](CLAUDE.md). Les lots de développement sont décrits dans [docs/plan-developpement-app.md](docs/plan-developpement-app.md).

## Prérequis

- Flutter 3.44 (stable), Dart 3.12
- Android Studio (Android 8 et plus) ; Xcode et CocoaPods pour iOS (iOS 15 et plus)

## Premier lancement

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # code généré : riverpod, freezed, json
flutter run --flavor dev -t lib/main_dev.dart
```

Les fichiers `*.g.dart`, `*.freezed.dart` et `lib/l10n/generated/` ne sont pas versionnés : ils sont produits par `build_runner` et `flutter gen-l10n`, ce dernier étant lancé automatiquement par `pub get`. Exception : `lib/core/design/tokens.g.dart`, qui est versionné.

## Saveurs

| Saveur | Identifiant | Nom affiché | Point d'entrée |
| --- | --- | --- | --- |
| `dev` | `com.aeenci.app.dev` | AEENCI Dev | `lib/main_dev.dart` |
| `prod` | `com.aeenci.app` | AEENCI | `lib/main_prod.dart` |

Les variables se passent par `--dart-define` :

| Variable | `dev` | `prod` |
| --- | --- | --- |
| `USE_MOCKS` | `true` par défaut | `false`, obligatoirement |
| `API_BASE_URL` | facultative avec les mocks | obligatoire, en HTTPS |

```bash
# dev, données factices (aucun backend nécessaire)
flutter run --flavor dev -t lib/main_dev.dart

# dev, API locale (émulateur Android ; sur un téléphone réel : IP du poste)
flutter run --flavor dev -t lib/main_dev.dart --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# prod
flutter run --flavor prod -t lib/main_prod.dart --dart-define=API_BASE_URL=https://api.aeenci.com/api/v1
```

## Données factices (`USE_MOCKS=true`)

Avec les mocks, l'application se développe et se démontre sans backend. Les données de `lib/core/mock/` sont conformes au contrat et manifestement fictives. Comptes de démonstration, tous avec le mot de passe `motdepasse` :

| Compte | E-mail | Ce qu'il voit |
| --- | --- | --- |
| Membre admis | `membre.test@exemple.com` | Les cinq onglets |
| Candidat | `candidat.test@exemple.com` | Le suivi de sa demande, en attente |
| Candidat refusé | `candidat.refuse@exemple.com` | Le suivi de sa demande, refusée avec le motif |
| Membre du bureau | `bureau.test@exemple.com` | Les onglets et le scan des présences |
| Compte sans fiche | `admin.test@exemple.com` | Refusé : « Ce compte n'a pas d'espace membre » |

En saveur `dev` avec les mocks, le lien « Comptes de démonstration » en bas de l'écran de connexion connecte à ces comptes en un geste. Il ouvre aussi les liens de test : activation (valide ou expirée) et nouveau mot de passe.

La page « Composants » (lien depuis l'accueil) règle la latence simulée et déclenche une erreur à la prochaine requête : réseau, 401, 422 ou 500. Elle simule aussi une mise à jour exigée ou une maintenance au prochain contrôle de `/app/config`.

## Thème

Les couleurs, tailles, espacements et rayons viennent de `docs/design/tokens.json`. Après toute modification de ce fichier :

```bash
dart run tool/generate_theme.dart
```

Cette commande régénère `lib/core/design/tokens.g.dart`. La CI et un test vérifient qu'il est à jour.

## Icône et écran de démarrage

Ils sont générés à partir de `assets/logos/aeenci-symbole.svg`. Pour les régénérer après une modification du symbole :

```bash
flutter test tool/brand/render_brand_assets_test.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

La première commande produit les PNG de `assets/branding/`. Les deux autres mettent à jour les ressources Android et iOS. Après `flutter_launcher_icons`, vérifier dans `ios/Runner.xcodeproj/project.pbxproj` que `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` vaut toujours `YES` : le paquet le remplace parfois par erreur.

## Vérifications

Les mêmes que celles de la CI (`.github/workflows/ci.yml`) :

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

## Secrets

Les fichiers suivants ne vont jamais dans Git : `google-services.json`, `GoogleService-Info.plist`, `key.properties`, les clés de signature. Des modèles `.example` indiquent où les placer :

- `android/key.properties.example`
- `android/app/src/{dev,prod}/google-services.json.example`
- `ios/config/{dev,prod}/GoogleService-Info.plist.example`

## Notifications push (Firebase)

Sans configuration Firebase, l'application se construit et fonctionne normalement : les notifications push sont simplement coupées (c'est toujours le cas avec `USE_MOCKS=true`, où la page des composants permet de simuler l'ouverture d'une notification).

Pour les activer, une fois par poste, avec un compte qui a accès au projet Firebase de l'association (`firebase login`) :

```bash
flutterfire configure --project=<id-du-projet> --platforms=android,ios --yes \
  --android-package-name=com.aeenci.app.dev --android-out=android/app/src/dev/google-services.json \
  --ios-bundle-id=com.aeenci.app.dev --ios-out=ios/config/dev/GoogleService-Info.plist \
  --out=lib/firebase_options_dev.dart
flutterfire configure --project=<id-du-projet> --platforms=android,ios --yes \
  --android-package-name=com.aeenci.app --android-out=android/app/src/prod/google-services.json \
  --ios-bundle-id=com.aeenci.app --ios-out=ios/config/prod/GoogleService-Info.plist \
  --out=lib/firebase_options_prod.dart
```

- Configurer **les deux saveurs** : dès qu'un `google-services.json` est présent, Gradle l'exige pour chaque saveur construite.
- Les fichiers produits restent hors de Git. L'application n'importe pas `firebase_options_*.dart` : Firebase lit les fichiers natifs de la saveur (une phase de build iOS copie `ios/config/<saveur>/GoogleService-Info.plist`). Si `flutterfire` modifie `ios/Runner.xcodeproj`, `android/` ou `firebase.json`, annuler ces changements.
- iOS sur un vrai téléphone : déposer la clé APNs (Apple Developer, « Keys ») dans la console Firebase, et activer la capacité Push Notifications de l'identifiant d'application. Le simulateur reçoit des notifications de test : `xcrun simctl push booted com.aeenci.app.dev push.apns` avec `{"aps":{"alert":{"title":"Test","body":"Texte"}},"route":"/cotisations"}`.
- La charge d'une notification porte l'écran à ouvrir dans `data.route` (table du contrat) ; une route inconnue ouvre le centre de notifications.

## Polices

Bricolage Grotesque et Plus Jakarta Sans sont embarquées dans `assets/fonts/` pour fonctionner hors connexion. Ce sont les instances statiques de Google Fonts, sous licence SIL Open Font License (voir `assets/fonts/OFL-*.txt`).
