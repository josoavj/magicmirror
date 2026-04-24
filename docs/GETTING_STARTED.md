# Démarrage rapide — Magic Mirror

> Ce guide te permettra d'avoir Magic Mirror fonctionnel en local en moins de 5 minutes.

---

## Table des matières

1. [Installation préalable](#1-installation-préalable)
2. [Configuration minimale](#2-configuration-minimale)
3. [Lancer l'application](#3-lancer-lapplication)
4. [Premier lancement](#4-premier-lancement)
5. [Prochaines étapes](#-prochaines-étapes)
6. [Dépannage](#-dépannage)

---

## 1. Installation préalable

### Vérifier Flutter

```bash
flutter --version
```

Si Flutter n'est pas installé, le télécharger depuis [flutter.dev](https://flutter.dev) et suivre le guide d'installation officiel avant de continuer.

### Cloner et préparer le projet

```bash
# Cloner le dépôt
git clone https://github.com/josoavj/magicmirror.git
cd magicmirror

# Installer les dépendances
flutter pub get
```

### Vérifier l'environnement

```bash
flutter doctor
```

`flutter doctor` analyse ton environnement et signale les outils manquants (Xcode, Android Studio, émulateurs, etc.). Résoudre tous les avertissements marqués `[!]` avant de continuer garantit un lancement sans surprise.

---

## 2. Configuration minimale

### Créer le fichier `.env`

```bash
cp .env.example .env
```

Le fichier `.env` centralise toutes les clés et variables sensibles. Il est automatiquement ignoré par Git (`.gitignore`) — tes clés ne seront jamais exposées sur GitHub.

### Renseigner les variables essentielles

Ouvrir `.env` et compléter au minimum :

```env
# Météo (obligatoire pour les suggestions contextuelles)
OPENWEATHERMAP_API_KEY=your_key_here

# Supabase (obligatoire pour l'authentification et l'agenda)
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

> **Mode développement sans clés :**  tu peux lancer l'app avec `OPENWEATHERMAP_API_KEY=demo` pour tester l'interface, mais les données météo réelles et l'agenda ne seront pas disponibles. Voir [WEATHER_SETUP.md](WEATHER_SETUP.md) et [SUPABASE_SETUP.md](SUPABASE_SETUP.md) pour obtenir tes clés gratuitement.

---

## 3. Lancer l'application

### Lister les appareils disponibles

```bash
flutter devices
```

Cette commande liste tous les appareils connectés (physiques ou émulés) ainsi que leur identifiant. Utilise cet identifiant dans la commande suivante si tu veux cibler un appareil précis.

### Lancer l'app

```bash
# Sur l'appareil par défaut
flutter run

# Sur un appareil spécifique
flutter run -d <device_id>
```

> La première compilation peut prendre 1 à 2 minutes. Les lancements suivants seront beaucoup plus rapides grâce au cache.

---

## 4. Premier lancement

### Permissions

Au premier démarrage, l'app demande les permissions suivantes :

| Permission | Utilisée pour |
|---|---|
| 📷 Caméra | Flux miroir temps réel + détection morphologique |
| 📍 Localisation | Récupération automatique de la météo locale |

Accorder ces deux permissions est nécessaire pour accéder aux fonctionnalités principales.

### Authentification

L'app ouvre automatiquement le flux d'authentification :

1. **Inscription** — créer un compte avec ton adresse e-mail
2. **Vérification e-mail** — confirmer l'adresse avant de continuer *(vérifier les spams si l'e-mail n'arrive pas)*
3. **Connexion** — accéder à l'application

> Si Supabase n'est pas encore configuré dans ton `.env`, l'authentification ne fonctionnera pas. Voir [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

### Écran d'accueil

Une fois connecté, l'écran d'accueil donne accès aux modules :

| Module | Description |
|---|---|
| 🪞 **Miroir** | Flux caméra temps réel avec analyse morphologique |
| 📅 **Agenda** | Événements du jour synchronisés depuis Supabase |
| 👤 **Profil** | Préférences vestimentaires, tailles, morphologie |
| ⚙️ **Paramètres** | Configuration de l'app et du compte |

---

## ✅ Prochaines étapes

Magic Mirror tourne en local — voici comment aller plus loin :

| Guide | Contenu |
|---|---|
| [WEATHER_SETUP.md](WEATHER_SETUP.md) | Obtenir une clé OpenWeatherMap réelle |
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Configurer l'authentification et l'agenda cloud |
| [SETUP.md](SETUP.md) | Préparer un build de production |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Comprendre la structure du code |

---

## ❓ Dépannage

### « Command not found: flutter »

Flutter n'est pas dans le `PATH`. L'ajouter manuellement :

```bash
export PATH="$PATH:~/flutter/bin"

# Vérifier que ça fonctionne
flutter --version
```

Pour rendre ce changement permanent, ajouter la ligne `export` dans ton fichier `~/.bashrc`, `~/.zshrc` ou équivalent selon ton shell.

### « Permission denied » sur Android

Le cache de build peut parfois corrompre les permissions. Nettoyer et relancer :

```bash
flutter clean
flutter pub get
flutter run
# Accepter les permissions demandées au lancement
```

### L'app plante au démarrage

Lancer avec les logs détaillés pour identifier la cause :

```bash
flutter clean
flutter pub get
flutter run -v
```

L'option `-v` (*verbose*) affiche les logs complets de compilation et d'exécution. Rechercher les lignes `ERROR` ou `EXCEPTION` pour identifier le problème.

### Erreurs dans `pubspec.yaml`

Des conflits de versions entre dépendances peuvent provoquer des erreurs au démarrage. Mettre à jour et réinstaller :

```bash
flutter pub upgrade
flutter pub get
```

> Si le problème persiste après ces étapes, consulter [SETUP.md](SETUP.md) pour un guide de dépannage plus complet, ou ouvrir une [issue GitHub](https://github.com/josoavj/magicmirror/issues).