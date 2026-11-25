import type { Metadata } from "next";
import { Navbar } from "../../components/Navbar";
import { IndividualsContent } from "./IndividualsContent";

export const metadata: Metadata = {
  title: "Stanomer | Za stanodavce i stanare — Ugovori, plaćanja i održavanje",
  description:
    "Digitalni most za stanodavce i stanare. Upravljajte ugovorima o zakupu, mesečnim plaćanjima, depozitima i održavanjem u jednoj aplikaciji.",
  icons: {
    icon: "/favicon.png",
    shortcut: "/favicon.ico",
    apple: "/favicon.png",
  },
};

export default function IndividualsPage() {
  return (
    <>
      <Navbar />
      <div className="h-[80px]" />
      <IndividualsContent />
    </>
  );
}
