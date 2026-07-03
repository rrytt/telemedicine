-- Migration 005: Add blood_type and medical_record to profiles
-- Date: 2026-06-29
-- 
-- This migration adds two columns to the public.profiles table
-- that are used in the patient profile edit/view screens.

alter table public.profiles
  add column if not exists blood_type text;

alter table public.profiles
  add column if not exists medical_record text;

-- Add the new columns to realtime publication
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end
$$;
