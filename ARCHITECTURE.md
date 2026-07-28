# 🏗️ Architecture - Magic Mirror

## Vision Modulaire

Magic Mirror adopte une architecture **Feature-First** et **Layered** (inspirée de la Clean Architecture). L'objectif est d'isoler chaque domaine fonctionnel pour maximiser la testabilité et la réutilisabilité.

## Structure des Dossiers (`lib/`)

### 1. `core/` & `config/`
- **Configuration** : `app_config.dart` centralise les *Feature Flags* et les constantes d'environnement.
- **Thème** : `app_theme.dart` définit un design system unifié (Glassmorphism).
- **Services** : Services transverses comme le `Logger`, `Cache` ou `TTS`.

### 2. `features/` (Le cœur de l'app)
Chaque feature (ex: `outfit_suggestion`) est organisée comme suit :

- **`domain/`** : 
    - `entities/` : Classes de données pures (ex: `Outfit`).
    - `services/` : Logique métier isolée (ex: `OutfitRankingService`).
- **`data/`** :
    - `models/` : Mapping JSON/Supabase (DTOs).
    - `services/` : Implémentations techniques (ex: `WeatherService`).
- **`presentation/`** :
    - `providers/` : Gestion d'état Riverpod (`Notifier`).
    - `widgets/` : Composants UI spécifiques à la feature, extraits pour être légers.
    - `screens/` : Écrans d'assemblage (Points d'entrée des routes).

### 3. `presentation/` (Global)
Regroupe les composants partagés par toute l'application (ex: `glass_container.dart`, `home_screen.dart`).

## Gestion d'État (Riverpod)

Nous utilisons **Riverpod** pour une gestion d'état réactive et testable :
- **Isolation** : Aucun provider n'est défini dans un fichier de widget.
- **Récupération de données** : Utilisation intensive de `FutureProvider` et `AsyncNotifier`.
- **Réglages** : Le `appSettingsProvider` centralise les préférences utilisateurs et les diffuse en temps réel.

## Principes de Développement

1. **Un fichier, une responsabilité** : Si un widget ou une classe dépasse ~200 lignes, il doit être décomposé.
2. **Zéro logique métier dans l'UI** : Les calculs de scores ou les transformations de données doivent résider dans le `domain/services`.
3. **Test-Driven Mindset** : Chaque nouveau service ou modèle doit être accompagné de son fichier de test dans le dossier `test/`.

## Flux de Données Types

1. L'UI observe un **Provider**.
2. Le **Provider** appelle un **Service de Domaine** pour la logique.
3. Le **Service de Domaine** utilise un **Service de Données** (API/Supabase).
4. Les données remontent sous forme d'**Entities** immuables.
