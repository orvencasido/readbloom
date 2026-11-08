# ReadBloom New Feature Implementation Plan

Created: 2026-07-25
Status: Feature 1 has been live-validated by the project owner. Feature 2 and Feature 2B have local implementation passes.

This document plans two proposed features:

1. AI-assisted teacher book creation.
2. Automatic reading remark detection for omission, repetition, self-correction, and possible mispronunciation.

Feature 1 is now working in the teacher app and Supabase Edge Functions. Feature 2 now has a local implementation pass for deterministic suggested reading remarks, backed by transcript-result columns and teacher review prefill. Feature 2B now has a local implementation pass for optional Gemini-reviewed remark suggestions gated by `READBLOOM_AI_REMARK_REVIEW_ENABLED`. This file remains the step-by-step implementation guide for the current ReadBloom codebase.

## Current Codebase Touchpoints

The current system already has the right foundation for both features:

- Teacher book creation already saves books and multiple quiz questions through:
  - `teacher_readbloom/lib/providers/teacher_provider.dart`
  - `teacher_readbloom/lib/repositories/teacher_repository.dart`
  - `teacher_readbloom/lib/screens/dashboard/mobile/books_mobile.dart`
  - `teacher_readbloom/lib/screens/dashboard/web/books_web.dart`
- Student recording upload and transcription already run through:
  - `student_readbloom/lib/providers/student_provider.dart`
  - `student_readbloom/lib/repositories/student_repository.dart`
  - `supabase/functions/process-reading-submission/index.ts`
- Teacher review already reads transcript and alignment data through:
  - `teacher_readbloom/lib/repositories/teacher_repository.dart`
  - `teacher_readbloom/lib/screens/dashboard/mobile/evaluation_detail_mobile.dart`
  - `teacher_readbloom/lib/screens/dashboard/web/evaluation_detail_popup.dart`
- Student messages already understand structured teacher feedback containing remark counts and selected words through:
  - `student_readbloom/lib/models/student_models.dart`
  - `student_readbloom/lib/screens/dashboard/mobile/messages_mobile.dart`
  - `student_readbloom/lib/screens/dashboard/web/messages_web.dart`

The safest implementation approach is to add server-side AI generation and detection first, then make the Flutter UI consume the generated/suggested values. API keys must stay in Supabase Edge Functions, not in Flutter.

## Feature 1: AI-Assisted Book Creation

### Goal

Add an "Auto Generate" action to the teacher book creation flow. The teacher provides a short prompt, grade level, section, and desired quiz count. The app asks an Edge Function to generate:

- book title,
- reading passage,
- 1 to 3 multiple-choice questions,
- choices for each question,
- correct answer for each question.

The generated content should fill the existing book creation form. The teacher must be able to review and edit everything before saving.

### Recommended User Flow

1. Teacher opens Book Management.
2. Teacher opens the Add Book form.
3. Teacher selects grade and section as usual.
4. Teacher clicks `Auto Generate`.
5. A dialog opens with:
   - prompt input,
   - reading level or grade level,
   - quiz count selector from 1 to 3,
   - optional passage length selector.
6. Teacher submits the prompt.
7. App shows a blocking loading dialog while generation is running.
8. Edge Function returns structured generated content.
9. App fills the existing title, passage, and quiz fields.
10. Teacher reviews and edits the content.
11. Teacher saves the book using the existing `addBook` flow.

### Backend Design

Create a new Supabase Edge Function:

```text
supabase/functions/generate-book-content/index.ts
```

Purpose:

- validate the caller is an authenticated active teacher,
- validate the teacher has access to the selected section,
- call the AI provider,
- force the model to return strict JSON,
- validate and sanitize the JSON,
- return generated content to Flutter.

Important rule:

- The Edge Function should not insert the book directly.
- It should only generate draft content.
- The teacher's existing save action should remain responsible for creating the book.

This keeps the teacher in control and avoids saving poor or inappropriate AI output automatically.

### Required Secrets

Add these Supabase secrets:

```bash
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-3.5-flash
```

If a different AI provider is used later, add equivalent secrets such as:

```bash
OPENAI_API_KEY=...
OPENAI_MODEL=...
```

