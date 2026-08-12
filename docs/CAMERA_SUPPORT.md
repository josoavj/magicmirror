# Support caméra par plateforme

Ce document décrit la compatibilité caméra de Magic Mirror selon les plateformes, les configurations requises, les options avancées et les procédures de dépannage.

---

## Compatibilité par plateforme

| Plateforme | Support | Détails |
|------------|---------|---------|
| Android | Complet | Caméra frontale, arrière, USB |
| iOS | Complet | Caméra frontale, arrière |
| macOS | Complet | Webcam intégrée et externe |
| Windows | Partiel | Webcam intégrée uniquement |
| Linux | Partiel | Webcam intégrée uniquement |
| Web | Non supporté | Aucune API caméra disponible |

> **Recommandation :** Pour une expérience optimale, privilégier Android, iOS ou macOS. Sur Windows et Linux, les caméras USB externes peuvent être instables.

---

## Configuration par plateforme

### Android

#### Permissions - `android/app/src/main/AndroidManifest.xml`

Les permissions suivantes sont obligatoires pour accéder à la caméra et à la géolocalisation :

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

- `CAMERA` : nécessaire pour activer le flux vidéo de la caméra.
- `ACCESS_FINE_LOCATION` : utilisé pour la météo géolocalisée. Si cette permission est refusée, l'app bascule sur Paris par défaut.

Ces permissions sont demandées automatiquement à l'utilisateur au premier lancement.

#### Configuration Gradle - `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21      // Android 5.0 minimum requis
        targetSdkVersion 34
    }
}
```

- `minSdkVersion 21` : correspond à Android 5.0 (Lollipop). Les appareils plus anciens ne sont pas supportés.
- `compileSdkVersion 34` et `targetSdkVersion 34` : requis pour être conforme aux dernières politiques du Play Store.

---

### iOS

#### Descriptions de permissions - `ios/Runner/Info.plist`

iOS exige que chaque permission soit accompagnée d'un message explicatif affiché à l'utilisateur lors de la demande d'accès :

```xml
<key>NSCameraUsageDescription</key>
<string>Magic Mirror utilise la caméra pour l'affichage du miroir</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Magic Mirror utilise votre localisation pour la météo</string>
```

> **Important :** Sans ces entrées dans `Info.plist`, l'app sera rejetée lors de la soumission sur l'App Store, et plantera au moment de la demande de permission.

#### Configuration CocoaPods - `ios/Podfile`

Ce bloc est requis pour que les dépendances Flutter (notamment les plugins caméra) soient correctement compilées avec les paramètres de build iOS :

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

Sans ce bloc, certains plugins peuvent échouer à la compilation sur des cibles iOS récentes.

---

### Windows et Linux

Le support caméra est partiel sur ces plateformes :

| Fonctionnalité | Windows | Linux |
|----------------|---------|-------|
| Webcam intégrée | Oui | Oui |
| Caméra USB externe | Limité | Limité |
| Caméra frontale/arrière | Non | Non |
| Traitement ML en temps réel | Dégradé | Dégradé |

Les caméras frontale et arrière sont des concepts propres aux appareils mobiles et n'existent pas sur desktop. Le traitement ML (analyse de morphologie, pose detection) peut être plus lent en raison des différences d'accès matériel bas niveau.

---

## Configuration avancée

### Résolution de la caméra

La résolution est configurable dans `lib/features/mirror/presentation/providers/camera_provider.dart` :

```dart
cameraController = CameraController(
  camera,
  ResolutionPreset.high, // Modifier ici selon les besoins
);
```

Tableau des résolutions disponibles et leur impact :

| Preset | Résolution approximative | RAM estimée | CPU (streaming) | Usage recommandé |
|--------|--------------------------|-------------|-----------------|------------------|
| `low` | 240p | 50–100 MB | 5–10% | Appareils faibles, debug |
| `medium` | 480p | 100–200 MB | 10–20% | Usage courant, bonne autonomie |
| `high` | 720p | 200–400 MB | 15–25% | Qualité miroir standard |
| `veryHigh` | 1080p+ | 400–800 MB | 30–50% | Appareils haut de gamme uniquement |

> **Note :** Le traitement ML (analyse de pose, morphologie) ajoute 40 à 60% de charge CPU en plus du streaming de base. Sur les appareils à faible RAM, préférer `medium` ou `low`.

---

## Troubleshooting

### "Camera not available on this device"

**Cause :** Aucune caméra détectée, ou permission refusée au niveau système.

**Solution :**
1. Vérifier que l'appareil dispose bien d'une caméra physique
2. Vérifier que la permission caméra est accordée
3. Sur Android, s'assurer que `android.permission.CAMERA` est présent dans `AndroidManifest.xml`
4. Sur iOS, vérifier que `NSCameraUsageDescription` est renseigné dans `Info.plist`

### "Camera already in use"

**Cause :** Le flux caméra est resté actif après une fermeture anormale de l'app, ou une autre application occupe la caméra.

**Solution :**
```bash
flutter clean
flutter run
```

Si le problème persiste, fermer toutes les apps utilisant la caméra avant de relancer.

---

## Références

| Document | Description |
|----------|-------------|
| `SETUP.md` | Configuration complète pour la production |
| `GETTING_STARTED.md` | Guide de démarrage rapide |
| `ARCHITECTURE.md` | Architecture détaillée de l'app |
