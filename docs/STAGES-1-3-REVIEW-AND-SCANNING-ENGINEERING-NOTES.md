# Stages 1-3: Review, Terminology, and Scanning

Last changed: 2026-08-11

These notes record the implemented behavior for later guide updates. They do not replace the currently published guides.

## Stage 1 - Localization Review Center clarity

- Layout proposals now select the first result automatically and immediately show its details.
- Decision choices explain their effects. A saved decision is stored in `layout-proposal.json` with its source checksum.
- During Stages 1-3, layout decisions are advisory. They do not edit a Delphi form and do not alter the current runtime display.
- The visual HTML review uses an expandable section for complete source text, translated text, ownership, provenance, and the recommended action.
- An empty project glossary is explicitly explained as normal; built-in UI terminology remains active.

## Stage 2 - terminology provenance and project glossary suggestions

- The new **Terminology Suggestions** tab identifies each candidate's provenance: project glossary, approved UI terminology, translation memory/catalog suggestion, provider, imported text, or human work.
- Provider results are never promoted automatically to authoritative project terminology.
- **Approve Selected** is an explicit developer decision.
- **Approve High-confidence All** accepts only terms already verified by a person, approved terminology, or a reviewed/approved catalog state.
- Conflicting translations for the same source text are marked low confidence and cannot be bulk-approved.
- Approved terms are saved to the project glossary, which remains authoritative over built-in terminology and provider output.

## Stage 3 - scan coverage and ownership

- Designer text continues to cover FMX/VCL captions, text, headings, menus, tabs, check/radio controls, prompts/hints, memo lines, and list items.
- Pascal scanning now additionally detects common dialog text, list `Add`/`AddObject` literals, `Title` and `Description` assignments, owner-drawn `FillText`/`TextOut` literals, `Format` templates, and literal fragments in concatenated UI assignments.
- Runtime and resourcestring discoveries are classified as requiring explicit runtime translation wiring until confirmed. Designer text is classified as automatic on managed forms.
- Scan and review reporting distinguishes designer automatic, runtime wired, runtime not wired, application/data, suspicious, and excluded entries.
- Suspicious source detection covers long repeated-character runs, unusually long unbroken tokens, exposed Delphi-style control names, test/placeholder text, and common setup placeholders.
- Suspicious entries are withheld from automatic provider translation and runtime-pack export. Validation and the Review Center identify the reason for developer review.
- Catalog schema version 6 persists ownership and suspicious-source metadata.

## Verification completed

- Foundation scanner/catalog/runtime/validation/export smoke tests: passed on Win32 and Win64.
- FMX Studio form creation and streaming: passed.
- Studio builds: Win32/Win64, Debug/Release passed.
- Complete Phase 10 release validation, including package, VCL/FMX runtime, launch, and Studio self-localization checks: passed.

No target application source, form, DPR, or DPROJ file was modified by this work.