Do not place any AI API key in:

- `teacher_readbloom/lib/config/backend_config.dart`,
- `--dart-define`,
- Flutter source files,
- frontend environment files.

### Edge Function Request Shape

Use a strict request body:

```json
{
  "prompt": "Create a Grade 3 passage about kindness.",
  "gradeLevel": "Grade 3",
  "sectionId": "uuid",
  "quizCount": 3,
  "passageLength": "short"
}
```

Validation rules:

- `prompt` is required and trimmed.
- `prompt` should have a maximum length, for example 1000 characters.
- `gradeLevel` is required.
- `sectionId` is required.
- `quizCount` must be between 1 and 3.
- `passageLength` must be one of `short`, `medium`, or `long`.
- caller must be a teacher.
- caller must be assigned to `sectionId`.

### Edge Function Response Shape

Return only validated JSON:

```json
{
  "title": "The Helpful Classmate",
  "passageText": "Mina saw that her classmate Leo dropped his books...",
  "questions": [
    {
      "questionText": "What did Mina do when Leo dropped his books?",
      "options": [
        "She laughed at him.",
        "She helped him pick them up.",
        "She walked away.",
        "She called the teacher."
      ],
      "correctOptionIndex": 1
    }
  ]
}
```

Validation rules before returning to Flutter:

- `title` must be non-empty.
- `passageText` must be non-empty.
- `questions.length` must be 1 to 3.
- every question must be non-empty.
- every question must have at least 2 choices, preferably 4.
- choices must be non-empty strings.
- `correctOptionIndex` must be inside the choices range.
- remove markdown fences if the AI returns them.
- reject unsafe or malformed output.

### AI Prompt Design

The Edge Function should build the actual AI prompt, not trust the frontend prompt directly.

Recommended system-style instruction:

```text
You generate child-appropriate reading practice content for ReadBloom.
Return only valid JSON. Do not include markdown.
The passage must be suitable for the requested grade level.
The questions must be answerable from the passage.
The choices must be clear and age-appropriate.
Do not include sensitive personal data, violent content, sexual content, profanity, or copyrighted text.
```

Recommended user-style instruction:

```text
Teacher prompt: {prompt}
Grade level: {gradeLevel}
Passage length: {passageLength}
Number of quiz questions: {quizCount}

Return JSON using exactly this schema:
{
  "title": string,
  "passageText": string,
  "questions": [
    {
      "questionText": string,
      "options": string[],
      "correctOptionIndex": number
    }
  ]
}
```

### Flutter Model Additions

Add model classes in:

```text
teacher_readbloom/lib/models/teacher_models.dart
```

Suggested classes:

```dart
class GeneratedBookDraft {
  final String title;
  final String passageText;
  final List<BookQuestionInput> questions;
}

class GenerateBookRequest {
  final String prompt;
  final String gradeLevel;
  final String sectionId;
  final int quizCount;
  final String passageLength;
}
```

Use existing `BookQuestionInput` if it already matches the form input shape. Avoid creating duplicate question models unless the existing class cannot represent generated data.

### Teacher Repository Changes

Update:

```text
teacher_readbloom/lib/repositories/teacher_repository.dart
```

Add to `TeacherRepository`:

```dart
Future<GeneratedBookDraft> generateBookDraft({
  required String prompt,
  required String gradeLevel,
  required String sectionId,
  required int quizCount,
  required String passageLength,
});
```

Mock repository behavior:

- Return deterministic generated content for local fallback.
- Do not call any AI service from the mock implementation.

Supabase repository behavior:

- call `client.functions.invoke('generate-book-content', body: {...})`,
- parse JSON into `GeneratedBookDraft`,
- throw a readable error if generation fails.

### Teacher Provider Changes

Update:

```text
teacher_readbloom/lib/providers/teacher_provider.dart
```

Add state:

```dart
bool _isGeneratingBookDraft = false;
String? _generateBookDraftError;
```

Add getters:

```dart
bool get isGeneratingBookDraft => _isGeneratingBookDraft;
String? get generateBookDraftError => _generateBookDraftError;
```

Add method:

