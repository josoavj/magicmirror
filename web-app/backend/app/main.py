"""
Application Principale FastAPI - Backend RAG & IA de Reflecto.
"""

import os
from contextlib import asynccontextmanager
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from app.services.rag_engine import RAGEngine
from app.services.llm_client import LLMClient

load_dotenv()

# Global instances
rag_engine: Optional[RAGEngine] = None
llm_client: Optional[LLMClient] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global rag_engine, llm_client
    print("🚀 [FastAPI] Initialisation du serveur et chargement des artefacts .pkl...")
    rag_engine = RAGEngine()
    llm_client = LLMClient()
    yield
    print("🛑 [FastAPI] Arrêt du serveur.")

app = FastAPI(
    title="Reflecto Fashion AI & RAG Backend",
    version="2.0.0",
    description="Microservice Python de Recommandation Vestimentaire RAG Vectoriel et Inférence LLM Multi-Fournisseurs",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# SCHÉMAS PYDANTIC (Validation de Données)
# ==========================================
class UserProfile(BaseModel):
    first_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    body_type: Optional[str] = None
    skin_tone: Optional[str] = None
    style_preference: Optional[str] = None

class WeatherContext(BaseModel):
    temp: Optional[float] = 22.0
    condition: Optional[str] = "Sunny"
    location: Optional[str] = "Antananarivo"

class EventItem(BaseModel):
    title: str
    type: Optional[str] = "General"
    time: Optional[str] = None

class CameraAnalysis(BaseModel):
    gender: Optional[str] = None
    morphology: Optional[str] = None
    silhouette: Optional[str] = None
    skinTone: Optional[str] = None
    suggestions: Optional[str] = None

class RecommendationRequest(BaseModel):
    profile: Optional[UserProfile] = None
    weather: Optional[WeatherContext] = None
    events: Optional[List[EventItem]] = []
    cameraAnalysis: Optional[CameraAnalysis] = None

class SearchQuery(BaseModel):
    query: str
    top_k: Optional[int] = 4

# ==========================================
# ENDPOINTS REST
# ==========================================
@app.get("/api/v1/health")
async def health_check():
    """Vérification de l'état du backend et des modèles chargés."""
    return {
        "status": "online",
        "service": "Reflecto RAG Backend",
        "models_loaded": rag_engine.is_loaded if rag_engine else False,
        "corpus_size": len(rag_engine.corpus) if rag_engine and rag_engine.corpus else 0,
        "groq_configured": bool(os.getenv("GROQ_API_KEY")),
        "openrouter_configured": bool(os.getenv("OPENROUTER_API_KEY")),
        "gemini_configured": bool(os.getenv("GEMINI_API_KEY")),
    }

@app.post("/api/v1/rag/search")
async def search_knowledge(req: SearchQuery):
    """Effectue une recherche vectorielle sémantique cosinus sur le corpus."""
    if not rag_engine:
        raise HTTPException(status_code=500, detail="RAG Engine non initialisé")
    
    rules = rag_engine.search_rules(req.query, top_k=req.top_k or 4)
    return {"query": req.query, "count": len(rules), "rules": rules}

@app.post("/api/v1/recommendations")
async def get_outfit_recommendations(req: RecommendationRequest):
    """Pipeline RAG complet : Vectorisation du contexte -> Extraction -> Prompt enrichi -> Inférence LLM."""
    if not rag_engine or not llm_client:
        raise HTTPException(status_code=500, detail="Services RAG non initialisés")

    # 1. Construction de la requête sémantique
    morphology = req.cameraAnalysis.morphology if req.cameraAnalysis and req.cameraAnalysis.morphology else (req.profile.body_type if req.profile else "H-Shape")
    skin_tone = req.cameraAnalysis.skinTone if req.cameraAnalysis and req.cameraAnalysis.skinTone else (req.profile.skin_tone if req.profile else "Warm")
    weather_cond = req.weather.condition if req.weather else "Sunny"
    weather_temp = req.weather.temp if req.weather else 22.0
    events_str = " ".join([f"{e.title} {e.type}" for e in req.events]) if req.events else "Journée libre"

    semantic_query = f"{morphology} {skin_tone} météo {weather_temp}°C {weather_cond} {events_str}"
    
    # 2. Recherche vectorielle NumPy cosinus
    retrieved_rules = rag_engine.search_rules(semantic_query, top_k=4)
    rag_context = rag_engine.format_prompt_context(retrieved_rules)

    # 3. Construction des Prompts
    system_prompt = (
        "Tu es 'Reflecto Style Assistant', un expert styliste personnel en haute couture.\n"
        "Génère EXACTEMENT 3 suggestions de tenues CRÉATIVES et HAUT DE GAMME adaptées au profil et au contexte.\n"
        "RÈGLE D'OR : Applique rigoureusement les règles RAG vectorisées fournies.\n"
        "RÈGLE DE LANGUE : Réponds UNIQUEMENT en Français pour les descriptions et les noms. Seul 'clothingItems' doit être en anglais.\n"
        "Réponds UNIQUEMENT avec l'objet JSON contenant la clé 'recommendations' avec un tableau de 3 objets."
    )

    user_prompt = f"""
Profil :
- Morphologie : {morphology}
- Teint : {skin_tone}
- Genre : {req.profile.gender if req.profile and req.profile.gender else 'Non précisé'}
- Météo : {weather_temp}°C, {weather_cond}
- Événements du jour : {events_str}

{rag_context}

Format JSON attendu :
{{
  "recommendations": [
    {{
      "name": "Nom de la tenue en français",
      "context": "Événement exact",
      "description": "Explication détaillée des coupes, tissus et couleurs recommandés.",
      "clothingItems": "Short prompt in English for fashion image generation",
      "tags": ["Tag1", "Tag2", "Tag3"],
      "match": 95
    }}
  ]
}}
"""

    # 4. Inférence avec Cascade Failover
    llm_result = await llm_client.generate_recommendations(system_prompt, user_prompt)

    return {
        "recommendations": llm_result["data"].get("recommendations", []),
        "meta": {
            "provider": llm_result["provider"],
            "model": llm_result["model"],
            "latency_ms": llm_result["latency_ms"],
            "rag_rules_applied": [r["title"] for r in retrieved_rules],
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
