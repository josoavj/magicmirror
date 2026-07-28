# Pipeline ML — Ranking de tenues (LightGBM)

Ce document décrit le pipeline de Machine Learning utilisé pour scorer et classer les tenues dans MagicMirror. Il remplace progressivement le scoring heuristique par des recommandations adaptatives.

---

## 1. Intégration Flutter : Ranking Hybride

Le score final d'une tenue est calculé par le `OutfitRankingService` (`lib/features/outfit_suggestion/domain/services/outfit_ranking_service.dart`).

Il combine deux sources :
1.  **Score Heuristique** : Règles métier (Météo, Agenda, Morphologie).
2.  **Score ML** : Prédiction du modèle LightGBM récupérée depuis Supabase.

### Formule de mixage
L'application utilise un poids (`AppConfig.hybridMlWeight`) pour fusionner les scores :
`FinalScore = (1 - w) * HeuristicScore + w * MLScore`

---

## 2. Cycle de vie des données ML

### Feedback Utilisateur
Chaque interaction (Like, Dislike, Favori) est enregistrée localement puis synchronisée vers la table `outfit_feedback_events` sur Supabase via le `OutfitTelemetryNotifier`.

### Entraînement (Backend)
Le pipeline Python (dossier `ml/`) extrait ces feedbacks pour entraîner un modèle LightGBM qui apprend les préférences de style de chaque utilisateur en fonction du contexte (température, type d'événement).

### Inférence
Les nouveaux scores sont publiés dans la table `outfit_ml_scores`, que l'application Flutter consomme en temps réel via le `outfitMlScoreMapProvider`.

---

## 3. Configuration dans l'App

Dans `lib/config/app_config.dart` :
- `enableHybridMlRanking` : Activer/Désactiver le mixage ML.
- `hybridMlWeight` : Influence du modèle ML (défaut: 0.4).
- `enableCloudFeedbackExport` : Activer l'envoi des feedbacks au cloud.

---

## 4. Tests de Ranking
La logique de fusion et de priorité est validée par des tests unitaires :
`test/unit/features/outfit_suggestion/outfit_ranking_service_test.dart`