```dart
Future<GeneratedBookDraft?> generateBookDraft({
  required String prompt,
  required String gradeLevel,
  required String sectionId,
  required int quizCount,
  required String passageLength,
});
```

Provider responsibilities:

- trim and validate prompt,
- require grade and section,
- enforce quiz count 1 to 3,
- set loading state,
- call repository,
- expose errors to UI,
- never save generated content automatically.

### Teacher UI Changes

Update both:

```text
teacher_readbloom/lib/screens/dashboard/mobile/books_mobile.dart
teacher_readbloom/lib/screens/dashboard/web/books_web.dart
```

Add an `Auto Generate` button near the Add Book form fields.

Suggested behavior:

1. Button opens an AI generation dialog.
2. Dialog contains:
   - prompt text field,
   - quiz count segmented control or dropdown,
   - passage length dropdown,
   - cancel button,
   - generate button.
3. On generate:
   - show existing reusable loading dialog from `teacher_readbloom/lib/widgets/loading_dialog.dart`,
   - call `TeacherProvider.generateBookDraft(...)`,
   - close loading dialog,
   - if successful, fill form controllers with returned values,
   - if failed, show snackbar/dialog.

Important UI rule:

- Generated content should be visibly editable in the normal form.
- Do not create a separate AI-only save path.

### Security and Cost Controls

Add these protections in the Edge Function:

- require authenticated teacher,
- verify assigned section,
- limit prompt length,
- limit output size,
- use low/medium generation temperature,
- reject invalid JSON,
- log generation activity only after success if desired,
- do not store the raw prompt unless intentionally needed,
- consider rate limiting later if the app is used by many teachers.

### Feature 1 Implementation Order

1. Add Edge Function `generate-book-content`.
2. Add documentation to `supabase/README.md` for required AI secrets.
3. Add Flutter model classes.
4. Add repository interface method.
5. Implement mock repository generation.
6. Implement Supabase repository function invocation.
7. Add provider loading/error method.
8. Add mobile Auto Generate dialog.
9. Add web Auto Generate dialog.
10. Deploy Edge Function to Supabase.
11. Set Supabase secrets.
12. Validate with a teacher account.

## Feature 2: Automatic Reading Remark Detection

### Goal

Automatically suggest reading remarks after speech-to-text processing:

- omission,
- repetition,
- self-correction,
- possible mispronunciation.

The key word is "suggest." The system should not pretend these are perfect clinical or final assessments. The teacher should still be able to review, add, remove, or override suggested marks before sending feedback.

### Reliability Expectations

Expected reliability by category:

- Omission: high enough for useful automation because missing expected words can be detected from text alignment.
- Repetition: medium to high because repeated spoken tokens can be detected from transcript tokens.
- Self-correction: medium because the pattern often looks like wrong word followed by corrected word, but transcription errors can confuse it.
- Mispronunciation: low to medium with normal speech-to-text alone. If the model hears the intended word, the transcript may hide the mispronunciation. Treat this as "possible mispronunciation" or "possible substitution" unless a pronunciation assessment API is added later.

Recommended thesis/MVP wording:

```text
AI-suggested reading remarks
```

Avoid wording such as:

```text
Automatically graded pronunciation errors
```

### Current Technical Foundation

The existing Edge Function:

```text
supabase/functions/process-reading-submission/index.ts
```

already:

- downloads the uploaded recording,
- sends it to Gemini,
- stores `raw_transcript`,
- normalizes expected passage and transcript,
- runs deterministic alignment,
- stores `alignment_json`,
- stores match/missing/extra/substitution counts.

This should be extended rather than replaced.

### Storage Design Options

There are two reasonable storage approaches.

#### Option A: Store Suggested Remarks Inside `alignment_json`

Example:

```json
{
  "tokens": [],
  "summary": {},
  "suggestedRemarks": {
    "omission": {
      "count": 2,
      "indexes": [4, 9],
      "words": ["little", "garden"],
      "confidence": "high"
    },
    "repetition": {
      "count": 1,
      "indexes": [13],
      "words": ["the"],
      "confidence": "medium"
    },
    "selfCorrection": {
      "count": 1,
      "indexes": [21],
      "words": ["runs"],
      "confidence": "medium"
    },
    "mispronunciation": {
      "count": 1,
      "indexes": [27],
      "words": ["beautiful"],
      "confidence": "low"
    }
  }
}
```

