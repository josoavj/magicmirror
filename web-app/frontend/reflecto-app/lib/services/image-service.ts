import type { Profile } from "@/hooks/useProfile";

export interface VisualContext {
  gender?: string;
  morphology?: string;
  body_type?: string;
  skinTone?: string;
  skin_tone?: string;
}

/**
 * Builds an enriched fashion prompt for Pollinations.AI.
 * Directly integrates real-time camera-detected traits (gender, morphology, skin tone).
 */
export function buildOutfitPrompt(
  outfitDescription: string,
  context?: VisualContext | Profile | null
): string {
  const genderRaw = (context as any)?.gender?.toLowerCase();
  const gender =
    genderRaw === "female" || genderRaw === "femme"
      ? "female high fashion model"
      : genderRaw === "male" || genderRaw === "homme"
      ? "male high fashion model"
      : "high fashion model";

  const bodyType = (context as any)?.morphology || (context as any)?.body_type || "balanced silhouette";
  const skinTone = (context as any)?.skinTone || (context as any)?.skin_tone || "natural skin complexion";

  const cleanDescription = (outfitDescription || "luxury outfit")
    .replace(/[^\w\s,-]/gi, "")
    .trim();

  return [
    `full body editorial fashion photography`,
    `${gender} wearing ${cleanDescription}`,
    `${bodyType} body shape`,
    `${skinTone} skin tone`,
    `vibrant high-end luxury editorial style`,
    `crisp details, 8k resolution, elegant studio lighting`,
    `clean minimalist studio background`,
  ].join(", ");
}

/**
 * Returns a Pollinations.AI URL for the given prompt.
 * Completely free, fast, no API key required.
 */
export function generateOutfitImageUrl(prompt: string, seed?: number): string {
  const encodedPrompt = encodeURIComponent(prompt);
  const seedParam = seed !== undefined ? `&seed=${seed}` : "";
  return `https://image.pollinations.ai/prompt/${encodedPrompt}?width=400&height=500&nologo=true${seedParam}`;
}

/**
 * Generates an outfit image URL from a description + detected visual context or user profile.
 */
export function getOutfitImage(
  description: string,
  context?: VisualContext | Profile | null,
  seed?: number
): string {
  const prompt = buildOutfitPrompt(description, context);
  return generateOutfitImageUrl(prompt, seed);
}
