# ReadBloom Current Status

Last reviewed: 2026-08-31

ReadBloom is a three-app Flutter thesis platform backed by one hosted Supabase project. The active code structure is:

- `student_readbloom`: student-facing reading, recording, quiz, journey, messages, and profile app.
- `teacher_readbloom`: teacher-facing dashboard, student progress, book management, activity log, badges, review, and settings app.
- `admin_readbloom`: admin-facing dashboard, account management, section management, book management, reading-history management, and activity views.
- `supabase`: database migrations, seed data, documentation, and Edge Function source.

The apps use Provider-based state with repository/service layers. The default runtime repositories are Supabase-backed; mock repositories remain only for local fallback and focused provider/widget checks. Mobile and web UI are split under `screens/.../mobile` and `screens/.../web`, while backend access is shared through each app's provider/repository/service code.

## Phase Status

Phase 1 repository cleanup and backend-readiness is complete.

Phase 2 backend foundation source files exist under `supabase/` and were applied manually in the hosted Supabase project by the project owner.

Phase 3 Supabase Auth integration is implemented across all three Flutter apps. Login uses role-aware auth and validates `profiles.role` plus `profiles.status`.

Phase 4 profile, sections, safety agreement, and profile picture integration is complete based on project-owner live validation.

Phase 5 books and quiz management is complete for the current create-and-display scope based on project-owner live validation.

Phase 6 student recording flow and Supabase reading-video upload is complete based on project-owner live validation.

Phase 7 speech-to-text processing is complete for the current backend scope based on project-owner live validation. Student uploads invoke the hosted `process-reading-submission` Edge Function and transcript results appear in Supabase.

Phase 8 quiz turn-in persistence is complete based on project-owner live validation. Quiz answers are saved, the reading submission is marked submitted, and activity rows are written.

Phase 9 teacher student-progress and review has a local implementation pass and partial live validation. Teacher login/data loading was fixed and project-owner validation shows teacher-side data correctly, but remaining data-reflection details still need final live confirmation before marking this phase fully complete.

Phase 10 badges, journey, messages, and activity logs has a local implementation pass across student, teacher, and admin apps. It uses Supabase-backed data and needs final hosted live validation.

Phase 11 admin account and data management has a local implementation pass. It adds Edge Function-backed account creation/deletion, section-backed role-specific profile creation, role/status/section filtering, account disabling, section creation/deletion, book deletion, reading-history deletion, and audit logging.

Phase 12 security and production hardening is in progress. Current work includes blocking loading dialogs, production-facing dummy-data cleanup, forgot-password recovery routing, password-reset provider coverage, and a manual live-validation checklist.

## Current Feature Additions

Feature 1 from `new-features.md` has a local implementation pass:

- Teacher mobile/web Add Book forms include AI-assisted draft generation.
- `TeacherProvider` and `TeacherRepository` expose draft generation without auto-saving.
- `supabase/functions/generate-book-content` validates active teacher access and section assignment before calling Gemini.
- The generated title, passage, and questions are returned as draft content for teacher review before saving.

Feature 2 from `new-features.md` has a local implementation pass:

- `process-reading-submission` stores deterministic suggested reading remarks for omission, repetition, self-correction, and possible mispronunciation.
- `transcript_results` includes suggested-remark columns.
- The teacher review popup preloads suggested marks while preserving teacher override before feedback is sent to students.

Feature 2B from `new-features.md` has a local implementation pass:

- `process-reading-submission` can optionally run a second Gemini review pass when `READBLOOM_AI_REMARK_REVIEW_ENABLED=true`.
- AI-reviewed suggestions are validated and merged with deterministic suggestions.
- If AI review fails, the function falls back to deterministic suggestions.
- Teacher review UI can label AI-reviewed suggestions distinctly.

Student, teacher, and admin mobile dashboard shells support pull-to-refresh for manual data reloads. All mobile tabs across student, teacher, and admin apps use always-scrollable top-level lists/scroll views and scrollable empty states so pull-to-refresh works reliably in portrait mode even when content is short or empty. Web refresh buttons were removed; browser refresh remains the web refresh path.

## Repository Health

- The root folder contains a placeholder `.git`, while each Flutter app has its own Git repository.
- `student_readbloom`, `teacher_readbloom`, and `admin_readbloom` had clean app-level Git status before the 2026-08-31 hardening edits.
- The `zip/` folder contains packaged copies/archives and is not the active source tree.
- The three app `README.md` files still look like Flutter starter documentation.
- Supabase URL and publishable key are currently hardcoded in each app's `BackendConfig`. No service-role key is present in Flutter code.

