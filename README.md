# Telemedicine App

A telemedicine platform built with Flutter featuring role-based dashboards (Patient, Doctor, Admin), real-time chat, video calls (Agora), and Supabase backend.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart 3) |
| **State Management** | GetX (controllers, routing, DI) |
| **Backend** | Supabase (Auth, PostgreSQL, Realtime, Storage) |
| **Video Calls** | Agora RTC Engine v6 |
| **Charts** | fl_chart (admin analytics) |

## Project Structure

```
lib/
├── main.dart                              # Entry point
├── app/
│   ├── app.dart                           # Route registration (GetMaterialApp + GetPage)
│   ├── core/
│   │   ├── agora/agora_service.dart       # Agora token & call helpers
│   │   └── supabase/
│   │       ├── supabase_service.dart      # Supabase client singleton
│   │       └── doctor_reviews_service.dart  # Doctor rating CRUD
│   ├── routes/
│   │   ├── app_pages.dart                 # Route name constants
│   │   └── image_viewer_view.dart         # Full-screen signed image viewer
│   ├── shared/widgets/
│   │   └── github_widgets.dart            # Shared UI components
│   ├── theme/
│   │   ├── github_theme.dart              # Light/dark ThemeData
│   │   └── theme_controller.dart          # Theme mode persistence
│   └── modules/
│       ├── auth/                          # Login, signup, account type selection
│       │   ├── controllers/auth_controller.dart
│       │   └── views/ (startup, login, admin_login, account_type)
│       ├── patient/                       # Patient dashboard, chat, search
│       │   ├── controllers/ (patient, doctor_posts, doctor_search, settings)
│       │   ├── patient_theme.dart
│       │   └── views/ (dashboard, chat, profile, settings, doctor_search)
│       ├── doctor/                        # Doctor dashboard, chat, appointments
│       │   ├── controllers/ (doctor, doctor_chat, settings)
│       │   ├── doctor_theme.dart, doctor_binding.dart
│       │   └── views/ (dashboard, chat, appointments, settings, etc.)
│       ├── admin/                         # Full admin panel
│       │   ├── controllers/admin_controller.dart
│       │   ├── admin_theme.dart
│       │   └── views/ (dashboard, accounts, patients, doctors, admins,
│       │               complaints, posts, reviews)
│       ├── profile/                       # Doctor profile editing + public profile
│       │   ├── controllers/profile_controller.dart
│       │   └── views/ (doctor_profile, public_profile)
│       └── call/views/agora_call_view.dart  # Video call UI
```

## Features by Role

### Patient
- Browse doctor posts with likes
- **Find Doctors** screen: full doctor list with star ratings, search by name/specialty, view profile, send consultation request
- Book appointments with status tracking (Pending → Accepted → Completed)
- Two-way chat with doctor (text + file/image attachments)
- Video calls (Agora)
- Submit complaints to admin
- Edit profile & upload avatar

### Doctor
- Appointment queue with accept/reject
- Chat per appointment (text, files, images)
- Clinical notes per patient
- Close session when consultation ends
- View & manage received star ratings on dashboard
- Video calls (Agora)
- Settings (theme, 2FA, help, about)

### Admin
- **Dashboard**: 8 stat cards (users, patients, doctors, admins, appointments, posts, complaints, open complaints) + account/complaint overview
- **Account Management**: split into 3 dedicated views
  - Manage Patients (search, view details, edit name, delete)
  - Manage Doctors (search, view, edit, delete, create doctor account)
  - Manage Admins (search, view, edit, delete — self-deletion blocked)
- **Manage Posts**: view/delete doctor posts
- **Manage Reviews**: view/delete patient reviews on doctors
- **Complaints**: view, filter by status, update status, respond

## Supabase Setup

### 1. Database Migrations

Run in order from `supabase/`:

