"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { useAuth } from "@/hooks/useAuth";
import { useProfile } from "@/hooks/useProfile";
import {
  User, Ruler, Palette, Sparkles, ArrowRight, ArrowLeft, CheckCircle2, Loader2
} from "lucide-react";

const STEPS = [
  { id: 1, title: "Who are you?", icon: User, description: "Let's personalize your mirror." },
  { id: 2, title: "Your physique", icon: Ruler, description: "Helps us tailor outfits to your proportions." },
  { id: 3, title: "Your style", icon: Palette, description: "Define your fashion DNA." },
];

export default function OnboardingPage() {
  const router = useRouter();
  const { user } = useAuth();
  const { updateProfile } = useProfile();
  const [step, setStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [form, setForm] = useState({
    first_name: "",
    age: "",
    gender: "Male",
    height_cm: "",
    weight_kg: "",
    body_type: "H-Shape",
    skin_tone: "Warm Tone",
    style_preference: "Casual",
  });

  const set = (key: string, value: string) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const handleFinish = async () => {
    if (!user?.id) return;
    setIsSubmitting(true);
    await updateProfile(user.id, {
      first_name: form.first_name || null,
      age: form.age ? parseInt(form.age) : null,
      height_cm: form.height_cm ? parseInt(form.height_cm) : null,
      weight_kg: form.weight_kg ? parseInt(form.weight_kg) : null,
      gender: form.gender,
      body_type: form.body_type,
      skin_tone: form.skin_tone,
      style_preference: form.style_preference,
      onboarding_completed: true,
    });
    router.push("/dashboard");
    router.refresh();
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-12 bg-navy">
      {/* Ambient glow */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-gold/5 rounded-full blur-[120px]" />
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-cyan-electric/5 rounded-full blur-[100px]" />
      </div>

      <div className="relative w-full max-w-lg">
        {/* Header */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-gold/10 border border-gold/20 rounded-full text-gold text-sm font-medium mb-6">
            <Sparkles size={14} />
            Setting up your mirror
          </div>
          <h1 className="text-3xl md:text-4xl font-extrabold text-white tracking-tight">
            {STEPS[step].title}
          </h1>
          <p className="mt-2 text-slate text-sm">{STEPS[step].description}</p>
        </div>

        {/* Step indicator */}
        <div className="flex items-center justify-center gap-3 mb-10">
          {STEPS.map((s, i) => (
            <div key={s.id} className="flex items-center gap-3">
              <motion.div
                animate={{
                  scale: i === step ? 1.15 : 1,
                  backgroundColor:
                    i < step ? "#D4A574" : i === step ? "#D4A574" : "rgba(255,255,255,0.1)",
                }}
                className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-navy"
              >
                {i < step ? <CheckCircle2 size={16} className="text-navy" /> : i + 1}
              </motion.div>
              {i < STEPS.length - 1 && (
                <div className={`w-12 h-px ${i < step ? "bg-gold" : "bg-white/10"}`} />
              )}
            </div>
          ))}
        </div>

        {/* Card */}
        <div className="glass rounded-3xl border border-white/10 p-8 shadow-2xl">
          <AnimatePresence mode="wait">
            {step === 0 && (
              <motion.div
                key="step0"
                initial={{ opacity: 0, x: 30 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -30 }}
                className="space-y-5"
              >
                <FormField label="First Name" hint="Will be displayed on your dashboard">
                  <input
                    type="text"
                    placeholder="e.g. Diana"
                    value={form.first_name}
                    onChange={(e) => set("first_name", e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/30 outline-none transition-all text-sm"
                  />
                </FormField>
                <FormField label="Age" hint="Helps the AI adapt your style recommendations">
                  <input
                    type="number"
                    placeholder="e.g. 24"
                    min={10}
                    max={100}
                    value={form.age}
                    onChange={(e) => set("age", e.target.value)}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/30 outline-none transition-all text-sm"
                  />
                </FormField>
                <FormField label="Gender">
                  <SelectField
                    value={form.gender}
                    onChange={(v) => set("gender", v)}
                    options={["Male", "Female", "Non-binary", "Prefer not to say"]}
                  />
                </FormField>
              </motion.div>
            )}

            {step === 1 && (
              <motion.div
                key="step1"
                initial={{ opacity: 0, x: 30 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -30 }}
                className="space-y-5"
              >
                <div className="grid grid-cols-2 gap-4">
                  <FormField label="Height (cm)">
                    <input
                      type="number"
                      placeholder="e.g. 172"
                      min={100}
                      max={250}
                      value={form.height_cm}
                      onChange={(e) => set("height_cm", e.target.value)}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/30 outline-none transition-all text-sm"
                    />
                  </FormField>
                  <FormField label="Weight (kg)">
                    <input
                      type="number"
                      placeholder="e.g. 65"
                      min={30}
                      max={300}
                      value={form.weight_kg}
                      onChange={(e) => set("weight_kg", e.target.value)}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/30 outline-none transition-all text-sm"
                    />
                  </FormField>
                </div>
                <FormField label="Body Shape / Silhouette" hint="Your natural body proportions">
                  <div className="grid grid-cols-2 gap-3">
                    {[
                      { val: "H-Shape", label: "H-Shape", desc: "Balanced proportions" },
                      { val: "V-Shape", label: "V-Shape", desc: "Broader shoulders" },
                      { val: "A-Shape", label: "A-Shape", desc: "Wider hips" },
                      { val: "X-Shape", label: "X-Shape", desc: "Hourglass figure" },
                    ].map((opt) => (
                      <button
                        key={opt.val}
                        type="button"
                        onClick={() => set("body_type", opt.val)}
                        className={`p-3 rounded-xl border text-left transition-all ${
                          form.body_type === opt.val
                            ? "border-gold bg-gold/10 text-gold"
                            : "border-white/10 bg-white/5 text-slate hover:border-white/30"
                        }`}
                      >
                        <p className="font-bold text-sm">{opt.label}</p>
                        <p className="text-[10px] opacity-70">{opt.desc}</p>
                      </button>
                    ))}
                  </div>
                </FormField>
              </motion.div>
            )}

            {step === 2 && (
              <motion.div
                key="step2"
                initial={{ opacity: 0, x: 30 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -30 }}
                className="space-y-5"
              >
                <FormField label="Skin Tone" hint="Used to match complementary outfit colours">
                  <div className="grid grid-cols-3 gap-2">
                    {[
                      { val: "Fair", color: "#F5DEB3" },
                      { val: "Light", color: "#DEB887" },
                      { val: "Warm", color: "#C19A6B" },
                      { val: "Medium", color: "#A0785A" },
                      { val: "Dark", color: "#6B4226" },
                      { val: "Deep", color: "#3B1F0E" },
                    ].map((tone) => (
                      <button
                        key={tone.val}
                        type="button"
                        onClick={() => set("skin_tone", tone.val)}
                        className={`flex items-center gap-2 px-3 py-2.5 rounded-xl border text-xs font-semibold transition-all ${
                          form.skin_tone === tone.val
                            ? "border-gold bg-gold/10 text-gold"
                            : "border-white/10 bg-white/5 text-slate hover:border-white/30"
                        }`}
                      >
                        <span
                          className="w-4 h-4 rounded-full flex-shrink-0 border border-white/20"
                          style={{ backgroundColor: tone.color }}
                        />
                        {tone.val}
                      </button>
                    ))}
                  </div>
                </FormField>
                <FormField label="Style Preference" hint="Your default fashion vibe">
                  <div className="grid grid-cols-3 gap-2">
                    {["Casual", "Formal", "Streetwear", "Chic", "Sportswear", "Elegant"].map(
                      (s) => (
                        <button
                          key={s}
                          type="button"
                          onClick={() => set("style_preference", s)}
                          className={`py-2.5 rounded-xl border text-xs font-semibold transition-all ${
                            form.style_preference === s
                              ? "border-cyan-electric bg-cyan-electric/10 text-cyan-electric"
                              : "border-white/10 bg-white/5 text-slate hover:border-white/30"
                          }`}
                        >
                          {s}
                        </button>
                      )
                    )}
                  </div>
                </FormField>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Navigation */}
          <div className="flex justify-between mt-8 pt-6 border-t border-white/5">
            <button
              onClick={() => setStep((s) => Math.max(0, s - 1))}
              disabled={step === 0}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl text-slate hover:text-white hover:bg-white/5 transition-all disabled:opacity-0"
            >
              <ArrowLeft size={16} /> Back
            </button>

            {step < STEPS.length - 1 ? (
              <button
                onClick={() => setStep((s) => s + 1)}
                className="flex items-center gap-2 px-6 py-2.5 bg-gold hover:bg-gold/90 text-navy font-bold rounded-xl transition-all shadow-lg shadow-gold/20"
              >
                Continue <ArrowRight size={16} />
              </button>
            ) : (
              <button
                onClick={handleFinish}
                disabled={isSubmitting}
                className="flex items-center gap-2 px-6 py-2.5 bg-gold hover:bg-gold/90 text-navy font-bold rounded-xl transition-all shadow-lg shadow-gold/20 disabled:opacity-50"
              >
                {isSubmitting ? (
                  <Loader2 size={16} className="animate-spin" />
                ) : (
                  <CheckCircle2 size={16} />
                )}
                {isSubmitting ? "Saving..." : "Start my journey"}
              </button>
            )}
          </div>
        </div>

        <p className="text-center text-xs text-slate-shadow opacity-40 mt-6 uppercase tracking-widest">
          Powered by ISPM × AI Technology
        </p>
      </div>
    </div>
  );
}

function FormField({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <label className="text-xs font-bold text-gold uppercase tracking-wider">{label}</label>
      {hint && <p className="text-[10px] text-slate-shadow mb-1.5">{hint}</p>}
      {children}
    </div>
  );
}

function SelectField({
  value,
  onChange,
  options,
}: {
  value: string;
  onChange: (v: string) => void;
  options: string[];
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all text-sm appearance-none"
    >
      {options.map((o) => (
        <option key={o} value={o} className="bg-slate-900">
          {o}
        </option>
      ))}
    </select>
  );
}
