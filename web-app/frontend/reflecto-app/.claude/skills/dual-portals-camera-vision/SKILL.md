---
name: dual-portals-camera-vision
description: Implements the Dual-Portal experience (Guest Demo Express mode vs Authenticated User Portal) and fixes the camera vision pipeline so that real-time detected attributes (gender, morphology, skin tone, clothing) directly drive the downstream recommendation LLM and Pollinations.AI image generation.
---

# 🏷️ Skill: Portails Double-Flux & Pipeline Caméra Temps Réel vers Pollinations.AI

## 📌 Rôle & Contexte
Ce skill guide Claude Code pour scinder l'expérience de **Reflecto** en deux parcours complémentaires (Public / Démo Express sans compte vs Utilisateur Connecté) et résoudre la rupture de transmission entre la caméra WebRTC et la génération d'images par IA.

---

## 🎯 Objectifs
1. **Implémenter le Portail Public Démo Express (Guest Mode)** : parcours ultra-rapide en 3 étapes (*Événement $\to$ Scan Caméra $\to$ Recommandations Immédiates*) sans obligation de créer un compte.
2. **Adapter le Portail Utilisateur Connecté** : conserver le dashboard, l'agenda Supabase, l'historique et fusionner les préférences sauvegardées avec l'analyse caméra en temps réel.
3. **Corriger et fiabiliser le Pipeline Caméra $\to$ Recommandations $\to$ Pollinations.AI** : veiller à ce que le genre, la morphologie, le teint et les couleurs détectés en direct déterminent strictement le prompt de génération de photos de mode.
4. **Garantir la sécurité & les performances** : intégrer une détection visuelle légère sans latence excessive tout en conservant le kill-switch RGPD WebRTC.

---

## 🛠️ Instructions d'Exécution Pas-à-Pas

### Étape 1 : Architecture des Deux Portails (Routing & State)
1. **Portail Public / Démo Express** (`/demo` ou composant Guest sur `/`) :
   - Pas de redirection forcée vers `/login`.
   - **Écran 1 : Contexte Événement & Météo**
     - Sélection rapide de l'événement (chips pré-configurés : *Entretien d'embauche, Soirée Gala, Mariage, Travail / Bureau, Rendez-vous casual* ou champ texte libre).
     - Détection météo automatique via géolocalisation ou ville par défaut.
   - **Écran 2 : Scan Caméra Live**
     - HUD style miroir intelligent (guidage de cadrage visage/buste).
     - Bouton *"Scanner mon look"*.
   - **Écran 3 : Résultat & Tenues IA**
     - Affichage instantané des 3 tenues adaptées à la personne scannée.
     - Galerie de photos générées par Pollinations.AI.

2. **Portail Connecté** (`/dashboard`, `/camera`, `/recommendations`, `/history`, `/settings`) :
   - Conserver l'authentification Supabase et la gestion de profil complète.
   - Lors d'un scan caméra sur `/camera`, les caractéristiques détectées en direct viennent enrichir le profil sans écraser définitivement les préférences personnalisées.

### Étape 2 : Extraction Visuelle Précise & Normalisée (`/api/analyze-outfit`)
- Adapter le prompt de vision et le schéma de retour JSON pour extraire obligatoirement :
  ```json
  {
    "gender": "male" | "female" | "unisex",
    "morphology": "H-Shape" | "V-Shape" | "A-Shape" | "X-Shape" | "O-Shape",
    "silhouette": "Description concise",
    "skinTone": "fair" | "light" | "warm" | "medium" | "dark" | "deep",
    "currentOutfitColors": ["navy", "white"],
    "confidence": 0.92,
    "suggestions": "Conseil stylistique immédiat"
  }
  ```
- Ajouter un fallback de vision (ex. LLaMA 3.2 Vision $\to$ Gemini 1.5/2.0 Flash Vision) pour garantir l'analyse même si un endpoint sature.

### Étape 3 : Raccordement Direct à la Génération d'Images (`image-service.ts`)
- Modifier `buildOutfitPrompt` dans `lib/services/image-service.ts` :
  ```typescript
  export function buildOutfitPrompt(
    outfitDescription: string,
    detectedContext: { gender?: string; morphology?: string; skinTone?: string }
  ): string {
    const gender = detectedContext.gender === "female" ? "female fashion model" : "male fashion model";
    const bodyType = detectedContext.morphology || "balanced silhouette";
    const skinTone = detectedContext.skinTone || "natural skin complexion";
    
    return [
      `full body editorial fashion photography`,
      `${gender} wearing ${outfitDescription}`,
      `${bodyType} body shape`,
      `${skinTone} skin tone`,
      `high-end studio lighting`,
      `crisp details, 8k resolution, clean background`
    ].join(", ");
  }
  ```
- S'assurer que le flux de recommandation passe systématiquement les attributs visuels détectés à Pollinations.AI.

### Étape 4 : Optimisation WebRTC & Conformité RGPD
- Conserver l'arrêt immédiat (`track.stop()`) dès que l'utilisateur quitte l'onglet ou navigue vers une autre page.
- Option de capture instantanée sur canvas pour réduire la taille du Base64 envoyé (max 800x600 px pour réduire la latence réseau).

---

## 📋 Livrable Obligatoire
À la fin de l'exécution, générer un fichier **`WALKTHROUGH_SKILL_2.md`** à la racine contenant :
- [ ] La description du flux Démo Express (Guest) vs Connecté.
- [ ] Les captures / logs montrant la transmission effective des métadonnées caméra vers Pollinations.AI.
- [ ] Le protocole de test pour valider qu'un visage masculin et un visage féminin génèrent bien des tenues distinctes et adaptées.
- [ ] La validation du cycle de vie de la caméra (kill switch).
