# 🚀 Getting Started - LevelMind

## Guide de démarrage rapide (5 min)

Bienvenue sur LevelMind! Ce guide te permettra de lancer l'app en quelques minutes.

---

## 1️⃣ Installation préalable

### Avoir Flutter installé?
```bash
flutter --version
```

**Non?** Télécharger depuis [flutter.dev](https://flutter.dev)

### Ensuite
```bash
# Cloner le projet
git clone https://github.com/josoavj/lvlmindapp.git
cd lvlmindapp

# Installer les dépendances
flutter pub get

# Vérifier l'installation
flutter doctor
```

---

## 2️⃣ Configuration minimale

### Créer le fichier `.env`
```bash
cp .env.example .env
```

### Ajouter clé OpenWeatherMap (optionnel pour dev)
```env
OPENWEATHERMAP_API_KEY=demo
```

*Voir [WEATHER_SETUP.md](WEATHER_SETUP.md) pour clé réelle*

---

## 3️⃣ Lancer l'app

```bash
# Lancer en développement
flutter run

# Sur appareil spécifique
flutter run -d <device_name>

# Lister appareils disponibles
flutter devices
```

---

## 4️⃣ Premier lancement

1. Accepter les permissions (caméra, localisation)
2. L'app s'ouvre avec 3 écrans:
   - 🎓 **Dashboard** - Contenu pédagogique
   - 📚 **Cours** - Catalogue de cours
   - ⚙️ **Paramètres** - Configuration

---

## ✅ Succès!

Tu as LevelMind en local! 🎉

### Prochaines étapes:
- Voir [SETUP.md](SETUP.md) pour configuration production
- Voir [WEATHER_SETUP.md](WEATHER_SETUP.md) pour météo réelle
- Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour structure du code

---

## ❓ Problèmes?

### "Command not found: flutter"
```bash
# Ajouter Flutter au PATH:
export PATH="$PATH:~/flutter/bin"

# Vérifier:
flutter --version
```

### "Permission denied" Android
```bash
flutter clean
flutter pub get
flutter run
# Accepter permissions
```

### App crash on launch
```bash
flutter clean
flutter pub get
flutter run -v  # Affiche logs détaillés
```

### "pubspec.yaml" errors
```bash
flutter pub upgrade
flutter pub get
```

Voir [SETUP.md](SETUP.md) troubleshooting pour plus...
