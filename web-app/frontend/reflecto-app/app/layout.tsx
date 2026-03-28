import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/ui/Sidebar";
import { AuthProvider } from "@/lib/auth-context";
import { CameraProvider } from "@/lib/camera-context";
import { ClientLayout } from "@/components/layout/ClientLayout";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Reflecto | AI Smart Mirror",
  description: "Personalized outfit recommendations powered by AI.",
  icons: {
    icon: "/logo/logo-reflecto.ico",
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <AuthProvider>
          <CameraProvider>
            <ClientLayout>
              {children}
            </ClientLayout>
          </CameraProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
