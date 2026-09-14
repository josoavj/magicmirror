import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { retrieveFashionRules, formatRAGPromptContext } from "@/lib/services/rag-service";
import { generateCompletion, extractJSON } from "@/lib/services/llm-provider";
import { getOutfitImage } from "@/lib/services/image-service";

export async function GET(request: Request) {
  try {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseServiceKey) {
      return NextResponse.json({ error: "Supabase credentials missing" }, { status: 500 });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const today = new Date().toISOString().split("T")[0];

    // 1. Fetch profiles with valid emails
    const { data: profiles, error: profError } = await supabase
      .from("profiles")
      .select("*")
      .limit(50);

    if (profError || !profiles || profiles.length === 0) {
      return NextResponse.json({ message: "Aucun utilisateur à notifier", count: 0 });
    }

    // Default Weather
    const defaultWeather = {
      temp: 24,
      condition: "Ensoleillé",
      advice: "Météo agréable idéale pour des cotons légers et des blazers fluides.",
      location: "Antananarivo",
    };

    let sentCount = 0;
    const webhookUrl =
      process.env.MAKE_WEBHOOK_URL ||
      process.env.Webhook_Make ||
      process.env.NEXT_PUBLIC_MAKE_WEBHOOK_URL;

    for (const profile of profiles) {
      if (!profile.user_id) continue;

      // 2. Fetch user's email from auth or profile
      let userEmail = profile.email;
      if (!userEmail) {
        const { data: authUser } = await supabase.auth.admin.getUserById(profile.user_id);
        userEmail = authUser?.user?.email;
      }

      if (!userEmail) continue;

      // 3. Fetch today's events
      const { data: events } = await supabase
        .from("events")
        .select("*")
        .eq("user_id", profile.user_id)
        .gte("start_time", `${today}T00:00:00`)
        .lte("start_time", `${today}T23:59:59`);

      const userEvents = (events || []).map((e: any) => ({
        title: e.title || "Rendez-vous",
        time: e.start_time ? e.start_time.split("T")[1]?.slice(0, 5) : "09:00",
        type: e.type || "Général",
      }));

      // 4. Retrieve RAG rules
      const ragRules = retrieveFashionRules({
        morphology: profile.body_type,
        skinTone: profile.skin_tone,
        weatherTemp: defaultWeather.temp,
        weatherCondition: defaultWeather.condition,
        events: userEvents,
        gender: profile.gender,
      }, 3);

      const topEventTitle = userEvents[0]?.title || "Journée Active & Élégance";

      const outfitName = `Look Signature - ${topEventTitle}`;
      const outfitDesc = `Composé spécialement pour votre silhouette ${profile.body_type || "équilibrée"} et vos rendez-vous du jour. Tissus respirants et finitions raffinées.`;
      const clothingDesc = `${profile.gender === "Female" ? "women" : "men"} tailored smart elegant outfit with minimalist premium accessories`;

      const imageUrl = getOutfitImage(clothingDesc, profile, 42);

      const payload = {
        type: "daily_digest" as const,
        user_email: userEmail,
        user_name: profile.first_name || "Membre Reflecto",
        weather: defaultWeather,
        events: userEvents,
        recommended_outfit: {
          name: outfitName,
          description: outfitDesc,
          context: topEventTitle,
          image_url: imageUrl,
          tags: ["Sur-Mesure", "RAG Actif", "Haute Couture"],
          match: 95,
        },
        sent_at: new Date().toISOString(),
      };

      if (webhookUrl) {
        try {
          console.log(`[Cron Daily Digest] Envoi payload vers Make.com (${webhookUrl}) pour ${userEmail}...`);
          const res = await fetch(webhookUrl, {
            method: "POST",
            headers: { 
              "Content-Type": "application/json",
              "User-Agent": "Reflecto-Smart-Mirror-Engine/1.0"
            },
            body: JSON.stringify(payload),
          });
          const resText = await res.text();
          console.log(`[Cron Daily Digest] Make.com response (${res.status}):`, resText);
          if (res.ok) {
            sentCount++;
          } else {
            console.warn(`[Cron Daily Digest] Make.com retourné code ${res.status}: ${resText}`);
          }
        } catch (e: any) {
          console.warn(`[Cron Daily Digest] Failed for ${userEmail}:`, e.message);
        }
      } else {
        console.warn("[Cron Daily Digest] Aucun webhookUrl défini (MAKE_WEBHOOK_URL ou Webhook_Make).");
      }
    }

    return NextResponse.json({
      success: true,
      message: `Daily digest traité pour ${sentCount} utilisateur(s).`,
      count: sentCount,
      webhookConfigured: !!webhookUrl,
    });
  } catch (error: any) {
    console.error("[Cron Daily Digest] Error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
