"use client";

import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Mail, Lock, LogIn, Globe, ArrowRight, Loader2 } from "lucide-react";
import { useAuth } from "@/lib/auth-context";

export default function AuthPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    const success = await login(email, password);
    if (!success) {
      alert("Please enter both email and password.");
    }
    setIsSubmitting(false);
  };

  return (
    <div className="min-h-[85vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 animate-in fade-in zoom-in duration-500">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <div className="mx-auto h-30 w-30 flex items-center justify-center mb-6">
            <img src="/logo/logo-reflecto-2.png" alt="Reflecto Logo" className="w-full h-full object-contain" />
          </div>
          <h2 className="text-3xl font-extrabold text-white tracking-tight">
            {isLogin ? "Welcome Back to Reflecto" : "Join Reflecto"}
          </h2>
          <p className="mt-2 text-sm text-slate">
            {isLogin ? "Your personal style awaits." : "Start your AI-powered style journey today."}
          </p>
        </div>

        <GlassCard className="mt-8 space-y-6">
          <form className="space-y-4" onSubmit={handleSubmit}>
            <div className="space-y-2">
              <label className="text-xs font-semibold text-gold uppercase tracking-wider ml-1">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate/50" size={18} />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-navy/50 border border-white/10 rounded-xl px-10 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/50 outline-none transition-all"
                  placeholder="name@example.com"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-semibold text-gold uppercase tracking-wider ml-1">Password</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate/50" size={18} />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-navy/50 border border-white/10 rounded-xl px-10 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/50 outline-none transition-all"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-gold hover:bg-gold-light disabled:bg-slate-shadow text-navy font-bold py-3 px-4 rounded-xl flex items-center justify-center gap-2 transition-all duration-300 shadow-lg shadow-gold/10 group"
            >
              {isSubmitting ? (
                <Loader2 size={18} className="animate-spin" />
              ) : (
                <>
                  <span>{isLogin ? "Sign In" : "Create Account"}</span>
                  <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
                </>
              )}
            </button>
          </form>

          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-white/10"></span>
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-[#2C3E50] px-2 text-slate">Or continue with</span>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4">
            <button className="flex items-center justify-center gap-3 w-full bg-white/5 hover:bg-white/10 border border-white/10 py-3 px-4 rounded-xl text-white transition-all group">
              <div className="p-1 bg-white rounded-md">
                <Globe size={16} className="text-navy" />
              </div>
              <span className="font-medium group-hover:text-gold transition-colors text-sm">Connect Google Calendar</span>
            </button>
          </div>

          <p className="text-center text-sm text-slate pt-4">
            {isLogin ? "Don't have an account?" : "Already have an account?"}{" "}
            <button
              onClick={() => setIsLogin(!isLogin)}
              className="font-semibold text-gold hover:text-gold-light underline underline-offset-4 transition-colors"
            >
              {isLogin ? "Sign up" : "Log in"}
            </button>
          </p>
        </GlassCard>

        <p className="mt-8 text-center text-xs text-slate-shadow uppercase tracking-widest opacity-50">
          Powered by ISPM x AI Technology
        </p>
      </div>
    </div>
  );
}
