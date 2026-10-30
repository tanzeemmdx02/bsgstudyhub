# Security notes

## Provisioning roles (required, manual)
Roles are never writable by clients. To create staff:
1. Create the user in Firebase Console -> Authentication.
2. Admin: create `users/{uid}` with `role: "admin"`, `name`, `email`, `status: "active"`.
3. Teacher: create `teachers/{uid}` with `name`, `email`.
Students self-register through the admission form (`users/{uid}`, role `student`).

## Deploy rules
`firebase deploy --only firestore:rules,storage` (then test with the Emulator).

## Known gaps (not fixed yet)
- Answer keys (`correctIndex`) are readable by students; grading is client-side.
- Teachers can edit any course/exam (no per-resource ownership yet).
- Admissions/attendance are staff-only because their data models are undefined.
- Admission form creates the Auth account before the profile write; a failed
  write leaves an Auth user without a profile (the app shows "Profile unavailable").
- Rules were written without running the Firebase Emulator. Test before deploying.
