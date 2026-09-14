"use client";

import { useState, useCallback, useEffect } from "react";
import { createPortal } from "react-dom";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { Calendar, Plus, Trash2, X, Loader2, Clock } from "lucide-react";
import {
  CalendarEvent,
  createEvent,
  deleteEvent,
  formatEventTime,
  EVENT_TYPES,
} from "@/lib/services/events-service";

const TYPE_COLORS: Record<string, string> = {
  Work: "bg-cyan-electric/20 text-cyan-electric border-cyan-electric/30",
  Social: "bg-gold/20 text-gold border-gold/30",
  Event: "bg-purple-400/20 text-purple-300 border-purple-400/30",
  Personal: "bg-green-400/20 text-green-300 border-green-400/30",
  Sport: "bg-orange-400/20 text-orange-300 border-orange-400/30",
};

const TYPE_DOT: Record<string, string> = {
  Work: "bg-cyan-electric",
  Social: "bg-gold",
  Event: "bg-purple-400",
  Personal: "bg-green-400",
  Sport: "bg-orange-400",
};

interface AgendaManagerProps {
  userId: string;
  initialEvents: CalendarEvent[];
}

export function AgendaManager({ userId, initialEvents }: AgendaManagerProps) {
  const [events, setEvents] = useState<CalendarEvent[]>(initialEvents);
  const [showModal, setShowModal] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);
  const router = useRouter();

  const [form, setForm] = useState({
    title: "",
    type: "Work",
    start_time: "",
    end_time: "",
  });

  // Needed for portal — only render on client
  useEffect(() => {
    setMounted(true);
  }, []);

  // Lock body scroll when modal is open
  useEffect(() => {
    if (showModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [showModal]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title || !form.start_time) return;
    setIsCreating(true);

    // Build ISO timestamps for today
    const today = new Date().toISOString().split("T")[0];
    const start_time = new Date(`${today}T${form.start_time}:00`).toISOString();
    const end_time = form.end_time
      ? new Date(`${today}T${form.end_time}:00`).toISOString()
      : null;

    const created = await createEvent(userId, {
      title: form.title,
      type: form.type,
      start_time,
      end_time: end_time || start_time,
    });

    if (created) {
      setEvents((prev) =>
        [...prev, created].sort(
          (a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
        )
      );
    }

    setForm({ title: "", type: "Work", start_time: "", end_time: "" });
    setShowModal(false);
    setIsCreating(false);
  };

  const handleDelete = useCallback(
    async (id: string) => {
      setDeletingId(id);
      const ok = await deleteEvent(id);
      if (ok) setEvents((prev) => prev.filter((e) => e.id !== id));
      setDeletingId(null);
    },
    []
  );

  const modal = (
    <AnimatePresence>
      {showModal && (
        <div
          style={{ position: "fixed", inset: 0, zIndex: 99999, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}
        >
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowModal(false)}
            style={{ position: "absolute", inset: 0, backgroundColor: "rgba(26,35,50,0.85)" }}
            className="backdrop-blur-sm"
          />
          {/* Modal Card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9 }}
            style={{ position: "relative", width: "100%", maxWidth: "28rem" }}
            className="glass rounded-3xl p-8 border border-white/10 shadow-2xl"
          >
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <Calendar size={20} className="text-gold" />
                New Event
              </h3>
              <button
                onClick={() => setShowModal(false)}
                className="p-2 text-slate hover:text-white transition-colors rounded-lg hover:bg-white/5"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreate} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gold uppercase tracking-wider">
                  Event Title
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Team Meeting, Lunch with Alex..."
                  value={form.title}
                  onChange={(e) => setForm((p) => ({ ...p, title: e.target.value }))}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white placeholder:text-slate/30 focus:border-gold/50 focus:ring-1 focus:ring-gold/30 outline-none transition-all text-sm"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gold uppercase tracking-wider">
                  Category
                </label>
                <div className="grid grid-cols-5 gap-2">
                  {EVENT_TYPES.map((t) => (
                    <button
                      key={t}
                      type="button"
                      onClick={() => setForm((p) => ({ ...p, type: t }))}
                      className={`py-2 rounded-xl text-[11px] font-bold border transition-all ${
                        form.type === t
                          ? TYPE_COLORS[t]
                          : "border-white/10 bg-white/5 text-slate hover:border-white/20"
                      }`}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-gold uppercase tracking-wider flex items-center gap-1">
                    <Clock size={10} /> Start Time
                  </label>
                  <input
                    type="time"
                    required
                    value={form.start_time}
                    onChange={(e) => setForm((p) => ({ ...p, start_time: e.target.value }))}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold/50 outline-none transition-all text-sm"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-xs font-bold text-slate uppercase tracking-wider flex items-center gap-1">
                    <Clock size={10} /> End Time
                  </label>
                  <input
                    type="time"
                    value={form.end_time}
                    onChange={(e) => setForm((p) => ({ ...p, end_time: e.target.value }))}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-gold/50 outline-none transition-all text-sm"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={isCreating}
                className="w-full mt-2 bg-gold hover:bg-gold/90 text-navy font-bold py-3 rounded-xl flex items-center justify-center gap-2 transition-all shadow-lg shadow-gold/20 disabled:opacity-50"
              >
                {isCreating ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
                {isCreating ? "Adding..." : "Add to Agenda"}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );

  return (
    <>
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <Calendar size={20} className="text-gold" />
          <h3 className="text-xl font-bold">Today's Agenda</h3>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-slate text-sm">{events.length} events</span>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gold/10 border border-gold/20 text-gold rounded-xl text-xs font-bold hover:bg-gold/20 transition-all"
          >
            <Plus size={14} /> Add
          </button>
        </div>
      </div>

      <div className="space-y-3">
        {events.length === 0 ? (
          <div className="text-center py-10 opacity-40">
            <Calendar size={36} className="mx-auto mb-3 text-slate" />
            <p className="text-sm text-slate">No events today. Add one!</p>
          </div>
        ) : (
          <AnimatePresence>
            {events.map((item) => (
              <motion.div
                key={item.id}
                initial={{ opacity: 0, y: -6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: 30, height: 0 }}
                onClick={() => router.push(`/recommendations?eventContext=${encodeURIComponent(item.title)}`)}
                className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors group cursor-pointer"
              >
                <div className="flex items-center gap-4">
                  <span className="text-gold font-mono text-sm w-10 flex-shrink-0">
                    {formatEventTime(item.start_time)}
                  </span>
                  <div>
                    <p className="font-medium text-sm">{item.title}</p>
                    <span
                      className={`text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded-full border ${
                        TYPE_COLORS[item.type] || "bg-white/10 text-slate border-white/10"
                      }`}
                    >
                      {item.type}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div
                    className={`w-2 h-2 rounded-full shadow-[0_0_8px_rgba(0,212,255,0.6)] ${
                      TYPE_DOT[item.type] || "bg-slate"
                    }`}
                  />
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDelete(item.id);
                    }}
                    disabled={deletingId === item.id}
                    className="opacity-0 group-hover:opacity-100 p-1.5 rounded-lg hover:bg-red-500/10 text-slate hover:text-red-400 transition-all font-medium"
                  >
                    {deletingId === item.id ? (
                      <Loader2 size={14} className="animate-spin" />
                    ) : (
                      <Trash2 size={14} />
                    )}
                  </button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        )}
      </div>

      {/* Portal: renders modal at document.body to escape ALL stacking contexts */}
      {mounted && createPortal(modal, document.body)}
    </>
  );
}
