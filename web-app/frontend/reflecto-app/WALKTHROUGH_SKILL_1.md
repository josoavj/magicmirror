# 📖 Walkthrough - SKILL 1 : RAG Fashion Knowledge, Python ML Backend (FastAPI + PKL) & Résilience Multi-LLM

Ce document détaille l'architecture complète du **Skill 1**, incluant le backend Python Machine Learning (FastAPI / Uvicorn / artefacts `.pkl`), la vectorisation sémantique et la chaîne de secours LLM.

---

## 🏗️ 1. Architecture Globale du Backend ML & RAG

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      1. PIPELINE MACHINE LEARNING (.pkl)                    │
│  - Script : backend/ml/train_and_vectorize.py                              │
│  - Extraction des données & vectorisation TF-IDF bi-grammes sublinéaire    │
│  - Artefacts générés dans backend/models/ :                                 │
│    • vectorizer.pkl (Modèle vectoriel)                                     │
│    • fashion_embeddings.pkl (Matrice d'embeddings des connaissances)       │
│    • knowledge_corpus.pkl (Corpus de règles indexées)                      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ (Pré-chargement en RAM au démarrage)
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    2. MICROSERVICE FASTAPI + UVICORN (ASGI)                 │
│  - Point d'entrée : backend/app/main.py                                     │
│  - Recherche vectorielle cosinus NumPy en < 5ms                             │
│  - Endpoints REST :                                                         │
│    • GET  /api/v1/health          (Statut, modèles chargés, APIs dispo)    │
│    • POST /api/v1/rag/search      (Recherche vectorielle pure)              │
│    • POST /api/v1/recommendations (Pipeline RAG + Groq / OpenRouter)        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ (Appel REST < 10ms)
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    3. FRONTEND NEXT.js 16 (App Router)                      │
│  - Route : app/api/recommendations/route.ts                                 │
│  - Interroge FastAPI (sur localhost:8000, ngrok ou Render)                  │
│  - Fallback automatique interne si le serveur Python est hors-ligne         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 2. Démarrage Rapide du Backend Python (FastAPI + Uvicorn)

### Étape 1 : Installer les Dépendances Python
Dans un terminal, placez-vous dans le dossier backend :
```bash
cd D:/DossierM2/Projet/magicmirror/web-app/backend
pip install -r requirements.txt
```

### Étape 2 : Entraîner et Générer les Artefacts `.pkl`
Exécutez le pipeline de vectorisation :
```bash
python ml/train_and_vectorize.py
```
*Sortie attendue :*
```
🚀 Démarrage du pipeline d'entraînement et vectorisation RAG...
📦 16 documents de connaissances chargés.
📊 Matrice d'embeddings générée : dimensions (16, 284)
💾 Vectorizer sauvegardé : .../backend/models/vectorizer.pkl
💾 Embeddings sauvegardés : .../backend/models/fashion_embeddings.pkl
💾 Corpus sauvegardé : .../backend/models/knowledge_corpus.pkl
✅ Entraînement & Sérialisation terminés avec succès !
```

### Étape 3 : Lancer le Serveur FastAPI avec Uvicorn
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Accédez à la documentation interactive Swagger sur : **`http://localhost:8000/docs`**.

---

## ⚙️ 3. Configuration des Variables d'Environnement

Dans votre fichier `.env` (backend) ou `.env.local` (frontend) :

```env
# Clés LLM
GROQ_API_KEY=gsk_votre_cle_groq_ici
OPENROUTER_API_KEY=sk-or-votre_cle_openrouter_ici
GEMINI_API_KEY=AIzaSy_votre_cle_gemini_ici

# URL du Backend FastAPI (utilisé par Next.js)
FASTAPI_BACKEND_URL=http://localhost:8000
```

---

## 🧪 4. Protocole de Test

### Test 1 : Santé du Microservice FastAPI
```bash
curl http://localhost:8000/api/v1/health
```
*Réponse attendue :*
```json
{
  "status": "online",
  "service": "Reflecto RAG Backend",
  "models_loaded": true,
  "corpus_size": 16,
  "groq_configured": true
}
```

### Test 2 : Recherche Vectorielle Cosinus Pure
```bash
curl -X POST http://localhost:8000/api/v1/rag/search \
  -H "Content-Type: application/json" \
  -d '{"query": "robe de soirée pour gala silhouette en sablier", "top_k": 2}'
```

### Test 3 : Recommandations Complètes via Next.js
1. Lancez FastAPI (`uvicorn app.main:app --port 8000`).
2. Dans un second terminal, lancez Next.js (`npm run dev`).
3. Allez sur `http://localhost:3000/recommendations`.
4. Observez la vitesse de génération ($< 500\text{ms}$).

---

## 🚢 5. Déploiement sur Render

1. Créez un nouveau **Web Service** sur [Render.com](https://dashboard.render.com).
2. Pointez sur le sous-dossier `web-app/backend/`.
3. Choisissez l'environnement **Docker** (le fichier `Dockerfile` gère l'installation des dépendances et l'exécution automatique de `train_and_vectorize.py`).
4. Ajoutez les variables d'environnement (`GROQ_API_KEY`, `OPENROUTER_API_KEY`, etc.).
5. Renseignez l'URL fournie par Render (ex. `https://reflecto-backend.onrender.com`) dans votre variable `FASTAPI_BACKEND_URL` sur le frontend Vercel/Render.
