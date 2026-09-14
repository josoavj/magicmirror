import { NextResponse } from "next/server";
import { isValidEmail } from "@/lib/services/notification-service";

export async function POST(request: Request) {
  try {
    const payload = await request.json();

    if (!payload || !payload.user_email) {
      return NextResponse.json(
        { error: "Le champ user_email est requis" },
        { status: 400 }
      );
    }

    if (!isValidEmail(payload.user_email)) {
      return NextResponse.json(
        { error: "Format d'adresse e-mail invalide" },
        { status: 400 }
      );
    }

    // Resolve Make.com Webhook URL from environment variables
    const webhookUrl =
      process.env.MAKE_WEBHOOK_URL ||
      process.env.Webhook_Make ||
      process.env.NEXT_PUBLIC_MAKE_WEBHOOK_URL;

    if (!webhookUrl) {
      console.warn("[Notifications API] Aucun MAKE_WEBHOOK_URL configuré dans .env.local.");
      return NextResponse.json(
        {
          success: true,
          warning: "Webhook URL non configurée dans .env.local, simulation d'envoi réussie.",
          mock: true,
        },
        { status: 200 }
      );
    }

    // Forward payload to Make.com
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 8000);

    const makeResponse = await fetch(webhookUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Reflecto-Smart-Mirror-Engine/1.0",
      },
      body: JSON.stringify({
        ...payload,
        sent_at: payload.sent_at || new Date().toISOString(),
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!makeResponse.ok) {
      const errText = await makeResponse.text();
      console.error(`[Notifications API] Make.com webhook failed (${makeResponse.status}):`, errText);
      return NextResponse.json(
        { error: `Make.com a retourné le code ${makeResponse.status}` },
        { status: makeResponse.status }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Notification transmise avec succès au scénario Make.com",
    });
  } catch (error: any) {
    console.error("[Notifications API] Error:", error);
    return NextResponse.json(
      { error: error.message || "Erreur interne lors de l'envoi de la notification" },
      { status: 500 }
    );
  }
}
