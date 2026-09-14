import { NextResponse } from "next/server";
import { retrieveFashionRules, formatRAGPromptContext } from "@/lib/services/rag-service";
import { generateCompletion, extractJSON } from "@/lib/services/llm-provider";

const RECOMMENDATIONS_SYSTEM_PROMPT = `Tu es "Reflecto Style Assistant", un expert consultant en mode haute couture et styliste personnel intégré dans une application de miroir intelligent.

Étant donné le profil d'un utilisateur, leur contexte actuel (météo, agenda du jour), l'analyse de leur tenue actuelle par caméra, ET les règles stylistiques RAG fournies, génère EXACTEMENT 3 suggestions de tenues CRÉATIVES, DISTINCTES ET ORIGINALES.

RÈGLE D'OR POUR L'AGENDA :
Si l'utilisateur a des événements dans son agenda, tu DOIS attribuer tes suggestions à ces événements. La valeur "context" DOIT être le titre exact de l'événement. S'il n'y a qu'un événement, génère une tenue pour cet événement, et les deux autres pour "Casual / Quotidien" ou "Soirée". S'il y a 3 événements, attache une tenue par événement. Il faut QUOI QU'IL ARRIVE 3 tenues !

RÈGLE ABSOLUE POUR LES RÈGLES RAG :
Tu DOIS appliquer rigoureusement les règles de coupe, de matières et de colorimétrie extraites de la base de connaissances RAG.

RÈGLE DE LANGUE :
Tu DOIS répondre UNIQUEMENT en français pour toutes les descriptions et noms de tenue. Seul le champ "clothingItems" doit être en anglais.

Format JSON attendu (strictement cet objet, aucun texte avant ou après) :
{
  "recommendations": [
    {
      "name": "Nom créatif en français (ex: Élégance Solaire)",
      "context": "TITRE EXACT DE L'ÉVÉNEMENT ou l'occasion",
      "description": "1-2 phrases détaillant les pièces, tissus et harmonies de couleurs selon la morphologie et le teint.",
      "clothingItems": "Courte description descriptive EN ANGLAIS pour génération de photo de mode (ex: tailored charcoal suit with sky blue silk tie)",
      "tags": ["Tag1", "Tag2", "Tag3"],
      "match": 92
    }
  ]
}`;

