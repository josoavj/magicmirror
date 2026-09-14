"""
Moteur RAG Vectoriel Hybride (OpenRouter Nemotron / Sentence-Transformers / TF-IDF).
Charge les fichiers .pkl en mémoire vive pour des recherches de similarité cosinus en < 5ms.
"""

import os
import pickle
import numpy as np
import requests
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Any

class RAGEngine:
    def __init__(self, models_dir: str = None):
        if models_dir is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            models_dir = os.path.join(base_dir, "models")

        self.models_dir = models_dir
        self.vectorizer = None
        self.embeddings_matrix = None
        self.corpus = None
        self.meta = {}
        self.st_model = None
        self.is_loaded = False
        self.load_models()

    def load_models(self):
        """Charge les fichiers .pkl en mémoire (RAM)."""
        vec_path = os.path.join(self.models_dir, "vectorizer.pkl")
        emb_path = os.path.join(self.models_dir, "fashion_embeddings.pkl")
        corp_path = os.path.join(self.models_dir, "knowledge_corpus.pkl")
        meta_path = os.path.join(self.models_dir, "model_meta.pkl")

        if os.path.exists(vec_path) and os.path.exists(emb_path) and os.path.exists(corp_path):
            with open(vec_path, "rb") as f:
                self.vectorizer = pickle.load(f)
            with open(emb_path, "rb") as f:
                self.embeddings_matrix = pickle.load(f)
            with open(corp_path, "rb") as f:
                self.corpus = pickle.load(f)
            if os.path.exists(meta_path):
                with open(meta_path, "rb") as f:
                    self.meta = pickle.load(f)

            if self.meta.get("embedding_type") == "sentence_transformers":
                try:
                    from sentence_transformers import SentenceTransformer
                    self.st_model = SentenceTransformer("all-MiniLM-L6-v2")
                except Exception:
                    pass

            self.is_loaded = True
            print(f"[RAGEngine] Modèles chargés en RAM ({self.meta.get('embedding_type', 'tfidf')}, {len(self.corpus)} fiches indexées).")
        else:
            print("[RAGEngine] AVERTISSEMENT : Fichiers .pkl introuvables. Exécutez train_and_vectorize.py.")
            self.is_loaded = False

    def _embed_query(self, query: str) -> np.ndarray:
        """Encode la requête selon le type d'embedding actif."""
        embedding_type = self.meta.get("embedding_type", "tfidf")

        # 1. OpenRouter Nemotron Embeddings (nvidia/nemotron-3-embed-1b:free)
        if embedding_type == "openrouter_nemotron" and os.getenv("OPENROUTER_API_KEY"):
            try:
                url = "https://openrouter.ai/api/v1/embeddings"
                headers = {
                    "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
                    "Content-Type": "application/json",
                    "HTTP-Referer": "http://localhost:3000",
                    "X-Title": "Reflecto Smart Mirror"
                }
                payload = {
                    "model": "nvidia/nemotron-3-embed-1b:free",
                    "input": [query],
                    "encoding_format": "float"
                }
                res = requests.post(url, headers=headers, json=payload, timeout=2.5)
                if res.status_code == 200:
                    return np.array([res.json()["data"][0]["embedding"]], dtype=np.float32)
                else:
                    payload["model"] = "nvidia/nemotron-3-embed-1b"
                    retry = requests.post(url, headers=headers, json=payload, timeout=2.5)
                    if retry.status_code == 200:
                        return np.array([retry.json()["data"][0]["embedding"]], dtype=np.float32)
            except Exception as e:
                print(f"[RAGEngine] Échec OpenRouter Nemotron query ({e}), bascule TF-IDF...")

        # 2. Sentence-Transformers local
        if self.st_model is not None:
            try:
                return self.st_model.encode([query], convert_to_numpy=True, normalize_embeddings=True)
            except Exception:
                pass

        # 3. TF-IDF
        if self.vectorizer is not None:
            return self.vectorizer.transform([query]).toarray()

        return np.zeros((1, self.embeddings_matrix.shape[1]))

    def search_rules(self, query: str, top_k: int = 4) -> List[Dict[str, Any]]:
        """Effectue la recherche par similarité cosinus en mémoire."""
        if not self.is_loaded or self.embeddings_matrix is None:
            return []

        query_vec = self._embed_query(query)
        similarities = cosine_similarity(query_vec, self.embeddings_matrix)[0]
        top_indices = np.argsort(similarities)[::-1][:top_k]

        results = []
        for idx in top_indices:
            score = float(similarities[idx])
            item = dict(self.corpus[idx])
            item["similarity_score"] = round(score, 3)
            results.append(item)

        return results

    def format_prompt_context(self, rules: List[Dict[str, Any]]) -> str:
        """Formate les règles extraites pour injection dans le prompt LLM."""
        if not rules:
            return ""

        lines = [f"• [{r.get('title', 'Règle')}] : {r.get('rules', '')}" for r in rules]
        return "\n---\n📚 CONNAISSANCES RAG APPLIQUÉES (RÈGLES D'EXPERTISE MODE VECTORISÉES) :\n" + "\n".join(lines) + "\n---"
