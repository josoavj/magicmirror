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
2. `AuthGate` choisit l'ecran initial:
   - non connecte: ecrans auth
   - connecte non verifie: verification email
   - connecte verifie: home
3. La home route vers les features (`/mirror`, `/agenda`, `/profile`, `/settings`, etc.).

## Patterns de donnees

### Agenda

- Etat: `StateNotifier` Riverpod
- Source: Supabase (`agenda_events`) via `agenda_supabase_service.dart`
- Operations: create/read/update/delete + statut termine

### Profil utilisateur

- Etat local: Riverpod + SharedPreferences
- Sync cloud: Supabase (`profiles`) + storage avatars
- Ecran compte dedie: gestion photo, securite, sync

### Meteo

- Service OpenWeatherMap
- Provider Riverpod pour la consommation UI

## Conventions

- Les surfaces visuelles utilisent `glass_container.dart`.
- Les providers sont localises au plus proche de leur feature.
- Les services externes (Supabase/API) sont encapsules dans la couche `data/services`.

## Liens utiles

- [README.md](README.md) - Vue globale du projet
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) - Demarrage rapide
- [docs/SETUP.md](docs/SETUP.md) - Configuration production
