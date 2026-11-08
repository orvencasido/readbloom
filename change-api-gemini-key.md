# How to Change / Update Your Gemini API Key in ReadBloom

This guide explains how to update the Google Gemini API Key used by ReadBloom's Supabase Edge Functions for:
1. **AI-Assisted Book & Quiz Draft Generation** (`generate-book-content`)
2. **Student Speech-to-Text Transcription & Reading Remarks** (`process-reading-submission`)

---

## Step 1: Get a New Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Sign in with your Google account.
3. Click **Create API key** (or choose an existing project).
4. Copy the generated API key (it starts with `AIza...`).

---

## Step 2: Update the Key in Supabase

You can update the secret using either the **Supabase Dashboard (Easiest)** or the **Supabase CLI**.

### Method A: Via Supabase Dashboard (Recommended)

1. Open the [Supabase Dashboard](https://supabase.com/dashboard).
2. Select your ReadBloom project (`msicdkvxjocwhabmybem`).
3. In the left sidebar, click the **Settings** gear icon (⚙️) at the bottom.
4. Navigate to **Edge Functions** (under *Configuration* or *Settings*).
5. In the **Secrets** section:
   - Look for `GEMINI_API_KEY`.
   - If it exists, click **Edit** (or the pencil/kebab menu icon), paste your new key, and click **Save**.
   - If it does not exist yet, click **Add new secret**, set the name to `GEMINI_API_KEY`, paste the value, and click **Add / Save**.

> **Note:**
> Supabase Edge Functions pick up new secrets immediately. You do **not** need to redeploy the Edge Functions or recompile the Flutter apps.

---

### Method B: Via Supabase CLI (Terminal)

If you have the Supabase CLI installed on your machine:

1. Log in to your Supabase account:
   ```bash
   npx supabase login
   ```
2. Link your local repository to your remote project:
   ```bash
   npx supabase link --project-ref msicdkvxjocwhabmybem
   ```
3. Update the secret:
   ```bash
   npx supabase secrets set GEMINI_API_KEY="AIzaSyYourNewGeminiApiKeyHere..."
   ```

---

## Optional: Gemini Configuration Secrets

You can also configure these optional secrets in the same Supabase Secrets section if needed:

| Secret Name | Default Value | Description |
| :--- | :--- | :--- |
| `GEMINI_MODEL` | `gemini-3.5-flash` | The Gemini model used for transcription and book generation. |
| `READBLOOM_AI_REMARK_REVIEW_ENABLED` | `false` | Set to `true` to enable an optional second-pass AI review of student reading remarks. |
| `GEMINI_FILE_ACTIVE_MAX_ATTEMPTS` | `20` | Max polling attempts when uploading larger media files to Gemini File API. |
| `GEMINI_FILE_ACTIVE_POLL_DELAY_MS` | `1500` | Delay (in ms) between polling attempts for Gemini File API processing. |

Example command to set a custom model:
```bash
npx supabase secrets set GEMINI_MODEL="gemini-2.5-flash"
```

---

## Step 3: Verify the New Key Works

### 1. Test Book Generation (Teacher App)
1. Log in to `teacher_readbloom` as a teacher.
2. Go to **Books** $\rightarrow$ **Add Book**.
3. Select a Grade and Section.
4. Click **Auto Generate**.
5. Enter a short prompt (e.g., *"A story about a brave little puppy"*), select quiz count, and click **Generate**.
6. If the title, passage, and quiz questions load properly into the form, your Gemini API key is working!

### 2. Test Reading Transcription (Student App)
1. Log in to `student_readbloom` as a student.
2. Complete a reading recording and submit it.
3. Check that the submission completes processing and that a transcript appears in the teacher's evaluation view.

---

## Important Security Checklist
- [x] **Never commit API keys to Git**: Do not put your Gemini API key inside `.dart` files or public repositories.
- [x] **Flutter apps remain unchanged**: The Flutter apps do not store the Gemini key, so you do not need to rebuild or republish the mobile/web apps when changing the API key.
