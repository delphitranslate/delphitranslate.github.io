# In-Place AI Translation Program

Last changed: August 7, 2026

Status: Groups 1 through 5 complete

## Product Direction

The primary translation workflow is:

**Scan → begin AI mode → Codex or Claude edits the development catalog in
place → protected reload → focused validation → export → integration → offline
runtime.**

There is no translation-file export/import round trip in this workflow. Google
and DeepL are direct-provider alternatives. CSV/JSON interchange and manual
editing remain specialist and fallback paths.

## Group 1 — Catalog Contract

- Development schema version 3.
- Translation origin recorded separately from linguistic status.
- Codex, Claude, Google, DeepL, human, imported, and suggestion origins.
- AI Draft status does not imply human review or approval.
- Origin, confidence, and review notes round-trip through JSON.
- Older catalogs migrate in memory without losing existing work.

## Group 2 — Safe In-Place Sessions

- Designer-authored Begin AI Mode, Copy Prompt, and Reload AI Work controls.
- Exact pre-session recovery snapshot.
- Studio editing and saving locked during the external session.
- SHA-256 file fingerprint recorded at load/save/start.
- Normal saves stop when the disk catalog changed externally.
- Designer-owned timer requires a stable external hash before enabling reload.
- Cancel / Restore recovers the exact pre-session catalog.

## Group 3 — Context and Agent Instructions

- Project-local `translation-profile.json`.
- Application, domain, audience, tone, formality, protected-term, terminology,
  and additional-instruction fields.
- Generated instruction file references the catalog and profile in place.
- Contract limits writable fields and protects keys, source, checksum, context,
  locale, runtime metadata, and entry order.
- Instructions require placeholder preservation, context-aware terminology,
  a second linguistic QA pass, valid JSON checkpoints, and a final count report.

## Group 4 — QA and Large Projects

- Protected catalog and entry fields compared before adoption.
- Only Needs Translation, Source Changed, Error, and existing AI Draft entries
  are eligible. Machine-translated, Imported, Edited, Reviewed, Approved,
  Excluded, and Obsolete entries are protected.
- Accepted changes are normalized to AI Draft.
- Agent origin, confidence, and review notes are preserved.
- Metadata-only AI confirmation is retained when an existing translation is
  still correct after a source change.
- Validation focuses on structural failures, low confidence, explicit review
  notes, inconsistent repeated terminology, accelerators, placeholders, source
  changes, and runtime wiring.
- A valid AI draft is not itself treated as an exception.
- Large catalogs can be saved as valid JSON checkpoints and resumed in the same
  catalog; only unresolved or source-changed work is eligible.

## Group 5 — Release Proof

The release gate requires:

1. Schema/provenance round-trip and legacy migration.
2. Valid in-place AI change adoption.
3. Protected-field mutation rejection.
4. Recovery snapshot/profile/instruction creation.
5. Direct FMX form streaming with designer-owned controls and timer.
6. Win32 and Win64 foundation/runtime/integration pilots.
7. Win32/Win64 Debug and Release Studio builds.
8. Normal and Italian self-localized launch checks.
9. Updated User Guide, Engineering Guide, Help, release notes, PDFs, and source
   distribution.
10. Scoped Git commit and push to every configured repository.

The complete gate passed on August 7, 2026. The deterministic direct-edit
pilots passed for real VCL and FMX samples under Win32 and Win64. The Studio
built with zero warnings and errors in Win32/Win64 Debug and Release, streamed
its FMX form directly in both architectures, launched in all four
configurations, and self-localized to Italian in all four configurations.

## Deliberate Boundaries

- The Studio does not embed or impersonate Codex or Claude.
- A developer gives the copied prompt to an already available workspace agent.
- Launching a locally installed Codex CLI or Claude Code command can be added
  later as an optional adapter after command/authentication behavior is agreed.
- The target application never receives agent credentials, provider keys, or
  runtime Internet behavior.
