import { GlassCard } from "@/components/ui/GlassCard";
import { getMockWeather } from "@/lib/mock-services";
import { ArrowRight } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { AgendaManager } from "./AgendaManager";
import Link from "next/link";

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  let profile = null;
  if (user) {
    const { data } = await supabase
      .from("profiles")
      .select("*")
      .eq("user_id", user.id)
      .single();
    profile = data;
  }

  const weather = await getMockWeather();
  const displayName = profile?.first_name || user?.email?.split('@')[0] || 'User';

  // Fetch today or future events server-side
  let events: any[] = [];
  if (user) {
    const today = new Date().toISOString().split('T')[0];
    const { data: evts } = await supabase
      .from('events')
      .select('*')
      .eq('user_id', user.id)
      .gte('start_time', `${today}T00:00:00+00:00`)
      .order('start_time');
    events = evts || [];
  }

  return (
    <div className="space-y-6 md:space-y-8">
      <header className="animate-in fade-in duration-700">
        <h1 className="text-2xl md:text-4xl font-bold text-beige mb-1 md:mb-2">
          Welcome back, <span className="text-gold">{displayName}</span> ✨
        </h1>
        <p className="text-slate text-sm md:text-lg">Here's your style overview for today.</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Weather Card */}
        <GlassCard className="flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-slate font-medium mb-1">Weather</p>
              <h2 className="text-3xl font-bold">{weather.temp}°C</h2>
              <p className="text-slate-shadow text-sm">{weather.condition} in {weather.location}</p>
            </div>
            <div className="relative p-1">
              <div className="absolute inset-0 bg-gold/10 blur-xl rounded-full" />
              <img
                src={`https://openweathermap.org/img/wn/${weather.icon}@2x.png`}
                alt={weather.condition}
                className="w-16 h-16 relative z-10 drop-shadow-[0_0_8px_rgba(212,165,116,0.5)]"
              />
            </div>
          </div>
          <div className="mt-6 pt-4 border-t border-white/5">
            <p className="text-cyan-light text-sm italic">"{weather.advice}"</p>
          </div>
        </GlassCard>

        {/* Agenda Card — real data with CRUD */}
        <GlassCard className="lg:col-span-2">
          {user ? (
            <AgendaManager userId={user.id} initialEvents={events} />
          ) : (
            <p className="text-slate text-sm">Log in to see your agenda.</p>
          )}
        </GlassCard>
      </div>

      {/* Main CTA */}
      <Link href="/camera">
        <GlassCard variant="gold" className="flex flex-col sm:flex-row items-center justify-between p-5 md:p-8 gap-4 group cursor-pointer hover:scale-[1.01] transition-transform">
          <div className="text-center sm:text-left">
            <h2 className="text-xl md:text-2xl font-bold text-gold mb-2">Ready to shine?</h2>
            <p className="text-white opacity-80 text-sm md:text-base">
              Let your mirror analyse your look and suggest the perfect outfit for today.
            </p>
          </div>
          <div className="bg-navy p-4 rounded-full text-gold group-hover:translate-x-2 transition-transform flex-shrink-0">
            <ArrowRight size={24} />
          </div>
        </GlassCard>
      </Link>
    </div>
  );
}
