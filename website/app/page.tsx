import type { Metadata } from "next";
import { Navbar } from "../components/Navbar";
import { HomeContent } from "./HomeContent";

export const metadata: Metadata = {
  title: "Stanomer | Nova generacija transparentnosti u upravljanju nekretninama",
  description: "Digitalni most za stanodavce i stanare. Upravljajte ugovorima, plaćanjima i održavanjem u jednoj aplikaciji.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.ico",
    apple: "/favicon.png",
  },
};

export default function RootPage() {
  return (
    <>
      <Navbar />
      <div className="h-[80px]" />
      <HomeContent />
    </>
  );
}
