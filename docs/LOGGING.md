# Système de logging centralisé

Toutes les sorties de logs de l'application passent par un système de logging centralisé, asynchrone et non-bloquant.

---

## 1. Fonctionnalités

### Stockage par plateforme

Les logs sont stockés dans les chemins natifs appropriés :

| Plateforme | Chemin                                                    |
|------------|-----------------------------------------------------------|
| Android    | `/data/data/com.example.magicmirror/cache/logs/`          |
| iOS        | `Documents/logs/`                                         |
| Linux      | `~/.cache/magicmirror/logs/`                              |
| Windows    | `AppData/Support/logs/`                                   |
| macOS      | `Application Support/logs/`                               |
| Web        | LocalStorage (fallback)                                   |

### Persistance

Chaque entrée de log contient :

- Timestamp ISO8601 précis
- Niveau de log (`INFO`, `WARNING`, `ERROR`, `DEBUG`)
- Tag identifiant la source
- Stack trace complet en cas d'erreur
- Rotation automatique à 5 MB
- Conservation des 7 derniers fichiers

### Niveaux de log (mode développement)

| Niveau    | Symbole |
|-----------|---------|
| `INFO`    | ℹ️      |
| `WARNING` | ⚠️      |
| `ERROR`   | ❌      |
| `DEBUG`   | 🔍      |

---

## 2. Utilisation

### Import

```dart
import 'package:magicmirror/core/utils/app_logger.dart';
```

### Initialisation — `main.dart`

```dart
void main() async {
  await logger.initialize();
  // ... reste du code
}
```

### Appels dans le code

```dart
// Info
logger.info('Opération réussie', tag: 'MyService');

// Warning
logger.warning('Attention: valeur invalide', tag: 'MyService');

// Error avec stack trace
try {
  // code
} catch (e, st) {
  logger.error('Erreur lors de l\'opération',
    tag: 'MyService',
    error: e,
    stackTrace: st,
  );
}

// Debug
logger.debug('Variable x = $x', tag: 'MyService');
```

---

## 3. Gestion des logs

```dart
// Accéder aux fichiers de logs
final logsPath = logger.getLogsDirectoryPath();
final logFiles = logger.getLogFiles();

// Exporter tous les logs
final exportPath = await logger.exportLogs();

// Effacer tous les logs
await logger.clearLogs();
```

---

## 4. Format des fichiers

Les fichiers de logs sont nommés : `magicmirror_YYYY-MM-DD.log`

```log
[2026-03-05 10:23:45.123] [INFO]    [AgendaSupabaseService] Synchronisation réussie
[2026-03-05 10:23:46.456] [WARNING] [WeatherService]         Erreur de géolocalisation, fallback sur Antananarivo
[2026-03-05 10:23:47.789] [ERROR]   [MorphologyService]      Erreur lors de l'analyse ML
Error: Exception: ML Kit error
StackTrace:
#0 MorphologyService.analyzePose (package:magicmirror/features/ai_ml/data/services/morphology_service.dart:32:5)
...
```

---

## 5. Fichiers modifiés

| Statut   | Fichier                                                                               | Description                              |
|----------|---------------------------------------------------------------------------------------|------------------------------------------|
| ✅ Créé  | `lib/core/utils/app_logger.dart`                                                      | Système de logging centralisé            |
| 📝 Modifié | `pubspec.yaml`                                                                      | Ajout de `path_provider`                 |
| 📝 Modifié | `lib/main.dart`                                                                     | Initialisation du logger                 |
| 📝 Modifié | `lib/config/app_config.dart`                                                        | Utilise logger pour `printStartupInfo`   |
| 📝 Modifié | `lib/features/agenda/data/services/agenda_supabase_service.dart`                    | Utilise logger                           |
| 📝 Modifié | `lib/features/mirror/presentation/providers/camera_provider.dart`                   | Utilise logger                           |
| 📝 Modifié | `lib/features/weather/presentation/widgets/weather_widget.dart`                     | Utilise logger                           |
| 📝 Modifié | `lib/features/ai_ml/data/services/morphology_service.dart`                          | Utilise logger                           |
| 📝 Modifié | `lib/features/settings/presentation/providers/settings_provider.dart`               | Utilise logger                           |
| 📝 Modifié | `lib/core/utils/logger.dart`                                                        | Export vers `app_logger.dart` (rétrocompatibilité) |

---

## 6. Architecture

```
AppLogger (Singleton)
├── Initialisation
│   ├── Détection plateforme
│   └── Création répertoire de logs
├── Logging
│   ├── Console (debug mode)
│   └── Fichier (toutes les plateformes)
├── Rotation
│   └── Automatique à 5 MB
├── Nettoyage
│   └── Conserve les 7 derniers fichiers
└── Utilitaires
    ├── Export
    ├── Clear
    └── Path access
```

---

## 7. Avantages

| Propriété      | Description                                          |
|----------------|------------------------------------------------------|
| Centralisé     | Un seul point d'entrée pour tous les logs            |
| Cross-platform | Support pour toutes les plateformes Flutter          |
| Persistant     | Les logs survivent aux redémarrages                  |
| Organisé       | Tags par service pour faciliter le debug             |
| Rotatif        | Gestion automatique de l'espace disque               |
| Traçable       | Stack traces complets pour les erreurs               |
| Performant     | Asynchrone et non-bloquant                           |

---

## 8. Exemple de logs générés

```shell
$ ls ~/.cache/magicmirror/logs/
magicmirror_2026-03-05.log
magicmirror_archived_2026-03-04_23-59-59.log
magicmirror_archived_2026-03-04_12-30-45.log

$ tail -f ~/.cache/magicmirror/logs/magicmirror_2026-03-05.log
[2026-03-05 08:15:23.456] [INFO] [MagicMirror] ========== START ==========
[2026-03-05 08:15:23.457] [INFO] [Config]      Mode: Développement
[2026-03-05 08:15:23.458] [INFO] [Calendrier]  Agenda Supabase
[2026-03-05 08:15:23.459] [INFO] [Features]    AI: ON
[2026-03-05 08:15:23.460] [INFO] [Features]    Météo: ON
[2026-03-05 08:15:23.461] [INFO] [Features]    Tenues: ON
[2026-03-05 08:15:23.462] [INFO] [MagicMirror] ========== OK ==========
```

---

## 9. Migration `print()` → `logger`

**Avant :**

```dart
print('Message');
debugPrint('Message');
```

**Après :**

```dart
logger.info('Message', tag: 'MonService');
```

Tous les `print()` et `debugPrint()` ont été remplacés par des appels appropriés à `logger`.