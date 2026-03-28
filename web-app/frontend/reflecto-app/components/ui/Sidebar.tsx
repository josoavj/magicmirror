"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  Home, 
  Camera, 
  Sparkles, 
  MessageSquare, 
  History, 
  Settings,
  LogOut
} from "lucide-react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import { useAuth } from "@/lib/auth-context";

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

const navItems = [
  { name: "Dashboard", href: "/dashboard", icon: Home },
  { name: "Mirror", href: "/camera", icon: Camera },
  { name: "Suggestions", href: "/recommendations", icon: Sparkles },
  { name: "Assistant", href: "/chat", icon: MessageSquare },
  { name: "History", href: "/history", icon: History },
  { name: "Settings", href: "/settings", icon: Settings },
];

export const Sidebar = () => {
  const pathname = usePathname();
  const { logout } = useAuth();

  return (
    <div className="w-64 h-screen glass border-r border-white/5 flex flex-col p-4 fixed left-0 top-0 z-50">
      <div className="mb-8 px-4 py-2">
        <Link href="/dashboard" className="flex items-center gap-3 group">
          <div className="relative w-16 h-16 flex items-center justify-center">
            <img src="/logo/logo-reflecto-2.png" alt="Logo" className="w-full h-full object-contain" />
          </div>
          <h1 className="text-xl font-bold text-white tracking-tight group-hover:text-gold transition-colors">Reflecto</h1>
        </Link>
      </div>

      <nav className="flex-1 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group",
                isActive 
                  ? "bg-gold text-navy shadow-lg shadow-gold/10" 
                  : "text-slate hover:bg-white/5 hover:text-white"
              )}
            >
              <item.icon size={18} className={cn(
                "transition-colors",
                isActive ? "text-navy" : "text-slate group-hover:text-gold"
              )} />
              <span className="font-semibold text-sm">{item.name}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto border-t border-white/5 pt-6 space-y-6">
        <button 
          onClick={logout}
          className="flex items-center gap-3 px-4 py-2 w-full rounded-xl text-slate hover:bg-white/5 hover:text-red-400 transition-all duration-200"
        >
          <LogOut size={18} />
          <span className="font-medium text-sm">Sign Out</span>
        </button>
        
        <div className="px-4 pb-2">
           <p className="text-[10px] uppercase tracking-[0.2em] text-slate/40 font-bold mb-3">Partner</p>
           <div className="flex items-center gap-3 grayscale opacity-40 hover:grayscale-0 hover:opacity-100 transition-all duration-500">
              <img src="/logo/logo-ispm.png" alt="ISPM Logo" className="h-8 object-contain" />
              <div className="h-6 w-px bg-white/10" />
              <span className="text-[10px] text-slate font-bold">ISPM</span>
           </div>
        </div>
      </div>
    </div>
  );
};
