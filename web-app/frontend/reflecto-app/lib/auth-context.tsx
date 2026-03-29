"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";

interface UserProfile {
  name: string;
  email?: string;
  phone?: string;
  morphology?: string;
  skinTone?: string;
  subscription?: string;
}

interface AuthContextType {
  user: UserProfile | null;
  login: (name: string, pass: string) => Promise<boolean>;
  logout: () => void;
  updateUser: (newData: Partial<UserProfile>) => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const savedUser = localStorage.getItem("reflecto_user");
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
    setIsLoading(false);
  }, []);

  useEffect(() => {
    if (!isLoading) {
      if (!user && pathname !== "/auth") {
        router.push("/auth");
      } else if (user && pathname === "/auth") {
        router.push("/dashboard");
      }
    }
  }, [user, isLoading, pathname, router]);

  const login = async (name: string, pass: string) => {
    // Mock authentication logic
    if (name && pass) {
      const mockUser: UserProfile = { 
        name,
        email: "user@example.com",
        phone: "+261 34 00 000 00",
        morphology: "H-Shape",
        skinTone: "Warm Tone",
        subscription: "Premium Member"
      };
      setUser(mockUser);
      localStorage.setItem("reflecto_user", JSON.stringify(mockUser));
      return true;
    }
    return false;
  };

  const updateUser = (newData: Partial<UserProfile>) => {
    if (user) {
      const updatedUser = { ...user, ...newData };
      setUser(updatedUser);
      localStorage.setItem("reflecto_user", JSON.stringify(updatedUser));
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem("reflecto_user");
    router.push("/auth");
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, updateUser, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
