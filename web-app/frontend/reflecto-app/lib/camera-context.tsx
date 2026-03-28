"use client";

import React, { createContext, useContext, useRef, useState, useEffect } from "react";
import { usePathname } from "next/navigation";

interface CameraContextType {
  stream: MediaStream | null;
  startCamera: () => Promise<void>;
  stopCamera: () => void;
  error: string | null;
}

const CameraContext = createContext<CameraContextType | undefined>(undefined);

export const CameraProvider = ({ children }: { children: React.ReactNode }) => {
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [error, setError] = useState<string | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const pathname = usePathname();

  const stopCamera = () => {
    if (streamRef.current) {
      const tracks = streamRef.current.getTracks();
      tracks.forEach(track => {
        track.stop();
        console.log(`[CameraContext] Track stopped: ${track.label}`);
      });
      streamRef.current = null;
      setStream(null);
    }
  };

  const startCamera = async () => {
    setError(null);
    try {
      if (streamRef.current) return;

      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user", width: { ideal: 1280 }, height: { ideal: 720 } }
      });

      streamRef.current = mediaStream;
      setStream(mediaStream);
    } catch (err) {
      console.error("[CameraContext] Error accessing camera:", err);
      setError("Camera access denied. Please enable permissions.");
    }
  };

  // Safety Net: If we are not on the camera page, the camera must be OFF
  // Safety Net: If we are not on the camera page, the camera must be OFF
  useEffect(() => {
    const isCameraPage = pathname === "/camera" || pathname === "/miror";
    if (!isCameraPage) {
      stopCamera();
    }
  }, [pathname]);

  // Clean up on window close
  useEffect(() => {
    window.addEventListener("beforeunload", stopCamera);
    return () => {
      window.removeEventListener("beforeunload", stopCamera);
      stopCamera();
    };
  }, []);

  return (
    <CameraContext.Provider value={{ stream, startCamera, stopCamera, error }}>
      {children}
    </CameraContext.Provider>
  );
};

export const useCamera = () => {
  const context = useContext(CameraContext);
  if (context === undefined) {
    throw new Error("useCamera must be used within a CameraProvider");
  }
  return context;
};
