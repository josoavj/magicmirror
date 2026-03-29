"use client";

import { useState, useEffect, useRef } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Camera as CameraIcon, Scan, RefreshCcw, CheckCircle2, Loader2, Sparkles, VideoOff } from "lucide-react";
import { analyzeOutfit } from "@/lib/mock-services";
import { motion, AnimatePresence } from "framer-motion";
import { useCamera } from "@/lib/camera-context";

export default function CameraPage() {
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const { stream, startCamera, stopCamera, error: cameraError } = useCamera();
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    startCamera();
    return () => stopCamera();
  }, []);

  useEffect(() => {
    if (stream && videoRef.current) {
      videoRef.current.srcObject = stream;
    }
  }, [stream]);

  const handleAnalyze = async () => {
    setIsAnalyzing(true);
    setAnalysisResult(null);
    try {
      const result = await analyzeOutfit("mock-image-data");
      setAnalysisResult(result);
    } catch (error) {
      console.error("Analysis failed", error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700 max-w-5xl mx-auto">
      <header className="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4">
        <div>
          <h1 className="text-2xl md:text-4xl font-bold text-white mb-1 md:mb-2">Smart Mirror</h1>
          <p className="text-slate text-sm md:text-lg italic">"Mirror, mirror on the wall, what's my style after all?"</p>
        </div>
        <div className="p-3 bg-cyan-electric/10 rounded-full text-cyan-electric animate-pulse">
          <Scan size={24} />
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
        <div className="lg:col-span-2 relative aspect-[3/4] max-h-[70vh] lg:max-h-none rounded-3xl overflow-hidden glass border-2 border-white/5 group shadow-2xl bg-black">
          <video 
            ref={videoRef}
            autoPlay 
            playsInline 
            muted 
            className="absolute inset-0 w-full h-full object-cover scale-x-[-1]" 
          />

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
            {!stream && !cameraError && (
              <div className="text-center space-y-4">
                <Loader2 size={48} className="text-gold animate-spin" />
                <p className="text-gold font-bold">Initializing Mirror...</p>
              </div>
            )}
            
            {cameraError && (
              <div className="text-center space-y-4 p-8 glass mx-8 pointer-events-auto">
                <VideoOff size={48} className="text-red-400 mx-auto" />
                <p className="text-white font-medium">{cameraError}</p>
                <button 
                  onClick={startCamera}
                  className="px-6 py-2 bg-gold text-navy rounded-full font-bold text-sm"
                >
                  Try Again
                </button>
              </div>
            )}
            
            {isAnalyzing && (
              <div className="text-center space-y-4 bg-navy/40 backdrop-blur-md p-6 rounded-3xl border border-cyan-electric/30">
                <div className="relative">
                  <div className="absolute inset-0 animate-ping bg-cyan-electric/20 rounded-full" />
                  <Loader2 size={64} className="text-cyan-electric animate-spin relative" />
                </div>
                <p className="text-cyan-electric font-bold tracking-widest uppercase">Analyzing Silhouette...</p>
              </div>
            )}
          </div>

          {stream && (
            <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex gap-4 z-30">
              <button
                onClick={handleAnalyze}
                disabled={isAnalyzing}
                className="bg-gold hover:bg-gold-light disabled:bg-slate-shadow text-navy px-8 py-3 rounded-full font-bold shadow-lg shadow-gold/20 flex items-center gap-3 transition-all active:scale-95"
              >
                {isAnalyzing ? "Processing..." : analysisResult ? "Re-analyze" : "Analyze My Outfit"}
                {!isAnalyzing && <Sparkles size={20} />}
              </button>
              <button 
                onClick={() => { stopCamera(); startCamera(); }}
                className="bg-white/10 backdrop-blur-md text-white p-3 rounded-full border border-white/10 hover:bg-white/20 transition-all pointer-events-auto"
              >
                <RefreshCcw size={24} />
              </button>
            </div>
          )}
        </div>

        <div className="space-y-6">
          <GlassCard className="p-6">
            <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
              <CheckCircle2 className="text-gold" size={20} />
              Analysis Results
            </h3>
            
            {analysisResult ? (
              <div className="space-y-6 animate-in slide-in-from-right duration-500">
                <ResultItem label="Morphology" value={analysisResult.morphology} />
                <ResultItem label="Silhouette" value={analysisResult.silhouette} />
                <ResultItem label="Skin Tone" value={analysisResult.skinTone} />
                <div className="pt-4 border-t border-white/5">
                  <p className="text-xs text-slate-shadow uppercase tracking-widest mb-2 font-bold">Confidence Score</p>
                  <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                    <motion.div 
                      initial={{ width: 0 }}
                      animate={{ width: `${analysisResult.confidence * 100}%` }}
                      className="h-full bg-gold shadow-[0_0_10px_rgba(212,165,116,0.5)]"
                    />
                  </div>
                </div>
              </div>
            ) : (
              <div className="h-64 flex flex-col items-center justify-center text-center space-y-4 opacity-30">
                <Scan size={48} />
                <p className="text-sm font-medium">Stand clearly in front of the mirror and press analyze</p>
              </div>
            )}
          </GlassCard>

          <GlassCard variant="ai" className="p-6">
            <h4 className="font-bold text-white mb-2">Pro Tip</h4>
            <p className="text-sm text-white/70 leading-relaxed">
              Ensure you have good lighting from the front and enough distance for a full-body scan.
            </p>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}

const ResultItem = ({ label, value }: { label: string, value: string }) => (
  <div>
    <p className="text-xs text-slate-shadow uppercase tracking-widest mb-1 font-bold">{label}</p>
    <p className="text-lg font-bold text-gold">{value}</p>
  </div>
);
