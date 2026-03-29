"use client";

import { useState, useEffect } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { 
  User, 
  Settings as SettingsIcon, 
  Bell, 
  Mic, 
  Shield, 
  Palette, 
  Eye, 
  Mail, 
  Camera, 
  Phone, 
  LogOut,
  X,
  Save
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAuth } from "@/lib/auth-context";

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState("profile");
  const { user, logout, updateUser } = useAuth();
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  // Settings States
  const [notifications, setNotifications] = useState({
    push: true,
    email: false
  });
  const [accessibility, setAccessibility] = useState({
    voice: true,
    contrast: false
  });

  const settingsTabs = [
    { id: "profile", label: "Profile", icon: User },
    { id: "style", label: "Style Preferences", icon: Palette },
    { id: "system", label: "System", icon: SettingsIcon },
    { id: "security", label: "Security", icon: Shield }
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-700 max-w-5xl mx-auto pb-20">
      <header>
        <h1 className="text-2xl md:text-4xl font-bold text-beige mb-1 md:mb-2">Settings</h1>
        <p className="text-slate text-sm md:text-lg">Manage your account and mirror preferences.</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 md:gap-8">
        {/* Navigation Tabs */}
        <div className="flex lg:flex-col gap-2 overflow-x-auto pb-2 lg:pb-0 scrollbar-hide">
          {settingsTabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all whitespace-nowrap flex-shrink-0 lg:w-full ${
                activeTab === tab.id 
                  ? "bg-gold text-navy font-bold shadow-lg shadow-gold/10" 
                  : "text-slate hover:bg-white/5 hover:text-beige"
              }`}
            >
              <tab.icon size={20} />
              <span>{tab.label}</span>
            </button>
          ))}
          
          <div className="pt-4 lg:pt-8 mt-4 lg:mt-8 border-t border-white/5 hidden lg:block">
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
                <GlassCard className="flex flex-col md:flex-row items-center gap-6 md:gap-8 p-5 md:p-8">
                  <div className="relative group">
                    <div className="w-24 h-24 md:w-32 md:h-32 rounded-3xl bg-white/5 border border-white/10 flex items-center justify-center overflow-hidden">
                       <User size={64} className="text-slate/30" />
                    </div>
                    <button className="absolute bottom-2 right-2 p-2 bg-gold rounded-xl text-navy shadow-lg scale-0 group-hover:scale-100 transition-transform">
                       <Camera size={16} />
                    </button>
                  </div>
                  <div className="flex-1 text-center md:text-left">
                     <h3 className="text-xl md:text-2xl font-bold text-white mb-1">{user?.name || "User Name"}</h3>
                     <p className="text-slate mb-4">
                        {user?.morphology || "H-Shape"} | {user?.skinTone || "Warm Tone"} | {user?.subscription || "Premium Member"}
                     </p>
                     <div className="flex flex-wrap justify-center md:justify-start gap-4">
                        <div className="flex items-center gap-2 text-xs text-slate-light bg-white/5 px-3 py-1.5 rounded-lg border border-white/5">
                           <Mail size={14} className="text-gold" />
                           {user?.email || "user@example.com"}
                        </div>
                        <div className="flex items-center gap-2 text-xs text-slate-light bg-white/5 px-3 py-1.5 rounded-lg border border-white/5">
                           <Phone size={14} className="text-cyan-electric" />
                           {user?.phone || "+261 34 00 000 00"}
                        </div>
                     </div>
                  </div>
                  <button 
                    onClick={() => setIsModalOpen(true)}
                    className="px-6 py-2 border border-gold text-gold rounded-xl hover:bg-gold hover:text-navy transition-all font-bold text-sm"
                  >
                     Edit Profile
                  </button>
                </GlassCard>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                   <GlassCard className="space-y-4">
                      <h4 className="font-bold border-b border-white/5 pb-2 text-gold">Notifications</h4>
                      <ToggleSetting 
                        icon={Bell} 
                        label="Push Notifications" 
                        description="Updates about new suggestions" 
                        active={notifications.push} 
                        onToggle={() => setNotifications(prev => ({ ...prev, push: !prev.push }))}
                      />
                      <ToggleSetting 
                        icon={Mail} 
                        label="Email Weekly Digest" 
                        description="Summary of your best looks" 
                        active={notifications.email} 
                        onToggle={() => setNotifications(prev => ({ ...prev, email: !prev.email }))}
                      />
                   </GlassCard>
                   
                   <GlassCard className="space-y-4">
                      <h4 className="font-bold border-b border-white/5 pb-2 text-cyan-electric">Accessibility</h4>
                      <ToggleSetting 
                        icon={Mic} 
                        label="Voice Feedback (TTS)" 
                        description="Assistant speaks suggestions" 
                        active={accessibility.voice} 
                        onToggle={() => setAccessibility(prev => ({ ...prev, voice: !prev.voice }))}
                      />
                      <ToggleSetting 
                        icon={Eye} 
                        label="High Contrast Mode" 
                        description="Enhanced UI visibility" 
                        active={accessibility.contrast} 
                        onToggle={() => setAccessibility(prev => ({ ...prev, contrast: !prev.contrast }))}
                      />
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

      {/* Edit Profile Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              className="absolute inset-0 bg-navy/80 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-lg glass-gold rounded-3xl p-5 md:p-8 border border-gold/30 shadow-2xl overflow-hidden max-h-[90vh] overflow-y-auto"
            >
              <div className="absolute top-0 right-0 p-4">
                <button 
                  onClick={() => setIsModalOpen(false)}
                  className="p-2 text-slate hover:text-white transition-colors"
                >
                  <X size={24} />
                </button>
              </div>

              <h2 className="text-2xl font-bold text-gold mb-6 flex items-center gap-3">
                <User size={24} />
                Edit Your Profile
              </h2>

              <form className="space-y-5" onSubmit={(e) => {
                e.preventDefault();
                const formData = new FormData(e.currentTarget);
                updateUser({
                  name: formData.get("name") as string,
                  email: formData.get("email") as string,
                  phone: formData.get("phone") as string,
                  morphology: formData.get("morphology") as string,
                  skinTone: formData.get("skinTone") as string,
                });
                setIsModalOpen(false);
              }}>
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate uppercase tracking-wider">Full Name</label>
                  <input 
                    name="name"
                    defaultValue={user?.name}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all"
                  />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-slate uppercase tracking-wider">Email Address</label>
                    <input 
                      name="email"
                      defaultValue={user?.email}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all text-sm"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-slate uppercase tracking-wider">Phone Number</label>
                    <input 
                      name="phone"
                      defaultValue={user?.phone}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all text-sm"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-slate uppercase tracking-wider">Silouhette</label>
                    <select 
                      name="morphology"
                      defaultValue={user?.morphology}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all text-sm appearance-none"
                    >
                      <option value="H-Shape">H-Shape</option>
                      <option value="V-Shape">V-Shape</option>
                      <option value="A-Shape">A-Shape</option>
                      <option value="X-Shape">X-Shape</option>
                    </select>
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-slate uppercase tracking-wider">Skin Tone</label>
                    <select 
                      name="skinTone"
                      defaultValue={user?.skinTone}
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold outline-none transition-all text-sm appearance-none"
                    >
                      <option value="Warm Tone">Warm Tone</option>
                      <option value="Cool Tone">Cool Tone</option>
                      <option value="Neutral Tone">Neutral Tone</option>
                    </select>
                  </div>
                </div>

                <button 
                  type="submit"
                  className="w-full mt-4 bg-gold text-navy font-bold py-4 rounded-xl flex items-center justify-center gap-2 hover:scale-[1.02] transition-all shadow-lg"
                >
                  <Save size={20} />
                  Save Changes
                </button>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

const ToggleSetting = ({ icon: Icon, label, description, active, onToggle }: { 
  icon: any, 
  label: string, 
  description: string, 
  active: boolean,
  onToggle: () => void
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
    <div 
      onClick={onToggle}
      className={`w-12 h-6 rounded-full relative cursor-pointer transition-colors shadow-inner ${active ? 'bg-gold' : 'bg-white/10'}`}
    >
       <motion.div 
         animate={{ x: active ? 24 : 4 }}
         initial={false}
         className="absolute top-1 w-4 h-4 bg-navy rounded-full shadow-md" 
       />
    </div>
  </div>
);
