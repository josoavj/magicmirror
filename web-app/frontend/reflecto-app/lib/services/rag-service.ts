import fashionKnowledge from "@/data/knowledge/fashion_knowledge.json";

export interface StyleQueryContext {
  morphology?: string;
  skinTone?: string;
  weatherTemp?: number;
  weatherCondition?: string;
  events?: Array<{ title?: string; type?: string }>;
  gender?: string;
}

export interface KnowledgeItem {
  id: string;
  category: "morphology" | "colorimetry" | "weather" | "event";
  target: string;
  tags: string[];
  title: string;
  rules: string;
  score?: number;
}

/**
 * Normalizes input text for resilient fuzzy matching (lowercase, no accents).
 */
function normalize(str: string): string {
  return (str || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .trim();
}

/**
 * Fashion RAG Retrieval Engine.
 * Extracts the top relevant expert styling rules based on user context.
 */
export function retrieveFashionRules(context: StyleQueryContext, topK: number = 4): KnowledgeItem[] {
  const items: KnowledgeItem[] = fashionKnowledge as KnowledgeItem[];
  
  const normMorph = normalize(context.morphology || "");
  const normSkin = normalize(context.skinTone || "");
  const normWeatherCond = normalize(context.weatherCondition || "");
  const temp = context.weatherTemp;
  const eventsString = normalize((context.events || []).map(e => `${e.title || ""} ${e.type || ""}`).join(" "));

  const scoredItems = items.map((item) => {
    let score = 0;
    const normTarget = normalize(item.target);
    const normTitle = normalize(item.title);
    const normRules = normalize(item.rules);

    // 1. Morphology Matching
    if (item.category === "morphology") {
      if (normMorph && (normTarget.includes(normMorph) || normMorph.includes(normTarget))) {
        score += 10;
      }
      for (const tag of item.tags) {
        if (normMorph.includes(normalize(tag))) score += 5;
      }
    }

    // 2. Colorimetry & Skin tone Matching
    if (item.category === "colorimetry") {
      if (normSkin) {
        if (normSkin.includes("chaud") || normSkin.includes("warm") || normSkin.includes("dore") || normSkin.includes("gold")) {
          if (normTarget.includes("printemps") || normTarget.includes("automne")) score += 8;
        } else if (normSkin.includes("froid") || normSkin.includes("cool") || normSkin.includes("pale") || normSkin.includes("ebene")) {
          if (normTarget.includes("hiver") || normTarget.includes("ete")) score += 8;
        }
        for (const tag of item.tags) {
          if (normSkin.includes(normalize(tag))) score += 4;
        }
      }
    }

    // 3. Weather & Temperature Matching
    if (item.category === "weather") {
      if (temp !== undefined) {
        if (temp < 10 && item.id === "weather-cold") score += 10;
        else if (temp >= 10 && temp <= 25 && item.id === "weather-mild") score += 10;
        else if (temp > 25 && item.id === "weather-hot") score += 10;
      }
      if (normWeatherCond && (normWeatherCond.includes("rain") || normWeatherCond.includes("pluie") || normWeatherCond.includes("drizzle"))) {
        if (item.id === "weather-rain") score += 9;
      }
    }

    // 4. Event & Dress Code Matching
    if (item.category === "event") {
      if (eventsString) {
        for (const tag of item.tags) {
          if (eventsString.includes(normalize(tag))) {
            score += 7;
          }
        }
      } else if (item.id === "event-casual") {
        // Default when no event
        score += 3;
      }
    }

    return { ...item, score };
  });

  // Sort descending by score and pick topK with score > 0
  const results = scoredItems
    .filter(i => (i.score || 0) > 0)
    .sort((a, b) => (b.score || 0) - (a.score || 0))
    .slice(0, topK);

  // Fallback if no specific rule reached high score
  if (results.length === 0) {
    return items.slice(0, 3);
  }

  return results;
}

/**
 * Formats retrieved RAG knowledge rules into a clean context prompt block.
 */
export function formatRAGPromptContext(rules: KnowledgeItem[]): string {
  if (!rules || rules.length === 0) return "";

  const formattedRules = rules
    .map(r => `• [${r.title}] : ${r.rules}`)
    .join("\n");

  return `
---
📚 BASE DE CONNAISSANCES STYLISTIQUE RAG (RÈGLES EXPERTES À APPLIQUER OBLIGATOIREMENT) :
${formattedRules}
---`;
}
