import { GlassCard } from "@/components/ui/GlassCard";
import { getMockWeather, getMockAgenda } from "@/lib/mock-services";
import { Sun, Calendar, ArrowRight } from "lucide-react";

export default async function DashboardPage() {
  const weather = await getMockWeather();
  const agenda = await getMockAgenda();

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <header>
        <h1 className="text-4xl font-bold text-beige mb-2">Welcome back, User</h1>
        <p className="text-slate text-lg">Here's your style overview for today.</p>
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

        {/* Agenda Card */}
        <GlassCard className="lg:col-span-2">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center gap-2">
              <Calendar size={20} className="text-gold" />
              <h3 className="text-xl font-bold">Today's Agenda</h3>
            </div>
            <span className="text-slate text-sm">{agenda.length} events</span>
          </div>
          <div className="space-y-4">
            {agenda.map((item) => (
              <div key={item.id} className="flex items-center justify-between p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                <div className="flex items-center gap-4">
                  <span className="text-gold font-mono text-sm">{item.time}</span>
                  <div>
                    <p className="font-medium">{item.title}</p>
                    <p className="text-xs text-slate uppercase tracking-wider">{item.category}</p>
                  </div>
                </div>
                <div className="w-2 h-2 rounded-full bg-cyan-electric shadow-[0_0_8px_rgba(0,212,255,0.6)]" />
              </div>
            ))}
          </div>
        </GlassCard>
      </div>

      {/* Main CTA */}
      <GlassCard variant="gold" className="flex items-center justify-between p-8 group cursor-pointer hover:scale-[1.01] transition-transform">
        <div>
          <h2 className="text-2xl font-bold text-gold mb-2">Ready to shine?</h2>
          <p className="text-white opacity-80">Let's find the perfect outfit for your day based on your agenda and weather.</p>
        </div>
        <div className="bg-navy p-4 rounded-full text-gold group-hover:translate-x-2 transition-transform">
          <ArrowRight size={24} />
        </div>
      </GlassCard>
    </div>
  );
}