## Current Dependencies

Shared app dependencies:

- `provider`
- `google_fonts`
- `fl_chart`
- `cupertino_icons`
- `supabase_flutter`
- `flutter_lints`

App-specific dependencies:

- Student: `camera`, `video_player`, `image_picker`
- Teacher: `file_picker`, `video_player`
- Admin: `file_picker`

## Current Architecture

Each app has one main provider:

- `StudentProvider`
- `TeacherProvider`
- `AdminProvider`

Each app uses the same broad folder pattern:

- `lib/config`
- `lib/services`
- `lib/repositories`
- `lib/models`
- `lib/screens`
- `lib/widgets`
- `lib/theme`
- `lib/assets`

The service/repository layer includes:

- Student: `StudentRepository`, `MockStudentRepository`, `SupabaseStudentRepository`, `AuthService`, `MockStudentAuthService`, `SupabaseRoleAuthService`
- Teacher: `TeacherRepository`, `MockTeacherRepository`, `SupabaseTeacherRepository`, `AuthService`, `MockTeacherAuthService`, `SupabaseRoleAuthService`
- Admin: `AdminRepository`, `MockAdminRepository`, `SupabaseAdminRepository`, `AuthService`, `MockAdminAuthService`, `SupabaseRoleAuthService`

## Implemented Backend Features

Supabase Auth:

- Role-aware login for student, teacher, and admin apps.
- Wrong-role and disabled-account blocking.
- Session restore on provider startup.
- Forgot-password request popups.
- Password recovery routing to reset-password screens.

Supabase database:

- Shared `profiles` table for account identity, role, status, email, full name, and avatar path.
- Student profile data through `student_profiles`.
- Teacher profile data through `teacher_profiles` and assigned sections through `teacher_sections`.
- Sections and schools.
- Books and multiple-choice questions.
- Reading submissions.
- Transcript results and alignment data.
- Quiz answers.
- Teacher feedback and student messages.
- Badges and student badge awards.
- Activity logs.
- Safety agreements and student safety acceptances.

Supabase Storage:

- Private `avatars` bucket for profile pictures.
- Private `reading-videos` bucket for student reading recordings.
- Private `reading-audio` bucket is defined for audio-oriented flows.
- Apps use signed URLs for private avatar/video display where needed.

Supabase Edge Functions:

- `process-reading-submission`: validates caller/submission access, downloads private media, sends media to Gemini, stores transcript/alignment/suggested remarks, updates submission status, and writes activity logs.
- `generate-book-content`: validates active teacher and assigned section access, calls Gemini, validates returned draft JSON, and returns draft content without saving it.
- `admin-create-user`: validates active admin, creates Supabase Auth users with the service-role key, inserts role-specific profile rows, assigns sections, and writes audit activity.
- `admin-delete-user`: validates active admin, blocks self/admin deletion, deletes student/teacher Auth users, and writes audit activity.

## Student App Status

Implemented screens:

- Splash
- Login
- Reset password
- Privacy/safety agreement
- Dashboard
- My Journey
- Messages
- Profile
- Calibration
- Read aloud
- Preview
- Uploading
- Quiz
- Congrats

Current behavior:

- Login uses Supabase role validation for `student`.
- Profile loads from `profiles`, `student_profiles`, and `sections`.
- Safety agreement acceptance checks and writes Supabase agreement records.
- Profile picture upload uses image picker/web file input and stores the avatar in private Supabase Storage.
- Dashboard and profile share the same provider-backed avatar/profile state.
- Assigned books load from Supabase using the student's exact grade and section.
- Quiz questions load from `book_questions`.
- Books without passages or quiz questions are blocked from starting.
- Camera and microphone are initialized before reading with optimized lightweight recording defaults (ResolutionPreset.low targeting 360p, 300 kbps video bitrate, 64 kbps audio bitrate, and 24 fps) to prevent rapid storage quota exhaustion.
- Read-aloud records local video/audio and tracks the 5-minute overtime flag.
- Preview plays the recorded local video and supports scrubbing.
- Upload creates a `reading_submissions` row, uploads media, updates status, and invokes speech-to-text processing.
- Quiz completion saves `quiz_answers`, marks the submission `submitted`, sets `submitted_at`, and writes activity.
- Journey shows Supabase-backed completed books, assigned book count, skill levels, streak, and awarded badges.
- Messages load Supabase `messages`, show teacher feedback and remark highlights, and mark messages read through `read_at`.

