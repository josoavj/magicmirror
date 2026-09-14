"use client";

import { useEffect, useState } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { History as HistoryIcon, Calendar, ArrowUpRight, Search, Filter, Loader2, ImageOff } from "lucide-react";
import { motion } from "framer-motion";
import { createClient } from "@/lib/supabase/client";

interface HistoryItem {
  id: string;
  viewed_at?: string;
  liked: boolean;
  recommendations: {
     context: string;
     match_percentage: number;
     outfits: {
        name: string;
        description: string;
        image_url: string;
        tags: string[];
     }
  } | null;
}

function getItemDate(item: HistoryItem): Date {
  const ts = item.viewed_at;
  return ts ? new Date(ts) : new Date(0);
}

function formatItemDate(item: HistoryItem, fmt: "short" | "year"): string {
  const d = getItemDate(item);
  if (d.getTime() === 0) return fmt === "year" ? "" : "Unknown";
  if (fmt === "year") return String(d.getFullYear());
  return d.toLocaleDateString("fr-FR", { month: "short", day: "numeric" });
}

export default function HistoryPage() {
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    const fetchHistory = async () => {
      setIsLoading(true);
      const supabase = createClient();
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        setIsLoading(false);
        return;
      }

      const { data, error } = await supabase
        .from("history")
        .select(`
          id, viewed_at, liked,
          recommendations (
             context, match_percentage,
             outfits (
                name, description, image_url, tags
             )
          )
        `)
        .eq("user_id", user.id);

      if (error) {
        console.error("Error fetching history:", error);
      } else {
        const rawData = data as any[] || [];
        const normalizedData: HistoryItem[] = rawData.map(item => {
           const rec = Array.isArray(item.recommendations) ? item.recommendations[0] : item.recommendations;
           const out = rec ? (Array.isArray(rec.outfits) ? rec.outfits[0] : rec.outfits) : null;
           
           return {
              id: item.id,
              viewed_at: item.viewed_at,
              liked: item.liked,
              recommendations: rec && out ? {
                 context: rec.context,
                 match_percentage: rec.match_percentage,
                 outfits: {
                    name: out.name,
                    description: out.description,
                    image_url: out.image_url,
                    tags: Array.isArray(out.tags) ? out.tags : []
                 }
              } : null
           };
        });

        const sortedData = normalizedData.sort((a, b) => {
           const dateA = getItemDate(a).getTime();
           const dateB = getItemDate(b).getTime();
           return dateB - dateA;
        });
        setHistory(sortedData);
      }
      setIsLoading(false);
    };

    fetchHistory();
  }, []);

  const filteredHistory = history.filter(item => {
    const rec = item.recommendations;
    const out = rec?.outfits;
    if (!rec || !out) return false;
    
    return (out.name || '').toLowerCase().includes(search.toLowerCase()) ||
           (rec.context || '').toLowerCase().includes(search.toLowerCase());
  });

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-right-4 duration-700 max-w-5xl mx-auto">
      <header className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-2xl md:text-4xl font-bold text-beige mb-1 md:mb-2">Style History</h1>
          <p className="text-slate text-sm md:text-lg">Revisiting your past reflections.</p>
        </div>
        <div className="flex gap-3 w-full md:w-auto">
           <div className="relative flex-1 md:flex-initial">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate/50" size={18} />
              <input 
                type="text" 
                placeholder="Search history..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-full pl-10 pr-4 py-2 text-sm focus:outline-none focus:border-gold/50"
              />
           </div>
           <button className="p-2 bg-white/5 border border-white/10 rounded-full text-slate hover:text-gold transition-colors flex-shrink-0">
              <Filter size={20} />
           </button>
        </div>
      </header>

      <div className="relative">
        {/* Timeline Line */}
        <div className="absolute left-8 top-4 bottom-4 w-px bg-gradient-to-b from-gold via-slate/20 to-transparent lg:block hidden" />

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 gap-4 opacity-40">
            <Loader2 className="animate-spin text-gold" size={40} />
            <p className="text-sm font-medium">Looking through the mirror's memory...</p>
          </div>
        ) : filteredHistory.length === 0 ? (
          <div className="text-center py-20 opacity-40">
            <HistoryIcon className="mx-auto mb-4" size={48} />
            <p>Aucun historique trouvé. Commencez par générer des suggestions depuis le miroir !</p>
          </div>
        ) : (
          <div className="space-y-12">
            {filteredHistory.map((item, index) => (
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
                     <p className="text-gold font-bold text-sm tracking-tight">
                        {formatItemDate(item, "short")}
                     </p>
                     <p className="text-slate text-[10px] uppercase tracking-widest">
                        {formatItemDate(item, "year")}
                     </p>
                  </div>

                  <GlassCard className="flex-1 flex items-center gap-6 p-4 hover:bg-white/5 transition-all group-hover:scale-[1.01] border-white/5 hover:border-gold/20">
                    <div className="h-24 w-24 rounded-xl overflow-hidden shadow-lg shadow-black/40 flex-shrink-0 bg-white/5">
                      {item.recommendations?.outfits?.image_url ? (
                        <img 
                          src={item.recommendations.outfits.image_url} 
                          alt={item.recommendations?.outfits?.name || "Outfit"} 
                          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                          onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center opacity-20">
                          <ImageOff size={24} />
                        </div>
                      )}
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                         <Calendar size={12} className="text-gold opacity-60" />
                         <span className="text-[10px] text-slate uppercase font-bold tracking-widest">{item.recommendations?.context}</span>
                         {item.recommendations?.match_percentage && (
                           <span className="text-[10px] text-cyan-electric font-bold ml-2">
                             {item.recommendations?.match_percentage}% Match
                           </span>
                         )}
                      </div>
                      <h3 className="text-xl font-bold group-hover:text-gold transition-colors">{item.recommendations?.outfits?.name}</h3>
                      <p className="text-sm text-slate md:block hidden line-clamp-2">{item.recommendations?.outfits?.description}</p>
                    </div>
                    
                    <button className="p-3 bg-white/5 rounded-full text-gold-light hover:bg-gold hover:text-navy transition-all">
                      <ArrowUpRight size={20} />
                    </button>
                  </GlassCard>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {!isLoading && filteredHistory.length > 0 && (
        <div className="pt-8 text-center">
           <button className="px-8 py-3 bg-white/5 border border-white/10 rounded-full text-slate text-sm font-bold uppercase tracking-widest hover:bg-white/10 transition-all">
              Load More History
           </button>
        </div>
      )}
    </div>
  );
}