| File | Purpose |
|------|---------|
| `schema.sql` | Core tables (profiles, appointments, chat_messages, complaints, doctor_posts) + RLS |
| `migrations/001_add_profiles_avatar_and_rls.sql` | Avatar storage, phone/specialty/bio fields |
| `migrations/002_one_sided_appointment_deletion.sql` | patient_deleted/doctor_deleted flags |
| `migrations/003_posts_comments_likes_rls.sql` | Post likes table + RLS |
| `migrations/004_doctor_reviews.sql` | Doctor reviews table + UNIQUE constraint + RLS |

### 2. Storage Buckets

Create two private buckets in Supabase Dashboard:

- `avatars` — Profile images (authenticated)
- `medical-files` — Chat attachments (authenticated + RLS)

### 3. Auth Configuration

- Enable **Email** auth provider in Supabase Dashboard
- (Optional) Enable Google OAuth

### 4. Agora Edge Function

Deploy `supabase/functions/agora-token/index.ts` as a Supabase Edge Function, then add secrets:

```
AGORA_APP_ID=your_app_id
AGORA_APP_CERTIFICATE=your_certificate
```

## Running the App

### Quick start (default values in supabase_service.dart):

```bash
flutter run
```

### With environment variables:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### With Agora video:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

### Static analysis:

```bash
flutter analyze lib/
# Expected: 0 errors, 0 warnings
```

## Authentication Flow

1. **Splash** → check Supabase session → redirect to account type or dashboard
2. **Account type** → choose Patient, Doctor (login), or Admin (separate login)
3. **Patient**: registers → admin approves → login
4. **Doctor**: admin creates account → doctor logs in
5. **Admin**: direct login (admin accounts created manually in DB)

## Core Workflows

### Appointment Booking
Patient selects doctor → sends request (Pending) → doctor accepts (Accepted) → chat & video enabled

### Chat & Files
Patient & doctor exchange messages in real-time. Supports text, images, and file attachments via Supabase Storage (RLS-protected). Uses Supabase Realtime for live updates.

### Video Calls
Agora RTC with channel per appointment. Token generated server-side via Supabase Edge Function with appointment ownership verification.

### Doctor Ratings
Patients rate doctors (1–5 stars) from the public profile page. One review per patient per doctor (upsert). Average rating + review count shown on the **Find Doctors** screen.

### Admin Panel
- Dashboard with site-wide statistics
- Dedicated views for patients, doctors, admins with search, edit, delete
- Doctor account creation (admin sets email + password + name)
- Post & review moderation
- Complaint management with status tracking

## Security (RLS)

All tables have Row-Level Security policies enforced at the database level:

- Patients see only their own data
- Doctors see only their assigned patients' data
- Admins have full read/write access
- Storage buckets are private (authenticated access only)
- Chat messages restricted to appointment participants
- Doctor reviews: one review per patient per doctor (UNIQUE constraint)

## Design System

Consistent styling applied across all auth screens and admin views:

- **Background**: Radial gradient (#EFF3FC → #D9E2EF → #C9D5E8)
- **Cards**: Glass-morphism (white 94% opacity, border-radius 28–32, soft shadows)
- **Inputs**: Border-radius 20, white fill, navy accent on focus
- **Buttons**: Navy (#1E3A5F), pill-shaped (radius 40)
- **Typography**: Primary #0A1F3A, Secondary #4A627A

Each module has its own `*_theme.dart` with reusable style classes (`AdminStyles`, `DoctorStyles`, `PatientStyles`).

## Admin Routes

| Route | View |
|-------|------|
| `/admin` | Dashboard |
| `/admin/accounts` | Legacy account list |
| `/admin/patients` | Manage patients |
| `/admin/doctors` | Manage doctors + create |
| `/admin/admins` | Manage admins |
| `/admin/complaints` | Complaint management |
| `/admin/posts` | Doctor post moderation |
| `/admin/reviews` | Review moderation |

## Linting

The project uses `flutter_lints` and passes with **zero errors, zero warnings** on `flutter analyze lib/`.
