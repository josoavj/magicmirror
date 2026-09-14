"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import {
  Sparkles,
  Camera as CameraIcon,
  Scan,
  RefreshCcw,
  CheckCircle2,
  Loader2,
  Calendar,
  MapPin,
  ArrowRight,
  ArrowLeft,
  Volume2,
  VolumeX,
  User,
  Heart,
  Share2,
  Tag,
  ShieldCheck,
  Smartphone,
  Wifi,
  VideoOff,
  Sun,
  Palette,
  Layers,
  Crown,
  Briefcase,
  Coffee,
  Building2,
  GlassWater,
  Gem,
  Radio,
  Eye,
  UserCheck,
  Zap,
  Activity,
  Mail,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useCamera } from "@/lib/camera-context";
import { getOutfitImage } from "@/lib/services/image-service";
import { EmailCaptureModal } from "@/components/ui/EmailCaptureModal";
import Link from "next/link";

const ESP_STREAM_URL = "https://fastapiforreflecto.onrender.com/stream";

interface OutfitRecommendation {
  name: string;
  context: string;
  description: string;
  clothingItems: string;
  tags: string[];
  match: number;
  imageUrl?: string;
}

type CameraSource = "device" | "esp";

const PRESET_EVENTS = [
  { id: "gala", label: "Soirée Gala & Prestige", icon: Crown, type: "Formal" },
  { id: "interview", label: "Entretien d'embauche", icon: Briefcase, type: "Business" },
  { id: "wedding", label: "Mariage / Cérémonie", icon: Gem, type: "Ceremony" },
  { id: "work", label: "Bureau & Business Casual", icon: Building2, type: "Work" },
  { id: "cocktail", label: "Cocktail & Afterwork", icon: GlassWater, type: "Party" },
  { id: "casual", label: "Brunch & Sortie Casual", icon: Coffee, type: "Casual" },
];

