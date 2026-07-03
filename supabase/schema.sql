-- Telemedicine schema (consolidated)
-- Run this script in Supabase SQL Editor.
-- Includes all migrations: base schema + 001..004

create extension if not exists pgcrypto;

-- ============================================================
-- ENUMS
-- ============================================================

create type public.app_role as enum ('patient', 'doctor');

do $$
begin
  if not exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'app_role' and e.enumlabel = 'admin'
  ) then
    alter type public.app_role add value 'admin';
  end if;
end
$$;

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role public.app_role not null default 'patient',
  is_approved boolean not null default false,
  avatar_url text,
  phone_number text,
  specialty text,
  bio text,
  blood_type text,
  medical_record text,
  consultation_fee numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists is_approved boolean not null default false;

alter table public.profiles
  add column if not exists blood_type text;

alter table public.profiles
  add column if not exists medical_record text;

-- Appointments
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_at timestamptz not null,
  status text not null default 'pending',
  is_urgent boolean not null default false,
  patient_deleted boolean not null default false,
  doctor_deleted boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointments_status_check
    check (status in ('pending', 'accepted', 'rejected', 'completed'))
);

-- Medical files
create table if not exists public.medical_files (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid references public.profiles(id) on delete set null,
  uploaded_by uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  file_path text not null unique,
  content_type text,
  created_at timestamptz not null default now()
);

-- Clinical notes
create table if not exists public.clinical_notes (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Chat messages
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message_text text,
  attachment_path text,
  attachment_name text,
  attachment_type text,
  delivery_status text not null default 'sent',
  seen_at timestamptz,
  created_at timestamptz not null default now(),
  constraint chat_message_content_check check (
    message_text is not null or attachment_path is not null
  )
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'chat_messages_delivery_status_check'
  ) then
    alter table public.chat_messages
      add constraint chat_messages_delivery_status_check
      check (delivery_status in ('sent', 'delivered', 'seen'));
  end if;
end
$$;

alter table public.chat_messages replica identity full;

-- Complaints
create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid references public.profiles(id) on delete set null,
  title text not null,
  body text not null,
  status text not null default 'open',
  admin_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint complaints_status_check check (status in ('open', 'in_review', 'resolved', 'rejected'))
);

-- Doctor settings
create table if not exists public.doctor_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  appointment_requests_notification boolean not null default true,
  new_messages_notification boolean not null default true,
  video_call_requests_notification boolean not null default true,
  doctor_name text not null default 'Dr. John Doe',
  specialization text not null default 'General Medicine',
  license_number text not null default 'MD123456',
  experience text not null default '10 years',
  working_hours text not null default 'Mon-Fri: 9:00 AM - 5:00 PM',
  two_factor_enabled boolean not null default false,
  profile_visibility boolean not null default true,
  show_online_status boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Feedback
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  user_type text not null default 'patient',
  feedback text not null,
  status text not null default 'pending',
  admin_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_user_type_check check (user_type in ('patient', 'doctor', 'admin')),
  constraint feedback_status_check check (status in ('pending', 'reviewed', 'responded'))
);

-- Doctor posts (migration 003)
create table if not exists public.doctor_posts (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Post comments (migration 003)
create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.doctor_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint post_comments_body_check check (char_length(body) > 0)
);

-- Post likes (migration 003)
create table if not exists public.post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.doctor_posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(post_id, user_id)
);

