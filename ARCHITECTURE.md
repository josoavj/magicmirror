# Magic Mirror - Smart Mirror App

## Architecture

Le projet suit une architecture Clean Architecture avec les couches :
- **Presentation** : UI/UX avec widgets et providers
- **Data** : Modèles et repositories
- **Domain** : Entités et logique métier
- **Core** : Services partagés, constants, thème

## Features

### Mirror (Miroir Intégré)
- Accès à la caméra de l'appareil
- Reconnaissance de morphologie/forme
- Affichage temps réel

### Agenda (Planning)
- Synchronisation Google Agenda
- Affichage des événements

### Weather (Météo)
- Données météo en temps réel
- API intégration

### AI/ML (Intelligence Artificielle)
- Reconnaissance morphologique
- Suggestions intelligentes

### Outfit Suggestion (Suggestions de Tenue)
- Recommandations basées sur :
  - Morphologie détectée
  - Météo du jour
  - Agenda de la journée
  - Préférences utilisateur

## Installation des dépendances

```bash
flutter pub get
```

## Exécution

```bash
flutter run
```
