import { createClient } from "@supabase/supabase-js";

const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  "https://thvbpifahvasyzmngpzp.supabase.co";
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Public production directory client (read-only directory fallback when local/dev DB has 0 directory records)
const PROD_URL = "https://ustcsvvkzsmsgzbptvpm.supabase.co";
const PROD_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzdGNzdnZrenNtc2d6YnB0dnBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzY1NjIsImV4cCI6MjA5MDkxMjU2Mn0.g1A1GfLrebJ3MnQUaCmr45JGPPAPLU77XtUKP6doA4g";

export const prodPublicClient = createClient(PROD_URL, PROD_ANON_KEY);