-- Doctor reviews (migration 004)
create table if not exists public.doctor_reviews (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  rating int not null check (rating >= 1 and rating <= 5),
  review_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(doctor_id, patient_id)
);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, is_approved, specialty, phone_number)
  values (
    new.id,
    coalesce(lower(new.raw_user_meta_data ->> 'role')::public.app_role, 'patient'::public.app_role),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    case
      when lower(coalesce(new.raw_user_meta_data ->> 'role', 'patient')) = 'doctor' then false
      else true
    end,
    new.raw_user_meta_data ->> 'specialty',
    new.raw_user_meta_data ->> 'phone_number'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function public.is_doctor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'doctor'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

-- updated_at triggers
drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_appointments_updated_at on public.appointments;
create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.set_updated_at();

drop trigger if exists trg_clinical_notes_updated_at on public.clinical_notes;
create trigger trg_clinical_notes_updated_at
before update on public.clinical_notes
for each row execute function public.set_updated_at();

drop trigger if exists trg_complaints_updated_at on public.complaints;
create trigger trg_complaints_updated_at
before update on public.complaints
for each row execute function public.set_updated_at();

drop trigger if exists trg_doctor_settings_updated_at on public.doctor_settings;
create trigger trg_doctor_settings_updated_at
before update on public.doctor_settings
for each row execute function public.set_updated_at();

drop trigger if exists trg_feedback_updated_at on public.feedback;
create trigger trg_feedback_updated_at
before update on public.feedback
for each row execute function public.set_updated_at();

drop trigger if exists trg_doctor_posts_updated_at on public.doctor_posts;
create trigger trg_doctor_posts_updated_at
before update on public.doctor_posts
for each row execute function public.set_updated_at();

drop trigger if exists trg_post_comments_updated_at on public.post_comments;
create trigger trg_post_comments_updated_at
before update on public.post_comments
for each row execute function public.set_updated_at();

drop trigger if exists trg_doctor_reviews_updated_at on public.doctor_reviews;
create trigger trg_doctor_reviews_updated_at
before update on public.doctor_reviews
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ============================================================
-- REALTIME PUBLICATION
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'appointments'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'profiles'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'doctor_posts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_posts;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'post_likes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.post_likes;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'doctor_reviews'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.doctor_reviews;
    END IF;
END $$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.appointments enable row level security;
alter table public.medical_files enable row level security;
alter table public.clinical_notes enable row level security;
alter table public.chat_messages enable row level security;
alter table public.complaints enable row level security;
alter table public.doctor_settings enable row level security;
alter table public.feedback enable row level security;
alter table public.doctor_posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.doctor_reviews enable row level security;

-- ============================================================
-- RLS: PROFILES
-- ============================================================

drop policy if exists "profiles_select_self_or_staff_or_doctors" on public.profiles;
create policy "profiles_select_self_or_staff_or_doctors"
on public.profiles
for select
using (
  id = auth.uid()
  or public.is_admin()
  or (role = 'doctor' and is_approved = true)
  or exists (
    select 1
    from public.appointments a
    where (
      a.patient_id = auth.uid()
      and a.doctor_id = profiles.id
    )
    or (
      public.is_doctor()
      and a.doctor_id = auth.uid()
      and a.patient_id = profiles.id
    )
  )
);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_admin_manage" on public.profiles;
create policy "profiles_admin_manage"
on public.profiles
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: APPOINTMENTS
-- ============================================================

drop policy if exists "appointments_select_own" on public.appointments;
create policy "appointments_select_own"
on public.appointments
for select
using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

drop policy if exists "appointments_insert_by_patient" on public.appointments;
create policy "appointments_insert_by_patient"
on public.appointments
for insert
with check (patient_id = auth.uid());

drop policy if exists "appointments_insert_by_doctor" on public.appointments;
create policy "appointments_insert_by_doctor"
on public.appointments
for insert
with check (doctor_id = auth.uid() and public.is_doctor());

drop policy if exists "appointments_update_own" on public.appointments;
create policy "appointments_update_own"
on public.appointments
for update
using (patient_id = auth.uid() or doctor_id = auth.uid())
with check (patient_id = auth.uid() or doctor_id = auth.uid());

drop policy if exists "appointments_doctor_accept" on public.appointments;
create policy "appointments_doctor_accept"
on public.appointments
for update
using (doctor_id = auth.uid() and public.is_doctor())
with check (doctor_id = auth.uid() and public.is_doctor());

drop policy if exists "appointments_admin_manage" on public.appointments;
create policy "appointments_admin_manage"
on public.appointments
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: MEDICAL FILES
-- ============================================================

drop policy if exists "medical_files_select_own" on public.medical_files;
create policy "medical_files_select_own"
on public.medical_files
for select
using (patient_id = auth.uid() or doctor_id = auth.uid() or uploaded_by = auth.uid() or public.is_admin());

drop policy if exists "medical_files_insert_own" on public.medical_files;
create policy "medical_files_insert_own"
on public.medical_files
for insert
with check (
  uploaded_by = auth.uid()
  and (
    (
      patient_id = auth.uid()
      and exists (
        select 1
        from public.appointments a
        where a.patient_id = medical_files.patient_id
          and a.doctor_id = medical_files.doctor_id
          and a.status = 'Accepted'
      )
    )
    or (
      doctor_id = auth.uid()
      and public.is_doctor()
      and exists (
        select 1
        from public.appointments a
        where a.patient_id = medical_files.patient_id
          and a.doctor_id = medical_files.doctor_id
          and a.status = 'Accepted'
      )
    )
  )
);

drop policy if exists "medical_files_admin_manage" on public.medical_files;
create policy "medical_files_admin_manage"
on public.medical_files
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: CLINICAL NOTES
-- ============================================================

drop policy if exists "clinical_notes_select_own" on public.clinical_notes;
create policy "clinical_notes_select_own"
on public.clinical_notes
for select
using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

drop policy if exists "clinical_notes_insert_doctor" on public.clinical_notes;
create policy "clinical_notes_insert_doctor"
on public.clinical_notes
for insert
with check (
  doctor_id = auth.uid()
  and public.is_doctor()
  and exists (
    select 1
    from public.appointments a
    where a.id = clinical_notes.appointment_id
      and a.patient_id = clinical_notes.patient_id
      and a.doctor_id = clinical_notes.doctor_id
      and a.status in ('Accepted', 'Completed')
  )
);

drop policy if exists "clinical_notes_update_doctor" on public.clinical_notes;
create policy "clinical_notes_update_doctor"
on public.clinical_notes
for update
using (
  doctor_id = auth.uid()
  and public.is_doctor()
  and exists (
    select 1
    from public.appointments a
    where a.id = clinical_notes.appointment_id
      and a.patient_id = clinical_notes.patient_id
      and a.doctor_id = clinical_notes.doctor_id
      and a.status in ('Accepted', 'Completed')
  )
)
with check (
  doctor_id = auth.uid()
  and public.is_doctor()
  and exists (
    select 1
    from public.appointments a
    where a.id = clinical_notes.appointment_id
      and a.patient_id = clinical_notes.patient_id
      and a.doctor_id = clinical_notes.doctor_id
      and a.status in ('Accepted', 'Completed')
  )
);

drop policy if exists "clinical_notes_admin_manage" on public.clinical_notes;
create policy "clinical_notes_admin_manage"
on public.clinical_notes
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: CHAT MESSAGES
-- ============================================================

drop policy if exists "chat_messages_select_own" on public.chat_messages;
create policy "chat_messages_select_own"
on public.chat_messages
for select
using (
  exists (
    select 1
    from public.appointments a
    where a.id = chat_messages.appointment_id
      and (a.patient_id = auth.uid() or a.doctor_id = auth.uid() or public.is_admin())
  )
);

drop policy if exists "chat_messages_insert_own" on public.chat_messages;
create policy "chat_messages_insert_own"
on public.chat_messages
for insert
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.appointments a
    where a.id = chat_messages.appointment_id
      and a.status = 'Accepted'
      and (a.patient_id = auth.uid() or a.doctor_id = auth.uid())
  )
);

