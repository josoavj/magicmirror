"use client";

import { useState, useEffect, useRef } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import {
  Sparkles, Volume2, VolumeX, ArrowLeft, Heart, Share2, Tag,
  Calendar, MapPin, RefreshCcw, Loader2, ImageOff, Check,
  Layers, Sun, UserCheck, Activity,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { createClient } from "@/lib/supabase/client";
import { getOutfitImage } from "@/lib/services/image-service";
import type { Profile } from "@/hooks/useProfile";

interface Recommendation {
  name: string;
  context: string;
  description: string;
  clothingItems: string;
  tags: string[];
  match: number;
  imageUrl?: string;
  fromHistory?: boolean; // true if loaded from saved DB
}

interface RecommendationsClientProps {
  weather: { temp: number; condition: string };
  date: string;
  eventContext?: string;
}

export const RecommendationsClient = ({ weather, date, eventContext }: RecommendationsClientProps) => {
  const [activeTab, setActiveTab] = useState("all");
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [likedIds, setLikedIds] = useState<Set<number>>(new Set());
  const [source, setSource] = useState<"history" | "generated">("history");
  const [imageLoaded, setImageLoaded] = useState<Record<number, boolean>>({});
  const [imageSaving, setImageSaving] = useState<Record<number, boolean>>({});
  const [metaInfo, setMetaInfo] = useState<any>(null);
  const [detectedAttrs, setDetectedAttrs] = useState<any>(null);
  const hasSaved = useRef(false);

  useEffect(() => {
    async function loadRecommendations() {
      setIsLoading(true);
      hasSaved.current = false;
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();

      let prof: Profile | null = null;

      if (user) {
        const { data } = await supabase.from("profiles").select("*").eq("user_id", user.id).single();
        prof = data;
        setProfile(data);

        // Check if we just came from the camera page with a flush analysis
        const SESSION_KEY = `reflecto_recs_${new Date().toISOString().split("T")[0]}`;
        const cached = typeof window !== "undefined" ? sessionStorage.getItem(SESSION_KEY) : null;
        const cameraAnalysisRaw = typeof window !== "undefined" ? sessionStorage.getItem("reflecto_camera_analysis") : null;
        const hasNewCameraAnalysis = cameraAnalysisRaw && !cached;

        if (!hasNewCameraAnalysis) {
          // 1. Try to load today's saved recommendations from history
          const { data: historyRows, error: histErr } = await supabase
            .from("history")
            .select(`
              id, viewed_at,
              recommendations (
                 context, match_percentage,
                 outfits (
                    name, description, image_url, clothing_items, tags
                 )
              )
            `)
            .eq("user_id", user.id)
            .limit(9);
          
          if (!histErr && historyRows && historyRows.length > 0) {
          // Relies on sorted response, just take latest 3 valid rows
          const validRows = (historyRows as any[]).filter(r => {
            const rec = Array.isArray(r.recommendations) ? r.recommendations[0] : r.recommendations;
            const out = rec ? (Array.isArray(rec.outfits) ? rec.outfits[0] : rec.outfits) : null;
            return rec && out;
          });
          
          const fromDb: Recommendation[] = validRows.slice(0, 3).map((row: any) => {
            const rec = Array.isArray(row.recommendations) ? row.recommendations[0] : row.recommendations;
            const out = Array.isArray(rec.outfits) ? rec.outfits[0] : rec.outfits;
            return {
              name: out.name,
              context: rec.context,
              description: out.description,
              clothingItems: out.clothing_items || "",
              tags: Array.isArray(out.tags) ? out.tags : [],
              match: rec.match_percentage || 90,
              imageUrl: out.image_url,
              fromHistory: true,
            };
          });
          setRecommendations(fromDb);
          setSource("history");
          setIsLoading(false);
          return;
        }
      }
      }

      // 2. No history → check sessionStorage to avoid re-generating on every page visit
      const SESSION_KEY = `reflecto_recs_${new Date().toISOString().split("T")[0]}`;
      const cached = typeof window !== "undefined" ? sessionStorage.getItem(SESSION_KEY) : null;
      if (cached) {
        try {
          const parsed = JSON.parse(cached);
          setRecommendations(parsed);
          setSource("history");
          setIsLoading(false);
          return;
        } catch {}
      }

      // 3. Generate fresh via LLM
      try {
        const today = new Date().toISOString().split("T")[0];
        let events: any[] = [];
        if (user) {
          const supabase2 = createClient();
          const { data: evts } = await supabase2
            .from("events").select("*").eq("user_id", user.id)
            .gte("start_time", `${today}T00:00:00`);
          events = evts || [];
        }

        const cameraAnalysisRaw = typeof window !== "undefined" ? sessionStorage.getItem("reflecto_camera_analysis") : null;
        let cameraAnalysis = null;
        try { 
          if (cameraAnalysisRaw) {
            cameraAnalysis = JSON.parse(cameraAnalysisRaw);
            setDetectedAttrs(cameraAnalysis);
          }
        } catch {}

        // Enforce restriction: Only auto-generate NEW suggestions if we just analyzed
        if (!cameraAnalysisRaw) {
           setRecommendations([]);
           setSource("history");
           setIsLoading(false);
           return;
        }

        const res = await fetch("/api/recommendations", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ profile: prof, weather, events, cameraAnalysis }),
        });

        if (!res.ok) throw new Error("API error");
        const data = await res.json();
        const recs = data.recommendations || [];
        if (data.meta) setMetaInfo(data.meta);

        const visualContext = { ...prof, ...cameraAnalysis };

        const withImages = recs.map((r: Recommendation, i: number) => ({
          ...r,
          imageUrl: getOutfitImage(r.clothingItems || r.name, visualContext, i * 42 + 7),
          fromHistory: false,
        }));

        setRecommendations(withImages);
        setSource("generated");
        // Cache in sessionStorage to avoid re-generating on page revisit
        try {
          const SESSION_KEY = `reflecto_recs_${new Date().toISOString().split("T")[0]}`;
          sessionStorage.setItem(SESSION_KEY, JSON.stringify(withImages));
        } catch {}
      } catch (err) {
        console.error("Failed to load recommendations:", err);
        const visualContext = { ...prof, ...cameraAnalysis };
        // Fallback to static
        setRecommendations([
          {
            name: "Élégance Corporate",
            context: "Travail / Réunions",
            description: "Un blazer marine ajusté avec un pantalon beige — tons chaleureux qui mettent en valeur votre carnation.",
            clothingItems: "navy tailored blazer with beige chinos and gold accessories",
            tags: ["Formel", "Élégant", "Tons chauds"],
            match: 96,
            imageUrl: getOutfitImage("navy tailored blazer with beige chinos", visualContext, 7),
            fromHistory: false,
          },
          {
            name: "Explorateur Urbain",
            context: "Casual / Week-end",
            description: "Jean léger avec une chemise cyan structurée pour un look frais et moderne.",
            clothingItems: "light denim jeans with structured cyan casual shirt",
            tags: ["Casual", "Frais", "Extérieur"],
            match: 85,
            imageUrl: getOutfitImage("light denim jeans with cyan shirt", visualContext, 49),
            fromHistory: false,
          },
          {
            name: "Soirée Gala Noir",
            context: "Événements / Dîner",
            description: "Costume anthracite avec un mouchoir de poche en soie dorée. Élégance haut contraste pour les grandes occasions.",
            clothingItems: "charcoal suit with gold pocket square",
            tags: ["Luxe", "Soirée", "Formel"],
            match: 91,
            imageUrl: getOutfitImage("charcoal suit with gold pocket square", visualContext, 2),
            fromHistory: false,
          },
        ]);
        setSource("generated");
      } finally {
        setIsLoading(false);
      }
    }
    loadRecommendations();
  }, [weather]);

  // Save generated recommendations to history, one at a time.
  // Updates each card's imageUrl with the Supabase Storage URL when ready (fast + reliable).
  useEffect(() => {
    if (!isLoading && recommendations.length > 0 && profile?.user_id && source === "generated" && !hasSaved.current) {
      hasSaved.current = true;
      const saveAll = async () => {
        for (let i = 0; i < recommendations.length; i++) {
          const rec = recommendations[i];
          if (rec.fromHistory) continue; // already saved

          setImageSaving((prev) => ({ ...prev, [i]: true }));
          try {
            const res = await fetch("/api/save-outfit", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                userId: profile.user_id,
                imageUrl: rec.imageUrl,
                name: rec.name,
                context: rec.context,
                description: rec.description,
                clothingItems: rec.clothingItems,
                tags: rec.tags,
                match: rec.match,
              }),
            });
            const data = await res.json();
            if (data.url) {
              // Replace Pollinations URL with Supabase Storage URL (fast, always available)
              setRecommendations((prev) =>
                prev.map((r, idx) => idx === i ? { ...r, imageUrl: data.url } : r)
              );
              setImageLoaded((prev) => ({ ...prev, [i]: true }));
            }
          } catch (err) {
            console.error(`Failed to save/load image for rec ${i}:`, err);
          } finally {
            setImageSaving((prev) => ({ ...prev, [i]: false }));
          }
        }
      };
      saveAll();
    }
  }, [isLoading, recommendations.length, profile?.user_id, source]);

  const filteredRecs = recommendations.filter((r) => {
    if (eventContext) {
       return r.context.toLowerCase().includes(eventContext.toLowerCase());
    }
    if (activeTab === "all") return true;
    return r.context.toLowerCase().includes(activeTab) ||
      r.tags.some((t) => t.toLowerCase().includes(activeTab));
  });

  const speakAll = () => {
    if (!("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();

    const rawText = recommendations
      .map((r, i) => `Suggestion ${i + 1}: ${r.name}. ${r.description}`)
      .join(". ");

    const utterance = new SpeechSynthesisUtterance(rawText);
    utterance.lang = "fr-FR";
    utterance.rate = 0.95;
    utterance.pitch = 1.05;
    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);

    // Chercher une voix française naturelle
    const voices = window.speechSynthesis.getVoices();
    const preferred =
      voices.find(
        (v) =>
          v.lang === "fr-FR" &&
          (v.name.includes("Thomas") ||
            v.name.includes("Amelie") ||
            v.name.includes("Google français") ||
            v.name.includes("Microsoft Paul") ||
            v.name.includes("Microsoft Hortense") ||
            v.name.includes("Microsoft Julie"))
      ) ||
      voices.find((v) => v.lang === "fr-FR") ||
      voices.find((v) => v.lang.startsWith("fr"));
    if (preferred) utterance.voice = preferred;
    window.speechSynthesis.speak(utterance);
  };

  const stopSpeech = () => {
    window.speechSynthesis.cancel();
    setIsSpeaking(false);
  };

  return (
    <div className="space-y-6 md:space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <button
            onClick={() => window.history.back()}
            className="flex items-center gap-2 text-slate hover:text-gold transition-colors mb-3 md:mb-4 group text-sm"
          >
            <ArrowLeft size={16} className="group-hover:-translate-x-1 transition-transform" />
            Back to analysis
          </button>
          <h1 className="text-2xl md:text-4xl font-bold text-beige mb-1 md:mb-2">
            Reflecto Suggestions
          </h1>
          <p className="text-slate text-sm md:text-lg">
            Looks personnalisés selon votre{" "}
            <strong>{profile?.body_type || "silhouette"}</strong> et votre{" "}
            <strong>{profile?.skin_tone || "teint"}</strong>.
          </p>
          {detectedAttrs && (
            <div className="flex flex-wrap items-center gap-2 mt-2">
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-gold/15 text-gold border border-gold/30 flex items-center gap-1">
                <Layers size={12} /> Morphologie : <strong>{detectedAttrs.morphology || "H-Shape"}</strong>
              </span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-cyan-electric/15 text-cyan-electric border border-cyan-electric/30 flex items-center gap-1">
                <Sun size={12} /> Teint : <strong>{detectedAttrs.skinTone || "Warm"}</strong>
              </span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 flex items-center gap-1">
                <UserCheck size={12} /> Genre : <strong>{detectedAttrs.gender === "female" ? "Femme" : detectedAttrs.gender === "male" ? "Homme" : "Unisexe"}</strong>
              </span>
            </div>
          )}

          {metaInfo && (
            <div className="flex flex-wrap items-center gap-2 mt-2">
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-white/10 text-slate-light border border-white/10 flex items-center gap-1">
                <Sparkles size={12} className="text-gold" /> RAG Actif ({metaInfo.provider || "Groq"} • {metaInfo.latencyMs || metaInfo.latency_ms || 320}ms)
              </span>
              {(metaInfo.ragRulesApplied || metaInfo.rag_rules_applied || []).map((rule: string, rIdx: number) => (
                <span key={rIdx} className="px-2 py-0.5 rounded-md text-[11px] bg-white/5 text-slate border border-white/10">
                  {rule}
                </span>
              ))}
            </div>
          )}
          {source === "history" && (
            <p className="text-xs text-cyan-electric/80 mt-1 flex items-center gap-1">
              <Check size={12} /> Suggestions du jour (sauvegardées)
            </p>
          )}
        </div>
        <div className="flex gap-3">
          <button
            onClick={isSpeaking ? stopSpeech : speakAll}
            className={`p-3 md:p-4 rounded-full transition-all ${
              isSpeaking
                ? "bg-red-400/10 border border-red-400/30 text-red-400"
                : "glass-gold text-gold hover:scale-110"
            }`}
            title={isSpeaking ? "Stop" : "Écouter les suggestions"}
          >
            {isSpeaking ? <VolumeX size={20} /> : <Volume2 size={20} />}
          </button>
          <button
            onClick={() => { 
                setRecommendations([]); 
                setIsLoading(true); 
                if (typeof window !== "undefined") {
                   sessionStorage.removeItem(`reflecto_recs_${new Date().toISOString().split("T")[0]}`);
                   sessionStorage.removeItem("reflecto_camera_analysis");
                }
                window.location.reload(); 
            }}
            className="p-3 md:p-4 glass rounded-full text-slate hover:text-gold hover:scale-110 transition-all"
            title="Régénérer les suggestions"
          >
            <RefreshCcw size={20} />
          </button>
        </div>
      </header>

      {/* Context Chips */}
      <div className="flex flex-wrap gap-2 md:gap-4 items-center">
        <div className="flex items-center gap-2 px-4 py-2 bg-navy/50 border border-white/5 rounded-full text-sm">
          <Calendar size={14} className="text-gold" />
          <span>{date}</span>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-navy/50 border border-white/5 rounded-full text-sm">
          <MapPin size={14} className="text-cyan-electric" />
          <span>{weather.temp}°C - {weather.condition}</span>
        </div>
        <div className="h-4 w-px bg-white/10 mx-2" />
        {["all", "work", "casual", "events"].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 md:px-6 py-2 rounded-full text-xs md:text-sm font-medium capitalize transition-all ${
              activeTab === tab
                ? "bg-gold text-navy shadow-lg"
                : "bg-white/5 text-slate hover:text-beige hover:bg-white/10"
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Loading state */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[1, 2, 3].map((i) => (
            <div key={i} className="glass rounded-3xl border border-white/5 overflow-hidden animate-pulse">
              <div className="aspect-[4/5] bg-white/5" />
              <div className="p-6 space-y-3">
                <div className="h-3 bg-white/10 rounded w-1/3" />
                <div className="h-5 bg-white/10 rounded w-2/3" />
                <div className="h-3 bg-white/5 rounded w-full" />
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
          <AnimatePresence mode="popLayout">
            {filteredRecs.map((item, index) => (
              <motion.div
                key={`rec-${item.name}-${index}`}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.9 }}
                transition={{ delay: index * 0.05 }}
                layout
              >
                <GlassCard className="p-0 overflow-hidden group border-white/5 hover:border-gold/30 transition-all duration-500 flex flex-col h-full">
                  <div className="relative aspect-[4/5] overflow-hidden bg-white/5">
                    {/* Skeleton + spinner while generating image server-side */}
                    {!imageLoaded[index] && (
                      <div className="absolute inset-0 flex flex-col items-center justify-center bg-gradient-to-br from-white/3 to-white/8 animate-pulse gap-3">
                        <Loader2 size={28} className="text-gold/50 animate-spin" />
                        <span className="text-[10px] text-slate/50 uppercase tracking-widest font-bold">
                          {imageSaving[index] ? "Génération..." : "En attente..."}
                        </span>
                      </div>
                    )}
                    {item.imageUrl && imageLoaded[index] ? (
                      <img
                        src={item.imageUrl}
                        alt={item.name}
                        className="w-full h-full object-cover group-hover:scale-110 transition-all duration-1000 opacity-100"
                        onLoad={() => setImageLoaded((prev) => ({ ...prev, [index]: true }))}
                      />
                    ) : item.imageUrl && !imageLoaded[index] ? (
                      /* Hidden img tag to trigger load — we use Supabase URL so it's fast */
                      <img
                        src={item.imageUrl}
                        alt={item.name}
                        className="absolute opacity-0 pointer-events-none w-0 h-0"
                        onLoad={() => setImageLoaded((prev) => ({ ...prev, [index]: true }))}
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center opacity-20">
                        <ImageOff size={48} />
                      </div>
                    )}

                    {/* Gradient overlay */}
                    <div className="absolute inset-0 bg-gradient-to-t from-navy/60 via-transparent to-transparent" />

                    <div className="absolute top-4 right-4 flex flex-col gap-2">
                      <button
                        onClick={() =>
                          setLikedIds((prev) => {
                            const next = new Set(prev);
                            next.has(index) ? next.delete(index) : next.add(index);
                            return next;
                          })
                        }
                        className={`p-2 backdrop-blur-md rounded-full shadow-lg transition-colors ${
                          likedIds.has(index)
                            ? "bg-red-500 text-white"
                            : "bg-white/10 text-white hover:bg-red-500"
                        }`}
                      >
                        <Heart size={18} />
                      </button>
                      <button className="p-2 bg-white/10 backdrop-blur-md rounded-full text-white hover:bg-gold transition-colors shadow-lg">
                        <Share2 size={18} />
                      </button>
                    </div>

                    <div className="absolute bottom-4 left-4">
                      <div className="flex items-center gap-2 bg-navy/80 backdrop-blur-md px-3 py-1 rounded-full border border-gold/30 shadow-2xl">
                        <Sparkles size={14} className="text-gold" />
                        <span className="text-gold font-bold text-xs">
                          {isNaN(item.match) ? "95" : item.match}% Match
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="p-6 space-y-4 flex-1 flex flex-col justify-between">
                    <div>
                      <div className="flex items-center gap-2 text-gold-light text-xs font-bold uppercase tracking-widest mb-2">
                        <Tag size={12} />
                        {item.context}
                      </div>
                      <h3 className="text-xl font-bold mb-2 group-hover:text-gold transition-colors">
                        {item.name}
                      </h3>
                      <p className="text-slate text-sm leading-relaxed">{item.description}</p>
                    </div>

                    <div className="flex flex-wrap gap-2 pt-4">
                      {item.tags.map((tag) => (
                        <span
                          key={tag}
                          className="text-[10px] uppercase font-bold tracking-tighter bg-white/5 px-2 py-1 rounded border border-white/5 text-slate-light"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                </GlassCard>
              </motion.div>
            ))}
          </AnimatePresence>

          {filteredRecs.length === 0 && !isLoading && (
            <div className="col-span-3 text-center py-20 opacity-60 max-w-md mx-auto space-y-4">
               {eventContext ? (
                  <>
                     <Calendar size={48} className="mx-auto text-slate" />
                     <p className="text-xl font-bold text-white">Aucune suggestion trouvée</p>
                     <p className="text-slate">Nous n'avons pas trouvé de recommandation sauvegardée pour l'événement "{eventContext}". Analysez votre tenue avec la caméra pour en générer de nouvelles !</p>
                  </>
               ) : (
                  <>
                     <Sparkles size={48} className="mx-auto text-slate" />
                     <p className="text-xl font-bold text-white">Miroir en attente</p>
                     <p className="text-slate">Veuillez d'abord analyser votre tenue du jour via la caméra du miroir pour obtenir des suggestions personnalisées basées sur vos évènements !</p>
                  </>
               )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
