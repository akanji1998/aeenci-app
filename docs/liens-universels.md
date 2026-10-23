# Liens universels (Android App Links, iOS Universal Links)

Un lien `https://aeenci.com/…` reçu par e-mail ou message ouvre l'application si elle est installée, et le site sinon. Seule la saveur **prod** (`com.aeenci.app`) déclare ces liens : un téléphone qui a aussi l'application `dev` ne demande pas laquelle ouvrir.

## Adresses prises en charge

| Adresse du site | Écran de l'application |
| --- | --- |
| `/activer-mon-compte?token=…` | Activation du compte (invitation) |
| `/reinitialiser-mot-de-passe?token=…&email=…` | Nouveau mot de passe |
| `/espace/opportunites` | Opportunités |
| `/espace/opportunites/{id}` | Détail d'une opportunité |
| `/evenements` et `/evenements/{slug}` | Événements, détail d'un événement |

- Lien ouvert sans être connecté : connexion, puis l'écran demandé (sauf activation et réinitialisation, qui sont publiques).
- Membre déjà connecté qui ouvre un lien d'activation : il reste connecté et arrive à l'accueil.
- Adresse de ces familles que l'application ne connaît pas : l'accueil, sans erreur.

La liste est la même à quatre endroits ; un test vérifie les deux premiers :

1. `lib/app/router/universal_links.dart` (`universalLinkPaths`) ;
2. `android/app/src/prod/AndroidManifest.xml` (`intent-filter` avec `autoVerify`) ;
3. `ios/Runner/RunnerProd.entitlements` (`applinks:aeenci.com`, sans chemins : ils sont dans le fichier Apple ci-dessous) ;
4. les deux fichiers `.well-known` du site, ci-dessous.

## Fichiers à servir par le site (`aeenci-site`)

Ils vont dans le dépôt du site, servis à la racine de `https://aeenci.com`, en HTTPS, **sans redirection**, avec `Content-Type: application/json`. Dans Next.js : `public/.well-known/`.

### `https://aeenci.com/.well-known/assetlinks.json` (Android)

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.aeenci.app",
      "sha256_cert_fingerprints": ["EMPREINTE_SHA256_DE_LA_CLE_DE_SIGNATURE"]
    }
  }
]
```

`EMPREINTE_SHA256_DE_LA_CLE_DE_SIGNATURE` : avec la signature d'application Google Play, l'empreinte **de la clé de signature d'application** (Play Console › Intégrité de l'application › Signature d'application), pas celle de la clé d'importation. Sinon : `keytool -list -v -keystore <fichier>.jks -alias <alias>`. On peut lister les deux empreintes si besoin.

### `https://aeenci.com/.well-known/apple-app-site-association` (iOS)

Sans extension, servi en `application/json`.

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAM_ID.com.aeenci.app"],
        "components": [
          { "/": "/activer-mon-compte*" },
          { "/": "/reinitialiser-mot-de-passe*" },
          { "/": "/espace/opportunites*" },
          { "/": "/evenements*" }
        ]
      }
    ]
  }
}
```

`TEAM_ID` : l'identifiant d'équipe du compte Apple Developer de l'association (Membership details). L'identifiant `com.aeenci.app` doit avoir la capacité **Associated Domains** activée dans le portail Apple Developer, en plus de Push Notifications.

## Vérifier

- Android (téléphone ou émulateur, application prod installée) :

  ```bash
  adb shell am start -W -a android.intent.action.VIEW -d "https://aeenci.com/activer-mon-compte?token=essai" com.aeenci.app
  adb shell pm get-app-links com.aeenci.app
  ```

  `get-app-links` doit afficher `aeenci.com: verified` une fois `assetlinks.json` en ligne (la vérification se relance avec `adb shell pm verify-app-links --re-verify com.aeenci.app`).

- iOS (simulateur, application prod installée) :

  ```bash
  xcrun simctl openurl booted "https://aeenci.com/espace/opportunites/12"
  ```

  Sur un vrai iPhone, Apple lit `apple-app-site-association` par son propre réseau (CDN) : comptez jusqu'à 24 h après une modification. Un lien tapé dans Safari n'ouvre pas l'application ; un lien touché dans Mail ou Messages, si.

- Sans le site en ligne, la saveur dev s'essaie avec le même chemin passé au routeur (tests de `test/app/router/universal_links_test.dart`).