drop policy if exists "chat_messages_update_participants" on public.chat_messages;
create policy "chat_messages_update_participants"
on public.chat_messages
for update
using (
  exists (
    select 1
    from public.appointments a
    where a.id = chat_messages.appointment_id
      and a.status = 'Accepted'
      and (a.patient_id = auth.uid() or a.doctor_id = auth.uid() or public.is_admin())
  )
)
with check (
  exists (
    select 1
    from public.appointments a
    where a.id = chat_messages.appointment_id
      and a.status = 'Accepted'
      and (a.patient_id = auth.uid() or a.doctor_id = auth.uid() or public.is_admin())
  )
);

drop policy if exists "chat_messages_admin_manage" on public.chat_messages;
create policy "chat_messages_admin_manage"
on public.chat_messages
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: COMPLAINTS
-- ============================================================

drop policy if exists "complaints_select_own_or_admin" on public.complaints;
create policy "complaints_select_own_or_admin"
on public.complaints
for select
using (
  patient_id = auth.uid()
  or doctor_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "complaints_insert_patient" on public.complaints;
create policy "complaints_insert_patient"
on public.complaints
for insert
with check (patient_id = auth.uid());

drop policy if exists "complaints_admin_manage" on public.complaints;
create policy "complaints_admin_manage"
on public.complaints
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: DOCTOR SETTINGS
-- ============================================================

drop policy if exists "doctor_settings_select_own" on public.doctor_settings;
create policy "doctor_settings_select_own"
on public.doctor_settings
for select
using (user_id = auth.uid());

drop policy if exists "doctor_settings_insert_own" on public.doctor_settings;
create policy "doctor_settings_insert_own"
on public.doctor_settings
for insert
with check (user_id = auth.uid());

drop policy if exists "doctor_settings_update_own" on public.doctor_settings;
create policy "doctor_settings_update_own"
on public.doctor_settings
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- ============================================================
-- RLS: FEEDBACK
-- ============================================================

drop policy if exists "feedback_insert_own" on public.feedback;
create policy "feedback_insert_own"
on public.feedback
for insert
with check (user_id = auth.uid() or user_id is null);

drop policy if exists "feedback_select_own" on public.feedback;
create policy "feedback_select_own"
on public.feedback
for select
using (user_id = auth.uid());

drop policy if exists "feedback_admin_manage" on public.feedback;
create policy "feedback_admin_manage"
on public.feedback
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: DOCTOR POSTS (migration 003)
-- ============================================================

drop policy if exists "doctor_posts_select_public" on public.doctor_posts;
create policy "doctor_posts_select_public"
on public.doctor_posts
for select
using (true);

drop policy if exists "doctor_posts_insert_doctor" on public.doctor_posts;
create policy "doctor_posts_insert_doctor"
on public.doctor_posts
for insert
with check (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'doctor'
      and p.is_approved = true
  )
);

