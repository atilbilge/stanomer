import type { Metadata } from "next";
import { LanguageProvider } from "../components/LanguageProvider";
import { Navbar } from "../components/Navbar";
import { HomeContent } from "./HomeContent";

export const metadata: Metadata = {
  title: "Stanomer | Mülk Yönetiminde Yeni Nesil Şeffaflık",
  description: "Ev sahipleri ve kiracılar için dijital köprü. Kontrat, ödeme ve arıza takibini tek uygulamada yönetin.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.ico",
    apple: "/favicon.png",
  },
};

export default function RootPage() {
  return (
    <LanguageProvider>
      <Navbar />
      <div className="h-[80px]" />
      <HomeContent />
    </LanguageProvider>
  );
}
