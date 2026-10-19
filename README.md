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

## Thème

Les couleurs, tailles, espacements et rayons viennent de `docs/design/tokens.json`. Après toute modification de ce fichier :

```bash
dart run tool/generate_theme.dart
```

Cette commande régénère `lib/core/design/tokens.g.dart`. La CI et un test vérifient qu'il est à jour.

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

## Polices

Bricolage Grotesque et Plus Jakarta Sans sont embarquées dans `assets/fonts/` pour fonctionner hors connexion. Ce sont les instances statiques de Google Fonts, sous licence SIL Open Font License (voir `assets/fonts/OFL-*.txt`).
