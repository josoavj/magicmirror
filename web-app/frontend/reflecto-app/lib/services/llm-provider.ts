import { analyzeImageBuffer } from "./pixel-analyzer";

export interface LLMMessage {
  role: "system" | "user" | "assistant";
  content: string | any[];
}

export interface CompletionOptions {
  messages: LLMMessage[];
  temperature?: number;
  maxTokens?: number;
  jsonMode?: boolean;
  timeoutMs?: number;
}

export interface VisionOptions {
  imageBase64: string;
  systemPrompt: string;
  userPrompt: string;
  timeoutMs?: number;
}

export interface LLMResponse {
  content: string;
  provider: "groq" | "openrouter" | "gemini" | "local_fallback";
  model: string;
  latencyMs: number;
}

/**
 * Resilient JSON extractor for LLM text responses.
 * Handles thought tokens (<think>...</think>), markdown fences, and embedded objects.
 */
export function extractJSON<T = any>(raw: string): T | null {
  if (!raw || typeof raw !== "string") return null;

  // 1. Strip reasoning thoughts (e.g. <think>...</think>)
  let cleaned = raw.replace(/<think>[\s\S]*?<\/think>/gi, "").trim();

  // 2. Direct parse
  try {
    return JSON.parse(cleaned);
  } catch {}

  // 3. Strip markdown fences (```json ... ```)
  const stripped = cleaned.replace(/```(?:json)?/gi, "").replace(/```/g, "").trim();
  try {
    return JSON.parse(stripped);
  } catch {}

  // 4. Find outer object {...}
  const firstObj = stripped.indexOf("{");
  const lastObj = stripped.lastIndexOf("}");
  if (firstObj !== -1 && lastObj > firstObj) {
    try {
      return JSON.parse(stripped.slice(firstObj, lastObj + 1).trim());
    } catch {}
  }

  // 5. Find outer array [...]
  const firstArr = stripped.indexOf("[");
  const lastArr = stripped.lastIndexOf("]");
  if (firstArr !== -1 && lastArr > firstArr) {
    try {
      return JSON.parse(stripped.slice(firstArr, lastArr + 1).trim());
    } catch {}
  }

  return null;
}

/**
 * Helper to execute a fetch with an explicit timeout.
 */
async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs: number = 5000): Promise<Response> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    throw error;
  }
}

// ==========================================
// PROVIDER 1: GROQ API
// ==========================================
async function callGroq(options: CompletionOptions): Promise<LLMResponse> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) throw new Error("GROQ_API_KEY not configured");

  const startTime = Date.now();
  // Models currently active on Groq Cloud
  const modelsToTry = [
    "openai/gpt-oss-20b",
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "deepseek-r1-distill-llama-70b",
    "gemma2-9b-it",
    "qwen-2.5-32b",
    "mixtral-8x7b-32768",
  ];

  let lastError = null;

  for (const model of modelsToTry) {
    try {
      const response = await fetchWithTimeout(
        "https://api.groq.com/openai/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: model,
            messages: options.messages,
            temperature: options.temperature ?? 0.7,
            max_tokens: options.maxTokens ?? 1000,
            response_format: options.jsonMode ? { type: "json_object" } : undefined,
          }),
        },
        options.timeoutMs || 4500
      );

      if (response.ok) {
        const data = await response.json();
        const content = data.choices[0]?.message?.content || "";
        console.log(`[LLMProvider] Groq completion succeeded with model: ${model}`);
        return {
          content,
          provider: "groq",
          model: model,
          latencyMs: Date.now() - startTime,
        };
      } else {
        const errText = await response.text();
        lastError = new Error(`Groq model ${model} returned ${response.status}: ${errText}`);
      }
    } catch (err: any) {
      lastError = err;
    }
  }

  throw lastError || new Error("All Groq models failed");
}

