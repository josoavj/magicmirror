/**
 * Notification Service for Make.com (Integromat) Webhook Automation
 * Handles both Guest Lead Capture (outfit recap) and Authenticated User Daily Digest.
 */

export interface DailyDigestPayload {
  type: "daily_digest";
  user_email: string;
  user_name: string;
  weather: {
    temp: number;
    condition: string;
    advice?: string;
    location: string;
  };
  events: Array<{
    title: string;
    time?: string;
    type?: string;
  }>;
  recommended_outfit: {
    name: string;
    description: string;
    context: string;
    image_url: string;
    tags: string[];
    match: number;
  };
  sent_at: string;
}

export interface GuestWelcomePayload {
  type: "guest_welcome_and_recap";
  user_email: string;
  event_context: string;
  detected_profile: {
    gender: string;
    morphology: string;
    skin_tone: string;
    suggestions?: string;
  };
  weather: {
    temp: number;
    condition: string;
    location: string;
  };
  recommended_outfit: {
    name: string;
    description: string;
    image_url: string;
    tags?: string[];
    match: number;
  };
  sent_at: string;
}

export type NotificationPayload = DailyDigestPayload | GuestWelcomePayload;

/**
 * Validates standard email address syntax.
 */
export function isValidEmail(email: string): boolean {
  if (!email || typeof email !== "string") return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim());
}

/**
 * Sends notification payload to Make.com webhook via backend proxy.
 */
export async function sendNotificationWebhook(
  payload: NotificationPayload
): Promise<{ success: boolean; error?: string; status?: number }> {
  if (!payload.user_email || !isValidEmail(payload.user_email)) {
    return { success: false, error: "Adresse email invalide" };
  }

  try {
    const response = await fetch("/api/notifications/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      return { success: false, error: data.error || `Erreur HTTP ${response.status}`, status: response.status };
    }

    return { success: true, status: 200 };
  } catch (err: any) {
    console.error("[NotificationService] Webhook call failed:", err);
    return { success: false, error: err.message || "Erreur réseau lors de l'envoi" };
  }
}
