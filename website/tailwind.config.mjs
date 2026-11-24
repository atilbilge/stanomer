/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: "#1B5888",
          pressed: "#12406A",
          surface: "#E5EEF6",
          logoGreen: "#40945D",
          blue: "#1B5888",
          green: "#40945D",
        },
        success: {
          DEFAULT: "#2A6E43",
          text: "#2A6E43",
          surface: "#E6F3EA",
        },
        alert: {
          DEFAULT: "#B5432E",
          text: "#A33C29",
          surface: "#FBEAE6",
        },
        pending: {
          DEFAULT: "#8A5206",
          text: "#8A5206",
          surface: "#FBF1DC",
          graphic: "#E0A63A",
        },
        stanomer: {
          bgPage: "#F8F7F5",
          bgCard: "#FFFFFF",
          textPrimary: "#1A1A1A",
          textSecondary: "#4A4A4A",
          textTertiary: "#666666",
          borderDefault: "#E5E3DF",
          borderInput: "#8A8A8A",
        },
      },
      borderRadius: {
        label: "4px",
        pill: "6px",
        input: "8px",
        card: "10px",
        btn: "10px",
        sheet: "16px",
        fab: "16px",
      },
      boxShadow: {
        card: "0 1px 0 rgba(0,0,0,0.04), 0 2px 8px rgba(0,0,0,0.06)",
        sheet: "0 4px 16px rgba(0,0,0,0.08)",
        modal: "0 16px 40px rgba(0,0,0,0.18)",
      },
      fontFamily: {
        sans: ["var(--font-nunito)", "Nunito", "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ["var(--font-dm-mono)", "DM Mono", "ui-monospace", "monospace"],
        serif: ["var(--font-dm-serif)", "DM Serif Display", "ui-serif", "serif"],
      },
    },
  },
  plugins: [],
};