// ==========================================
// PROVIDER 2: OPENROUTER API
// ==========================================
async function callOpenRouter(options: CompletionOptions): Promise<LLMResponse> {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) throw new Error("OPENROUTER_API_KEY not configured");

  const startTime = Date.now();
  const modelsToTry = [
    "meta-llama/llama-3.3-70b-instruct:free",
    "meta-llama/llama-3.1-8b-instruct:free",
    "mistralai/mistral-7b-instruct:free",
    "google/gemini-2.0-flash-lite-preview-02-05:free",
    "google/gemini-2.0-flash-001",
    "openai/gpt-4o-mini",
  ];

  let lastError: any = null;

  for (const model of modelsToTry) {
    try {
      const response = await fetchWithTimeout(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
            "HTTP-Referer": process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
            "X-Title": "Reflecto Smart Mirror",
          },
          body: JSON.stringify({
            model: model,
            messages: options.messages,
            temperature: options.temperature ?? 0.7,
            max_tokens: options.maxTokens ?? 1000,
            response_format: options.jsonMode ? { type: "json_object" } : undefined,
          }),
        },
        options.timeoutMs || 5000
      );

      if (response.ok) {
        const data = await response.json();
        const content = data.choices[0]?.message?.content || "";
        console.log(`[LLMProvider] OpenRouter completion succeeded with model: ${model}`);
        return {
          content,
          provider: "openrouter",
          model: model,
          latencyMs: Date.now() - startTime,
        };
      } else {
        const errText = await response.text();
        lastError = new Error(`OpenRouter model ${model} returned ${response.status}: ${errText}`);
      }
    } catch (err: any) {
      lastError = err;
    }
  }

  throw lastError || new Error("All OpenRouter models failed");
}

// ==========================================
// PROVIDER 3: GOOGLE GEMINI DIRECT API
// ==========================================
async function callGemini(options: CompletionOptions): Promise<LLMResponse> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error("GEMINI_API_KEY not configured");

  const startTime = Date.now();
  const modelsToTry = ["gemini-1.5-flash", "gemini-2.0-flash"];

  let lastError: any = null;

  for (const model of modelsToTry) {
    try {
      const contents = options.messages
        .filter((m) => m.role !== "system")
        .map((m) => ({
          role: m.role === "assistant" ? "model" : "user",
          parts: [{ text: typeof m.content === "string" ? m.content : JSON.stringify(m.content) }],
        }));

      const systemMsg = options.messages.find((m) => m.role === "system");

      const response = await fetchWithTimeout(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents,
            systemInstruction: systemMsg ? { parts: [{ text: String(systemMsg.content) }] } : undefined,
            generationConfig: {
              temperature: options.temperature ?? 0.7,
              maxOutputTokens: options.maxTokens ?? 1000,
              responseMimeType: options.jsonMode ? "application/json" : "text/plain",
            },
          }),
        },
        options.timeoutMs || 5000
      );

      if (response.ok) {
        const data = await response.json();
        const content = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
        console.log(`[LLMProvider] Gemini completion succeeded with model: ${model}`);
        return {
          content,
          provider: "gemini",
          model: model,
          latencyMs: Date.now() - startTime,
        };
      } else {
        const errText = await response.text();
        lastError = new Error(`Gemini model ${model} returned ${response.status}: ${errText}`);
      }
    } catch (err: any) {
      lastError = err;
    }
  }

  throw lastError || new Error("All Gemini models failed");
}

// ==========================================
// PROVIDER 4: LOCAL DETERMINISTIC FALLBACK
// ==========================================
function getLocalFallbackResponse(options: CompletionOptions): LLMResponse {
  console.log("[LLMProvider] Using Local Deterministic Fallback Engine");
  const isJson = options.jsonMode;

  if (isJson) {
    const fallbackRecs = {
      recommendations: [
        {
          name: "Élégance Structurée",
          context: "Travail / Réunions",
          description: "Un blazer marine ajusté avec un pantalon beige. Les matières nobles et la coupe valorisent votre posture.",
          clothingItems: "navy tailored blazer with beige chinos and leather shoes",
          tags: ["Formel", "Élégant", "Coupe Optimale"],
          match: 94,
        },
        {
          name: "Harmonie Quotidienne",
          context: "Casual / Week-end",
          description: "Jean brut épuré avec chemise claire fluide pour un look frais et moderne.",
          clothingItems: "raw denim jeans with crisp white casual shirt",
          tags: ["Casual", "Frais", "Confort"],
          match: 88,
        },
        {
          name: "Soirée Signature",
          context: "Soirée & Dîner",
          description: "Costume sombre soigné avec contrastes subtils pour une allure charismatique.",
          clothingItems: "charcoal tailored suit with refined accessories",
          tags: ["Chic", "Prestige", "Soirée"],
          match: 92,
        },
      ],
    };
    return {
      content: JSON.stringify(fallbackRecs),
      provider: "local_fallback",
      model: "reflecto-rule-engine-v1",
      latencyMs: 15,
    };
  }

  return {
    content: "Pour sublimer votre tenue aujourd'hui, privilégiez des coupes harmonieuses et des matières adaptées à la saison. Les contrastes sobres valoriseront parfaitement votre silhouette.",
    provider: "local_fallback",
    model: "reflecto-rule-engine-v1",
    latencyMs: 10,
  };
}