Pros:

- no migration required,
- quick to implement,
- keeps all transcript analysis in one JSON payload.

Cons:

- harder to query directly in SQL,
- less clean if remark data grows.

#### Option B: Add Columns to `transcript_results`

Create migration:

```text
supabase/migrations/202607250001_transcript_suggested_remarks.sql
```

Add columns:

```sql
alter table public.transcript_results
add column if not exists suggested_remarks_json jsonb,
add column if not exists suggested_omission_count int not null default 0,
add column if not exists suggested_repetition_count int not null default 0,
add column if not exists suggested_self_correction_count int not null default 0,
add column if not exists suggested_mispronunciation_count int not null default 0;
```

Pros:

- easier to load and display,
- summary counts are queryable,
- cleaner separation between word alignment and reading-remark suggestions.

Cons:

- requires hosted migration,
- needs repository updates.

Recommended approach:

- Use Option B for cleaner production data.
- Also keep per-token details in `suggested_remarks_json`.

### Suggested Remark JSON Shape

Use one consistent JSON shape:

```json
{
  "version": 1,
  "source": "deterministic_alignment",
  "remarks": {
    "omission": {
      "label": "Omission",
      "count": 0,
      "indexes": [],
      "words": [],
      "confidence": "high"
    },
    "repetition": {
      "label": "Repetition",
      "count": 0,
      "indexes": [],
      "words": [],
      "confidence": "medium"
    },
    "selfCorrection": {
      "label": "Self-Correction",
      "count": 0,
      "indexes": [],
      "words": [],
      "confidence": "medium"
    },
    "mispronunciation": {
      "label": "Possible Mispronunciation",
      "count": 0,
      "indexes": [],
      "words": [],
      "confidence": "low"
    }
  }
}
```

The `indexes` should refer to transcript token indexes when highlighting transcript words. For omissions, there may be no spoken transcript token, so either:

- use expected passage token indexes, or
- attach omission to the nearest transcript token position.

Recommended:

- Store both when available:

```json
{
  "transcriptIndexes": [12],
  "expectedIndexes": [14],
  "words": ["garden"]
}
```

This avoids confusion between transcript highlighting and expected-passage highlighting.

### Detection Logic

Implement deterministic detection first. Use AI as an optional second pass only if needed.

#### Omission Detection

Source:

- existing alignment tokens where expected word is present but spoken word is missing.

Rule:

- If alignment class is `missing`, add expected word to omission suggestions.

Data to store:

- expected word,
- expected index,
- nearest transcript index if available,
- confidence `high`.

#### Repetition Detection

Source:

- transcript/spoken tokens and alignment `extra` tokens.

Basic rule:

- If the same spoken word appears consecutively, mark the later duplicate as repetition.

Example:

```text
the the dog ran
```

Mark second `the`.

Expanded rule:

- Detect short repeated phrases of 2 to 4 words.

Example:

```text
the little the little bird
```

Mark the second repeated phrase.

Confidence:

- consecutive duplicate word: high,
- repeated phrase: medium.

#### Self-Correction Detection

Source:

- alignment substitutions and nearby following matches.

Common pattern:

```text
expected: The dog runs fast.
spoken: The dog run runs fast.
```

Possible rule:

- If a substituted or extra word is followed within 1 to 3 spoken tokens by the expected/correct word, mark it as self-correction.

Another pattern:

```text
spoken: She go, goes to school.
```

Possible rule:

- If an incorrect token appears immediately before a correct token for the same expected position or nearby expected position, mark the corrected word and/or incorrect attempt.

Confidence:

- medium by default.
- high only for very obvious repeated-correction patterns.

#### Possible Mispronunciation Detection

With normal speech-to-text, this should be treated carefully.

Possible deterministic rule:

- If alignment marks a substitution and it is not better classified as self-correction, mark the expected word as possible mispronunciation/substitution.

Example:

```text
expected: beautiful
transcript: pitiful
```

This may be:

- mispronunciation,
- wrong word,
- speech-to-text error.

So label it as:

