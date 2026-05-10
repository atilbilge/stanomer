import { LanguageProvider } from "../components/LanguageProvider";
import { Navbar } from "../components/Navbar";
import { HomeContent } from "./HomeContent";

export default function RootPage() {
  return (
    <LanguageProvider>
      <Navbar />
      <div className="h-[80px]" />
      <HomeContent />
    </LanguageProvider>
  );
}