drop policy if exists "doctor_posts_modify_own" on public.doctor_posts;
create policy "doctor_posts_modify_own"
on public.doctor_posts
for all
using (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'doctor'
      and p.is_approved = true
  )
)
with check (
  doctor_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'doctor'
      and p.is_approved = true
  )
);

drop policy if exists "doctor_posts_admin_all" on public.doctor_posts;
create policy "doctor_posts_admin_all"
on public.doctor_posts
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: POST COMMENTS (migration 003)
-- ============================================================

drop policy if exists "post_comments_select_public" on public.post_comments;
create policy "post_comments_select_public"
on public.post_comments
for select
using (true);

drop policy if exists "post_comments_insert_auth" on public.post_comments;
create policy "post_comments_insert_auth"
on public.post_comments
for insert
with check (user_id = auth.uid());

drop policy if exists "post_comments_modify_own" on public.post_comments;
create policy "post_comments_modify_own"
on public.post_comments
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "post_comments_admin_all" on public.post_comments;
create policy "post_comments_admin_all"
on public.post_comments
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: POST LIKES (migration 003)
-- ============================================================

drop policy if exists "post_likes_select_public" on public.post_likes;
create policy "post_likes_select_public"
on public.post_likes
for select
using (true);

drop policy if exists "post_likes_modify_own" on public.post_likes;
create policy "post_likes_modify_own"
on public.post_likes
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "post_likes_admin_all" on public.post_likes;
create policy "post_likes_admin_all"
on public.post_likes
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- RLS: DOCTOR REVIEWS (migration 004)
-- ============================================================

drop policy if exists "doctor_reviews_select_public" on public.doctor_reviews;
create policy "doctor_reviews_select_public"
on public.doctor_reviews
for select
using (true);

drop policy if exists "doctor_reviews_insert_patient" on public.doctor_reviews;
create policy "doctor_reviews_insert_patient"
on public.doctor_reviews
for insert
with check (
  patient_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'patient'
  )
);

drop policy if exists "doctor_reviews_modify_own" on public.doctor_reviews;
create policy "doctor_reviews_modify_own"
on public.doctor_reviews
for all
using (patient_id = auth.uid())
with check (patient_id = auth.uid());

drop policy if exists "doctor_reviews_admin_all" on public.doctor_reviews;
create policy "doctor_reviews_admin_all"
on public.doctor_reviews
for all
using (public.is_admin())
with check (public.is_admin());

-- ============================================================
-- STORAGE BUCKETS & POLICIES
-- ============================================================

-- Medical files bucket
insert into storage.buckets (id, name, public)
values ('medical-files', 'medical-files', false)
on conflict (id) do nothing;

drop policy if exists "storage_select_medical_files" on storage.objects;
create policy "storage_select_medical_files"
on storage.objects
for select
using (
  bucket_id = 'medical-files'
  and (
    split_part(name, '/', 1) = auth.uid()::text
    or exists (
      select 1
      from public.medical_files mf
      where mf.file_path = name
        and (mf.patient_id = auth.uid() or mf.doctor_id = auth.uid() or mf.uploaded_by = auth.uid())
    )
  )
);

drop policy if exists "storage_insert_medical_files" on storage.objects;
create policy "storage_insert_medical_files"
on storage.objects
for insert
with check (
  bucket_id = 'medical-files'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Avatars bucket
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "storage_select_avatars_auth" on storage.objects;
create policy "storage_select_avatars_auth"
on storage.objects
for select
using (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
);

drop policy if exists "storage_insert_own_avatars" on storage.objects;
create policy "storage_insert_own_avatars"
on storage.objects
for insert
with check (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
  and left(name, length(auth.uid() || '/')) = auth.uid() || '/'
);

drop policy if exists "storage_delete_own_avatars" on storage.objects;
create policy "storage_delete_own_avatars"
on storage.objects
for delete
using (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
  and left(name, length(auth.uid() || '/')) = auth.uid() || '/'
);
