# Telemedicine (Flutter + GetX + Supabase)

تطبيق مكالمات أطباء مع نوعين من الحسابات (Patient / Doctor) وتصميم قريب من GitHub.

## Features

- GetX architecture (routing + controllers)
- Supabase Auth (Login / Signup)
- Role-based routing (Patient vs Doctor)
- Role-based routing (Patient, Doctor, Admin)
- Patient dashboard with doctor selection and appointment booking
- Doctor dashboard with appointment acceptance + clinical notes
- Admin dashboard for account approvals, edits, deletes, and complaints review
- Two-way chat between patient and doctor per appointment
- Patient can send files/images/videos in chat via Supabase Storage
- SQL schema and RLS policies جاهزة في:
	- [supabase/schema.sql](supabase/schema.sql)

## Supabase Setup

1. افتح Supabase SQL Editor.
2. نفذ الملف [supabase/schema.sql](supabase/schema.sql) كاملًا.
3. تأكد أن Email auth مفعل من لوحة Supabase.
4. انشر Edge Function الخاصة بـ Agora من المسار:
	- [supabase/functions/agora-token/index.ts](supabase/functions/agora-token/index.ts)
5. أضف أسرار الوظيفة في Supabase Secrets:
	- `AGORA_APP_ID`
	- `AGORA_APP_CERTIFICATE`

## Run App

يمكن التشغيل مباشرة لأن القيم الافتراضية موجودة في الخدمة، أو تمرير القيم عبر dart-define:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

اختياريًا يمكنك تمرير App ID مباشرة للتطبيق:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

## Auth + Roles Flow

- عند التسجيل يتم تمرير الدور (`patient` أو `doctor`).
- يتم حفظ الدور في:
	- `profiles.role` (الأساسي)
	- `user_metadata.role` (fallback)
- بعد تسجيل الدخول، التطبيق يقرأ الدور ويوجه المستخدم تلقائيًا إلى واجهته.
- حسابات patient/doctor تحتاج موافقة admin قبل الدخول.
- حساب admin حساب خاص (لا يتم إنشاؤه من التطبيق).

## Appointment + Chat Flow

- المريض يختار الطبيب ووقت الموعد ثم يرسل طلب حجز بحالة `Pending`.
- الطبيب يقبل الموعد من بوابة الطبيب (`Accept Appointment`) فتتحول الحالة إلى `Accepted`.
- بعد القبول، يتم تفعيل الدردشة الثنائية بين المريض والطبيب.
- بعد القبول، يتم تفعيل مكالمة الفيديو بين المريض والطبيب عبر Agora.
- المريض يمكنه إرسال نصوص وملفات/صور/فيديو، وتظهر للطبيب داخل نفس الدردشة.

## Agora Token Flow

- التطبيق يبني اسم قناة خاص بكل موعد باستخدام `appointmentId`.
- عند بدء مكالمة الفيديو، التطبيق يستدعي Supabase Edge Function `agora-token`.
- الوظيفة تتحقق أن المستخدم الحالي هو المريض أو الطبيب الخاص بالموعد.
- الوظيفة تنشئ توكن Agora مؤقتًا وتعيده للتطبيق.
- لا حاجة لتخزين `AGORA_APP_CERTIFICATE` داخل تطبيق Flutter.

## Admin Workflow

- الإدمن يسجل الدخول من بطاقة Admin في شاشة اختيار الحساب.
- يمكنه إدارة الحسابات: تأكيد الحساب، تعديل الاسم، تغيير الدور، حذف الحساب.
- يمكنه مراجعة الشكاوى الواردة من المرضى والرد عليها وتحديث حالتها.

## Security (RLS)

تم تضمين RLS Policies في SQL بحيث:

- المريض يرى بياناته فقط.
- الطبيب يرى بيانات مرضاه فقط.
- الملاحظات السريرية يكتبها الطبيب فقط.
- ملفات Storage خاصة ومقيدة بسياسات وصول.

## Important Note

يفضل أمنيًا استخدام مفاتيح Supabase عبر `--dart-define` أو إدارة أسرار CI/CD بدل حفظها داخل الكود.