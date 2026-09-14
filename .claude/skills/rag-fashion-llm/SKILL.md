---
name: rag-fashion-llm
description: Sets up the Fashion RAG (Retrieval-Augmented Generation) knowledge base, cleans raw data from public/data, configures embeddings and vector search, and implements a multi-provider LLM fallback chain (Groq -> OpenRouter -> Gemini -> deterministic fallback) with Render deployment readiness.
---

# 🏷️ Skill: RAG Fashion Knowledge Base & Résilience Multi-LLM

## 📌 Rôle & Contexte
Ce skill guide l'agent Claude Code pour transformer le système de recommandation vestimentaire de **Reflecto** en un moteur RAG expert alimenté par une base de connaissances stylistique nettoyée, vectorisée et servie par une cascade de modèles de langage résiliente et ultra-rapide.

---

## 🎯 Objectifs
1. **Nettoyer et restructurer** les données brutes de scraping contenues dans `public/data/` (`morphologie-type.csv`, `seans_and_weather.csv`, `skintone.csv`) en fiches de connaissances Markdown/JSON expertes.
2. **Implémenter le pipeline RAG** : chunking sémantique, embeddings (ex. Nemotron, BGE, ou text-embedding) et recherche vectorielle (via Supabase `pgvector` ou microservice vectoriel).
3. **Mettre en place la cascade de Fallback Multi-Providers** : Groq (priorité 1, vitesse $<400\text{ms}$) $\to$ OpenRouter (priorité 2) $\to$ Google Gemini (priorité 3) $\to$ Fallback local déterministe.
4. **Préparer le déploiement sur Render** (et configuration pour tunnel `ngrok` en test local).

---

## 🛠️ Instructions d'Exécution Pas-à-Pas

### Étape 1 : Nettoyage & Normalisation des Données (`public/data`)
Les fichiers actuels contiennent du bruit de scraping web. Tu dois les analyser et générer 4 documents de référence propres dans `data/knowledge/` :

1. `data/knowledge/morphologies.md` :
   - Classification : $A$ (Poire/Triangle), $V$ (Triangle inversé), $H$ (Rectangle), $X$ (Sablier), $O$ (Rondeur), $8$ (Huit).
   - Pour chaque morphologie : coupes idéales, pièces maîtresses, matières recommandées, coupes à proscrire.
2. `data/knowledge/colorimetrie_skintone.md` :
   - Théorie des 4 saisons : Printemps (chaud/lumineux), Été (froid/doux), Automne (chaud/profond), Hiver (froid/contrasté).
   - Règles d'association selon la carnation (Fair, Light, Warm, Medium, Dark, Deep), couleur des yeux et sous-tons de peau.
3. `data/knowledge/saisons_meteo.md` :
   - Règles vestimentaires et matières selon la météo : grand froid ($<10^\circ\text{C}$), tempéré ($10-25^\circ\text{C}$), chaleur ($>25^\circ\text{C}$), pluie/vent/neige.
4. `data/knowledge/dress_codes_evenements.md` :
   - Règles strictes pour chaque contexte : *Business Formal*, *Smart Casual*, *Gala / Black Tie*, *Cocktail*, *Mariage*, *Quotidien / Détente*.

### Étape 2 : Pipeline Vectoriel & Recherche Sémantique
- Définir le schéma de stockage vectoriel (ex. table Supabase `fashion_knowledge` avec `content`, `metadata` et `embedding vector(1536)` ou `vector(1024)`).
- Implémenter la fonction de recherche par similarité cosinus (`match_fashion_rules`) pour récupérer les 3 règles les plus pertinentes selon le profil, l'événement et la météo.
- Créer un script d'ingestion/indexation réexécutable (`scripts/ingest-knowledge.ts` ou script Python).

### Étape 3 : Service LLM avec Cascade de Fallback
Créer un service centralisé `lib/services/llm-provider.ts` qui expose une méthode unifiée `generateCompletion(options)` :
```typescript
// Ordre de priorité de la cascade :
// 1. Groq (Modèle: llama-3.3-70b-versatile ou llama-3.1-8b-instant) -> Hyper rapide
// 2. OpenRouter (Modèle: meta-llama/llama-3.1-8b-instruct) -> Haute compatibilité
// 3. Google Gemini (Modèle: gemini-1.5-flash ou gemini-2.0-flash) -> Fallback résistant
// 4. Local Rule Fallback -> Rendu prédictif basé sur les fiches RAG si panne réseau totale
```
- Chaque étape doit avoir un timeout court (ex. 4000ms max par provider) avant de basculer automatiquement sur le suivant sans bloquer l'UI.
- Gérer le parsing JSON strict avec extracteur tolérant aux markdowns fences (```json).

### Étape 4 : Injection du RAG dans les Recommandations
- Mettre à jour `/api/recommendations/route.ts` pour :
  1. Récupérer les règles RAG pertinentes via la requête vectorielle.
  2. Injecter ces règles dans le prompt système du LLM.
  3. Appeler le `llm-provider` unifié.

### Étape 5 : Déploiement Render & Configuration ngrok
- Documenter et adapter la configuration pour Render (Web Service Next.js ou API).
- Configurer les variables d'environnement (`GROQ_API_KEY`, `OPENROUTER_API_KEY`, `GEMINI_API_KEY`, `EMBEDDING_API_KEY`).
- Fournir les commandes pour exposer le serveur via `ngrok` lors des phases de tests locaux.

---

## 📋 Livrable Obligatoire
À la fin de l'exécution, générer un fichier **`WALKTHROUGH_SKILL_1.md`** à la racine contenant :
- [ ] La liste des fichiers créés / modifiés.
- [ ] La structure des fiches de connaissances nettoyées.
- [ ] Les variables d'environnement requises.
- [ ] Le protocole de test pour simuler une panne API (Groq coupé $\to$ bascule OpenRouter $\to$ Gemini).
- [ ] Les instructions de déploiement sur Render et de tunnel ngrok.
