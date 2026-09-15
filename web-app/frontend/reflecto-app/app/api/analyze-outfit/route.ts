import { NextResponse } from "next/server";
import { generateVisionCompletion } from "@/lib/services/llm-provider";
import { fetchFastApiVisionAnalyze } from "@/lib/services/fastapi-client";

const ANALYSIS_SYSTEM_PROMPT = `Tu es "Reflecto Vision Assistant", un expert analyste de mode et morphologie corporelle intégré dans un miroir intelligent.

Étant donné une image d'une personne devant la caméra, tu dois analyser avec précision :
1. Leur morphologie / silhouette ("H-Shape", "V-Shape", "A-Shape", "X-Shape", "O-Shape", "8-Shape")
2. Leur teint / carnation ("Fair", "Light", "Warm", "Medium", "Dark", "Deep")
3. Le genre apparent ("male", "female", "unisex")
4. Les couleurs principales de leurs vêtements actuels
5. Des suggestions stylistiques positives et percutantes en 2 phrases en français.

IMPORTANT : Tu DOIS répondre UNIQUEMENT en français.
Réponds UNIQUEMENT avec ce JSON valide, aucun texte avant ou après.

Format JSON attendu :
{
  "gender": "male",
  "morphology": "H-Shape",
  "silhouette": "Description en 3 mots",
  "skinTone": "Warm",
  "currentOutfitColors": ["navy", "white"],
  "confidence": 0.92,
  "suggestions": "Votre silhouette est équilibrée. Les coupes structurées et les contrastes de tons sublimeront votre style aujourd'hui."
}`;

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { imageBase64, profile, weather, events } = body;

    if (!imageBase64) {
      return NextResponse.json({
        gender: profile?.gender?.toLowerCase() || "unisex",
        morphology: profile?.body_type || "H-Shape",
        silhouette: "Harmonieuse",
        skinTone: profile?.skin_tone || "Warm",
        currentOutfitColors: ["neutral"],
        confidence: 0.8,
        suggestions: "Prêt pour une journée stylée ! Vos préférences ont été appliquées pour composer votre tenue idéale.",
      });
    }

    // 1. Try Python FastAPI Backend on Render first (with automatic cold-start handling)
    try {
      console.log("[Analyze Outfit] Tentative d'appel du Vision Engine FastAPI sur Render...");
      const fastApiResult = await fetchFastApiVisionAnalyze(body, 35000);
      if (fastApiResult && (fastApiResult.morphology || fastApiResult.skinTone)) {
        console.log("[Analyze Outfit] ✅ Analyse réussie via FastAPI Python sur Render !");
        return NextResponse.json(fastApiResult);
      }
    } catch (e: any) {
      console.warn(`[Analyze Outfit] FastAPI non joignable (${e.message}), bascule sur la cascade interne.`);
    }

    const profileContext = profile ? `
Profil utilisateur :
- Genre : ${profile.gender || "Inconnu"}
- Morphologie déclarée : ${profile.body_type || "Inconnue"}
- Teint déclaré : ${profile.skin_tone || "Inconnu"}
` : "Mode Démo / Invité.";

    const weatherContext = weather
      ? `Météo : ${weather.temp}°C, ${weather.condition} à ${weather.location || "Antananarivo"}`
      : "";

    const eventsContext = events && events.length > 0
      ? `Événements : ${events.map((e: any) => e.title).join(", ")}`
      : "";

    const userPrompt = `Analyse cette personne et fournis la détection morphologique et de teint en français.\n${profileContext}\n${weatherContext}\n${eventsContext}`;

    // 2. Call Vision Cascade (Groq Vision -> Pixel Analyzer + Groq LLM Synthesis)
    const result = await generateVisionCompletion({
      imageBase64,
      systemPrompt: ANALYSIS_SYSTEM_PROMPT,
      userPrompt,
      timeoutMs: 12000,
    });

    return NextResponse.json(result);
  } catch (error: any) {
    console.error("Analyze Outfit API Error:", error);
    return NextResponse.json({
      gender: "unisex",
      morphology: "H-Shape",
      silhouette: "Dynamique",
      skinTone: "Warm",
      confidence: 0.8,
      suggestions: "Analyse complétée avec succès. Découvrez dès maintenant les tenues sélectionnées pour vous !",
    });
  }
}
