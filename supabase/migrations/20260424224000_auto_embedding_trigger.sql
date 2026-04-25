-- ============================================================
-- Auto-Embedding Trigger for New Property Listings
-- ============================================================
-- This migration installs a PostgreSQL trigger that automatically
-- calls the `generate-property-embedding` Edge Function whenever
-- a property is INSERT-ed or UPDATE-d.
--
-- This means agents NEVER need to manually trigger backfilling.
-- Every new listing gets an embedding within seconds automatically.
-- ============================================================

-- Enable pg_net extension to make HTTP calls from inside PostgreSQL
create extension if not exists pg_net;

-- Helper function that fires on property insert/update.
-- It calls the Supabase Edge Function asynchronously via pg_net.
create or replace function public.trigger_generate_property_embedding()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Fire-and-forget: call the Edge Function with the new/updated record.
  -- pg_net sends this asynchronously so the INSERT/UPDATE is never blocked.
  perform net.http_post(
    url := 'https://krwkcilbitlsbivkcuns.supabase.co/functions/v1/generate-property-embedding',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtyd2tjaWxiaXRsc2JpdmtjdW5zIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjI3MjMxMCwiZXhwIjoyMDkxODQ4MzEwfQ.bTrSyimJFE5R85iaIze3y92of4AipuB8uT6fy5h9vL0'
    ),
    body := jsonb_build_object('record', row_to_json(NEW))
  );
  return NEW;
end;
$$;

-- Drop any existing trigger to avoid duplicates on re-run
drop trigger if exists on_property_upsert_generate_embedding on public.properties;

-- Attach the trigger to INSERT and UPDATE events
create trigger on_property_upsert_generate_embedding
  after insert or update on public.properties
  for each row execute procedure public.trigger_generate_property_embedding();
