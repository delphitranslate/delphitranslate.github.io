# In-Place AI Translation Program

Last changed: August 7, 2026

Status: Retired and superseded by the provider-only workflow on August 7, 2026

> Historical engineering record only. The Codex/Claude command-line product
> path described below has been removed. Current releases use only Google Cloud
> Translation or DeepL through the Studio's built-in provider client.

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

- Designer-authored Translate Automatically, Cancel Translation, Prompt, and
  Reload controls.
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
- The Studio now launches a separately installed Codex CLI or Claude Code
  command. The developer installs and signs in to that command using the
  vendor's supported authentication flow.
- The normal path is one button: Translate Automatically. The Studio supplies
  the contract through standard input, monitors the child process, verifies
  protected fields, adopts safe AI Draft changes, saves, and validates.
- Prompt and Reload remain recovery controls. They are not required during a
  successful automatic run.
- The Studio stores the engine, executable path, and model selection. It does
  not store the agent's authentication token.
- The target application never receives agent credentials, provider keys, or
  runtime Internet behavior.

## Maximized Professional UI Revision

The Studio starts maximized. Every workflow card is designer-authored and
client-aligned, resizable lists and memos are anchored to the appropriate page
edges, and the status card remains visible at the bottom. The Translate page
uses built-in source/target language lists and automatic locale defaults.
Engine Settings combines the primary Codex/Claude command configuration with
the optional Google/DeepL provider configuration. A visual audit confirmed
that all seven pages fit at 1600x900 without bottom clipping.
