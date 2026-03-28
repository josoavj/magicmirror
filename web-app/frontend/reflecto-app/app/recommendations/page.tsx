"use client";

import { useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Sparkles, Volume2, ArrowLeft, Heart, Share2, Tag, Calendar, MapPin, RefreshCcw } from "lucide-react";
import { motion } from "framer-motion";

const mockRecommendations = [
  {
    id: 1,
    name: "Golden Hour Corporate",
    context: "Work / Meetings",
    description: "A Navy tailored blazer paired with beige chinos and gold-toned accessories to match your silhouette.",
    image: "https://samsonsurmesure.fr/wp-content/uploads/2024/02/samson-sur-mesure-ete-23-details-3-soren-costume-beige-1.jpg",
    tags: ["Formal", "Elegant", "H-Shape"],
    match: 98
  },
  {
    id: 2,
    name: "Urban Explorer",
    context: "Casual / Weekend",
    description: "Lightweight denim with a structured cyan shirt for a fresh, modern look compatible with your tone.",
    image: "https://images.unsplash.com/photo-1617137968427-85924c800a22?q=80&w=400&h=500&auto=format&fit=crop",
    tags: ["Casual", "Fresh", "Outdoors"],
    match: 85
  },
  {
    id: 3,
    name: "Evening Gala Noir",
    context: "Events / Dinner",
    description: "Deep charcoal suit with a silk gold pocket square. High-contrast elegance for special occasions.",
    image: "https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=400&h=500&auto=format&fit=crop",
    tags: ["Luxury", "Evening", "Formal"],
    match: 92
  }
];

export default function RecommendationsPage() {
  const [activeTab, setActiveTab] = useState("all");

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <header className="flex justify-between items-center">
        <div>
          <button 
            onClick={() => window.history.back()}
            className="flex items-center gap-2 text-slate hover:text-gold transition-colors mb-4 group text-sm"
          >
            <ArrowLeft size={16} className="group-hover:-translate-x-1 transition-transform" />
            Back to analysis
          </button>
          <h1 className="text-4xl font-bold text-beige mb-2">Reflecto Suggestions</h1>
          <p className="text-slate text-lg">AI-tailored looks based on your <strong>H-Shape</strong> silhouette and <strong>Warm</strong> skin tone.</p>
        </div>
        <div className="flex gap-3">
           <button className="p-4 glass-gold rounded-full text-gold hover:scale-110 transition-transform">
             <Volume2 size={24} />
           </button>
        </div>
      </header>

      {/* Quick Context Chips */}
      <div className="flex flex-wrap gap-4 items-center">
        <div className="flex items-center gap-2 px-4 py-2 bg-navy/50 border border-white/5 rounded-full text-sm">
           <Calendar size={14} className="text-gold" />
           <span>Monday, March 28</span>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-navy/50 border border-white/5 rounded-full text-sm">
           <MapPin size={14} className="text-cyan-electric" />
           <span>22°C - Sunny</span>
        </div>
        <div className="h-4 w-px bg-white/10 mx-2" />
        {["all", "work", "casual", "events"].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-6 py-2 rounded-full text-sm font-medium capitalize transition-all ${
              activeTab === tab 
                ? "bg-gold text-navy shadow-lg" 
                : "bg-white/5 text-slate hover:text-beige hover:bg-white/10"
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Recommendations Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        {mockRecommendations.map((item, index) => (
          <motion.div
            key={item.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
          >
            <GlassCard className="p-0 overflow-hidden group border-white/5 hover:border-gold/30 transition-all duration-500 flex flex-col h-full">
              <div className="relative aspect-[4/5] overflow-hidden">
                <img 
                  src={item.image} 
                  alt={item.name} 
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                />
                <div className="absolute top-4 right-4 flex flex-col gap-2">
                   <button className="p-2 bg-white/10 backdrop-blur-md rounded-full text-white hover:bg-red-500 transition-colors shadow-lg">
                     <Heart size={18} />
                   </button>
                   <button className="p-2 bg-white/10 backdrop-blur-md rounded-full text-white hover:bg-gold transition-colors shadow-lg">
                     <Share2 size={18} />
                   </button>
                </div>
                <div className="absolute bottom-4 left-4">
                  <div className="flex items-center gap-2 bg-navy/80 backdrop-blur-md px-3 py-1 rounded-full border border-gold/30 shadow-2xl">
                    <Sparkles size={14} className="text-gold" />
                    <span className="text-gold font-bold text-xs">{item.match}% Match</span>
                  </div>
                </div>
              </div>
              
              <div className="p-6 space-y-4 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center gap-2 text-gold-light text-xs font-bold uppercase tracking-widest mb-2">
                    <Tag size={12} />
                    {item.context}
                  </div>
                  <h3 className="text-xl font-bold mb-2 group-hover:text-gold transition-colors">{item.name}</h3>
                  <p className="text-slate text-sm leading-relaxed">{item.description}</p>
                </div>
                
                <div className="flex flex-wrap gap-2 pt-4">
                  {item.tags.map(tag => (
                    <span key={tag} className="text-[10px] uppercase font-bold tracking-tighter bg-white/5 px-2 py-1 rounded border border-white/5 text-slate-light">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            </GlassCard>
          </motion.div>
        ))}
        
        {/* Placeholder for more */}
        <div className="border-2 border-dashed border-white/5 rounded-2xl flex flex-col items-center justify-center p-8 opacity-40 hover:opacity-100 hover:border-gold transition-all cursor-pointer group">
           <div className="p-6 bg-white/5 rounded-full mb-4 group-hover:scale-110 transition-transform">
             <RefreshCcw size={32} className="text-slate group-hover:text-gold" />
           </div>
           <p className="font-bold text-beige">Try another suggestion</p>
           <p className="text-xs text-slate mt-2 text-center">Reflecting new possibilities...</p>
        </div>
      </div>
    </div>
  );
}
