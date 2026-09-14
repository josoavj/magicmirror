import { NextResponse } from "next/server";
import { generateCompletion } from "@/lib/services/llm-provider";

const SYSTEM_PROMPT = `Tu es "Reflecto Style Assistant", un consultant en image et styliste de mode bienveillant et branché, intégré dans un miroir intelligent connecté.

Tu donnes des conseils de mode concis, percutants et personnalisés selon les questions de l'utilisateur, la météo et son contexte.
Garde tes réponses courtes (2 à 4 phrases max), vivantes et élégantes. Évite les pavés de texte.

IMPORTANT : Tu DOIS répondre EXCLUSIVEMENT en Français (Français).`;

export async function POST(request: Request) {
  try {
    const { messages } = await request.json();

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: "Valid messages array is required" }, { status: 400 });
    }

    const payloadMessages = [
      { role: "system" as const, content: SYSTEM_PROMPT },
      ...messages.map((m: any) => ({
        role: (m.role === "user" || m.role === "assistant" ? m.role : "user") as "user" | "assistant",
        content: String(m.content || m.text || ""),
      })),
    ];

    const response = await generateCompletion({
      messages: payloadMessages,
      temperature: 0.7,
      maxTokens: 500,
      timeoutMs: 4500,
    });

    return NextResponse.json({
      text: response.content || "Je reste à votre entière disposition pour parfaire votre tenue !",
      meta: {
        provider: response.provider,
        model: response.model,
        latencyMs: response.latencyMs,
      },
    });
  } catch (error: any) {
    console.error("Chat API Error:", error);
    return NextResponse.json({
      text: "Je suis ravi de vous conseiller ! Pour aujourd'hui, privilégiez des coupes épurées et des matières confortables adaptées à votre journée.",
    });
  }
}
