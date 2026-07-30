<p align="center">
  <img src="https://github.com/josoavj/magicmirror/assets/76913187/5dda5a6a-5e5d-41e6-a818-17b853a7957f" alt="Magic Mirror Logo" width="150"/>
</p>

<h1 align="center">Magic Mirror</h1>

<p align="center">
  <strong>Miroir intelligent modulaire avec caméra, météo et recommandations IA</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.1.0-blue?style=flat-square" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.10.4-blue?style=flat-square" alt="Dart Version">
  <img src="https://img.shields.io/badge/Version-1.1.0-orange?style=flat-square" alt="Version actuelle">
  <img src="https://img.shields.io/badge/Status-Stable-green?style=flat-square" alt="Statut Stable">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="Licence">
  <img src="https://img.shields.io/github/last-commit/josoavj/magicmirror?style=flat-square" alt="Dernier commit">
</p>

---

## 📊 Vue d'ensemble des fonctionnalités

| Fonctionnalité | Statut | Détails |
|---|---|---|
| 🪞 **Miroir caméra** | ✅ 100% | Caméra temps réel, détection morphologie, contrôles de zoom/exposition |
| 📅 **Agenda / Calendrier** | ✅ 100% | Agenda cloud Supabase avec gestion complète (CRUD) |
| 🌦️ **Météo** | ✅ 100% | API OpenWeatherMap + géolocalisation pour recommandations contextuelles |
| 🤖 **Morphologie IA** | ✅ 100% | Google ML Kit — détection de pose et classification automatique |
| 👔 **Suggestions de tenues** | ✅ 100% | Algorithme de ranking hybride (Heuristique + ML + LLM) |
| 👤 **Profil utilisateur** | ✅ 100% | Synchronisation cloud complète (avatar, préférences, morphologie) |
| 🧪 **Suite de Tests** | ✅ 100% | Tests unitaires, de state management (Riverpod) et de widgets |
| 🗣️ **Synthèse vocale** | ✅ 100% | Feedback audio intelligent pour les recommandations |

---

## 🏗️ Architecture & Modularité

L'application suit une architecture **Feature-first** strictement modulaire. Chaque fonctionnalité est isolée dans son propre module (`lib/features/`) et découpée en couches :

- **Domain** : Entités pures et logique métier (Services).
- **Data** : Modèles, dépôts et sources de données (Supabase, API).
- **Presentation** : Écrans légers, widgets réutilisables et Providers (Riverpod).

Cette structure garantit une haute maintenabilité et facilite l'ajout de nouvelles fonctionnalités sans effet de bord.

---

## 🚀 Démarrage rapide

### Installation

```bash
git clone https://github.com/josoavj/magicmirror.git
cd magicmirror
flutter pub get
```

### Configuration

Copiez le fichier `.env.example` vers `assets/.env` et renseignez vos clés :
- `SUPABASE_URL` & `SUPABASE_ANON_KEY`
- `OPENWEATHERMAP_API_KEY`

### Exécution

```bash
flutter run
```

---

## 🧪 Tests & Qualité

Le projet inclut une suite de tests robuste pour garantir la stabilité :

```bash
flutter analyze          # Analyse statique (zéro erreur)
flutter test             # Exécution des 20+ tests unitaires et widgets
```

**Couverture des tests :**
- **Unitaires** : Logique de ranking, parsing JSON, utilitaires.
- **Presentation** : État des providers (Notifiers), logique du HUD.
- **Widgets** : Flux d'authentification, navigation, affichage des cartes.

---

## 📁 Structure du projet

### 🌍 Racine
- `assets/` : Ressources statiques (images, polices, configuration `.env`).
- `docs/` : Documentation technique détaillée et guides de configuration.
- `ml/` : Scripts Python pour le pipeline de Machine Learning (LightGBM).
- `test/` : Suite de tests complète (Unit, Presentation, Data, Widgets).

### 🏗️ Application (`lib/`)
- **`config/`** : Centralisation des *Feature Flags* et configuration d'environnement.
- **`core/`** : Socle technique transverse.
    - `services/` : Moteurs de base (Storage, Cache, TTS, Permissions).
    - `theme/` : Design system unifié (Glassmorphism, Couleurs).
    - `utils/` : Utilitaires globaux (Logger, PlatformHelper, Responsive).
    - `error/` : Gestion unifiée des exceptions et résultats.
- **`features/`** : Modules organisés par domaine fonctionnel (Feature-First). Chaque module est découpé en :
    - `domain/` : Entités pures et services de logique métier.
    - `data/` : Modèles (DTO), repositories et services techniques (API/DB).
    - `presentation/` : Widgets isolés, Providers (Riverpod) et Écrans d'assemblage.
- **`presentation/`** : Composants et écrans globaux (Home, About).
- **`routes/`** : Définition centralisée de la navigation.
- **`main.dart`** : Point d'entrée, initialisation des services et injection de l'AuthGate.

---

## 🌍 Support des plateformes

| Plateforme | Statut | Caméra | Météo | Agenda |
|---|---|---|---|---|
| 📱 **Android / iOS** | ✅ | ✅ | ✅ | ✅ |
| 🖥️ **macOS** | ✅ | ✅ | ✅ | ✅ |
| 💻 **Linux / Windows**| ⚠️ | ⚠️ | ✅ | ✅ |

---

<p align="center">Made by <a href="https://github.com/josoavj">@josoavj</a></p>
