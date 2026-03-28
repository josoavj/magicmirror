"use client";

import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { User, Settings as SettingsIcon, Bell, Mic, Shield, Palette, Eye, Mail, Camera, Phone, LogOut } from "lucide-react";
import { motion } from "framer-motion";
import { useAuth } from "@/lib/auth-context";

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState("profile");
  const { user, logout } = useAuth();

  const settingsTabs = [
    { id: "profile", label: "Profile", icon: User },
    { id: "style", label: "Style Preferences", icon: Palette },
    { id: "system", label: "System", icon: SettingsIcon },
    { id: "security", label: "Security", icon: Shield }
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-700 max-w-5xl mx-auto">
      <header>
        <h1 className="text-4xl font-bold text-beige mb-2">Settings</h1>
        <p className="text-slate text-lg">Manage your account and mirror preferences.</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        {/* Navigation Tabs */}
        <div className="space-y-2">
          {settingsTabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                activeTab === tab.id 
                  ? "bg-gold text-navy font-bold shadow-lg shadow-gold/10" 
                  : "text-slate hover:bg-white/5 hover:text-beige"
              }`}
            >
              <tab.icon size={20} />
              <span>{tab.label}</span>
            </button>
          ))}
          
          <div className="pt-8 mt-8 border-t border-white/5">
             <button 
                onClick={logout}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-400 hover:bg-red-400/10 transition-all font-bold"
             >
                <LogOut size={20} />
                <span>Sign Out</span>
             </button>
          </div>
        </div>

        {/* Content Area */}
        <div className="lg:col-span-3 space-y-6">
          <AnimatePresence mode="wait">
            {activeTab === "profile" && (
              <motion.div
                key="profile"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="space-y-6"
              >
                <GlassCard className="flex flex-col md:flex-row items-center gap-8 p-8">
                  <div className="relative group">
                    <div className="w-32 h-32 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center overflow-hidden">
                       <User size={64} className="text-slate/30" />
                    </div>
                    <button className="absolute bottom-2 right-2 p-2 bg-gold rounded-xl text-navy shadow-lg scale-0 group-hover:scale-100 transition-transform">
                       <Camera size={16} />
                    </button>
                  </div>
                  <div className="flex-1 text-center md:text-left">
                     <h3 className="text-2xl font-bold text-white mb-1">{user?.name || "User Name"}</h3>
                     <p className="text-slate mb-4">H-Shape | Warm Tone | Premium Member</p>
                     <div className="flex flex-wrap justify-center md:justify-start gap-4">
                        <div className="flex items-center gap-2 text-xs text-slate-light bg-white/5 px-3 py-1.5 rounded-lg border border-white/5">
                           <Mail size={14} className="text-gold" />
                           user@example.com
                        </div>
                        <div className="flex items-center gap-2 text-xs text-slate-light bg-white/5 px-3 py-1.5 rounded-lg border border-white/5">
                           <Phone size={14} className="text-cyan-electric" />
                           +261 34 00 000 00
                        </div>
                     </div>
                  </div>
                  <button className="px-6 py-2 border border-gold text-gold rounded-xl hover:bg-gold hover:text-navy transition-all font-bold text-sm">
                     Edit Profile
                  </button>
                </GlassCard>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                   <GlassCard className="space-y-4">
                      <h4 className="font-bold border-b border-white/5 pb-2 text-gold">Notifications</h4>
                      <ToggleSetting icon={Bell} label="Push Notifications" description="Updates about new suggestions" active={true} />
                      <ToggleSetting icon={Mail} label="Email Weekly Digest" description="Summary of your best looks" active={false} />
                   </GlassCard>
                   
                   <GlassCard className="space-y-4">
                      <h4 className="font-bold border-b border-white/5 pb-2 text-cyan-electric">Accessibility</h4>
                      <ToggleSetting icon={Mic} label="Voice Feedback (TTS)" description="Assistant speaks suggestions" active={true} />
                      <ToggleSetting icon={Eye} label="High Contrast Mode" description="Enhanced UI visibility" active={false} />
                   </GlassCard>
                </div>
              </motion.div>
            )}
            
            {activeTab !== "profile" && (
              <motion.div
                key="other"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="h-64 flex items-center justify-center glass rounded-3xl"
              >
                <p className="text-slate italic font-medium">This section is being reflected...</p>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  );
}

const ToggleSetting = ({ icon: Icon, label, description, active }: { 
  icon: any, 
  label: string, 
  description: string, 
  active: boolean 
}) => (
  <div className="flex items-center justify-between py-2">
    <div className="flex items-center gap-3">
      <div className="p-2 bg-white/5 rounded-lg text-slate">
        <Icon size={18} />
      </div>
      <div>
        <p className="text-sm font-bold text-beige">{label}</p>
        <p className="text-[10px] text-slate">{description}</p>
      </div>
    </div>
    <div className={`w-12 h-6 rounded-full relative cursor-pointer transition-colors ${active ? 'bg-gold' : 'bg-white/10'}`}>
       <div className={`absolute top-1 w-4 h-4 bg-navy rounded-full transition-all ${active ? 'right-1' : 'left-1'}`} />
    </div>
  </div>
);

const AnimatePresence = ({ children, mode }: { children: any, mode?: any }) => children;
