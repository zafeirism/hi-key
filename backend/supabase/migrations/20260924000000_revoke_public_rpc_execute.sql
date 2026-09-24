-- Defense in depth: only the backend (service_role) may call our RPCs.
--
-- Postgres grants EXECUTE on new functions to PUBLIC, and Supabase additionally grants it to
-- anon/authenticated, which exposes every public-schema function through PostgREST to anyone
-- holding the publishable key (shipped in the iOS app). The credit RPCs are SECURITY INVOKER,
-- so RLS (enabled, no policies) already blocks those roles from touching any row — this just
-- stops them from reaching the functions at all.

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;

-- Apply the same to functions created by future migrations.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated;