```text
Possible Mispronunciation
```

Confidence:

- low by default.

Future improvement:

- Add a pronunciation assessment API that returns phoneme-level or word-level pronunciation scores.
- Store audio timestamps per word if available.

### Edge Function Changes

Update:

```text
supabase/functions/process-reading-submission/index.ts
```

Add a new function:

```ts
function detectReadingRemarks(alignment: AlignmentResult): SuggestedReadingRemarks {
  // derive omissions, repetitions, self-corrections, and possible mispronunciations
}
```

Required data from alignment:

- expected normalized tokens,
- spoken normalized tokens,
- aligned token pairs,
- classification for each aligned token,
- token indexes.

If current alignment tokens do not include enough index data, update alignment output first to include:

```ts
{
  expectedWord: string | null,
  spokenWord: string | null,
  expectedIndex: number | null,
  spokenIndex: number | null,
  type: 'match' | 'missing' | 'extra' | 'substitution'
}
```

Then detection becomes much easier and safer.

When upserting `transcript_results`, include:

```ts
suggested_remarks_json: suggestedRemarks,
suggested_omission_count: suggestedRemarks.remarks.omission.count,
suggested_repetition_count: suggestedRemarks.remarks.repetition.count,
suggested_self_correction_count: suggestedRemarks.remarks.selfCorrection.count,
suggested_mispronunciation_count: suggestedRemarks.remarks.mispronunciation.count,
```

If using Option A instead, add `suggestedRemarks` under `alignment_json`.

### Optional AI Review Pass

An optional second pass can ask Gemini to classify likely self-corrections and possible mispronunciations using:

- original passage,
- raw transcript,
- deterministic alignment JSON.

However, this should not replace deterministic logic for omissions and repetitions.

Recommended phased approach:

1. Phase 2A: deterministic suggestions only.
2. Phase 2B: optional AI review pass for self-correction and possible mispronunciation.
3. Phase 2C: teacher accepts/edits suggestions.

If using an AI review pass, require strict JSON output and validate it like the book generator.

### Teacher Model Changes

Update:

```text
teacher_readbloom/lib/models/teacher_models.dart
```

Add model classes:

```dart
class SuggestedReadingRemarks {
  final ReadingRemarkSuggestion omission;
  final ReadingRemarkSuggestion repetition;
  final ReadingRemarkSuggestion selfCorrection;
  final ReadingRemarkSuggestion mispronunciation;
}

class ReadingRemarkSuggestion {
  final String label;
  final int count;
  final List<int> transcriptIndexes;
  final List<int> expectedIndexes;
  final List<String> words;
  final String confidence;
}
```

Update the model used for teacher reading submissions/reviews to include:

```dart
final SuggestedReadingRemarks? suggestedRemarks;
```

### Teacher Repository Changes

Update:

```text
teacher_readbloom/lib/repositories/teacher_repository.dart
```

The existing query currently loads:

```text
transcript_results(raw_transcript,alignment_json,overall_accuracy)
```

Update it to load:

```text
transcript_results(
  raw_transcript,
  alignment_json,
  overall_accuracy,
  suggested_remarks_json,
  suggested_omission_count,
  suggested_repetition_count,
  suggested_self_correction_count,
  suggested_mispronunciation_count
)
```

Add parser helpers:

```dart
SuggestedReadingRemarks? _suggestedRemarksFromJson(dynamic raw);
ReadingRemarkSuggestion _remarkSuggestionFromJson(...);
```

Parsing must be defensive:

- tolerate missing JSON,
- tolerate older transcript rows without suggested remarks,
- default counts to zero,
- never crash teacher login if suggested remark parsing fails.

### Teacher UI Changes

Update:

```text
teacher_readbloom/lib/screens/dashboard/mobile/evaluation_detail_mobile.dart
teacher_readbloom/lib/screens/dashboard/web/evaluation_detail_popup.dart
```

Current teacher review already lets teachers manually tag:

- omission,
- repetition,
- self-correction,
- mispronunciation.

Modify the popup so suggested remarks initialize the current selected state.

Recommended behavior:

