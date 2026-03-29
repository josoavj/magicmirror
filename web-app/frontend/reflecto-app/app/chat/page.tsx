"use client";

import { useState, useRef, useEffect } from "react";
import { GlassCard } from "@/components/ui/GlassCard";
import { Send, User, Sparkles, Wand2, Mic, History as HistoryIcon, MoreVertical } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { getAIResponse } from "@/lib/mock-services";

interface Message {
  id: string;
  text: string;
  sender: "user" | "ai";
  timestamp: Date;
}

export default function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "1",
      text: "Hello! I'm your Reflecto Style Assistant. How can I help you today?",
      sender: "ai",
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isTyping]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMsg: Message = {
      id: Date.now().toString(),
      text: input,
      sender: "user",
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMsg]);
    setInput("");
    setIsTyping(true);

    try {
      const aiResponseText = await getAIResponse(input);
      const aiMsg: Message = {
        id: (Date.now() + 1).toString(),
        text: aiResponseText,
        sender: "ai",
        timestamp: new Date()
      };
      setMessages(prev => [...prev, aiMsg]);
    } catch (error) {
       console.error("AI failed", error);
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div className="h-[calc(100vh-6rem)] lg:h-[calc(100vh-8rem)] flex flex-col animate-in fade-in duration-700 max-w-4xl mx-auto">
      <header className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-gradient-to-br from-cyan-electric to-cyan-ai rounded-2xl shadow-lg shadow-cyan-electric/20 text-navy">
             <Wand2 size={24} />
          </div>
          <div>
            <h1 className="text-xl md:text-2xl font-bold text-beige">Style Assistant</h1>
            <div className="flex items-center gap-2">
               <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
               <span className="text-xs text-slate uppercase tracking-widest font-bold">Online</span>
            </div>
          </div>
        </div>
        <div className="flex gap-2">
           <button className="p-2 text-slate hover:bg-white/5 rounded-lg transition-colors"><HistoryIcon size={20} /></button>
           <button className="p-2 text-slate hover:bg-white/5 rounded-lg transition-colors"><MoreVertical size={20} /></button>
        </div>
      </header>

      <GlassCard className="flex-1 overflow-hidden p-0 flex flex-col bg-navy/20 border-white/5">
        <div 
          ref={scrollRef}
          className="flex-1 overflow-y-auto p-6 space-y-6 scrollbar-hide"
        >
          <AnimatePresence initial={false}>
            {messages.map((msg) => (
              <motion.div
                key={msg.id}
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                className={`flex ${msg.sender === "user" ? "justify-end" : "justify-start"}`}
              >
                <div className={`flex gap-3 max-w-[85%] md:max-w-[80%] ${msg.sender === "user" ? "flex-row-reverse" : "flex-row"}`}>
                  <div className={`p-2 rounded-xl h-10 w-10 flex-shrink-0 flex items-center justify-center shadow-lg ${
                    msg.sender === "user" ? "bg-gold text-navy" : "bg-cyan-ai/20 text-cyan-electric border border-cyan-electric/20"
                  }`}>
                    {msg.sender === "user" ? <User size={20} /> : <Sparkles size={20} />}
                  </div>
                  <div className={`p-4 rounded-2xl ${
                    msg.sender === "user" 
                      ? "bg-gold/90 text-navy font-medium shadow-xl shadow-gold/5" 
                      : "bg-white/5 text-beige border border-white/10 backdrop-blur-md"
                  }`}>
                    <p className="text-sm leading-relaxed">{msg.text}</p>
                    <p className={`text-[10px] mt-2 opacity-50 ${msg.sender === "user" ? "text-navy" : "text-slate"}`}>
                      {msg.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
            
            {isTyping && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex justify-start"
              >
                <div className="flex gap-3">
                  <div className="bg-cyan-ai/20 text-cyan-electric border border-cyan-electric/20 p-2 rounded-xl h-10 w-10 flex items-center justify-center">
                    <Sparkles size={20} className="animate-spin-slow" />
                  </div>
                  <div className="bg-white/5 p-4 rounded-2xl flex gap-1">
                    <div className="w-1.5 h-1.5 bg-cyan-electric rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                    <div className="w-1.5 h-1.5 bg-cyan-electric rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                    <div className="w-1.5 h-1.5 bg-cyan-electric rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="p-4 bg-navy/40 backdrop-blur-xl border-t border-white/5">
          <div className="relative flex items-center gap-3">
            <button className="p-3 text-slate hover:text-gold transition-colors bg-white/5 rounded-xl border border-white/5">
               <Mic size={20} />
            </button>
            <div className="flex-1 relative">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                placeholder="Ask me anything about your style..."
                className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-beige placeholder:text-slate/40 focus:outline-none focus:border-gold/50 transition-all text-sm"
              />
              <div className="absolute right-3 top-1/2 -translate-y-1/2 text-cyan-electric opacity-50">
                 <Sparkles size={16} />
              </div>
            </div>
            <button
              onClick={handleSend}
              disabled={!input.trim()}
              className="bg-gold hover:bg-gold-light disabled:opacity-50 disabled:cursor-not-allowed p-3 rounded-xl text-navy transition-all shadow-lg shadow-gold/20"
            >
              <Send size={20} />
            </button>
          </div>
        </div>
      </GlassCard>
      
      <div className="mt-4 flex gap-2 justify-center flex-wrap">
         {["Suggest a tie?", "Is it raining?", "Change profile"].map(suggestion => (
           <button 
             key={suggestion}
             onClick={() => setInput(suggestion)}
             className="text-[10px] uppercase font-bold tracking-widest px-3 py-1.5 rounded-lg border border-white/5 hover:border-gold/30 hover:bg-gold/5 transition-all text-slate-light"
           >
             {suggestion}
           </button>
         ))}
      </div>
    </div>
  );
}
