# 🪞 Reflecto — Miroir Intelligent avec IA

## 📌 Description

**Reflecto** est un miroir intelligent grand public combinant **vision par ordinateur**, **intelligence artificielle** et **IoT** afin de proposer des **recommandations vestimentaires personnalisées en temps réel**.

Grâce à une caméra intégrée, le système analyse les caractéristiques de l’utilisateur (morphologie, silhouette, genre, couleur de peau) et suggère des tenues adaptées au contexte quotidien.

Les recommandations prennent en compte :

- 🌦️ La météo en temps réel  
- 📅 L’agenda personnel  
- 🕒 L’heure de la journée  
- 🍂 La saison  

Le système inclut également une **interface conversationnelle** (langage naturel) ainsi qu’une **synthèse vocale** pour restituer les suggestions.

---

## 🌐 Version actuelle du projet

Cette version correspond à la **version Web de Reflecto**, qui joue un rôle central dans l’architecture :

- 🧠 Traitement des données (IA & logique métier)
- 🌍 Interface utilisateur (frontend)
- 🔗 Communication avec les composants IoT

👉 Les données analysées (image, commandes utilisateur, etc.) sont **envoyées depuis cette plateforme vers un module embarqué (Arduino / miroir intelligent)** pour affichage et interaction physique.

---

## 📱 Évolution prévue

Une **version mobile** est également prévue :

- 📷 Utilisation directe de la caméra du smartphone  
- 🎤 Utilisation du micro pour les commandes vocales  
- 🚫 Sans dépendance IoT  
- ⚡ Traitement optimisé via les ressources du device  

Cette version permettra une **expérience plus accessible et portable**.

---

## 🚀 Fonctionnalités principales

- 🎯 **Analyse visuelle intelligente**
  - Détection de la morphologie et de la silhouette
  - Analyse du teint et des caractéristiques générales

- 👗 **Recommandations vestimentaires personnalisées**
  - Suggestions adaptées au contexte (travail, sortie, événement, etc.)
  - Adaptation dynamique (météo, heure, saison)

- 💬 **Interface conversationnelle**
  - Interaction en langage naturel
  - Requêtes personnalisées

- 🔊 **Synthèse vocale**
  - Restitution audio des recommandations

- 🧠 **Historique des looks**
  - Suivi de l’évolution stylistique
  - Mémoire des préférences

- ♿ **Accessibilité**
  - Adapté aux personnes malvoyantes, âgées ou neuroatypiques

---

## 🛠️ Technologies utilisées

### Frontend
- **Next.js**
- **React**
- **TypeScript**
- **Tailwind CSS**

### Backend
- **Node.js**
- **API REST / GraphQL (selon implémentation)**

### Intelligence Artificielle
- **Computer Vision** (OpenCV / TensorFlow / API externe)
- **IA générative** (recommandations contextuelles)

### IoT
- **Arduino** (interface miroir)
- Communication via API / HTTP / WebSocket

### Services externes
- API météo (ex: OpenWeather)
- Intégration agenda
- Synthèse vocale (Web Speech API ou équivalent)

---

## 🧩 Architecture du projet

Reflecto repose sur une combinaison de technologies modernes :

- **Frontend** : Interface utilisateur interactive (Web ou embarquée)
- **Backend** : API de traitement et orchestration
- **Vision par ordinateur** : Analyse d’image (caméra)
- **IA / Machine Learning** : Génération de recommandations
- **IoT** : Intégration matérielle (miroir + caméra)
- **Services externes** :
  - API météo
  - Intégration agenda

## ⚙️ Installation (exemple générique)


## 🎨 Palette de couleurs

# Couleurs principales :

- **Bleu marine foncé** - #2C3E50 / #1A2332

# Fond principal, évoque la sophistication et la technologie
- **Or / Doré** - #D4A574 / #C9A063

# Cadre du miroir orné, détails décoratifs
Apporte l'élégance et le luxe
- **Cyan / Turquoise clair** - #7DD3C0 / #6ECFBD

# Effet de reflet du miroir (partie gauche)
Représente la fraîcheur et l'innovation
- **Bleu cyan électrique** - #00D4FF / #1EC9E8

# Réseau neuronal (lignes d'IA)
Symbolise la technologie et l'intelligence artificielle
- **Gris ardoise** - #4A5F7A / #5B6D84

# Surface du miroir, ombres
Crée la profondeur et l'effet 3D
- **Beige doré clair** - #E8C89A

# Texte "REFLECTO"
Harmonise avec le cadre doré

```bash
# Cloner le projet
git clone https://github.com/ton-username/reflecto.git

# Accéder au dossier
cd reflecto

# Installer les dépendances
npm install

# Lancer le projet
npm run dev