"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  Home, 
  Camera, 
  Sparkles, 
  MessageSquare, 
  History, 
  Settings,
  LogOut,
  Menu,
  X
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
  const [isOpen, setIsOpen] = useState(false);

  // Close sidebar when route changes (mobile navigation)
  useEffect(() => {
    setIsOpen(false);
  }, [pathname]);

  // Prevent body scroll when mobile sidebar is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [isOpen]);

  return (
    <>
      {/* Burger Button — Mobile Only */}
      <button
        onClick={() => setIsOpen(true)}
        className="fixed top-4 left-4 z-[60] p-3 glass rounded-xl text-gold lg:hidden"
        aria-label="Open menu"
      >
        <Menu size={22} />
      </button>

      {/* Backdrop — Mobile Only */}
      {isOpen && (
        <div
          onClick={() => setIsOpen(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[70] lg:hidden"
        />
      )}

      {/* Sidebar Panel */}
      <div className={cn(
        "w-64 h-screen glass border-r border-white/5 flex flex-col p-4 fixed top-0 z-[80] transition-transform duration-300 ease-in-out",
        // Mobile: slide in/out from left
        isOpen ? "translate-x-0" : "-translate-x-full",
        // Desktop: always visible
        "lg:translate-x-0 lg:left-0"
      )}>
        {/* Close button — Mobile Only */}
        <button
          onClick={() => setIsOpen(false)}
          className="absolute top-4 right-4 p-2 text-slate hover:text-white transition-colors lg:hidden"
          aria-label="Close menu"
        >
          <X size={20} />
        </button>

        <div className="mb-8 px-4 py-2">
          <Link href="/dashboard" className="flex items-center gap-3 group">
            <div className="relative w-16 h-16 flex items-center justify-center">
              <img src="/logo/logo-reflecto-2.png" alt="Logo" className="w-full h-full object-contain" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-tight group-hover:text-gold transition-colors">Reflecto</h1>
          </Link>
          
          <div className="mt-4 px-2">
             <p className="text-[8px] uppercase tracking-[0.2em] text-slate/40 font-bold mb-2">Partner</p>
             <div className="flex items-center gap-2 grayscale opacity-40 hover:grayscale-0 hover:opacity-100 transition-all duration-500">
                <img src="/logo/logo-ispm.png" alt="ISPM Logo" className="h-6 object-contain" />
                <div className="h-5 w-px bg-white/10" />
                <span className="text-[10px] text-slate font-bold">ISPM</span>
             </div>
          </div>
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

        <div className="mt-auto border-t border-white/5 pt-6">
          <button 
            onClick={logout}
            className="flex items-center gap-3 px-4 py-2 w-full rounded-xl text-slate hover:bg-white/5 hover:text-red-400 transition-all duration-200"
          >
            <LogOut size={18} />
            <span className="font-medium text-sm">Sign Out</span>
          </button>
        </div>
      </div>
    </>
  );
};