Remaining student concerns:

- The student recording timer now enforces the 5-minute cap locally and stops the active camera recording when the limit is reached.
- Temporary local recording cleanup should still be reviewed on discard/cancel paths.
- Some data-loss guards from `point-of-errors.md` remain useful: confirmation before cancel/start-over, route-level protection during recording/upload/quiz, and clearer permission-denied handling.

## Teacher App Status

Implemented screens:

- Login
- Reset password
- Dashboard
- Students Progress
- Student detail/evaluation review
- Books
- Badges
- Activity Log
- Profile/settings

Current behavior:

- Login uses Supabase role validation for `teacher`.
- Teacher account loads from `profiles`, `teacher_profiles`, and `schools`.
- Assigned sections load from `teacher_sections` and `sections`.
- Dashboard data, assigned students, class stats, recent reading activity, reading reviews, and books load from Supabase.
- Optional dashboard/review data is fail-soft and no longer signs the teacher out when a secondary query fails.
- Student progress filters derive from real loaded student grade/section values.
- Reading history popups list real submitted attempts.
- Review UI shows transcript, actual passage, quiz score, reading accuracy, student avatar, and signed video playback.
- Review UI supports teacher remark tagging for omission, repetition, self-correction, and mispronunciation.
- Suggested reading remarks can preload from transcript processing while preserving teacher override.
- Feedback writes `teacher_feedback`, inserts a student `messages` row, and writes a best-effort activity log.
- Skill-level updates persist to `student_profiles`.
- Badges load from `student_badges`; awarding a badge creates/reuses `badges`, inserts `student_badges`, and writes activity.
- Book creation saves published books and multiple questions to Supabase.
- AI-assisted book draft generation fills the add-book form for teacher review before saving.

Remaining teacher concerns:

- Book edit/delete, draft/archive status controls, and full post-creation quiz editing are not complete in the teacher app.
- Some dirty-form and accidental-send guards from `point-of-errors.md` remain useful.
- Video review should handle expired/invalid signed URL initialization failures more explicitly.

## Admin App Status

Implemented screens:

- Login
- Reset password
- Dashboard
- Users
- Sections
- Books
- Reading History
- Activity views

Current behavior:

- Login uses Supabase role validation for `admin`.
- Admin account loads from `profiles`.
- Admin profile picture upload stores avatars in private Supabase Storage and displays them through signed URLs.
- Users load from `profiles` with section labels where available.
- Users can be filtered by search text, role, status, and section.
- Admin account creation calls `admin-create-user`.
- Student accounts require one grade/section assignment.
- Teacher accounts can select multiple assigned sections.
- Account disabling updates `profiles.status = disabled`; role-aware login blocks disabled accounts.
- Student/teacher deletion calls `admin-delete-user`.
- Section creation/deletion, book deletion, and reading-history deletion are Supabase-backed.
- Dashboard counts derive from the real loaded user list.
- Activity data loads from `activity_logs` and is reused by dashboard/activity views.
- Admin create/disable/delete and management actions write best-effort audit rows.

Remaining admin concerns:

- Delete-oriented destructive actions now require typed `DELETE` confirmation in the admin UI.
- Create-account and add-section forms still need more complete inline validation/normalization.
- Some management pagination/search state behavior from `point-of-errors.md` remains worth addressing.

## Backend Status

Backend source files exist under `supabase/`:

- `supabase/migrations/202607170001_initial_schema.sql`
- `supabase/migrations/202607170002_rls_policies.sql`
- `supabase/migrations/202607170003_storage.sql`
- `supabase/migrations/202607170004_student_skill_levels.sql`
- `supabase/migrations/202607250001_transcript_suggested_remarks.sql`
- `supabase/seed.sql`
- `supabase/README.md`
- `supabase/docs/phase2_backend_notes.md`
- `supabase/functions/process-reading-submission/index.ts`
- `supabase/functions/generate-book-content/index.ts`
- `supabase/functions/admin-create-user/index.ts`
- `supabase/functions/admin-delete-user/index.ts`

The migrations define:

- profiles and role/status fields,
- student and teacher profile extensions,
- schools and sections,
- teacher-section assignments,
- safety agreement versioning,
- books and quiz questions,
- reading submissions,
- transcript results,
- suggested reading-remark columns,
- quiz answers,
- teacher feedback,
- student messages,
- badges and student badge awards,
- activity logs,
- private Storage buckets,
- numeric reading, vocabulary, word master, and comprehension levels,
- RLS helper functions and policies for student, teacher, and admin boundaries.

The project owner reported that the hosted backend has been manually updated for the core flows already live-validated. This workspace still does not show local Supabase CLI execution history, so hosted deployment state should be confirmed in the Supabase dashboard before final presentation.

Required hosted secrets:

- `GEMINI_API_KEY`
- optional `GEMINI_MODEL`
- optional `READBLOOM_AI_REMARK_REVIEW_ENABLED`
- optional Gemini file polling tuning values
- `SUPABASE_SERVICE_ROLE_KEY` for privileged admin Edge Functions

The service-role key must remain only in Supabase Edge Function secrets and must never be added to Flutter source.

## Remaining Work Before Marking Done

The project is MVP/thesis-ready once the core live demo flows below pass with real hosted Supabase data:

- Confirm one real admin account, teacher account, and student account.
- Confirm each role can log in only to its correct app.
- Confirm wrong-role login attempts show the `Cannot login` popup and do not enter dashboards.
- Confirm disabled accounts cannot enter any app.
- Confirm student safety agreement appears only once after acceptance.
- Confirm profile picture upload works for all three roles and persists after logout/login.
- Confirm admin can create student and teacher accounts with correct section assignment.
- Confirm admin can add/delete sections, delete books, delete reading histories, and delete disposable student/teacher accounts.
- Confirm teacher can create a book with multiple quiz questions.
- Confirm teacher-created books appear only for matching student grade/section.
- Confirm student can record, preview, start over, upload, and submit a reading.
- Confirm uploaded videos are stored privately under `reading-videos`.
- Confirm `reading_submissions` moves through `uploaded`, `processed`, and `submitted`.
- Confirm Gemini transcription stores transcript/alignment/suggested remarks in `transcript_results`.
- Confirm quiz answer rows are created after final submission.
- Confirm teacher can open a submitted reading, view transcript/passage/quiz score/video, mark remarks, and send feedback.
- Confirm feedback appears in the student's Messages page with remark counts and highlights.
- Confirm teacher badge awards and skill-level updates reflect on student dashboard/journey.
- Confirm admin dashboard counts and activity tables reflect real Supabase data.
- Confirm long-running actions show blocking loading dialogs or dedicated progress screens.
- Confirm failed upload, failed transcription, camera/microphone denial, and retry paths show clear user-facing messages.
- Confirm RLS policies prevent students/teachers from reading or mutating data outside their allowed scope.
- Decide and document media retention rules for reading videos/audio.
- Finalize privacy wording for student video/audio recording and Google AI Studio/Gemini processing.
- Confirm production web URLs and Supabase Auth redirect URLs are configured for password recovery.
- Build the student Android APK before real mobile deployment. Build teacher/admin APKs too if they are part of the thesis demo.

## Completion Estimate

- MVP/thesis readiness: approximately 90%, pending final hosted live validation.
- Full production readiness: approximately 85%, pending remaining security, RLS, failure-path, retention, and deployed-environment validation.

## Important Risks

Authentication and authorization:

- Role isolation must be enforced by Supabase RLS and Edge Function checks, not only client-side app routing.
- Authorization should depend on trusted profile rows and policies, not editable user metadata.
- Admin account creation/deletion must remain in Edge Functions using server-side secrets.

Recording and privacy:

- Student video/audio recordings are sensitive.
- Storage buckets must remain private.
- Teachers should access videos only through authorized signed URLs.
- A retention policy for recordings still needs a final decision.

Speech-to-text and accuracy:

- Gemini transcription may be imperfect for children, background noise, accents, and low-quality microphones.
- Alignment and suggested remarks should be treated as teacher-assistive, not final automatic grading.
- Teacher review should preserve raw transcript, normalized transcript, expected passage, alignment, and teacher overrides.

Data consistency:

- Books, quizzes, sections, badges, feedback, and submissions should come from Supabase in production.
- Dummy/demo records should stay isolated to seed/dev fixtures.
- Student submissions should preserve the exact passage/question snapshot used at submission time because books may change later.

Frontend reliability:

- Multi-step reading flows need strong route/exit protection.
- Destructive admin actions need careful confirmation.
- Important failures should use persistent app dialogs when SnackBars are too easy to miss.
