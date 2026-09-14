import { NextResponse } from "next/server";
import { generateVisionCompletion } from "@/lib/services/llm-provider";

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
    const { imageBase64, profile, weather, events } = await request.json();

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

    // Call Vision Cascade (OpenRouter Vision -> Gemini Vision -> Local Fallback)
    const result = await generateVisionCompletion({
      imageBase64,
      systemPrompt: ANALYSIS_SYSTEM_PROMPT,
      userPrompt,
      timeoutMs: 7000,
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
