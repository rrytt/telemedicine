-- Migration: Add one-sided appointment deletion support
-- This adds soft-delete flags so patients and doctors can remove appointments locally.

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS patient_deleted boolean not null default false;

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS doctor_deleted boolean not null default false;