1. When review opens, load `submission.suggestedRemarks`.
2. Pre-fill the four count boxes.
3. Pre-highlight suggested transcript words.
4. Show a subtle label such as `AI suggestions`.
5. Let the teacher remove or add marks manually.
6. When teacher sends feedback, send the final teacher-reviewed values, not only the raw AI suggestions.

Important:

- Do not lock the teacher into the AI result.
- The teacher's final reviewed tags should still be the source of the student message.

### Student Message Changes

The student app may not need major changes if the teacher feedback message continues using the existing structured `messages.body` format.

Check:

```text
student_readbloom/lib/models/student_models.dart
```

If the teacher sends the final reviewed remarks in the same existing JSON shape, student messages should continue working.

Only update the student app if:

- the remark JSON shape changes,
- new fields like confidence/source need to be displayed,
- omissions need expected-passage highlighting instead of transcript highlighting.

Recommended MVP:

- Do not show confidence/source to students.
- Keep student messages focused on the teacher-reviewed result.

### Migration Plan

Create:

```text
supabase/migrations/202607250001_transcript_suggested_remarks.sql
```

Suggested SQL:

```sql
alter table public.transcript_results
add column if not exists suggested_remarks_json jsonb,
add column if not exists suggested_omission_count int not null default 0,
add column if not exists suggested_repetition_count int not null default 0,
add column if not exists suggested_self_correction_count int not null default 0,
add column if not exists suggested_mispronunciation_count int not null default 0;
```

RLS:

- Existing `transcript_results` RLS should continue to apply.
- No separate policy should be needed if the new columns are on the same table.

Backfill:

- Existing processed rows will have empty suggested remarks.
- Optional: write a one-time admin script or Edge Function mode to recalculate suggestions from existing `alignment_json`.
- MVP can skip backfill and only generate suggestions for new submissions.

### Feature 2 Implementation Order

1. Add migration columns for suggested remarks.
2. Update `process-reading-submission` alignment token output if indexes are missing.
3. Add deterministic `detectReadingRemarks` function.
4. Store suggested remarks in `transcript_results`.
5. Update `supabase/README.md` with the new processing behavior.
6. Update teacher models.
7. Update teacher repository query and parser.
8. Update teacher mobile review popup to pre-fill suggestions.
9. Update teacher web review popup to pre-fill suggestions.
10. Confirm student message JSON remains compatible.
11. Deploy migration and Edge Function.
12. Run a new student submission and verify suggested remarks appear in Supabase.
13. Verify teacher popup displays suggestions and allows edits.
14. Verify student receives the teacher-reviewed final feedback.

## Feature 2B: AI-Assisted Reading Remark Review

### Goal

Improve Feature 2 by adding a second Gemini review pass after transcription and deterministic alignment. Gemini should review the recording context, transcript, expected passage, alignment tokens, and deterministic suggestions, then return stricter AI-assisted remark suggestions for:

- omission,
- repetition,
- self-correction,
- possible mispronunciation.

The teacher must still review and approve the final marks before feedback is sent to the student.

### Recommended Architecture

Keep the current Feature 2 deterministic detector as the baseline. Add an optional AI review pass inside:

```text
supabase/functions/process-reading-submission/index.ts
```

Recommended processing sequence:

1. Download student recording.
2. Ask Gemini to transcribe the recording.
3. Normalize and align transcript against the expected passage.
4. Run deterministic `detectReadingRemarks`.
5. Ask Gemini to review the passage, transcript, alignment, and deterministic suggestions.
6. Validate Gemini's strict JSON response.
7. Merge AI suggestions with deterministic suggestions.
8. Store the merged result in `transcript_results.suggested_remarks_json`.
9. Store summary counts in the existing suggested-count columns.
10. Teacher popup loads the merged suggestions and allows edits.

### Why Keep Deterministic Rules

Do not replace deterministic logic completely. Deterministic rules are more predictable for omissions and simple repetitions. Gemini should improve context-sensitive cases, especially:

- self-correction,
- repeated phrases,
- likely substitutions,
- possible mispronunciation.

Recommended source label:

```json
{
  "source": "deterministic_alignment_with_ai_review"
}
```

### Important Accuracy Limits

Gemini can help classify remarks, but it is not a clinical pronunciation assessment engine.

