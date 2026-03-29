"use client";

import { useAuth } from "@/lib/auth-context";
import { Sidebar } from "@/components/ui/Sidebar";
import { usePathname } from "next/navigation";

export const ClientLayout = ({ children }: { children: React.ReactNode }) => {
  const { user, isLoading } = useAuth();
  const pathname = usePathname();

  if (isLoading) {
    return (
      <div className="min-h-screen bg-navy flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-gold border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const showSidebar = user && pathname !== "/auth";

  return (
    <div className="flex bg-navy min-h-screen">
      {showSidebar && <Sidebar />}
      <main className={`flex-1 ${showSidebar ? "lg:ml-64" : ""} p-4 lg:p-8 ${showSidebar ? "pt-16 lg:pt-8" : ""} min-h-screen bg-transparent transition-all duration-300`}>
        <div className="max-w-7xl mx-auto h-full">
          {children}
        </div>
      </main>
    </div>
  );
};