// ==========================================
// UNIVERSAL CASCADING COMPLETION
// ==========================================
export async function generateCompletion(options: CompletionOptions): Promise<LLMResponse> {
  // 1. Groq (Ultra-fast)
  if (process.env.GROQ_API_KEY) {
    try {
      return await callGroq(options);
    } catch (err: any) {
      console.warn(`[LLMProvider] Groq failed, switching to OpenRouter: ${err.message}`);
    }
  }

  // 2. OpenRouter (Multi-model hub)
  if (process.env.OPENROUTER_API_KEY) {
    try {
      return await callOpenRouter(options);
    } catch (err: any) {
      console.warn(`[LLMProvider] OpenRouter failed, switching to Gemini: ${err.message}`);
    }
  }

  // 3. Google Gemini (High availability)
  if (process.env.GEMINI_API_KEY) {
    try {
      return await callGemini(options);
    } catch (err: any) {
      console.warn(`[LLMProvider] Gemini failed, switching to Local Fallback: ${err.message}`);
    }
  }

  // 4. Local Rule Fallback
  return getLocalFallbackResponse(options);
}

// ==========================================
// VISION CASCADE (Groq Vision -> OpenRouter Vision -> Gemini Vision -> Pixel Analyzer + Groq Synthesis)
// ==========================================
export async function generateVisionCompletion(options: VisionOptions): Promise<any> {
  const { imageBase64, systemPrompt, userPrompt } = options;
  const cleanBase64 = imageBase64.startsWith("data:") ? imageBase64 : `data:image/jpeg;base64,${imageBase64}`;
  const combinedPrompt = `${systemPrompt}\n\n${userPrompt}\n\nIMPORTANT: Tu DOIS répondre UNIQUEMENT avec un objet JSON valide (aucun texte avant ou après).`;

  // 1. Try Groq Vision Models (Ultra-fast)
  if (process.env.GROQ_API_KEY) {
    const groqVisionModels = [
      "llama-3.2-11b-vision-preview",
      "llama-3.2-90b-vision-preview",
    ];

    for (const model of groqVisionModels) {
      try {
        const response = await fetchWithTimeout(
          "https://api.groq.com/openai/v1/chat/completions",
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              model: model,
              messages: [
                {
                  role: "user",
                  content: [
                    { type: "image_url", image_url: { url: cleanBase64 } },
                    { type: "text", text: combinedPrompt },
                  ],
                },
              ],
              temperature: 0.2,
              max_tokens: 800,
              response_format: { type: "json_object" },
            }),
          },
          options.timeoutMs || 6000
        );

        if (response.ok) {
          const data = await response.json();
          const raw = data.choices[0]?.message?.content || "{}";
          const parsed = extractJSON(raw);
          if (parsed && (parsed.morphology || parsed.suggestions || parsed.skinTone)) {
            console.log(`[VisionProvider] Groq Vision analysis succeeded with model: ${model}`);
            return parsed;
          }
        } else {
          const errBody = await response.text();
          console.warn(`[VisionProvider] Groq Vision Model ${model} returned ${response.status}: ${errBody.slice(0, 100)}`);
        }
      } catch (e: any) {
        console.warn(`[VisionProvider] Groq Vision Model ${model} failed: ${e.message}`);
      }
    }
  }

  // 2. Try OpenRouter Vision (Multi-provider)
  if (process.env.OPENROUTER_API_KEY) {
    const visionModels = [
      "google/gemini-2.0-flash-001",
      "meta-llama/llama-3.2-11b-vision-instruct",
      "qwen/qwen-2.5-vl-72b-instruct",
      "mistralai/pixtral-12b",
      "openrouter/auto",
    ];

    for (const model of visionModels) {
      try {
        const response = await fetchWithTimeout(
          "https://openrouter.ai/api/v1/chat/completions",
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
              "Content-Type": "application/json",
              "HTTP-Referer": process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
              "X-Title": "Reflecto Smart Mirror Vision",
            },
            body: JSON.stringify({
              model: model,
              messages: [
                {
                  role: "user",
                  content: [
                    { type: "image_url", image_url: { url: cleanBase64 } },
                    { type: "text", text: combinedPrompt },
                  ],
                },
              ],
              temperature: 0.2,
              max_tokens: 800,
            }),
          },
          options.timeoutMs || 7000
        );

        if (response.ok) {
          const data = await response.json();
          const raw = data.choices[0]?.message?.content || "{}";
          const parsed = extractJSON(raw);
          if (parsed && (parsed.morphology || parsed.suggestions || parsed.skinTone)) {
            console.log(`[VisionProvider] OpenRouter Vision analysis succeeded with model: ${model}`);
            return parsed;
          }
        } else {
          const errBody = await response.text();
          console.warn(`[VisionProvider] OpenRouter Model ${model} returned ${response.status}: ${errBody.slice(0, 100)}`);
        }
      } catch (e: any) {
        console.warn(`[VisionProvider] OpenRouter Model ${model} failed: ${e.message}`);
      }
    }
  }

  // 3. Try Gemini Vision Direct
  if (process.env.GEMINI_API_KEY) {
    const directGeminiModels = ["gemini-1.5-flash", "gemini-2.0-flash"];
    const base64Data = cleanBase64.split(",")[1] || cleanBase64;
    const apiKey = process.env.GEMINI_API_KEY.trim();
    const isBearer = apiKey.startsWith("AQ.") || apiKey.startsWith("ya29.");

    for (const gModel of directGeminiModels) {
      try {
        const endpointUrl = isBearer
          ? `https://generativelanguage.googleapis.com/v1beta/models/${gModel}:generateContent`
          : `https://generativelanguage.googleapis.com/v1beta/models/${gModel}:generateContent?key=${apiKey}`;

        const headers: Record<string, string> = { "Content-Type": "application/json" };
        if (isBearer) {
          headers["Authorization"] = `Bearer ${apiKey}`;
        }

        const response = await fetchWithTimeout(
          endpointUrl,
          {
            method: "POST",
            headers,
            body: JSON.stringify({
              contents: [
                {
                  role: "user",
                  parts: [
                    { text: combinedPrompt },
                    { inlineData: { mimeType: "image/jpeg", data: base64Data } },
                  ],
                },
              ],
              generationConfig: {
                temperature: 0.2,
                maxOutputTokens: 800,
              },
            }),
          },
          options.timeoutMs || 7000
        );

        if (response.ok) {
          const data = await response.json();
          const raw = data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
          const parsed = extractJSON(raw);
          if (parsed && (parsed.morphology || parsed.suggestions || parsed.skinTone)) {
            console.log(`[VisionProvider] Gemini Vision Direct succeeded with model: ${gModel}`);
            return parsed;
          }
        }
      } catch (e: any) {
        console.warn(`[VisionProvider] Gemini Vision Direct ${gModel} failed: ${e.message}`);
      }
    }
  }

  // 4. Real Pixel Analysis + Groq LLM Stylist Synthesis
  console.log("[VisionProvider] Utilizing Real Pixel Analysis + Groq LLM Stylist Synthesis");
  const pixelProfile = analyzeImageBuffer(cleanBase64);

  // Use Groq to generate customized stylist suggestions in real time from pixel traits
  let liveSuggestion = `Posture élégante détectée. Votre silhouette ${pixelProfile.morphology} et votre carnation ${pixelProfile.skinTone} sont mises en valeur par vos tons actuels (${pixelProfile.currentOutfitColors.join(", ")}).`;

  try {
    const groqSynthesis = await generateCompletion({
      messages: [
        {
          role: "system",
          content: "Tu es Reflecto Style Assistant. Rédige en 2 phrases élégantes et percutantes en français un compliment de posture et un conseil de haute couture adapté à la silhouette et à la carnation données.",
        },
        {
          role: "user",
          content: `Profil détecté par analyse de l'image : Morphologie = ${pixelProfile.morphology}, Silhouette = ${pixelProfile.silhouette}, Carnation = ${pixelProfile.skinTone}, Couleurs des vêtements détectées = ${pixelProfile.currentOutfitColors.join(", ")}. Donne un conseil stylistique sur-mesure.`,
        },
      ],
      temperature: 0.7,
      maxTokens: 150,
      jsonMode: false,
      timeoutMs: 3500,
    });

    if (groqSynthesis && groqSynthesis.content && groqSynthesis.content.length > 20) {
      // Strip any reasoning tokens
      liveSuggestion = groqSynthesis.content.replace(/<think>[\s\S]*?<\/think>/gi, "").replace(/"/g, "").trim();
    }
  } catch (err: any) {
    console.warn("[VisionProvider] Groq synthesis fallback:", err.message);
  }

  return {
    gender: pixelProfile.gender,
    morphology: pixelProfile.morphology,
    silhouette: pixelProfile.silhouette,
    skinTone: pixelProfile.skinTone,
    fitzpatrickScale: pixelProfile.fitzpatrickScale,
    currentOutfitColors: pixelProfile.currentOutfitColors,
    confidence: pixelProfile.confidence,
    suggestions: liveSuggestion,
  };
}
