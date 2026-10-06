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

- **Moteur de Recommandation** : Optimisation majeure du moteur de classement de tenues (filtrage contextuel météo/agenda/morphologie).
- **Gestion de l'Agenda** : Stabilisation du cycle de vie des dialogues et de la persistance des événements.

### Artéfacts Release & Build

- **Build Android Production (Version Code 2)** : Génération et signature des artéfacts `magicmirror-v1.0.1.apk` et `magicmirror-v1.0.1.aab` (SHA-256 validés).
- **Stabilisation Branche UI** : Consolidation du build release Android re-généré depuis la branche UI.

### Sécurité & Confidentialité

- **Stockage des Logs** : Migration des logs de débogage vers les répertoires sandboxés/privés natifs de l'application.
- **Synchronisation Cloud** : Verrouillage strict de la synchronisation Supabase scopée exclusivement à l'identifiant `user_id` authentifié.

## [1.0.0-beta] - 2026-04-01

### Livraison Initiale & Artéfacts (Version Code 1)

- **Artéfacts Release Initiaux** : Génération des premiers builds Android APK et App Bundle (AAB) `magicmirror-v1.0.0-beta.apk`.
- **Règles R8/ProGuard** : Intégration des premières règles de shrink pour éviter les échecs de build liés aux modules optionnels ML Kit.

### Fonctionnalités de Base

- **Miroir Caméra & Morphologie IA** : Déploiement initial du miroir en direct avec détection de pose et estimation de silhouette via Google ML Kit.
- **Authentification & Profil** : Système complet d'inscription/connexion par e-mail et synchronisation cloud Supabase.
- **Agenda & Météo** : Prise en charge des événements d'agenda cloud (CRUD) et météo OpenWeatherMap.
- **Moteur de Recommandation V1** : Algorithme de scoring heuristique combinant météo, horaire et type d'événement.
- **Intégration Calendrier** : Configuration initiale du support Google Calendar comme calendrier par défaut.