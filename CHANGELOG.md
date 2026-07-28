# Changelog

Toutes les évolutions notables de Magic Mirror sont documentées dans ce fichier.

## [1.1.0] - 2026-07-28

### Architecture & Modularité
- **Refactoring Global** : Transformation de l'application en structure strictement modulaire (Feature-First).
- **Extraction des Widgets** : Décomposition de tous les écrans monolithiques en composants réutilisables.
- **Isolation du Domaine** : Création de services de domaine (ex: `OutfitRankingService`) pour séparer la logique métier de l'interface utilisateur.
- **Standardisation des Providers** : Migration de tous les providers Riverpod vers des fichiers dédiés.

### Tests & Qualité
- **Suite de Tests Complète** : Implémentation de plus de 20 tests couvrant les modèles, la logique métier, le state management et les widgets.
- **Infrastructure de Test** : Organisation hiérarchique du dossier `test/` (unit, presentation, data, widgets) et utilisation de `mocktail`.
- **Analyse Statique** : Correction de tous les avertissements de l'analyseur Flutter (zéro issue).

### UI/UX
- **Contrôles Caméra** : Extraction et amélioration de l'interface de contrôle du zoom et de l'exposition dans le mode Miroir.
- **Feedback Transparent** : Affichage des raisons de recommandation dans les suggestions de tenues.
- **Stepper d'Authentification** : Refonte complète du flux d'inscription en 3 étapes claires.

## [1.0.1-beta] - 2026-05-05

### Refactor & Performance
- Optimisation majeure du moteur de recommandation de tenues.
- Stabilisation de la gestion du cycle de vie des dialogues dans l'agenda.

### Security
- Migration des logs vers le répertoire privé de l'application.
- Verrouillage strict de la synchronisation cloud par ID utilisateur.

## [1.0.0] - 2026-03-31
- Version initiale avec support Supabase (Auth, Profil, Agenda) et détection morphologique IA.
