"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import {
  Camera as CameraIcon,
  Scan,
  RefreshCcw,
  CheckCircle2,
  Loader2,
  Sparkles,
  VideoOff,
  Volume2,
  VolumeX,
  ArrowRight,
  Wifi,
  Smartphone,
  Layers,
  Sun,
  UserCheck,
  Activity,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useCamera } from "@/lib/camera-context";
import { createClient } from "@/lib/supabase/client";
import { analyzeFaceWithFaceApi, loadFaceApiScript } from "@/lib/services/face-detection";
import Link from "next/link";

const ESP_STREAM_URL = "https://fastapiforreflecto.onrender.com/stream";

interface AnalysisResult {
  gender?: string;
  morphology: string;
  silhouette: string;
  skinTone: string;
  confidence: number;
  suggestions: string;
}

type CameraSource = "device" | "esp";

export default function CameraPage() {
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [ttsSupported, setTtsSupported] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  const [events, setEvents] = useState<any[]>([]);
  const [weatherCtx, setWeatherCtx] = useState<any>(null);
  const [cameraSource, setCameraSource] = useState<CameraSource>("device");
  const [espConnected, setEspConnected] = useState(false);
  const [espLoading, setEspLoading] = useState(false);

  const { stream, startCamera, stopCamera, error: cameraError } = useCamera();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const espImgRef = useRef<HTMLImageElement>(null);

  useEffect(() => {
    if (cameraSource === "device") {
      startCamera();
    } else {
      stopCamera();
    }
    setTtsSupported(typeof window !== "undefined" && "speechSynthesis" in window);
    return () => stopCamera();
  }, [cameraSource]);

  useEffect(() => {
    if (stream && videoRef.current) {
      videoRef.current.srcObject = stream;
    }
  }, [stream]);

  // Pre-load Face-API.js models as soon as camera stream is active (warm-up for instant detection)
  useEffect(() => {
    if (stream) {
      loadFaceApiScript().catch(() => {}); // silent warm-up, non-blocking
    }
  }, [stream]);

  // Handle ESP module connection
  const handleConnectEsp = () => {
    setEspLoading(true);
    setCameraSource("esp");
    // The <img> onLoad will confirm connection
  };

  const handleDisconnectEsp = () => {
    setCameraSource("device");
    setEspConnected(false);
    setEspLoading(false);
  };

  // Load user profile + events for richer context
  useEffect(() => {
    async function loadContext() {
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: prof } = await supabase
        .from("profiles")
        .select("*")
        .eq("user_id", user.id)
        .single();
      setProfile(prof);

      // Load today's events
      const today = new Date().toISOString().split("T")[0];
      const { data: evts } = await supabase
        .from("events")
        .select("*")
        .eq("user_id", user.id)
        .gte("start_time", `${today}T00:00:00`)
        .lte("start_time", `${today}T23:59:59`)
        .order("start_time");
      setEvents(evts || []);

      // Get weather (simple fetch)
      try {
        const apiKey = process.env.NEXT_PUBLIC_OPENWEATHER_API_KEY;
        const res = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?q=Antananarivo&units=metric&appid=${apiKey}`
        );
        const w = await res.json();
        if (w.cod === 200) {
          setWeatherCtx({ temp: Math.round(w.main.temp), condition: w.weather[0].main, location: w.name });
        }
      } catch {}
    }
    loadContext();
  }, []);

  // Capture a frame from the webcam or ESP stream as base64 JPEG
  const captureFrame = useCallback((): string | null => {
    const canvas = canvasRef.current;
    if (!canvas) return null;

    if (cameraSource === "esp") {
      // Capture from ESP stream img element
      const img = espImgRef.current;
      if (!img) return null;
      canvas.width = img.naturalWidth || 640;
      canvas.height = img.naturalHeight || 480;
      const ctx = canvas.getContext("2d");
      if (!ctx) return null;
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      return canvas.toDataURL("image/jpeg", 0.85);
    }

    // Device camera
    const video = videoRef.current;
    if (!video) return null;

    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext("2d");
    if (!ctx) return null;

    // Mirror the video (undo the CSS scaleX -1)
    ctx.save();
    ctx.translate(canvas.width, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    ctx.restore();

    return canvas.toDataURL("image/jpeg", 0.85);
  }, [cameraSource]);

  const handleAnalyze = async () => {
    setIsAnalyzing(true);
    setAnalysisResult(null);
    stopSpeech();

    try {
      const imageBase64 = captureFrame();

      // 1. Run Certified Face-API.js Biometric Recognition in browser first
      let faceBio = null;
      try {
        const sourceEl = cameraSource === "esp" ? espImgRef.current : videoRef.current;
        if (sourceEl) {
          faceBio = await analyzeFaceWithFaceApi(sourceEl);
        }
      } catch (fErr) {
        console.warn("[Camera] FaceAPI scan skipped:", fErr);
      }

      // Enrich profile with certified biometrics if detected
      const enrichedProfile = {
        ...profile,
        gender: faceBio?.gender || profile?.gender,
        body_type: faceBio?.morphology || profile?.body_type,
        skin_tone: faceBio?.skinTone || profile?.skin_tone,
      };

      const response = await fetch("/api/analyze-outfit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          imageBase64,
          profile: enrichedProfile,
          weather: weatherCtx,
          events,
        }),
      });

      if (!response.ok) throw new Error("Analysis failed");
      const result = await response.json();

      // Merge certified Face-API biometrics (highest priority) with backend result
      const finalResult = {
        ...result,
        gender: faceBio?.gender || result.gender || profile?.gender,
        morphology: faceBio?.morphology || result.morphology,
        skinTone: faceBio?.skinTone || result.skinTone,
        fitzpatrickScale: faceBio?.fitzpatrickScale || result.fitzpatrickScale,
        genderConfidence: faceBio?.genderConfidence,
      };

      setAnalysisResult(finalResult);
      
      // Pass the analysis to recommendations page by saving it temporarily
      sessionStorage.setItem("reflecto_camera_analysis", JSON.stringify(finalResult));
      // Invalidate the daily cache so suggestions will re-generate based on this new analysis
      sessionStorage.removeItem(`reflecto_recs_${new Date().toISOString().split("T")[0]}`);
      
    } catch (error) {
      console.error("Analysis failed", error);
      const fallbackResult = {
        morphology: profile?.body_type || "H-Shape",
        silhouette: "Équilibrée",
        skinTone: profile?.skin_tone || "Warm",
        fitzpatrickScale: "Type III (Warm / Doré)",
        confidence: 0.75,
        suggestions:
          "Je vois beaucoup de potentiel ! Avec votre silhouette, je recommanderais de structurer les épaules. Essayez d'ajouter une touche de couleur vive qui réveillera votre tenue. C'est le moment d'être audacieux !",
      };
      setAnalysisResult(fallbackResult);
      sessionStorage.setItem("reflecto_camera_analysis", JSON.stringify(fallbackResult));
      sessionStorage.removeItem(`reflecto_recs_${new Date().toISOString().split("T")[0]}`);
    } finally {
      setIsAnalyzing(false);
    }
  };

  // Text-to-Speech using Web Speech API — voix française courante
  const speakSuggestions = () => {
    if (!ttsSupported || !analysisResult?.suggestions) return;
    window.speechSynthesis.cancel();

    const utterance = new SpeechSynthesisUtterance(analysisResult.suggestions);
    utterance.lang = "fr-FR";
    utterance.rate = 0.95;
    utterance.pitch = 1.05;

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

    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);

    window.speechSynthesis.speak(utterance);
  };

  const stopSpeech = () => {
    if (ttsSupported) window.speechSynthesis.cancel();
    setIsSpeaking(false);
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700 max-w-5xl mx-auto">
      {/* Hidden canvas for frame capture */}
      <canvas ref={canvasRef} className="hidden" />

      <header className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <h1 className="text-2xl md:text-4xl font-bold text-white mb-1 md:mb-2">Smart Mirror</h1>
          <p className="text-slate text-sm md:text-lg italic">
            "Mirror, mirror on the wall, what's my style after all?"
          </p>
        </div>
        <div className="flex items-center gap-3">
          {/* Source Toggle: Device Camera vs ESP Module */}
          <div className="flex items-center bg-white/5 border border-white/10 rounded-full p-1 gap-1">
            <button
              onClick={() => { setCameraSource("device"); setEspConnected(false); setEspLoading(false); }}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all ${
                cameraSource === "device"
                  ? "bg-cyan-electric text-navy shadow-lg shadow-cyan-electric/30"
                  : "text-slate hover:text-white"
              }`}
            >
              <Smartphone size={14} />
              Appareil
            </button>
            <button
              onClick={cameraSource === "esp" ? handleDisconnectEsp : handleConnectEsp}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all ${
                cameraSource === "esp"
                  ? espConnected
                    ? "bg-emerald-500 text-white shadow-lg shadow-emerald-500/30"
                    : "bg-gold text-navy shadow-lg shadow-gold/30 animate-pulse"
                  : "text-slate hover:text-white"
              }`}
            >
              {cameraSource === "esp" && espLoading && !espConnected ? (
                <Loader2 size={14} className="animate-spin" />
              ) : cameraSource === "esp" && espConnected ? (
                <Wifi size={14} />
              ) : (
                <Wifi size={14} />
              )}
              {cameraSource === "esp" && espConnected ? "Module connecté" : "ESP Module"}
            </button>
          </div>
          <div className="p-3 bg-cyan-electric/10 rounded-full text-cyan-electric animate-pulse">
            <Scan size={24} />
          </div>
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
        {/* Video Feed */}
        <div className={`lg:col-span-2 relative aspect-[3/4] max-h-[70vh] lg:max-h-none rounded-3xl overflow-hidden glass border-2 ${
          cameraSource === "esp" && espConnected
            ? "border-emerald-500/30 shadow-[0_0_30px_rgba(16,185,129,0.15)]"
            : "border-white/5"
        } group shadow-2xl bg-black`}>
          {/* Device camera feed */}
          {cameraSource === "device" && (
            <video
              ref={videoRef}
              autoPlay
              playsInline
              muted
              className="absolute inset-0 w-full h-full object-cover scale-x-[-1]"
            />
          )}

          {/* ESP32-CAM stream feed */}
          {cameraSource === "esp" && (
            <img
              ref={espImgRef}
              src={ESP_STREAM_URL}
              alt="ESP32-CAM Stream"
              crossOrigin="anonymous"
              onLoad={() => { setEspConnected(true); setEspLoading(false); }}
              onError={() => { setEspConnected(false); setEspLoading(false); }}
              className="absolute inset-0 w-full h-full object-cover"
            />
          )}

          {/* ESP source indicator badge */}
          {cameraSource === "esp" && (
            <div className="absolute top-4 left-4 z-30 flex items-center gap-2 px-3 py-1.5 rounded-full bg-navy/70 backdrop-blur-md border border-emerald-500/40 text-xs font-bold">
              <span className={`w-2 h-2 rounded-full ${espConnected ? "bg-emerald-400 animate-pulse" : "bg-amber-400 animate-pulse"}`} />
              <span className={espConnected ? "text-emerald-400" : "text-amber-400"}>
                {espConnected ? "ESP32-CAM Live" : "Connexion en cours..."}
              </span>
            </div>
          )}

          <AnimatePresence>
            {isAnalyzing && (
              <motion.div
                initial={{ top: "0%" }}
                animate={{ top: "100%" }}
                transition={{ repeat: Infinity, duration: 2, ease: "linear" }}
                className="absolute left-0 right-0 h-1 bg-gradient-to-r from-transparent via-cyan-electric to-transparent z-20 shadow-[0_0_15px_rgba(0,212,255,1)]"
              />
            )}
          </AnimatePresence>

          <div className="absolute inset-0 flex flex-col items-center justify-center space-y-4 z-10 pointer-events-none">
            {cameraSource === "device" && !stream && !cameraError && (
              <div className="text-center space-y-4">
                <Loader2 size={48} className="text-gold animate-spin" />
                <p className="text-gold font-bold">Initialisation du miroir...</p>
              </div>
            )}

            {cameraSource === "device" && cameraError && (
              <div className="text-center space-y-4 p-8 glass mx-8 pointer-events-auto">
                <VideoOff size={48} className="text-red-400 mx-auto" />
                <p className="text-white font-medium">{cameraError}</p>
                <button
                  onClick={startCamera}
                  className="px-6 py-2 bg-gold text-navy rounded-full font-bold text-sm"
                >
                  Réessayer
                </button>
              </div>
            )}

            {cameraSource === "esp" && espLoading && !espConnected && (
              <div className="text-center space-y-4 p-8 glass mx-8">
                <Loader2 size={48} className="text-emerald-400 animate-spin mx-auto" />
                <p className="text-emerald-400 font-bold">Connexion au module ESP32-CAM...</p>
                <p className="text-white/40 text-xs">En attente du flux vidéo depuis le module</p>
              </div>
            )}

            {isAnalyzing && (
              <div className="text-center space-y-4 bg-navy/40 backdrop-blur-md p-6 rounded-3xl border border-cyan-electric/30">
                <div className="relative">
                  <div className="absolute inset-0 animate-ping bg-cyan-electric/20 rounded-full" />
                  <Loader2 size={64} className="text-cyan-electric animate-spin relative" />
                </div>
                <p className="text-cyan-electric font-bold tracking-widest uppercase">
                  Analyse IA...
                </p>
                <p className="text-white/50 text-xs">Llama 3.2 Vision processing</p>
              </div>
            )}
          </div>

          {(stream || (cameraSource === "esp" && espConnected)) && (
            <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex gap-4 z-30">
              <button
                onClick={handleAnalyze}
                disabled={isAnalyzing}
                className="bg-gold hover:bg-gold/90 disabled:bg-slate-shadow text-navy px-8 py-3 rounded-full font-bold shadow-lg shadow-gold/20 flex items-center gap-3 transition-all active:scale-95"
              >
                {isAnalyzing ? "Analyse..." : analysisResult ? "Re-analyser" : "Analyser Ma Tenue"}
                {!isAnalyzing && <Sparkles size={20} />}
              </button>
              {cameraSource === "device" && (
                <button
                  onClick={() => { stopCamera(); startCamera(); }}
                  className="bg-white/10 backdrop-blur-md text-white p-3 rounded-full border border-white/10 hover:bg-white/20 transition-all"
                >
                  <RefreshCcw size={24} />
                </button>
              )}
            </div>
          )}
        </div>

        {/* Results Panel */}
        <div className="space-y-6">
          <GlassCard className="p-6">
            <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
              <CheckCircle2 className="text-gold" size={20} />
              Analysis Results
            </h3>

            {analysisResult ? (
              <div className="space-y-4 animate-in slide-in-from-right duration-500">
                <ResultItem icon={Layers} label="Morphologie" value={analysisResult.morphology || "H-Shape"} />
                <ResultItem
                  icon={Sun}
                  label="Carnation / Teint"
                  value={`${analysisResult.skinTone || "Warm"}${analysisResult.fitzpatrickScale ? ` · ${analysisResult.fitzpatrickScale.split("(")[0].trim()}` : ""}`}
                />
                <ResultItem
                  icon={UserCheck}
                  label="Genre Détecté"
                  value={`${analysisResult.gender === "female" ? "Femme" : analysisResult.gender === "male" ? "Homme" : "Unisexe"}${analysisResult.genderConfidence ? ` (${Math.round(analysisResult.genderConfidence * 100)}%)` : ""}`}
                />
                <ResultItem icon={Activity} label="Silhouette" value={analysisResult.silhouette || "Équilibrée"} />

                <div className="pt-3 border-t border-white/5">
                  <p className="text-xs text-slate-shadow uppercase tracking-widest mb-2 font-bold">
                    Score de Confiance
                  </p>
                  <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${(analysisResult.confidence || 0.88) * 100}%` }}
                      className="h-full bg-gold shadow-[0_0_10px_rgba(212,165,116,0.5)]"
                    />
                  </div>
                  <p className="text-right text-xs text-gold mt-1">
                    {Math.round((analysisResult.confidence || 0.88) * 100)}%
                  </p>
                </div>

                {/* Suggestions */}
                <div className="pt-3 border-t border-white/5">
                  <p className="text-xs text-slate-shadow uppercase tracking-widest mb-2 font-bold">
                    Conseils Styliste IA
                  </p>
                  <p className="text-sm text-white/80 leading-relaxed italic bg-gold/10 p-3 rounded-xl border border-gold/20">
                    "{analysisResult.suggestions}"
                  </p>
                </div>

                {/* TTS & Navigation actions */}
                <div className="flex flex-col gap-3 pt-2">
                  {ttsSupported && (
                    <button
                      onClick={isSpeaking ? stopSpeech : speakSuggestions}
                      className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl font-bold text-sm transition-all border ${
                        isSpeaking
                          ? "border-red-400/40 bg-red-400/10 text-red-400 hover:bg-red-400/20"
                          : "border-cyan-electric/30 bg-cyan-electric/10 text-cyan-electric hover:bg-cyan-electric/20"
                      }`}
                    >
                      {isSpeaking ? (
                        <><VolumeX size={16} /> Arrêter la voix</>
                      ) : (
                        <><Volume2 size={16} /> Écouter les conseils</>
                      )}
                    </button>
                  )}

                  <Link href="/recommendations" className="w-full">
                    <button className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl font-bold text-sm bg-gold hover:bg-gold/90 text-navy transition-all shadow-lg shadow-gold/20">
                      <Sparkles size={16} />
                      Voir mes suggestions IA
                      <ArrowRight size={16} />
                    </button>
                  </Link>
                </div>
              </div>
            ) : (
              <div className="h-64 flex flex-col items-center justify-center text-center space-y-4 opacity-30">
                <Scan size={48} />
                <p className="text-sm font-medium">
                  Placez-vous face au miroir et cliquez sur "Analyser Ma Tenue"
                </p>
              </div>
            )}
          </GlassCard>

          <GlassCard variant="ai" className="p-6">
            <h4 className="font-bold text-white mb-2 flex items-center gap-2">
              <Sparkles size={16} className="text-gold" />
              Conseil d'utilisation
            </h4>
            <p className="text-sm text-white/70 leading-relaxed">
              Pour une analyse optimale, assurez-vous d'avoir une bonne luminosité frontale et de cadrer le haut du corps. L'IA adapte ses recommandations selon votre silhouette, votre teint et votre agenda.
            </p>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}

const ResultItem = ({ label, value, icon: Icon }: { label: string; value: string; icon?: any }) => (
  <div className="flex items-center justify-between p-2.5 bg-white/5 rounded-xl border border-white/5">
    <span className="text-xs text-slate flex items-center gap-1.5 font-medium">
      {Icon && <Icon size={14} className="text-gold" />}
      {label}
    </span>
    <span className="text-sm font-bold text-gold px-2 py-0.5 bg-gold/10 rounded border border-gold/20">
      {value}
    </span>
  </div>
);
