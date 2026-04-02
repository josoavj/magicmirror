# 🏗️ Architecture - Magic Mirror

## Vue d'ensemble

Magic Mirror est une application Flutter modulaire basee sur Riverpod, avec une organisation par features.

- `config/`: configuration applicative (feature flags, bootstrap)
- `core/`: services transverses, utilitaires, constantes, theme
- `features/`: logique metier et UI par domaine fonctionnel
- `presentation/`: ecrans/widgets partages hors feature
- `routes/`: definitions de routes

## Structure actuelle (lib)

```text
lib/
├── main.dart
├── config/
│   ├── app_config.dart
│   └── di_setup.dart
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   └── presentation/screens/
│   ├── user_profile/
│   │   ├── data/
│   │   └── presentation/
│   ├── agenda/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── mirror/
│   │   ├── data/
│   │   └── presentation/
│   ├── weather/
│   │   ├── data/
│   │   └── presentation/
│   ├── ai_ml/
│   │   ├── data/
│   │   └── presentation/
│   ├── outfit_suggestion/
│   │   ├── data/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       └── presentation/
├── presentation/
│   ├── screens/
│   └── widgets/
├── routes/
│   ├── app_routes.dart
│   └── route_names.dart
└── generated/
    └── assets.gen.dart
```

## Flux applicatif principal

1. `main.dart` initialise dotenv, Supabase, logger puis lance `AuthGate`.
2. `AuthGate` choisit l'écran initial:
    - non connecté: écrans auth
    - connecté non vérifié: vérification email
    - connecté vérifié: home
3. La home route vers les features (`/mirror`, `/agenda`, `/profile`, `/settings`, etc.).

## Patterns de données

### Agenda

- État: `StateNotifier` Riverpod
- Source: Supabase (`agenda_events`) via `agenda_supabase_service.dart`
- Opérations: create/read/update/delete + statut terminé

### Profil utilisateur

- État local: Riverpod + SharedPreferences
- Sync cloud: Supabase (`profiles`) + storage avatars
- Écran compte dédié: gestion photo, sécurité, sync

### Météo

- Service OpenWeatherMap
- Provider Riverpod pour la consommation UI

## Conventions

- Les surfaces visuelles utilisent `glass_container.dart`.
- Les providers sont localisés au plus proche de leur feature.
- Les services externes (Supabase/API) sont encapsulés dans la couche `data/services`.

## Liens utiles

- [README.md](README.md) - Vue globale du projet
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) - Démarrage rapide
- [docs/SETUP.md](docs/SETUP.md) - Configuration production
