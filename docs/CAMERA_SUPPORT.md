# 📹 Support Caméra par Plateforme

## Support des fonctionnalités caméra par plateforme

| Plateforme | Status | Notes |
|---|---|---|
| 📱 Android | ✅ Full | Support complet |
| 🍎 iOS | ✅ Full | Support complet |
| 🖥️ macOS | ✅ Full | Support complet |
| 💻 Windows | ⚠️ Partiel | Caméra intégrée seulement |
| 🐧 Linux | ⚠️ Partiel | Caméra intégrée seulement |
| 🌐 Web | ❌ Non | Pas de support caméra |

---

## 📱 Android

### Permissions requises
Ajouter dans `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Build.gradle
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Runtime Permissions
L'app demande automatiquement les permissions au lancement.

---

## 🍎 iOS

### Info.plist
Ajouter dans `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Magic Mirror utilise la caméra pour l'affichage du miroir</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Magic Mirror utilise votre localisation pour la météo</string>
```

### Podfile
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

---

## 🖥️ Windows & 🐧 Linux

### Support limité
- ✅ Caméra intégrée (webcam)
- ⚠️ Caméra USB externe peut être instable
- ❌ Caméra frontale/arrière (mobile only)

### Solution: Utiliser sur mobile
Pour meilleure expérience, utiliser sur:
- Android
- iOS
- macOS

---

## 🧪 Test de la caméra

### Vérifier permissions
```bash
# Android
adb shell pm list permissions | grep android.permission.CAMERA

# iOS
# Settings > Privacy > Camera > Magic Mirror
```

### Debug caméra
```bash
flutter run -v  # Affiche logs caméra
```

Chercher: `camera` dans les logs

---

## 🔧 Configuration avancée

### Résolution caméra
Modifier dans [`lib/features/mirror/presentation/providers/camera_provider.dart`](../lib/features/mirror/presentation/providers/camera_provider.dart):
```dart
cameraController = CameraController(
  camera,
  ResolutionPreset.high,  // Options: low, medium, high, veryHigh
);
```

### Timeout et reprise caméra
Le comportement de reprise/réinitialisation caméra est géré dans:
- [`lib/features/mirror/presentation/providers/camera_provider.dart`](../lib/features/mirror/presentation/providers/camera_provider.dart)
- [`lib/core/services/permission_service.dart`](../lib/core/services/permission_service.dart)

---

## 🐛 Troubleshooting

### "Camera not available on this device"
- Vérifier que l'appareil a une caméra
- Vérifier permissions OS

### "Camera already in use"
```bash
flutter clean
flutter run
```

### Caméra lente / lag important
- Réduire résolution: `ResolutionPreset.medium`
- Augmenter `cameraTimeout`
- Moins d'effets/filtres simultanés

### Caméra freeze sur exit
App gère automatiquement. Si persist:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Performances

### RAM usage (estimation)
- **Résolution low**: 50-100MB
- **Résolution medium**: 100-200MB
- **Résolution high**: 200-500MB

### CPU usage
- Idle: 5-10%
- Streaming: 15-25%
- ML processing: 40-60%

---

Pour plus d'infos, voir:
- [SETUP.md](SETUP.md) - Configuration production
- [GETTING_STARTED.md](GETTING_STARTED.md) - Guide démarrage
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture détaillée
