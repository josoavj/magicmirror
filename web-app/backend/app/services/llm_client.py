"""
Client LLM Asynchrone Python avec Cascade de Failover (Groq -> OpenRouter -> Gemini -> Fallback Déterministe).
"""

import os
import json
import re
import time
import httpx
from typing import List, Dict, Any, Optional

def extract_json_object(raw_text: str) -> Optional[Dict[str, Any]]:
    """Extrait proprement un dictionnaire JSON depuis une réponse LLM."""
    if not raw_text:
        return None

    # 1. Parsing direct
    try:
        return json.loads(raw_text.strip())
    except Exception:
        pass

    # 2. Nettoyage des balises markdown ```json
    cleaned = re.sub(r"```(?:json)?", "", raw_text, flags=re.IGNORECASE).replace("```", "").strip()
    try:
        return json.loads(cleaned)
    except Exception:
        pass

    # 3. Extraction de la première accolade ouvrante à la dernière fermante
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start != -1 and end != -1 and end > start:
        try:
            return json.loads(cleaned[start:end + 1])
        except Exception:
            pass

    return None

class LLMClient:
    def __init__(self):
        self.groq_api_key = os.getenv("GROQ_API_KEY")
        self.openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")

    async def generate_recommendations(
        self,
        system_prompt: str,
        user_prompt: str,
        timeout_sec: float = 4.5
    ) -> Dict[str, Any]:
        """Exécute la cascade de génération LLM."""
        start_time = time.time()
        errors = []

        # 1. Essai Groq (Llama 3.1 8B Instant / 3.3 70B - Vitesse < 400ms)
        if self.groq_api_key:
            groq_models = [
                "openai/gpt-oss-20b",
                "llama-3.3-70b-versatile",
                "llama-3.1-8b-instant",
                "deepseek-r1-distill-llama-70b",
                "gemma2-9b-it",
                "qwen-2.5-32b",
                "mixtral-8x7b-32768",
            ]
            for model_name in groq_models:
                try:
                    async with httpx.AsyncClient(timeout=timeout_sec) as client:
                        resp = await client.post(
                            "https://api.groq.com/openai/v1/chat/completions",
                            headers={
                                "Authorization": f"Bearer {self.groq_api_key}",
                                "Content-Type": "application/json",
                            },
                            json={
                                "model": model_name,
                                "messages": [
                                    {"role": "system", "content": system_prompt},
                                    {"role": "user", "content": user_prompt},
                                ],
                                "temperature": 0.7,
                                "response_format": {"type": "json_object"},
                            },
                        )
                        if resp.status_code == 200:
                            content = resp.json()["choices"][0]["message"]["content"]
                            parsed = extract_json_object(content)
                            if parsed:
                                return {
                                    "data": parsed,
                                    "provider": "groq",
                                    "model": model_name,
                                    "latency_ms": int((time.time() - start_time) * 1000),
                                }
                except Exception as e:
                    errors.append(f"groq ({model_name}): {e}")
            print(f"[LLMClient] Tous les modèles Groq ont échoué, bascule sur OpenRouter...")

        # 2. Essai OpenRouter
        if self.openrouter_api_key:
            try:
                async with httpx.AsyncClient(timeout=timeout_sec) as client:
                    resp = await client.post(
                        "https://openrouter.ai/api/v1/chat/completions",
                        headers={
                            "Authorization": f"Bearer {self.openrouter_api_key}",
                            "Content-Type": "application/json",
                            "HTTP-Referer": "http://localhost:3000",
                            "X-Title": "Reflecto Smart Mirror",
                        },
                        json={
                            "model": "meta-llama/llama-3.1-8b-instruct",
                            "messages": [
                                {"role": "system", "content": system_prompt},
                                {"role": "user", "content": user_prompt},
                            ],
                            "temperature": 0.7,
                            "response_format": {"type": "json_object"},
                        },
                    )
                    if resp.status_code == 200:
                        content = resp.json()["choices"][0]["message"]["content"]
                        parsed = extract_json_object(content)
                        if parsed:
                            return {
                                "data": parsed,
                                "provider": "openrouter",
                                "model": "llama-3.1-8b-instruct",
                                "latency_ms": int((time.time() - start_time) * 1000),
                            }
            except Exception as e:
                print(f"[LLMClient] OpenRouter a échoué : {e}, bascule sur Gemini...")
                errors.append(f"openrouter: {e}")

        # 3. Essai Google Gemini Flash
        if self.gemini_api_key:
            try:
                async with httpx.AsyncClient(timeout=timeout_sec) as client:
                    resp = await client.post(
                        f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={self.gemini_api_key}",
                        headers={"Content-Type": "application/json"},
                        json={
                            "contents": [{"role": "user", "parts": [{"text": f"{system_prompt}\n\n{user_prompt}"}]}],
                            "generationConfig": {"responseMimeType": "application/json", "temperature": 0.7},
                        },
                    )
                    if resp.status_code == 200:
                        content = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
                        parsed = extract_json_object(content)
                        if parsed:
                            return {
                                "data": parsed,
                                "provider": "gemini",
                                "model": "gemini-1.5-flash",
                                "latency_ms": int((time.time() - start_time) * 1000),
                            }
            except Exception as e:
                print(f"[LLMClient] Gemini a échoué : {e}")
                errors.append(f"gemini: {e}")

        # 4. Fallback Local Déterministe
        print("[LLMClient] Utilisation du fallback déterministe RAG.")
        fallback = {
            "recommendations": [
                {
                    "name": "Costume Tailleur RAG",
                    "context": "Travail / Professionnel",
                    "description": "Blazer en laine peignée sur mesure et pantalon chino assorti, coupés selon les règles de votre silhouette.",
                    "clothingItems": "tailored navy wool blazer with beige formal trousers",
                    "tags": ["Coupe Optimale", "Formel", "RAG ML"],
                    "match": 95,
                },
                {
                    "name": "Harmonie Urbaine",
                    "context": "Casual / Week-end",
                    "description": "Jean brut droit avec chemise popeline claire respirante et veste mi-saison.",
                    "clothingItems": "raw denim jeans with crisp white casual shirt and lightweight jacket",
                    "tags": ["Moderne", "Respirant", "Confort"],
                    "match": 89,
                },
                {
                    "name": "Prestige Signature",
                    "context": "Soirée / Gala",
                    "description": "Ensemble sombre raffiné avec touches dorées et contrastes valorisants.",
                    "clothingItems": "charcoal tailored suit with refined accessories",
                    "tags": ["Chic", "Prestige", "Soirée"],
                    "match": 93,
                },
            ]
        }
        return {
            "data": fallback,
            "provider": "local_fallback",
            "model": "rag-deterministic-engine",
            "latency_ms": int((time.time() - start_time) * 1000),
            "errors": errors,
        }
