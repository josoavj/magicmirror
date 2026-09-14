import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

export async function POST(request: Request) {
  try {
    const { userId, imageUrl, name, description, clothingItems, tags, match, context } =
      await request.json();

    if (!userId || !imageUrl) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    // 1. Determine folder from context
    let folder = "casual";
    if (context) {
      const ctxLower = context.toLowerCase();
      if (
        ctxLower.includes("work") ||
        ctxLower.includes("travail") ||
        ctxLower.includes("meeting") ||
        ctxLower.includes("réunion")
      )
        folder = "work";
      else if (
        ctxLower.includes("event") ||
        ctxLower.includes("événement") ||
        ctxLower.includes("soirée") ||
        ctxLower.includes("dîner") ||
        ctxLower.includes("dinner")
      )
        folder = "event";
    }

    // 2. Fetch image from Pollinations with a fallback so it doesn't crash on 429 Timeout
    let buffer: Buffer | null = null;
    let publicUrl = imageUrl;

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      const imageRes = await fetch(imageUrl, { signal: controller.signal });
      clearTimeout(timeout);
      
      if (!imageRes.ok) {
         console.warn(`Image fetch warning: ${imageRes.status}. Using raw URL.`);
      } else {
         buffer = Buffer.from(await imageRes.arrayBuffer());
      }
    } catch (fetchErr: any) {
      console.warn("Image download failed (timeout). Using raw URL fallback:", fetchErr.message);
    }

    // 3. Upload to Supabase Storage if successful
    if (buffer) {
      const filename = `${userId}_${Date.now()}.png`;
      const storagePath = `outfits/${folder}/${filename}`;

      const { error: uploadError } = await supabaseAdmin
        .storage
        .from("reflecto-assets")
        .upload(storagePath, buffer, { contentType: "image/png", upsert: true });

      if (uploadError) {
        console.warn("Storage upload error, using raw URL:", uploadError.message);
      } else {
        const { data: { publicUrl: loadedUrl } } = supabaseAdmin
          .storage
          .from("reflecto-assets")
          .getPublicUrl(storagePath);
        publicUrl = loadedUrl;
      }
    }

    // 4. Proper Relational Insertion (outfits -> recommendations -> history)
    const matchVal = isNaN(Number(match)) ? 90 : Math.round(Number(match));

    // A. Insert Outfit
    const { data: outfitData, error: outfitError } = await supabaseAdmin
      .from("outfits")
      .insert({
         name: name || "Tenue générée",
         description: description || "",
         category: folder,
         // These require the user to have added the columns via SQL!
         image_url: publicUrl,
         clothing_items: clothingItems || "",
         tags: Array.isArray(tags) ? tags : []
      })
      .select()
      .single();

    if (outfitError) {
      console.error("Outfit Insert Error:", outfitError.message);
      return NextResponse.json({ success: false, error: "Database error. Please run the ALTER TABLE script." }, { status: 500 });
    }

    // B. Insert Recommendation
    const { data: recData, error: recError } = await supabaseAdmin
      .from("recommendations")
      .insert({
         user_id: userId,
         outfit_id: outfitData.id,
         context: context || folder,
         match_percentage: matchVal
      })
      .select()
      .single();

    if (recError) {
      console.error("Recommendation Insert Error:", recError.message);
      return NextResponse.json({ success: false, error: "Database error on recommendation." }, { status: 500 });
    }

    // C. Insert History Link
    const { data: histData, error: histError } = await supabaseAdmin
      .from("history")
      .insert({
         user_id: userId,
         recommendation_id: recData.id
      })
      .select()
      .single();

    if (histError) {
      console.error("History Insert Error:", histError.message);
      return NextResponse.json({ success: false, error: "Database error on history link." }, { status: 500 });
    }

    return NextResponse.json({ success: true, url: publicUrl, data: histData });
  } catch (error: any) {
    console.error("Save Outfit Fatal Error:", error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
