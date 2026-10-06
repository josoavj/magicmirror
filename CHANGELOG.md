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

### Caméra & Mode Miroir

- **Rendu Plein Écran Centré** : Redimensionnement vidéo automatique sans déformation (`BoxFit.cover` + `Transform.scale` dynamique).
- **Effet Miroir Automatique** : Retournement horizontal (`isFlipped`) activé sur la caméra frontale.
- **Contrôles Permanents** : Maintien continu de la barre de zoom (1x-3x) et du contrôle d'exposition en bas à droite sans masquage automatique.
- **Badge de Corps Détecté** : Repositionnement du badge de détection corporelle en bas à gauche avec texte réactif.
- **Indépendance de l'HUD** : Le statut "IA active" et le bouton Paramètres restent visibles en haut à droite, indépendamment du cycle d'affichage de la date/heure.

### UI/UX & Écran À Propos

- **Mise à jour À Propos** : Intégration du rôle de Développeur Fullstack (`josoavj`), du bouton d'appel direct (+261 33 60 223 60) et du lien vers la politique de confidentialité.
- **Garde-robe / Dressing** : Valorisation de la fonctionnalité de gestion et prise en compte de la garde-robe personnelle dans les suggestions de tenues.
- **Design Refactoring** : Rendu épuré, Glassmorphism amélioré et lisibilité accrue sur toutes les tailles d'écran.

### Sécurité & Stabilité

- **Fix Crash Natif Android (R8 / ProGuard)** : Ajout des règles de conservation dans `android/app/proguard-rules.pro` pour ML Kit Pose Detection et MediaPipe, résolvant le crash JNI `NoSuchFieldError`.
- **Politique de Sécurité (SECURITY.md)** : Documentation complète du modèle de sécurité v1.1.0+ (RLS Supabase strict `user_id = auth.uid()`, chiffrement local via `flutter_secure_storage`, traitement IA 100% local sur l'appareil).
- **Licence MIT** : Intégration du fichier de licence officielle `LICENSE`.
- **Gestion des données** : Isolation et chiffrement du stockage local des préférences et jetons de session.

### Documentation & Qualité

- **Phase de Maintenance** : Notification explicite de la phase de maintenance dans le `README.md` et les 9 guides d'architecture/configuration (`docs/`).
- **Nettoyage du Code** : Suppression intégrale des commentaires de débug temporaires dans le code source.
- **Suite de Tests Complète** : Validation de l'ensemble des 25 tests unitaires et de widgets (analyse statique `flutter analyze` à zéro avertissement).

## [1.0.1-beta] - 2026-05-05

### Refactor & Performance

- Optimisation majeure du moteur de recommandation de tenues.
- Stabilisation de la gestion du cycle de vie des dialogues dans l'agenda.

### Security

- Migration des logs vers le répertoire privé de l'application.
- Verrouillage strict de la synchronisation cloud par ID utilisateur.

## [1.0.0] - 2026-03-31

- Version initiale avec support Supabase (Auth, Profil, Agenda) et détection morphologique IA.
- Cette première version couvre les principales fonctionnalités comme le miroir, la suggestion des tenues et aussi, celui du profil utilisateur.
- **Spécificité** : Utilisation de Google Calendar comme calendrier par défaut.