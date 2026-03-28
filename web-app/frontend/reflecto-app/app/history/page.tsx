"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { History as HistoryIcon, Calendar, ArrowUpRight, Search, Filter } from "lucide-react";
import { motion } from "framer-motion";

const mockHistory = [
  {
    id: "h1",
    date: "March 27, 2026",
    name: "Golden Hour Corporate",
    context: "Work",
    image: "https://samsonsurmesure.fr/wp-content/uploads/2024/02/samson-sur-mesure-ete-23-details-3-soren-costume-beige-1.jpg"
  },
  {
    id: "h2",
    date: "March 26, 2026",
    name: "Spring Breeze Casual",
    context: "Social",
    image: "https://images.unsplash.com/photo-1516762689617-e1cffcef479d?q=80&w=200&h=200&auto=format&fit=crop"
  },
  {
    id: "h3",
    date: "March 25, 2026",
    name: "Midnight Gala Suit",
    context: "Event",
    image: "https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=200&h=200&auto=format&fit=crop"
  },
  {
    id: "h4",
    date: "March 24, 2026",
    name: "Weekend Brunch",
    context: "Social",
    image: "https://images.unsplash.com/photo-1488161628813-04466f872be2?q=80&w=200&h=200&auto=format&fit=crop"
  }
];

export default function HistoryPage() {
  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-right-4 duration-700 max-w-5xl mx-auto">
      <header className="flex justify-between items-end">
        <div>
          <h1 className="text-4xl font-bold text-beige mb-2">Style History</h1>
          <p className="text-slate text-lg">Revisiting your past reflections.</p>
        </div>
        <div className="flex gap-3">
           <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate/50" size={18} />
              <input 
                type="text" 
                placeholder="Search history..."
                className="bg-white/5 border border-white/10 rounded-full pl-10 pr-4 py-2 text-sm focus:outline-none focus:border-gold/50"
              />
           </div>
           <button className="p-2 bg-white/5 border border-white/10 rounded-full text-slate hover:text-gold transition-colors">
              <Filter size={20} />
           </button>
        </div>
      </header>

      <div className="relative">
        {/* Timeline Line */}
        <div className="absolute left-8 top-4 bottom-4 w-px bg-gradient-to-b from-gold via-slate/20 to-transparent lg:block hidden" />

        <div className="space-y-12">
          {mockHistory.map((item, index) => (
            <motion.div 
              key={item.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              className="relative lg:pl-20"
            >
              {/* Timeline Dot */}
              <div className="absolute left-7 top-1/2 -translate-y-1/2 w-3 h-3 bg-gold rounded-full shadow-[0_0_10px_rgba(212,165,116,0.8)] lg:block hidden z-10" />
              
              <div className="flex flex-col md:flex-row items-center gap-6 group">
                <div className="text-left w-32 hidden md:block">
                   <p className="text-gold font-bold text-sm tracking-tight">{item.date.split(',')[0]}</p>
                   <p className="text-slate text-[10px] uppercase tracking-widest">{item.date.split(',')[1]}</p>
                </div>

                <GlassCard className="flex-1 flex items-center gap-6 p-4 hover:bg-white/5 transition-all group-hover:scale-[1.01] border-white/5 hover:border-gold/20">
                  <div className="h-24 w-24 rounded-xl overflow-hidden shadow-lg shadow-black/40 flex-shrink-0">
                    <img src={item.image} alt={item.name} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                  </div>
                  
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                       <Calendar size={12} className="text-gold opacity-60" />
                       <span className="text-[10px] text-slate uppercase font-bold tracking-widest">{item.context}</span>
                    </div>
                    <h3 className="text-xl font-bold group-hover:text-gold transition-colors">{item.name}</h3>
                    <p className="text-sm text-slate md:block hidden">Successfully matched with your H-Shape profile.</p>
                  </div>
                  
                  <button className="p-3 bg-white/5 rounded-full text-gold-light hover:bg-gold hover:text-navy transition-all">
                    <ArrowUpRight size={20} />
                  </button>
                </GlassCard>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      <div className="pt-8 text-center">
         <button className="px-8 py-3 bg-white/5 border border-white/10 rounded-full text-slate text-sm font-bold uppercase tracking-widest hover:bg-white/10 transition-all">
            Load More History
         </button>
      </div>
    </div>
  );
}