- If Gemini transcribes the intended word correctly, it may hide a pronunciation error.
- If audio quality is poor, Gemini may mistake background noise for spoken words.
- If the transcript is wrong, AI remark classification may also be wrong.

Use `Possible Mispronunciation`, not `Mispronunciation Detected`, in teacher-facing and student-facing text.

### Edge Function Request To Gemini

The AI review pass should not send private account data. It only needs the learning artifacts:

```json
{
  "expectedPassage": "The original passage text...",
  "rawTranscript": "The student's transcript...",
  "alignment": [
    {
      "expected": "the",
      "spoken": "the",
      "expectedIndex": 0,
      "spokenIndex": 0,
      "status": "match"
    }
  ],
  "deterministicSuggestions": {}
}
```

Do not include:

- student name,
- teacher name,
- email,
- section name unless truly needed,
- profile IDs,
- storage paths.

### Gemini Prompt Design

Recommended instruction:

```text
You review oral reading assessment data for ReadBloom.
Return only valid JSON. Do not include markdown.
Classify only likely reading remarks from the provided passage, transcript, and alignment.
Use the deterministic suggestions as hints, but correct them if the context clearly suggests a better classification.
Do not invent words that do not appear in either the expected passage or transcript.
Use transcriptIndexes for words that can be highlighted in the transcript.
Use expectedIndexes for omitted expected words.
Treat pronunciation as "possible mispronunciation" because transcript-only evidence is uncertain.
When unsure, leave the item out.
```

Recommended payload instruction:

```text
Return JSON using exactly this schema:
{
  "remarks": {
    "omission": {
      "transcriptIndexes": number[],
      "expectedIndexes": number[],
      "words": string[],
      "confidence": "high" | "medium" | "low",
      "reason": string
    },
    "repetition": {
      "transcriptIndexes": number[],
      "expectedIndexes": number[],
      "words": string[],
      "confidence": "high" | "medium" | "low",
      "reason": string
    },
    "selfCorrection": {
      "transcriptIndexes": number[],
      "expectedIndexes": number[],
      "words": string[],
      "confidence": "high" | "medium" | "low",
      "reason": string
    },
    "mispronunciation": {
      "transcriptIndexes": number[],
      "expectedIndexes": number[],
      "words": string[],
      "confidence": "high" | "medium" | "low",
      "reason": string
    }
  }
}
```

### Validation Rules

Before storing AI output:

- Reject non-JSON or malformed output.
- Reject indexes that are outside the transcript/alignment range.
- Remove duplicate indexes.
- Clamp each remark category to a reasonable maximum, for example 50 words.
- Require every `words` entry to match the corresponding transcript or expected token after normalization when possible.
- Allow empty arrays.
- Default invalid confidence values to `low`.
- If AI validation fails, fall back to deterministic suggestions and continue processing.

### Merge Policy

Recommended MVP merge policy:

1. Always keep deterministic omissions.
2. Always keep deterministic exact consecutive repetitions.
3. Allow AI to add or remove self-correction suggestions.
4. Allow AI to add possible mispronunciation suggestions, but keep confidence `low` or `medium`.
5. If AI and deterministic suggestions conflict on the same transcript index, prefer this order:
   - self-correction,
   - repetition,
   - omission,
   - possible mispronunciation.

Reason:

- Self-correction is more specific than a generic substitution.
- Repetition is visible from transcript tokens.
- Omission may not map cleanly to transcript indexes.
- Mispronunciation is the least certain without phoneme-level scoring.

### Storage Shape

Reuse existing Feature 2 columns:

```text
transcript_results.suggested_remarks_json
transcript_results.suggested_omission_count
transcript_results.suggested_repetition_count
transcript_results.suggested_self_correction_count
transcript_results.suggested_mispronunciation_count
```

Recommended JSON:

```json
{
  "version": 2,
  "source": "deterministic_alignment_with_ai_review",
  "remarks": {
    "omission": {
      "label": "Omission",
      "count": 1,
      "transcriptIndexes": [],
      "expectedIndexes": [4],
      "words": ["garden"],
      "confidence": "high",
      "reason": "Expected word was absent from the spoken transcript."
    }
  },
  "review": {
    "aiProvider": "google_ai_studio",
    "aiModel": "gemini-3.5-flash",
    "deterministicFallbackUsed": false
  }
}
```