export async function POST(request: Request) {
  try {
    const requestBody = await request.json();
    const { profile, weather, events, cameraAnalysis } = requestBody;

    // OPTION A : Tentative d'appel au Microservice Python FastAPI s'il est configuré/actif
    const fastApiUrl = process.env.FASTAPI_BACKEND_URL || "http://127.0.0.1:8000";
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000); // 8s max pour FastAPI
      console.log(`[Next.js API] 🚀 Appel du Microservice Python FastAPI sur ${fastApiUrl}/api/v1/recommendations...`);
      const fastApiRes = await fetch(`${fastApiUrl}/api/v1/recommendations`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      if (fastApiRes.ok) {
        const fastApiData = await fastApiRes.json();
        console.log(`[Next.js API] ✅ Réponse reçue avec succès du backend Python FastAPI !`);
        if (fastApiData && Array.isArray(fastApiData.recommendations) && fastApiData.recommendations.length > 0) {
          return NextResponse.json(fastApiData);
        }
      } else {
        console.warn(`[Next.js API] ⚠️ FastAPI Python a répondu avec code ${fastApiRes.status}`);
      }
    } catch (fastApiErr: any) {
      console.warn(`[Next.js API] ℹ️ FastAPI Python non joignable (${fastApiErr.message}), exécution de la cascade RAG interne.`);
    }

    // OPTION B : Exécution RAG & Cascade Multi-LLM Interne (Groq -> OpenRouter -> Gemini -> Local)
    
    // 1. RAG Retrieval Engine: Extract relevant style & colorimetry rules
    const ragRules = retrieveFashionRules({
      morphology: cameraAnalysis?.morphology || profile?.body_type,
      skinTone: cameraAnalysis?.skinTone || profile?.skin_tone,
      weatherTemp: weather?.temp,
      weatherCondition: weather?.condition,
      events: events,
      gender: profile?.gender,
    }, 4);

    const ragContextPrompt = formatRAGPromptContext(ragRules);

    // 2. Build User & Contextual Prompts
    const profileContext = profile ? `
Profil utilisateur :
- Prénom : ${profile.first_name || "Inconnu"}
- Âge : ${profile.age || "Non précisé"}
- Genre : ${profile.gender || "Non précisé"}
- Morphologie déclarée : ${profile.body_type || "H-Shape"}
- Teint déclaré : ${profile.skin_tone || "Warm"}
- Style préféré : ${profile.style_preference || "Casual"}
` : "Profil utilisateur : Mode Invité / Non renseigné.";

    const weatherContext = weather
      ? `Météo actuelle : ${weather.temp}°C, ${weather.condition} à ${weather.location || "Antananarivo"}`
      : "Météo : Non renseignée.";

    const eventsContext = events && events.length > 0
      ? `Événements au programme aujourd'hui : ${events.map((e: any) => `${e.title || "Événement"} (${e.type || "Général"})`).join(", ")}`
      : "Aucun événement prévu — Journée libre.";

    const cameraContext = cameraAnalysis ? `
Analyse visuelle Caméra (Temps Réel) :
- Morphologie observée : ${cameraAnalysis.morphology || "H-Shape"}
- Silhouette : ${cameraAnalysis.silhouette || "Équilibrée"}
- Teint détecté : ${cameraAnalysis.skinTone || "Warm"}
- Conseils caméra : ${cameraAnalysis.suggestions || ""}
` : "";

    const userPrompt = `
Génère 3 suggestions de tenues vestimentaires haut de gamme pour cette personne.

${profileContext}
${weatherContext}
${eventsContext}
${cameraContext}
${ragContextPrompt}

Réponds UNIQUEMENT avec l'objet JSON contenant la clé "recommendations" avec exactement 3 tenues.`;

    // 3. Call Universal LLM Provider with Cascading Failover (Groq -> OpenRouter -> Gemini -> Local)
    const llmResponse = await generateCompletion({
      messages: [
        { role: "system", content: RECOMMENDATIONS_SYSTEM_PROMPT },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.7,
      maxTokens: 1200,
      jsonMode: true,
      timeoutMs: 5000,
    });

    // 4. Parse & Validate JSON
    const parsed = extractJSON<any>(llmResponse.content);
    let recommendations = parsed?.recommendations || parsed?.outfits || parsed?.tenues || parsed?.suggestions || parsed?.items;

    if (!Array.isArray(recommendations) || recommendations.length === 0) {
      if (Array.isArray(parsed)) {
        recommendations = parsed;
      } else {
        console.warn("[Recommendations] Could not parse recommendations from LLM response. Raw content was:", llmResponse.content.slice(0, 300));
        recommendations = [
          {
            name: "Élégance Structurée",
            context: events?.[0]?.title || "Travail / Réunions",
            description: "Un blazer marine ajusté avec un pantalon beige. Les matières nobles et la coupe valorisent votre posture.",
            clothingItems: "navy tailored blazer with beige chinos and leather shoes",
            tags: ["Formel", "Élégant", "Coupe Optimale"],
            match: 94,
          },
          {
            name: "Harmonie Quotidienne",
            context: events?.[1]?.title || "Casual / Week-end",
            description: "Jean brut épuré avec chemise claire fluide pour un look frais et moderne.",
            clothingItems: "raw denim jeans with crisp white casual shirt",
            tags: ["Casual", "Frais", "Confort"],
            match: 88,
          },
          {
            name: "Soirée Signature",
            context: events?.[2]?.title || "Soirée & Dîner",
            description: "Costume sombre soigné avec contrastes subtils pour une allure charismatique.",
            clothingItems: "charcoal tailored suit with refined accessories",
            tags: ["Chic", "Prestige", "Soirée"],
            match: 92,
          },
        ];
      }
    }

    return NextResponse.json({
      recommendations,
      meta: {
        provider: llmResponse.provider,
        model: llmResponse.model,
        latencyMs: llmResponse.latencyMs,
        ragRulesApplied: ragRules.map(r => r.title),
      },
    });
  } catch (error: any) {
    console.error("Recommendations API Error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
