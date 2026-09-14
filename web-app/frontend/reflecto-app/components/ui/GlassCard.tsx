import { ReactNode } from "react";
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface GlassCardProps {
  children: ReactNode;
  className?: string;
  variant?: "default" | "gold" | "ai";
}

export const GlassCard = ({ children, className, variant = "default" }: GlassCardProps) => {
  const variants = {
    default: "glass",
    gold: "glass-gold",
    ai: "glass border-cyan-electric/30 shadow-cyan-electric/10"
  };

  return (
    <div className={cn(
      "p-6 rounded-2xl transition-all duration-300",
      variants[variant],
      className
    )}>
      {children}
    </div>
  );
};