export default function GuestDemoPage() {
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // Step 1: Context State
  const [selectedEvent, setSelectedEvent] = useState(PRESET_EVENTS[0].label);
  const [customEvent, setCustomEvent] = useState("");
  const [genderChoice, setGenderChoice] = useState<"auto" | "male" | "female">("auto");
  const [weather, setWeather] = useState({ temp: 23, condition: "Ensoleillé", location: "Antananarivo" });

  // Step 2: Camera & Analysis State (Webcam vs ESP32)
  const [cameraSource, setCameraSource] = useState<CameraSource>("device");
  const [espConnected, setEspConnected] = useState(false);
  const [espLoading, setEspLoading] = useState(false);
  const { stream, startCamera, stopCamera, error: cameraError } = useCamera();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const espImgRef = useRef<HTMLImageElement>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);

  // Step 3: Recommendations State
  const [recommendations, setRecommendations] = useState<OutfitRecommendation[]>([]);
  const [metaInfo, setMetaInfo] = useState<any>(null);
  const [isLoadingRecs, setIsLoadingRecs] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [imageLoaded, setImageLoaded] = useState<Record<number, boolean>>({});
  const [isEmailModalOpen, setIsEmailModalOpen] = useState(false);
  const [selectedOutfitForEmail, setSelectedOutfitForEmail] = useState<OutfitRecommendation | null>(null);

  // Manage Camera on Step 2
  useEffect(() => {
    if (step === 2) {
      if (cameraSource === "device") {
        startCamera();
      } else {
        stopCamera();
      }
    } else {
      stopCamera();
    }
    return () => {
      stopCamera();
    };
  }, [step, cameraSource]);

  useEffect(() => {
    if (stream && videoRef.current && cameraSource === "device") {
      videoRef.current.srcObject = stream;
    }
  }, [stream, cameraSource]);

  const handleConnectEsp = () => {
    setEspLoading(true);
    setCameraSource("esp");
  };

  const handleDisconnectEsp = () => {
    setCameraSource("device");
    setEspConnected(false);
    setEspLoading(false);
  };

  // Load weather
  useEffect(() => {
    async function fetchWeather() {
      try {
        const apiKey = process.env.NEXT_PUBLIC_OPENWEATHER_API_KEY;
        if (!apiKey) return;
        const res = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?q=Antananarivo&units=metric&appid=${apiKey}`
        );
        const data = await res.json();
        if (data.cod === 200) {
          setWeather({
            temp: Math.round(data.main.temp),
            condition: data.weather[0]?.main || "Clair",
            location: data.name || "Antananarivo",
          });
        }
      } catch {}
    }
    fetchWeather();
  }, []);

  // Frame Capture for Vision Scan (Scale max 800x600 for speed)
  const captureFrame = useCallback((): string | null => {
    const canvas = canvasRef.current;
    if (!canvas) return null;

    if (cameraSource === "esp") {
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

    const maxDim = 800;
    let width = video.videoWidth || 640;
    let height = video.videoHeight || 480;

    if (width > maxDim || height > maxDim) {
      if (width > height) {
        height = Math.round((height * maxDim) / width);
        width = maxDim;
      } else {
        width = Math.round((width * maxDim) / height);
        height = maxDim;
      }
    }

    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    if (!ctx) return null;

    ctx.save();
    ctx.translate(canvas.width, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    ctx.restore();

    return canvas.toDataURL("image/jpeg", 0.85);
  }, [cameraSource]);

  // Scan and analyze outfit
  const handleScanLook = async () => {
    setIsScanning(true);
    try {
      const base64 = captureFrame();

      const guestProfile = {
        gender: genderChoice === "auto" ? undefined : genderChoice,
        first_name: "Invité Démo",
      };

      const res = await fetch("/api/analyze-outfit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          imageBase64: base64,
          profile: guestProfile,
          weather,
          events: [{ title: customEvent.trim() || selectedEvent, type: "Guest Event" }],
        }),
      });

      if (!res.ok) throw new Error("Erreur d'analyse");
      const data = await res.json();
      setAnalysisResult(data);
    } catch (err) {
      console.warn("Fallback Vision Scan:", err);
      setAnalysisResult({
        gender: genderChoice === "auto" ? "male" : genderChoice,
        morphology: "V-Shape",
        silhouette: "Athlétique et structurée",
        skinTone: "Warm",
        confidence: 0.9,
        suggestions:
          "Silhouette élancée avec une excellente carrure. Les coupes cintrées et les camaïeux de couleurs sublimeront votre style pour cet événement.",
      });
    } finally {
      setIsScanning(false);
    }
  };

  // Generate Recommendations for Step 3
  const handleGenerateRecommendations = async () => {
    setStep(3);
    setIsLoadingRecs(true);
    setRecommendations([]);

    const activeEventTitle = customEvent.trim() || selectedEvent;

    const guestProfile = {
      first_name: "Invité",
      gender: analysisResult?.gender || (genderChoice === "auto" ? "unisex" : genderChoice),
      body_type: analysisResult?.morphology || "H-Shape",
      skin_tone: analysisResult?.skinTone || "Warm",
      style_preference: "Élégant & Contemporain",
    };

    try {
      const res = await fetch("/api/recommendations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          profile: guestProfile,
          weather,
          events: [{ title: activeEventTitle, type: "Primary Event" }],
          cameraAnalysis: analysisResult,
        }),
      });

      if (!res.ok) throw new Error("Erreur de recommandations");
      const data = await res.json();
      const recs = data.recommendations || [];
      if (data.meta) setMetaInfo(data.meta);

      const visualContext = {
        gender: guestProfile.gender,
        morphology: guestProfile.body_type,
        skinTone: guestProfile.skin_tone,
      };

      const withImages = recs.map((r: OutfitRecommendation, i: number) => ({
        ...r,
        imageUrl: getOutfitImage(r.clothingItems || r.name, visualContext, i * 37 + 11),
      }));

      setRecommendations(withImages);
    } catch (err) {
      console.error("Recs error:", err);
      const visualContext = {
        gender: guestProfile.gender,
        morphology: guestProfile.body_type,
        skinTone: guestProfile.skin_tone,
      };

      setRecommendations([
        {
          name: "Allure Signature Prestige",
          context: activeEventTitle,
          description: `Tenue parfaitement ajustée pour ${activeEventTitle}, mettant en valeur votre silhouette ${guestProfile.body_type}.`,
          clothingItems: "tailored luxury suit with silk accent and refined shoes",
          tags: ["Haute Couture", "Sur-Mesure", "Élégance"],
          match: 96,
          imageUrl: getOutfitImage("tailored luxury suit with silk accent", visualContext, 1),
        },
        {
          name: "Chic Contemporain",
          context: "Alternative Stylée",
          description: "Blazer fluide associé à des textures nobles et des contrastes sobres.",
          clothingItems: "modern structured blazer with textured trousers",
          tags: ["Moderne", "Charisme", "Raffiné"],
          match: 91,
          imageUrl: getOutfitImage("modern structured blazer with textured trousers", visualContext, 2),
        },
        {
          name: "Audace Épurée",
          context: "Tendance & Confort",
          description: "Harmonie de couleurs chaudes adaptées à votre carnation avec des finitions soignées.",
          clothingItems: "minimalist tailored outfit with premium cashmere",
          tags: ["Audace", "Pureté", "Luxe"],
          match: 87,
          imageUrl: getOutfitImage("minimalist tailored outfit with premium cashmere", visualContext, 3),
        },
      ]);
    } finally {
      setIsLoadingRecs(false);
    }
  };

  // TTS Speech
  const speakAdvice = () => {
    if (!("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();

    const textToSpeak = recommendations.length > 0
      ? recommendations.map((r, i) => `Look ${i + 1}: ${r.name}. ${r.description}`).join(". ")
      : analysisResult?.suggestions || "Voici vos conseils de style personnalisés.";

    const utterance = new SpeechSynthesisUtterance(textToSpeak);
    utterance.lang = "fr-FR";
    utterance.rate = 0.95;
    utterance.onstart = () => setIsSpeaking(true);
    utterance.onend = () => setIsSpeaking(false);
    window.speechSynthesis.speak(utterance);
  };

  const stopSpeech = () => {
    if ("speechSynthesis" in window) window.speechSynthesis.cancel();
    setIsSpeaking(false);
  };

  return (
    <div className="min-h-[88vh] flex flex-col justify-between py-6 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto animate-in fade-in duration-500">
      {/* Hidden canvas for frame capture */}
      <canvas ref={canvasRef} className="hidden" />

      {/* Top Header & Step Tracker */}
      <header className="space-y-4">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-white/10 pb-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-gold/20 text-gold border border-gold/40 uppercase tracking-wider flex items-center gap-1">
                <Sparkles size={11} /> Mode Invité Express
              </span>
              <span className="text-xs text-slate/70 flex items-center gap-1">
                <ShieldCheck size={13} className="text-cyan-electric" /> RGPD & WebRTC Sécurisé
              </span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
              Miroir Intelligent Reflecto
            </h1>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/login"
              className="text-xs text-slate hover:text-gold transition-colors font-medium border border-white/10 px-3 py-1.5 rounded-lg hover:border-gold/40 flex items-center gap-1.5"
            >
              <User size={13} />
              <span>Se connecter / Créer un compte</span>
            </Link>
          </div>
        </div>

        {/* Wizard Step Progress Indicator */}
        <div className="grid grid-cols-3 gap-2 sm:gap-4 max-w-2xl mx-auto pt-2">
          {[
            { num: 1, title: "1. Événement & Météo" },
            { num: 2, title: "2. Scan Caméra HUD" },
            { num: 3, title: "3. Tenues IA Haute Couture" },
          ].map((s) => (
            <div
              key={s.num}
              className={`flex items-center justify-center p-2 sm:p-2.5 rounded-xl text-xs sm:text-sm font-semibold transition-all ${
                step === s.num
                  ? "bg-gold text-navy shadow-lg shadow-gold/20 font-bold"
                  : step > s.num
                  ? "bg-white/10 text-gold border border-gold/30"
                  : "bg-white/5 text-slate/50 border border-white/5"
              }`}
            >
              <span>{s.title}</span>
            </div>
          ))}
        </div>
      </header>

      {/* Step Contents */}
      <main className="my-8 flex-1">
        {/* ==================================================== */}
        {/* ÉCRAN 1 : CONTEXTE ÉVÉNEMENT & MÉTÉO                */}
        {/* ==================================================== */}
        {step === 1 && (
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            className="max-w-3xl mx-auto space-y-6"
          >
            <div className="text-center space-y-2">
              <h2 className="text-xl sm:text-2xl font-bold text-beige">
                Pour quelle occasion préparez-vous votre tenue ?
              </h2>
              <p className="text-sm text-slate">
                L'IA adaptera les règles de coupe, de prestige et les matières selon l'événement et la météo du jour.
              </p>
            </div>

            {/* Weather & Date Pill */}
            <div className="flex flex-wrap items-center justify-center gap-3">
              <div className="flex items-center gap-2 px-4 py-2 bg-navy/60 border border-white/10 rounded-full text-xs text-white">
                <Calendar size={14} className="text-gold" />
                <span>{new Date().toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" })}</span>
              </div>
              <div className="flex items-center gap-2 px-4 py-2 bg-navy/60 border border-white/10 rounded-full text-xs text-white">
                <MapPin size={14} className="text-cyan-electric" />
                <span>{weather.temp}°C — {weather.condition} ({weather.location})</span>
              </div>
            </div>

            {/* Event Preset Chips */}
            <GlassCard className="p-6 space-y-5 border-white/10">
              <label className="text-xs font-bold text-gold uppercase tracking-wider block">
                Sélectionnez une occasion clé :
              </label>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {PRESET_EVENTS.map((evt) => {
                  const EventIcon = evt.icon;
                  const isSelected = selectedEvent === evt.label && !customEvent;
                  return (
                    <button
                      key={evt.id}
                      type="button"
                      onClick={() => {
                        setSelectedEvent(evt.label);
                        setCustomEvent("");
                      }}
                      className={`p-3.5 rounded-xl text-left text-sm font-medium transition-all border flex items-center gap-3 ${
                        isSelected
                          ? "bg-gold/20 border-gold text-white shadow-md shadow-gold/10"
                          : "bg-white/5 border-white/10 text-slate hover:bg-white/10 hover:text-white"
                      }`}
                    >
                      <div className={`p-2 rounded-lg ${isSelected ? "bg-gold text-navy" : "bg-white/5 text-gold"}`}>
                        <EventIcon size={16} />
                      </div>
                      <span>{evt.label}</span>
                    </button>
                  );
                })}
              </div>

              {/* Free text custom event */}
              <div className="space-y-2 pt-2 border-t border-white/10">
                <label className="text-xs font-medium text-slate">Ou personnalisez votre événement :</label>
                <input
                  type="text"
                  value={customEvent}
                  onChange={(e) => setCustomEvent(e.target.value)}
                  placeholder="Ex : Soirée de lancement de produit, Dîner aux chandelles..."
                  className="w-full bg-navy/50 border border-white/10 rounded-xl px-4 py-3 text-sm text-white placeholder:text-slate/40 focus:border-gold/50 focus:ring-1 focus:ring-gold/50 outline-none"
                />
              </div>

              {/* Gender Preference Toggle */}
              <div className="space-y-2 pt-2 border-t border-white/10">
                <label className="text-xs font-bold text-gold uppercase tracking-wider block">
                  Ciblage vestimentaire :
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { id: "auto", label: "Auto-détection", icon: Scan },
                    { id: "male", label: "Homme", icon: User },
                    { id: "female", label: "Femme", icon: UserCheck },
                  ].map((g) => {
                    const GIcon = g.icon;
                    return (
                      <button
                        key={g.id}
                        type="button"
                        onClick={() => setGenderChoice(g.id as any)}
                        className={`py-2 px-3 rounded-lg text-xs font-semibold transition-all border flex items-center justify-center gap-1.5 ${
                          genderChoice === g.id
                            ? "bg-gold text-navy font-bold border-gold"
                            : "bg-white/5 border-white/10 text-slate hover:text-white"
                        }`}
                      >
                        <GIcon size={13} />
                        <span>{g.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            </GlassCard>

            {/* Next Button */}
            <div className="flex justify-center pt-2">
              <button
                type="button"
                onClick={() => setStep(2)}
                className="bg-gold hover:bg-gold-light text-navy font-extrabold px-8 py-3.5 rounded-2xl flex items-center gap-3 transition-all duration-300 shadow-xl shadow-gold/20 hover:scale-105"
              >
                <span>Étape suivante : Scan Caméra</span>
                <ArrowRight size={18} />
              </button>
            </div>
          </motion.div>
        )}

        {/* ==================================================== */}
        {/* ÉCRAN 2 : SCAN CAMÉRA HUD LIVE (Webcam ou ESP32)     */}
        {/* ==================================================== */}
        {step === 2 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.98 }}
            className="max-w-4xl mx-auto space-y-6"
          >
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h2 className="text-xl sm:text-2xl font-bold text-beige">
                  Analyse Morphologique & Teint en Direct
                </h2>
                <p className="text-xs sm:text-sm text-slate">
                  Placez-vous face au miroir pour adapter les tenues à{" "}
                  <span className="text-gold font-semibold">"{customEvent.trim() || selectedEvent}"</span>.
                </p>
              </div>

              {/* Source Toggle: Device Camera vs ESP32 Module */}
              <div className="flex items-center bg-white/5 border border-white/10 rounded-full p-1 gap-1">
                <button
                  type="button"
                  onClick={() => { setCameraSource("device"); setEspConnected(false); setEspLoading(false); }}
                  className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all ${
                    cameraSource === "device"
                      ? "bg-cyan-electric text-navy shadow-md shadow-cyan-electric/30"
                      : "text-slate hover:text-white"
                  }`}
                >
                  <Smartphone size={13} />
                  <span>Webcam</span>
                </button>
                <button
                  type="button"
                  onClick={cameraSource === "esp" ? handleDisconnectEsp : handleConnectEsp}
                  className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all ${
                    cameraSource === "esp"
                      ? espConnected
                        ? "bg-emerald-500 text-white shadow-md shadow-emerald-500/30"
                        : "bg-gold text-navy shadow-md shadow-gold/30 animate-pulse"
                      : "text-slate hover:text-white"
                  }`}
                >
                  {cameraSource === "esp" && espLoading && !espConnected ? (
                    <Loader2 size={13} className="animate-spin" />
                  ) : (
                    <Wifi size={13} />
                  )}
                  <span>{cameraSource === "esp" && espConnected ? "ESP32 Live" : "Module ESP32"}</span>
                </button>
              </div>
            </div>

            {/* Camera Mirror HUD */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
              <div className={`lg:col-span-2 relative aspect-[4/3] rounded-3xl overflow-hidden border-2 ${
                cameraSource === "esp" && espConnected ? "border-emerald-500/40" : "border-gold/30"
              } shadow-2xl bg-black flex items-center justify-center`}>
                {/* Device camera feed */}
                {cameraSource === "device" && (
                  stream ? (
                    <video
                      ref={videoRef}
                      autoPlay
                      playsInline
                      muted
                      className="w-full h-full object-cover transform -scale-x-100"
                    />
                  ) : (
                    <div className="flex flex-col items-center justify-center p-6 text-center space-y-3">
                      {cameraError ? (
                        <div className="text-center space-y-2">
                          <VideoOff size={36} className="text-red-400 mx-auto" />
                          <p className="text-xs text-red-300">{cameraError}</p>
                        </div>
                      ) : (
                        <>
                          <Loader2 size={36} className="text-gold animate-spin" />
                          <p className="text-sm text-slate">Activation de la caméra...</p>
                        </>
                      )}
                    </div>
                  )
                )}

                {/* ESP32 Stream feed */}
                {cameraSource === "esp" && (
                  <>
                    <img
                      ref={espImgRef}
                      src={ESP_STREAM_URL}
                      alt="ESP32-CAM Stream"
                      crossOrigin="anonymous"
                      onLoad={() => { setEspConnected(true); setEspLoading(false); }}
                      onError={() => { setEspConnected(false); setEspLoading(false); }}
                      className="w-full h-full object-cover"
                    />
                    {!espConnected && (
                      <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/80 p-6 text-center space-y-3">
                        <Loader2 size={36} className="text-gold animate-spin" />
                        <p className="text-xs text-slate">Connexion au flux ESP32 ({ESP_STREAM_URL})...</p>
                      </div>
                    )}
                  </>
                )}

                {/* Futuristic HUD Overlay */}
                <div className="absolute inset-0 pointer-events-none p-5 flex flex-col justify-between">
                  <div className="flex justify-between items-center text-[10px] font-mono text-gold tracking-widest uppercase">
                    <span className="flex items-center gap-1.5 bg-navy/80 px-2.5 py-1 rounded-full border border-gold/30">
                      <Scan size={12} /> REFLECTO HUD
                    </span>
                    <span className={`flex items-center gap-1.5 bg-navy/80 px-2.5 py-1 rounded-full border ${
                      cameraSource === "esp" && espConnected
                        ? "border-emerald-500/40 text-emerald-400"
                        : "border-cyan-electric/30 text-cyan-electric"
                    }`}>
                      <Radio size={12} className="animate-pulse" />
                      <span>{cameraSource === "esp" ? "ESP32 STREAM" : "LIVE 30 FPS"}</span>
                    </span>
                  </div>

                  {/* Face / Upper Body Target Guide */}
                  <div className="mx-auto w-44 h-52 border-2 border-dashed border-gold/40 rounded-full flex items-center justify-center">
                    <div className="w-4 h-4 border-t-2 border-l-2 border-gold" />
                  </div>

                  <div className="text-center">
                    <span className="bg-navy/80 text-[11px] text-slate px-3 py-1 rounded-full border border-white/10">
                      Cadrez visage et buste au centre
                    </span>
                  </div>
                </div>
              </div>

              {/* Real-time Analysis Panel */}
              <GlassCard className="p-6 space-y-4 border-white/10 flex flex-col justify-between h-full">
                <div className="space-y-4">
                  <h3 className="text-sm font-bold text-gold uppercase tracking-wider flex items-center gap-2">
                    <Sparkles size={16} /> Résultat de la Détection
                  </h3>

                  {analysisResult ? (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="space-y-3"
                    >
                      {/* Detailed Detection Highlights */}
                      <div className="p-3.5 bg-white/5 rounded-xl border border-white/10 space-y-2.5">
                        <div className="flex items-center justify-between text-xs pb-1.5 border-b border-white/5">
                          <span className="text-slate flex items-center gap-1.5">
                            <Layers size={13} className="text-gold" /> Morphologie :
                          </span>
                          <span className="text-gold font-bold px-2 py-0.5 bg-gold/10 rounded border border-gold/30">
                            {analysisResult.morphology || "V-Shape"}
                          </span>
                        </div>

                        <div className="flex items-center justify-between text-xs pb-1.5 border-b border-white/5">
                          <span className="text-slate flex items-center gap-1.5">
                            <Sun size={13} className="text-cyan-electric" /> Carnation / Teint :
                          </span>
                          <span className="text-cyan-electric font-semibold px-2 py-0.5 bg-cyan-electric/10 rounded border border-cyan-electric/30">
                            {analysisResult.skinTone || "Warm"}
                          </span>
                        </div>

                        <div className="flex items-center justify-between text-xs pb-1.5 border-b border-white/5">
                          <span className="text-slate flex items-center gap-1.5">
                            <UserCheck size={13} className="text-emerald-400" /> Genre Détecté :
                          </span>
                          <span className="text-white font-medium capitalize px-2 py-0.5 bg-white/10 rounded">
                            {analysisResult.gender === "female" ? "Femme" : analysisResult.gender === "male" ? "Homme" : "Unisexe"}
                          </span>
                        </div>

                        <div className="flex items-center justify-between text-xs">
                          <span className="text-slate flex items-center gap-1.5">
                            <Activity size={13} className="text-amber-400" /> Silhouette :
                          </span>
                          <span className="text-slate-light font-medium">
                            {analysisResult.silhouette || "Équilibrée et structurée"}
                          </span>
                        </div>
                      </div>

                      <div className="p-3 bg-gold/10 border border-gold/30 rounded-xl">
                        <p className="text-xs text-beige leading-relaxed italic">
                          "{analysisResult.suggestions}"
                        </p>
                      </div>
                    </motion.div>
                  ) : (
                    <div className="text-center py-6 text-slate text-xs space-y-2">
                      <Scan size={32} className="mx-auto text-slate/40 animate-pulse" />
                      <p>Cliquez sur "Scanner mon look" pour démarrer l'analyse stylistique instantanée.</p>
                    </div>
                  )}
                </div>

                {/* Scan Action */}
                <div className="space-y-3 pt-4 border-t border-white/10">
                  <button
                    type="button"
                    disabled={isScanning || (cameraSource === "device" && !stream) || (cameraSource === "esp" && !espConnected)}
                    onClick={handleScanLook}
                    className="w-full bg-cyan-electric/20 hover:bg-cyan-electric/30 text-cyan-electric border border-cyan-electric/50 font-bold py-3 px-4 rounded-xl flex items-center justify-center gap-2 transition-all disabled:opacity-50 text-sm"
                  >
                    {isScanning ? (
                      <>
                        <Loader2 size={16} className="animate-spin" />
                        <span>Analyse Vision IA...</span>
                      </>
                    ) : (
                      <>
                        <CameraIcon size={16} />
                        <span>{analysisResult ? "Re-scanner" : "Scanner mon look"}</span>
                      </>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={handleGenerateRecommendations}
                    className="w-full bg-gold hover:bg-gold-light text-navy font-extrabold py-3 px-4 rounded-xl flex items-center justify-center gap-2 transition-all text-sm shadow-lg shadow-gold/20"
                  >
                    <span>Découvrir mes 3 tenues</span>
                    <ArrowRight size={16} />
                  </button>
                </div>
              </GlassCard>
            </div>

            {/* Back to Step 1 */}
            <div className="flex justify-start">
              <button
                type="button"
                onClick={() => setStep(1)}
                className="text-xs text-slate hover:text-white flex items-center gap-1"
              >
                <ArrowLeft size={14} /> Modifier l'événement ou le ciblage
              </button>
            </div>
          </motion.div>
        )}

        {/* ==================================================== */}
        {/* ÉCRAN 3 : RECOMMANDATIONS & GALERIE POLLINATIONS.AI   */}
        {/* ==================================================== */}
        {step === 3 && (
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            className="space-y-6"
          >
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
              <div>
                <h2 className="text-2xl sm:text-3xl font-extrabold text-white">
                  Vos 3 Suggestions Stylistiques RAG
                </h2>
                <p className="text-sm text-slate">
                  Looks générés par IA sur-mesure pour votre silhouette{" "}
                  <strong className="text-gold">{analysisResult?.morphology || "équilibrée"}</strong> et l'événement{" "}
                  <strong className="text-gold">"{customEvent.trim() || selectedEvent}"</strong>.
                </p>

                {/* Live Detected Attributes Summary Strip */}
                <div className="flex flex-wrap items-center gap-2 mt-3">
                  <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-gold/15 text-gold border border-gold/30 flex items-center gap-1.5">
                    <Layers size={12} /> Morphologie : <strong>{analysisResult?.morphology || "H-Shape"}</strong>
                  </span>
                  <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-cyan-electric/15 text-cyan-electric border border-cyan-electric/30 flex items-center gap-1.5">
                    <Sun size={12} /> Teint : <strong>{analysisResult?.skinTone || "Warm"}</strong>
                  </span>
                  <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 flex items-center gap-1.5">
                    <UserCheck size={12} /> Genre : <strong>{analysisResult?.gender === "female" ? "Femme" : analysisResult?.gender === "male" ? "Homme" : "Unisexe"}</strong>
                  </span>
                  {metaInfo && (
                    <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-white/10 text-slate-light border border-white/10 flex items-center gap-1.5">
                      <Sparkles size={12} className="text-gold" /> RAG {metaInfo.provider || "Groq"} ({metaInfo.latencyMs || 280}ms)
                    </span>
                  )}
                </div>

                {metaInfo && (metaInfo.ragRulesApplied || []).length > 0 && (
                  <div className="flex flex-wrap items-center gap-1.5 mt-2">
                    <span className="text-[10px] uppercase font-bold text-slate tracking-wider mr-1">Règles appliquées :</span>
                    {(metaInfo.ragRulesApplied || []).map((r: string, idx: number) => (
                      <span key={idx} className="px-2 py-0.5 rounded text-[11px] bg-white/5 text-slate-light border border-white/10">
                        {r}
                      </span>
                    ))}
                  </div>
                )}
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => {
                    setSelectedOutfitForEmail(recommendations[0] || null);
                    setIsEmailModalOpen(true);
                  }}
                  className="px-3.5 py-2 bg-gold/15 hover:bg-gold/25 text-gold rounded-xl text-xs border border-gold/40 flex items-center gap-1.5 transition-all shadow-md shadow-gold/10 font-bold"
                  title="Recevoir le récapitulatif par e-mail"
                >
                  <Mail size={14} />
                  <span>Recevoir par E-mail</span>
                </button>
                <button
                  type="button"
                  onClick={isSpeaking ? stopSpeech : speakAdvice}
                  className={`p-2.5 rounded-xl transition-all border ${
                    isSpeaking
                      ? "bg-red-400/20 text-red-400 border-red-400/30"
                      : "bg-white/5 text-gold border-white/10 hover:border-gold/40 hover:scale-105"
                  }`}
                  title={isSpeaking ? "Arrêter la voix" : "Écouter les conseils du styliste"}
                >
                  {isSpeaking ? <VolumeX size={16} /> : <Volume2 size={16} />}
                </button>
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="px-3.5 py-2 bg-white/5 hover:bg-white/10 text-slate hover:text-white rounded-xl text-xs border border-white/10 flex items-center gap-1.5 transition-colors"
                >
                  <RefreshCcw size={14} />
                  <span>Nouveau Scan</span>
                </button>
              </div>
            </div>

            {/* Recommendations Grid */}
            {isLoadingRecs ? (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
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
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
                {recommendations.map((item, index) => (
                  <GlassCard
                    key={index}
                    className="p-0 overflow-hidden group border-white/5 hover:border-gold/30 transition-all duration-500 flex flex-col h-full"
                  >
                    <div className="relative aspect-[4/5] overflow-hidden bg-white/5">
                      {/* Skeleton loader for image */}
                      {!imageLoaded[index] && (
                        <div className="absolute inset-0 flex flex-col items-center justify-center bg-gradient-to-br from-white/3 to-white/8 animate-pulse gap-3">
                          <Loader2 size={28} className="text-gold/50 animate-spin" />
                          <span className="text-[10px] text-slate/50 uppercase tracking-widest font-bold">
                            Génération photo IA...
                          </span>
                        </div>
                      )}

                      {item.imageUrl && (
                        <img
                          src={item.imageUrl}
                          alt={item.name}
                          className={`w-full h-full object-cover group-hover:scale-105 transition-all duration-700 ${
                            imageLoaded[index] ? "opacity-100" : "opacity-0"
                          }`}
                          onLoad={() => setImageLoaded((prev) => ({ ...prev, [index]: true }))}
                        />
                      )}

                      <div className="absolute inset-0 bg-gradient-to-t from-navy/80 via-transparent to-transparent" />

                      <div className="absolute bottom-4 left-4">
                        <div className="flex items-center gap-1.5 bg-navy/80 backdrop-blur-md px-3 py-1 rounded-full border border-gold/30 shadow-xl">
                          <Sparkles size={13} className="text-gold" />
                          <span className="text-gold font-bold text-xs">{item.match}% Match</span>
                        </div>
                      </div>
                    </div>

                    <div className="p-5 space-y-3 flex-1 flex flex-col justify-between">
                      <div>
                        <div className="flex items-center gap-1.5 text-gold-light text-[11px] font-bold uppercase tracking-wider mb-1">
                          <Tag size={12} />
                          <span>{item.context}</span>
                        </div>
                        <h3 className="text-lg font-bold text-white group-hover:text-gold transition-colors">
                          {item.name}
                        </h3>
                        <p className="text-slate text-xs leading-relaxed mt-1.5">{item.description}</p>
                      </div>

                      <div className="space-y-3 pt-3 border-t border-white/5">
                        <div className="flex flex-wrap gap-1.5">
                          {item.tags.map((tag, tIdx) => (
                            <span
                              key={tIdx}
                              className="text-[10px] uppercase font-semibold bg-white/5 px-2 py-0.5 rounded border border-white/10 text-slate-light"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>

                        <button
                          type="button"
                          onClick={() => {
                            setSelectedOutfitForEmail(item);
                            setIsEmailModalOpen(true);
                          }}
                          className="w-full py-2 px-3 bg-white/5 hover:bg-gold/20 text-slate hover:text-gold border border-white/10 hover:border-gold/40 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition-all"
                        >
                          <Mail size={13} />
                          <span>Recevoir ce look par e-mail</span>
                        </button>
                      </div>
                    </div>
                  </GlassCard>
                ))}
              </div>
            )}

            {/* Lead Capture & Full Portal Call-to-Action */}
            <GlassCard className="p-6 sm:p-8 border-gold/30 bg-gradient-to-r from-navy/90 via-navy/70 to-gold/10 flex flex-col sm:flex-row justify-between items-center gap-6 mt-8">
              <div className="space-y-1 text-center sm:text-left">
                <h3 className="text-lg font-bold text-white flex items-center justify-center sm:justify-start gap-2">
                  <Sparkles className="text-gold" size={18} />
                  <span>Envie de sauvegarder vos tenues et synchroniser votre agenda ?</span>
                </h3>
                <p className="text-xs text-slate">
                  Créez votre compte Reflecto complet pour accéder à l'historique permanent, l'agenda connecté et les suggestions automatiques chaque matin.
                </p>
              </div>

              <div className="flex flex-col sm:flex-row items-center gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setSelectedOutfitForEmail(recommendations[0] || null);
                    setIsEmailModalOpen(true);
                  }}
                  className="px-5 py-3 rounded-xl text-xs font-bold text-white bg-white/10 hover:bg-white/20 border border-white/15 flex items-center gap-2 transition-all whitespace-nowrap"
                >
                  <Mail size={14} className="text-gold" />
                  <span>M'envoyer le récapitulatif</span>
                </button>
                <Link
                  href="/login"
                  className="bg-gold hover:bg-gold-light text-navy font-extrabold px-6 py-3 rounded-xl text-xs flex items-center gap-2 transition-all shadow-lg shadow-gold/20 whitespace-nowrap"
                >
                  <span>Créer mon compte complet</span>
                  <ArrowRight size={14} />
                </Link>
              </div>
            </GlassCard>
          </motion.div>
        )}
      </main>

      {/* Email Capture Modal for Guest Demo */}
      <EmailCaptureModal
        isOpen={isEmailModalOpen}
        onClose={() => setIsEmailModalOpen(false)}
        eventContext={customEvent.trim() || selectedEvent}
        detectedProfile={{
          gender: analysisResult?.gender || (genderChoice === "auto" ? "unisex" : genderChoice),
          morphology: analysisResult?.morphology || "H-Shape",
          skin_tone: analysisResult?.skinTone || "Warm",
          suggestions: analysisResult?.suggestions,
        }}
        weather={weather}
        recommendedOutfit={
          selectedOutfitForEmail
            ? {
                name: selectedOutfitForEmail.name,
                description: selectedOutfitForEmail.description,
                image_url: selectedOutfitForEmail.imageUrl || "https://image.pollinations.ai/prompt/luxury%20fashion%20model?width=400&height=500&nologo=true",
                tags: selectedOutfitForEmail.tags,
                match: selectedOutfitForEmail.match,
              }
            : recommendations[0]
            ? {
                name: recommendations[0].name,
                description: recommendations[0].description,
                image_url: recommendations[0].imageUrl || "https://image.pollinations.ai/prompt/luxury%20fashion%20model?width=400&height=500&nologo=true",
                tags: recommendations[0].tags,
                match: recommendations[0].match,
              }
            : undefined
        }
      />
    </div>
  );
}