No new migration is required if Feature 2 columns already exist.

### Configuration

Use existing secrets:

```bash
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-3.5-flash
```

Optional new flags:

```bash
READBLOOM_AI_REMARK_REVIEW_ENABLED=true
READBLOOM_AI_REMARK_MAX_ALIGNMENT_TOKENS=800
```

If the enabled flag is missing or false, the Edge Function should use deterministic Feature 2 only.

### Cost and Latency Controls

- Do not run AI remark review if the transcript is empty.
- Skip AI review for very long alignments above `READBLOOM_AI_REMARK_MAX_ALIGNMENT_TOKENS`.
- Use compact alignment JSON in the AI prompt.
- Keep temperature low, for example `0` or `0.1`.
- Ask for JSON only.
- Fall back gracefully if Gemini times out or returns invalid JSON.

### Flutter Impact

The teacher app can keep the existing Feature 2 UI because it already reads `suggested_remarks_json`.

Optional UI improvement:

- Show the source label as `AI-reviewed suggestions` when `source = deterministic_alignment_with_ai_review`.
- Keep the same teacher override behavior.
- Do not expose confidence or AI reasoning to students in the MVP.

The student app should not need changes because students still receive the final teacher-reviewed feedback message.

The admin app should not need changes unless later dashboards expose AI review usage/cost.

### Feature 2B Implementation Order

1. Add `READBLOOM_AI_REMARK_REVIEW_ENABLED` handling in `process-reading-submission`.
2. Add compact alignment serialization for Gemini review.
3. Add `reviewRemarksWithGemini` function.
4. Add strict AI JSON parser and validator.
5. Add merge function for deterministic plus AI-reviewed suggestions.
6. Store version 2 suggested remarks JSON.
7. Keep deterministic fallback on all AI failures.
8. Update teacher repository parser only if version 2 shape requires it.
9. Optionally update teacher popup source label.
10. Deploy updated `process-reading-submission`.
11. Set `READBLOOM_AI_REMARK_REVIEW_ENABLED=true`.
12. Validate with new student submissions.

## Combined Implementation Strategy

Do not build both features in one large change. They touch different user workflows and should be implemented separately.

Recommended sequence:

1. Implement AI-assisted book generation first.
2. Verify teacher can generate, edit, save, and students can read generated books.
3. Implement deterministic reading remark suggestions.
4. Verify teacher review suggestions on newly processed student submissions.
5. Only then consider optional AI-based remark review.

Reason:

- AI book generation is lower risk because it only pre-fills teacher form fields.
- Automatic reading remark detection affects assessment and feedback, so it needs more careful validation.

## Deployment Checklist

For AI book generation:

- deploy `generate-book-content`,
- set AI provider secrets,
- validate with teacher account,
- confirm no AI key appears in Flutter code.

For automatic reading remark detection:

- apply transcript suggested remarks migration,
- deploy updated `process-reading-submission`,
- submit a new student recording,
- confirm `transcript_results` stores suggested remarks,
- confirm teacher popup shows suggestions,
- confirm teacher-reviewed feedback reaches student messages.

## Product and Thesis Notes

Use careful wording in the UI and documentation:

- Say `AI suggestions`, `Suggested remarks`, or `Possible mispronunciation`.
- Avoid saying the system perfectly detects pronunciation.
- Keep teacher review as the final step before feedback is sent.

This makes the feature technically honest and better aligned with a thesis defense: the system assists the teacher using speech-to-text and alignment, while the teacher remains responsible for final evaluation.

## Future Enhancements

After the MVP works:

- Add AI-generated passage difficulty controls.
- Add vocabulary targets for generated passages.
- Add Filipino/local context content controls if needed.
- Add age/grade readability checks.
- Add teacher regeneration options for only title, passage, or quiz.
- Add backfill processing for old transcript results.
- Add audio timestamps if the transcription provider supports them.
- Add pronunciation-assessment provider support for stronger mispronunciation detection.
- Add rate limiting and usage analytics for AI generation.
