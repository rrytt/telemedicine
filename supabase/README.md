This folder contains Supabase migration / setup instructions for the Telemedicine app.

Steps to apply changes:

1) Create the `avatars` storage bucket (private/authenticated recommended):

Using Supabase CLI:

```bash
supabase storage create-bucket avatars --public false
```

Or via Supabase Dashboard: Storage → New bucket → name `avatars` → Privacy: Private (authenticated).

> Important: this bucket must be created manually before running the SQL migration. The migration script only updates tables and policies; it does not create the storage bucket.

2) Apply the SQL migration:

Open `supabase/migrations/001_add_profiles_avatar_and_rls.sql` and run it in the Supabase SQL editor (Dashboard → SQL Editor → New query) or run via psql connected to your project's database.

3) Verify:

- Upload an avatar from the app; the client should save the path `userId/filename` into `profiles.avatar_url`.
- Use the authenticated endpoint to retrieve images:
  `https://{PROJECT_REF}.supabase.co/storage/v1/object/authenticated/avatars/{path}`
- Confirm the new profile fields are present for the signed-in user: `phone_number`, `specialty`, and `bio`.

Notes / Troubleshooting:
- If your `profiles` table has other NOT NULL columns, include them in the `upsert` payload from the app or alter the column to accept NULL.
- Adjust policies if you want admins to read/modify all profiles.
- For public profile images (no auth required), set bucket public, but be cautious about privacy.
