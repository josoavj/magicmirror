"use client";

import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import {
  Mail,
  Sparkles,
  CheckCircle2,
  X,
  Send,
  Loader2,
  ShieldCheck,
  Tag,
  AlertCircle,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import {
  sendNotificationWebhook,
  isValidEmail,
  GuestWelcomePayload,
} from "@/lib/services/notification-service";

interface EmailCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventContext: string;
  detectedProfile: {
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
  recommendedOutfit?: {
    name: string;
    description: string;
    image_url: string;
    tags?: string[];
    match: number;
  };
}

export const EmailCaptureModal = ({
  isOpen,
  onClose,
  eventContext,
  detectedProfile,
  weather,
  recommendedOutfit,
}: EmailCaptureModalProps) => {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValidEmail(email)) {
      setStatus("error");
      setErrorMessage("Veuillez saisir une adresse e-mail valide.");
      return;
    }

    setStatus("loading");
    setErrorMessage("");

    const payload: GuestWelcomePayload = {
      type: "guest_welcome_and_recap",
      user_email: email.trim(),
      event_context: eventContext,
      detected_profile: detectedProfile,
      weather: weather,
      recommended_outfit: recommendedOutfit || {
        name: "Look Signature Reflecto",
        description: `Tenue haute couture ajustée pour ${eventContext}.`,
        image_url: "https://image.pollinations.ai/prompt/luxury%20fashion%20model?width=400&height=500&nologo=true",
        match: 95,
      },
      sent_at: new Date().toISOString(),
    };

    const result = await sendNotificationWebhook(payload);

    if (result.success) {
      setStatus("success");
    } else {
      setStatus("error");
      setErrorMessage(result.error || "Impossible d'envoyer l'e-mail. Veuillez réessayer.");
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in duration-300">
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="w-full max-w-lg relative"
        >
          <GlassCard className="p-6 sm:p-8 border-gold/40 shadow-2xl relative overflow-hidden bg-navy/95">
            {/* Close button */}
            <button
              onClick={onClose}
              className="absolute top-4 right-4 p-2 text-slate hover:text-white rounded-full bg-white/5 hover:bg-white/10 transition-colors"
            >
              <X size={18} />
            </button>

            {status === "success" ? (
              <div className="text-center py-6 space-y-4 animate-in zoom-in-95 duration-300">
                <div className="w-16 h-16 bg-emerald-500/20 text-emerald-400 rounded-full flex items-center justify-center mx-auto border border-emerald-500/40">
                  <CheckCircle2 size={36} />
                </div>
                <h3 className="text-2xl font-bold text-white">Récapitulatif Envoyé !</h3>
                <p className="text-sm text-slate max-w-sm mx-auto">
                  Votre sélection de style pour <strong className="text-gold">"{eventContext}"</strong> a été transmise à{" "}
                  <strong className="text-white">{email}</strong>.
                </p>
                <div className="pt-4">
                  <button
                    onClick={onClose}
                    className="bg-gold hover:bg-gold-light text-navy font-bold px-8 py-2.5 rounded-xl text-sm transition-all shadow-lg shadow-gold/20"
                  >
                    Fermer
                  </button>
                </div>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                {/* Header */}
                <div className="space-y-1.5 text-center sm:text-left">
                  <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-gold/15 text-gold border border-gold/30 uppercase tracking-wider mb-1">
                    <Sparkles size={12} />
                    <span>Récapitulatif de Style</span>
                  </div>
                  <h3 className="text-xl sm:text-2xl font-extrabold text-white">
                    Recevez votre look par E-mail
                  </h3>
                  <p className="text-xs text-slate">
                    Conservez votre fiche morphologique et la photo haute résolution de votre tenue idéale pour{" "}
                    <strong className="text-gold">"{eventContext}"</strong>.
                  </p>
                </div>

                {/* Outfit Preview Card */}
                {recommendedOutfit && (
                  <div className="flex items-center gap-3 p-3 bg-white/5 rounded-2xl border border-white/10">
                    <div className="w-14 h-16 rounded-xl overflow-hidden bg-white/5 flex-shrink-0">
                      <img
                        src={recommendedOutfit.image_url}
                        alt={recommendedOutfit.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="min-w-0 flex-1">
                      <h4 className="text-sm font-bold text-white truncate">
                        {recommendedOutfit.name}
                      </h4>
                      <p className="text-xs text-slate truncate">
                        {recommendedOutfit.description}
                      </p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] text-gold font-bold">
                          {recommendedOutfit.match}% Match
                        </span>
                        <span className="text-[10px] text-slate/70">
                          {detectedProfile.morphology} • {detectedProfile.skin_tone}
                        </span>
                      </div>
                    </div>
                  </div>
                )}

                {/* Email Input */}
                <div className="space-y-2">
                  <label className="text-xs font-semibold text-gold uppercase tracking-wider block">
                    Votre adresse e-mail :
                  </label>
                  <div className="relative">
                    <Mail
                      className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate/50"
                      size={18}
                    />
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="nom@exemple.com"
                      className="w-full bg-navy/60 border border-white/15 rounded-xl pl-10 pr-4 py-3 text-sm text-white placeholder:text-slate/40 focus:border-gold/60 focus:ring-1 focus:ring-gold/60 outline-none transition-all"
                    />
                  </div>
                </div>

                {/* Error message */}
                {status === "error" && (
                  <div className="p-3 bg-red-900/30 border border-red-500/40 rounded-xl text-xs text-red-300 flex items-center gap-2">
                    <AlertCircle size={15} className="flex-shrink-0" />
                    <span>{errorMessage}</span>
                  </div>
                )}

                {/* Submit button */}
                <div className="flex flex-col sm:flex-row gap-3 pt-2">
                  <button
                    type="submit"
                    disabled={status === "loading"}
                    className="flex-1 bg-gold hover:bg-gold-light text-navy font-bold py-3 px-4 rounded-xl text-sm flex items-center justify-center gap-2 transition-all shadow-lg shadow-gold/20 disabled:opacity-50"
                  >
                    {status === "loading" ? (
                      <>
                        <Loader2 size={16} className="animate-spin" />
                        <span>Envoi vers Make.com...</span>
                      </>
                    ) : (
                      <>
                        <Send size={16} />
                        <span>Envoyer mon look</span>
                      </>
                    )}
                  </button>
                  <button
                    type="button"
                    onClick={onClose}
                    className="py-3 px-4 text-xs font-semibold text-slate hover:text-white rounded-xl border border-white/10 hover:bg-white/5 transition-colors"
                  >
                    Passer
                  </button>
                </div>

                {/* GDPR Disclaimer */}
                <p className="text-[11px] text-slate/50 text-center flex items-center justify-center gap-1">
                  <ShieldCheck size={12} className="text-cyan-electric" />
                  Vos données restent strictement confidentielles et ne sont jamais revendues.
                </p>
              </form>
            )}
          </GlassCard>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
