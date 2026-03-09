import { createClient, SupabaseClient } from "@supabase/supabase-js";

let _supabase: SupabaseClient;

export function getSupabase() {
  if (!_supabase) {
    _supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SECRET_KEY!,
    );
  }
  return _supabase;
}
