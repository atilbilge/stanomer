import type { Metadata } from "next";
import { Navbar } from "../components/Navbar";
import { HomeContent } from "./HomeContent";

export const metadata: Metadata = {
  title: "Stanomer | End-to-End Operating System for Real Estate Agencies",
  description:
    "Publish listings to 4zida.rs and Halo Oglasi via live XML, manage CRM leads, digital leases, EUR/RSD rent & expenses, maintenance, and team tasks in one unified suite.",
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
