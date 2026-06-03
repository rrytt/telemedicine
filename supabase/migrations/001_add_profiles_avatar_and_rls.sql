-- Migration: Add avatar and profile fields, enable RLS and create policies
-- Run this in Supabase SQL editor or via psql connected to your Supabase DB.

-- 1) Add profile columns (if not present)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS specialty text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bio text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone_number text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS blood_type text;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS medical_record text;

-- 2) Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3) Policies: allow public select, and owner-only insert/update
DROP POLICY IF EXISTS "Profiles: select public" ON public.profiles;
CREATE POLICY "Profiles: select public" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Profiles: insert own" ON public.profiles;
CREATE POLICY "Profiles: insert own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Profiles: update own" ON public.profiles;
CREATE POLICY "Profiles: update own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4) (Optional) If admins should modify profiles, create an admin policy
-- Uncomment and adapt the condition to your admin check
-- CREATE POLICY IF NOT EXISTS "Profiles: admin full access" ON public.profiles
--   FOR ALL USING (auth.role() = 'authenticated' AND exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 5) Storage object policies (storage.objects table) for avatars bucket
-- Note: Supabase stores objects in the storage.objects table in the storage schema.
-- These policies allow authenticated users to read objects and insert only into their own folder.

-- Allow authenticated users to select (read) objects in avatars bucket
DROP POLICY IF EXISTS "Storage: select avatars authenticated" ON storage.objects;
CREATE POLICY "Storage: select avatars authenticated" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'avatars' AND auth.role() = 'authenticated'
  );

-- Allow insert only when object path starts with the user's uid (userId/filename)
DROP POLICY IF EXISTS "Storage: insert own avatars" ON storage.objects;
CREATE POLICY "Storage: insert own avatars" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND left(name, length(auth.uid() || '/')) = auth.uid() || '/'
  );

-- Allow delete only for owner (their own path)
DROP POLICY IF EXISTS "Storage: delete own avatars" ON storage.objects;
CREATE POLICY "Storage: delete own avatars" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND left(name, length(auth.uid() || '/')) = auth.uid() || '/'
  );

-- End of migration
