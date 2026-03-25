-- Telemedicine schema (Supabase)
-- Run this script in Supabase SQL Editor.

create extension if not exists pgcrypto;

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

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role public.app_role not null default 'patient',
  is_approved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists is_approved boolean not null default false;

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_at timestamptz not null,
  status text not null default 'Pending',
  is_urgent boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointments_status_check
    check (status in ('Pending', 'Accepted', 'Rejected', 'Completed'))
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message_text text,
  attachment_path text,
  attachment_name text,
  attachment_type text,
  created_at timestamptz not null default now(),
  constraint chat_message_content_check check (
    message_text is not null or attachment_path is not null
  )
);

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

create table if not exists public.clinical_notes (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.set_updated_at();

create trigger trg_clinical_notes_updated_at
before update on public.clinical_notes
for each row execute function public.set_updated_at();

create trigger trg_complaints_updated_at
before update on public.complaints
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (
    new.id,
    coalesce((new.raw_user_meta_data ->> 'role')::public.app_role, 'patient'::public.app_role),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  update public.profiles
  set is_approved = (role = 'admin')
  where id = new.id;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_doctor()
returns boolean
language sql
stable
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
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.appointments enable row level security;
alter table public.medical_files enable row level security;
alter table public.clinical_notes enable row level security;
alter table public.chat_messages enable row level security;
alter table public.complaints enable row level security;

-- Profiles policies
drop policy if exists "profiles_select_self_or_doctor" on public.profiles;
create policy "profiles_select_self_or_doctor"
on public.profiles
for select
using (id = auth.uid() or public.is_doctor() or public.is_admin());

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

-- Appointments policies
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

-- Medical files policies
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
  and (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_doctor())
);

drop policy if exists "medical_files_admin_manage" on public.medical_files;
create policy "medical_files_admin_manage"
on public.medical_files
for all
using (public.is_admin())
with check (public.is_admin());

-- Clinical notes policies
drop policy if exists "clinical_notes_select_own" on public.clinical_notes;
create policy "clinical_notes_select_own"
on public.clinical_notes
for select
using (patient_id = auth.uid() or doctor_id = auth.uid() or public.is_admin());

drop policy if exists "clinical_notes_insert_doctor" on public.clinical_notes;
create policy "clinical_notes_insert_doctor"
on public.clinical_notes
for insert
with check (doctor_id = auth.uid() and public.is_doctor());

drop policy if exists "clinical_notes_update_doctor" on public.clinical_notes;
create policy "clinical_notes_update_doctor"
on public.clinical_notes
for update
using (doctor_id = auth.uid() and public.is_doctor())
with check (doctor_id = auth.uid() and public.is_doctor());

drop policy if exists "clinical_notes_admin_manage" on public.clinical_notes;
create policy "clinical_notes_admin_manage"
on public.clinical_notes
for all
using (public.is_admin())
with check (public.is_admin());

-- Chat messages policies
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

drop policy if exists "chat_messages_admin_manage" on public.chat_messages;
create policy "chat_messages_admin_manage"
on public.chat_messages
for all
using (public.is_admin())
with check (public.is_admin());

-- Complaints policies
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

-- Storage bucket and policies
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
