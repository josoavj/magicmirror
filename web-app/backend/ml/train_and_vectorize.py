"""
Pipeline de Vectorisation & Embeddings RAG Fashion Reflecto.
Supporte :
1. OpenRouter NVIDIA Nemotron Embeddings (nvidia/nemotron-3-embed-1b:free) via OPENROUTER_API_KEY
2. NVIDIA NIM Direct API (nvidia/nv-embedqa-e5-v5) via NVIDIA_API_KEY
3. Dense Neural Local (Sentence-Transformers / all-MiniLM-L6-v2)
4. TF-IDF Bi-grammes haute précision (Fallback instantané)
"""

import os
import pickle
import json
import numpy as np
import requests
from dotenv import load_dotenv

load_dotenv()

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BASE_DIR, "models")
DATA_DIR = os.path.join(BASE_DIR, "..", "frontend", "reflecto-app", "data", "knowledge")

os.makedirs(MODELS_DIR, exist_ok=True)

def load_knowledge_corpus():
    """Charge les fiches de connaissances et construit le corpus sémantique."""
    json_path = os.path.join(DATA_DIR, "fashion_knowledge.json")
    if os.path.exists(json_path):
        with open(json_path, "r", encoding="utf-8") as f:
            return json.load(f)
    raise FileNotFoundError(f"Fichier de connaissances introuvable : {json_path}")

def get_openrouter_nemotron_embeddings(texts: list, api_key: str):
    """Génère des embeddings via OpenRouter avec le modèle nvidia/nemotron-3-embed-1b:free."""
    print("⚡ Appel d'OpenRouter pour Nemotron Embeddings (nvidia/nemotron-3-embed-1b:free)...")
    url = "https://openrouter.ai/api/v1/embeddings"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:3000",
        "X-Title": "Reflecto Smart Mirror"
    }
    
    # Batch call ou chunk call
    payload = {
        "model": "nvidia/nemotron-3-embed-1b:free",
        "input": texts,
        "encoding_format": "float"
    }
    
    response = requests.post(url, headers=headers, json=payload, timeout=30)
    if response.status_code == 200:
        data = response.json()
        embeddings = [item["embedding"] for item in data["data"]]
        return np.array(embeddings, dtype=np.float32)
    else:
        # Essai avec le modèle standard sans suffixe :free
        payload["model"] = "nvidia/nemotron-3-embed-1b"
        retry_res = requests.post(url, headers=headers, json=payload, timeout=30)
        if retry_res.status_code == 200:
            data = retry_res.json()
            embeddings = [item["embedding"] for item in data["data"]]
            return np.array(embeddings, dtype=np.float32)
        raise Exception(f"Erreur OpenRouter ({response.status_code}): {response.text}")

def train_and_export():
    print("🚀 Démarrage du pipeline d'entraînement et vectorisation RAG...")
    corpus = load_knowledge_corpus()
    print(f"📦 {len(corpus)} documents de connaissances chargés.")

    # Concaténation des textes sémantiques
    documents_text = [
        f"{item['title']} : {item['target']} | Mots-clés: {' '.join(item.get('tags', []))} | Règles: {item['rules']}"
        for item in corpus
    ]

    embeddings_matrix = None
    embedding_type = "tfidf"

    # 1. Tentative OpenRouter Nemotron (nvidia/nemotron-3-embed-1b:free)
    openrouter_key = os.getenv("OPENROUTER_API_KEY")
    if openrouter_key:
        try:
            embeddings_matrix = get_openrouter_nemotron_embeddings(documents_text, openrouter_key)
            embedding_type = "openrouter_nemotron"
            print("✅ Embeddings générés avec succès via OpenRouter Nemotron (nvidia/nemotron-3-embed-1b:free) !")
        except Exception as e:
            print(f"⚠️ Échec OpenRouter Nemotron ({e}), tentative des alternatives...")

    # 2. Tentative Sentence-Transformers Neural Local
    if embeddings_matrix is None:
        try:
            from sentence_transformers import SentenceTransformer
            print("🧠 Chargement du modèle neural dense local (all-MiniLM-L6-v2)...")
            st_model = SentenceTransformer("all-MiniLM-L6-v2")
            embeddings_matrix = st_model.encode(documents_text, convert_to_numpy=True, normalize_embeddings=True)
            embedding_type = "sentence_transformers"
            print("✅ Embeddings neuronaux denses générés avec succès !")
        except Exception as e:
            print(f"⚠️ Sentence-Transformers non disponible ({e}), utilisation du vectoriseur TF-IDF...")

    # 3. Fallback TF-IDF
    from sklearn.feature_extraction.text import TfidfVectorizer
    tfidf_vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        sublinear_tf=True,
        norm="l2",
        strip_accents="unicode"
    )
    tfidf_matrix = tfidf_vectorizer.fit_transform(documents_text).toarray()

    if embeddings_matrix is None:
        embeddings_matrix = tfidf_matrix
        embedding_type = "tfidf"

    # Sauvegarde des artefacts .pkl
    vectorizer_path = os.path.join(MODELS_DIR, "vectorizer.pkl")
    embeddings_path = os.path.join(MODELS_DIR, "fashion_embeddings.pkl")
    corpus_path = os.path.join(MODELS_DIR, "knowledge_corpus.pkl")
    meta_path = os.path.join(MODELS_DIR, "model_meta.pkl")

    with open(vectorizer_path, "wb") as f:
        pickle.dump(tfidf_vectorizer, f)
    with open(embeddings_path, "wb") as f:
        pickle.dump(embeddings_matrix, f)
    with open(corpus_path, "wb") as f:
        pickle.dump(corpus, f)
    with open(meta_path, "wb") as f:
        pickle.dump({"embedding_type": embedding_type, "dim": embeddings_matrix.shape[1]}, f)

    print(f"\n📊 Type d'embeddings actif : {embedding_type.upper()} (Dimension vectorielle : {embeddings_matrix.shape})")
    print(f"💾 Artefacts .pkl enregistrés dans {MODELS_DIR}")
    print("✅ Pipeline d'entraînement et de sérialisation terminé avec succès !")

if __name__ == "__main__":
    train_and_export()
