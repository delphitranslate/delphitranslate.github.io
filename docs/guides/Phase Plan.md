# Delphi App Translation Studio — Numbered Phase Plan

Last changed: August 7, 2026

## Purpose

This document is the authoritative numbered implementation plan for Delphi App
Translation Studio. A phase is marked complete only after its implementation is
validated and committed. Engineering details and discoveries remain in
`Engineering Notes.md`.

Current status: Phases 1 through 30 record the completed implementation
foundation. Professional release work continues under the approved
**API-Free End-to-End Translation Workflow** stages documented in
`API-Free Workflow Plan.md`. Completion of the historical phases does not by
itself constitute a professional 1.0 release.

## Completed Foundation

### Phase 1 — Project Structure and Repository

Status: Complete

Create the required source, build, documentation, export, sample, image, help,
distribution, and tool folders. Establish local Git and the public GitHub
repository.

### Phase 2 — Designer-Authored FMX Studio Shell

Status: Complete

Create the Windows FMX Studio application and its orange-and-blue,
designer-editable workflow interface without runtime-created controls.

### Phase 3 — Delphi Project Detection

Status: Complete

Open `.dproj` and `.dpr` projects, identify VCL or FMX, inventory forms and
source units, and recognize Win32 and Win64 targets.

### Phase 4 — VCL Form Scanning

Status: Complete

Read text DFM resources and extract designated VCL captions, hints, prompts,
items, and memo content without loading or modifying the target application.

### Phase 5 — FMX Form Scanning

Status: Complete

Read text FMX resources and extract designated FireMonkey text properties using
the same stable-key model.

### Phase 6 — Delphi Resourcestring Scanning

Status: Complete

Discover Delphi `resourcestring` declarations with stable unit-and-symbol keys
and source locations.

### Phase 7 — Incremental Catalog Merge

Status: Complete

Preserve unchanged translations, add new entries, flag changed source text for
review, and retain removed entries as obsolete.

### Phase 8 — Development Catalog Editing and Persistence

Status: Complete

Create, open, edit, and save target-language development catalogs with language
and locale metadata.

### Phase 9 — Catalog Validation

Status: Complete

Validate identity, required metadata, translations, placeholders, accelerator
keys, source changes, duplicates, and locale settings.

### Phase 10 — Offline Runtime-Pack Export

Status: Complete

Export compact UTF-8 JSON language packs under
`Localization\Languages` without provider credentials or development history.

### Phase 11 — Framework-Neutral Runtime

Status: Complete

Load and discover offline language packs, remember the selected language, expose
fallback translation, and build pack-specific `TFormatSettings`.

### Phase 12 — VCL and FMX Runtime Application

Status: Complete

Apply stable-key translations to existing designer-created VCL or FMX forms,
components, menus, item collections, and memo lines.

### Phase 13 — Integration Planning and Review Packages

Status: Complete

Detect a designated language menu and generate a review package containing the
appropriate runtime units, target integration unit, language packs, and language
manifest without changing target source.

## Current Integration Tranche

### Phase 14 — Transactional Integration Change Sets

Status: Complete

Model every proposed target change in memory, show the affected files and
descriptions, and separate preview from application.

### Phase 15 — Designer-Persisted VCL Language Menu

Status: Complete

Insert or update native-language `TMenuItem` children beneath a designated VCL
menu in the text DFM while preserving designer editability and existing menu
content.

### Phase 16 — Designer-Persisted FMX Language Menu

Status: Complete

Insert or update native-language `TMenuItem` children beneath a designated FMX
menu in the text FMX with the same preservation and idempotency rules.

### Phase 17 — Startup and Project Wiring

Status: Complete

Add the generated integration unit and framework runtime to the target project,
initialize translation before form creation, and connect persisted language menu
items to a form event handler.

### Phase 18 — Studio Self-Localization

Status: Complete

Integrate the offline runtime into the Studio itself, add a designer-authored
Language menu, and allow the Studio project to produce and consume its own
language packs.

### Phase 19 — Backup, Rollback, and Idempotency Safeguards

Status: Complete

Check writable/source-control state, create a verified pre-change backup, apply
files atomically, roll back a failed operation, record a manifest, and ensure
repeated integration updates rather than duplicates.

### Phase 20 — End-to-End Validation and Documentation

Status: Complete

Exercise integration against isolated VCL and FMX fixtures under Win32 and
Win64, verify self-localization startup behavior, add repeatable smoke tests, and
record the implemented workflow in the engineering notes.

## Later Product Work

### Phase 21 — Runtime Deployment and Writable Preferences

Status: Complete

Resolve development and deployed language-pack locations, keep user preferences
in a writable per-user location, and package language files for application
deployment.

### Phase 22 — Provider Settings Page

Status: Complete

Add a designer-authored Settings page for DeepL and Google, masked credentials,
secure persistence choice, session-only use, connection testing, replacement,
and removal.

### Phase 23 — Windows Credential Security

Status: Complete

Store remembered provider secrets as Windows Generic Credentials, keep
session-only keys only in memory, redact diagnostics, and ensure secrets never
enter projects, catalogs, logs, exports, or backups.

### Phase 24 — DeepL and Google Translation Clients

Status: Complete

Implement official HTTPS APIs, provider-specific authentication, batching,
timeouts, retry, cancellation, response validation, and actionable errors.

### Phase 25 — Confirmed Bulk Translation

Status: Complete

Count entries and characters, preserve existing translations, obtain explicit
confirmation, translate eligible entries, and mark results as machine
translated.

### Phase 26 — Review and Multi-Language Workflow

Status: Complete

Improve language inventory and review filters for untranslated,
machine-translated, edited, reviewed, approved, changed, excluded, and obsolete
entries.

### Phase 27 — Translation Reuse and Quality Checks

Status: Complete

Reuse exact reviewed translations where context permits and expand placeholder,
accelerator, formatting, locale, and likely-overflow diagnostics.

### Phase 28 — Provider and Integration Hardening

Status: Complete

Exercise provider transports with deterministic fixtures, harden error handling,
complete deployment tooling, and expand real-project integration diagnostics.

### Phase 29 — Release Help and Packaging

Status: Complete

Prepare Help Doc Creator-compatible help sources, sample provider configuration,
release checklists, and clean source-distribution content without credentials.

### Phase 30 — Complete Guides and Release Validation

Status: Complete

Create the full User Guide and Engineering Guide as editable Word documents with
real TOCs and companion PDFs, verify pagination visually, and complete the final
Win32/Win64 build and smoke-test matrices.

## Approved Professional Validation Program

Status: Stages 0 through 10 complete

On August 7, 2026, the project direction was revised after comparing the Studio
with Poker Galaxy's offline FMX localization. The review separated translation
management from translation creation and established that provider APIs are
optional inputs, not requirements of the product.

The approved post-foundation stages are:

0. Baseline and governance.
1. Honest runtime-coverage and `resourcestring` contract.
2. API-free development JSON and CSV interchange.
3. Argument-aware Delphi placeholder validation.
4. Developer-accepted translation suggestions.
5. Exact integration review.
6. Optional provider positioning.
7. Real FMX pilot.
8. Real VCL pilot.
9. Usability and linguistic review.
10. Documentation and release alignment.

The authoritative scope, gates, safeguards, pilot-selection rules, deferred
work, and release standard are maintained in
`API-Free Workflow Plan.md`.

## In-Place AI Translation Program

Status: Groups 1 through 5 complete

The approved primary workflow now uses Codex or Claude to modify the saved
development JSON directly in place. The Studio creates a recovery snapshot,
terminology profile, and exact agent contract; locks its own catalog editor;
detects stable external changes; verifies every protected field; and adopts
only permitted translation data. Google/DeepL and CSV remain alternatives.

The five controlled groups are:

1. Schema version 3 translation provenance and corrected product definition.
2. Safe AI Translation Mode, file fingerprints, and conflict protection.
3. Agent instructions, project terminology profile, and protected reload.
4. Exception-focused QA and resumable large-catalog behavior.
5. VCL/FMX/self pilots, documentation, packaging, Git, and release validation.

The authoritative record is `In-Place AI Translation Plan.md`.

Release proof completed on August 7, 2026: direct-edit Codex-style VCL and FMX
pilots passed under Win32 and Win64; all four Studio configurations built,
streamed, launched, and self-localized successfully.

Stages 5 through 10 were completed on August 7, 2026. Integration now provides
a complete line-numbered original/proposed diff, records every viewed file,
and requires an explicit final review confirmation before Apply. Provider
translation is separately labeled optional.

The project-owned, compilable FMX and VCL reference applications completed the
API-free workflow under Win32 and Win64: scan, deterministic Italian CSV/JSON
interchange, explicit review/approval, validation, pack export, integration,
build, deployment, preference persistence, and required Italian launch title.
Representative forms were visually reviewed for clipping, overlap, menu
translation, and untranslated designated properties.

The FMX pilot identified an important lifecycle boundary: translating the
first form from the DPR immediately after `Application.CreateForm` could fault
after FMX streaming. Integration now persists a form `OnCreate` handler in the
FMX resource, preserves an existing handler when present, and calls
`ApplyTranslation(Self)` from the corresponding Pascal method. VCL retains its
DPR startup application.

Linguistic readiness is now explicit. Imported work can be marked Reviewed,
and only Reviewed work can be Approved. Structural validity, linguistic
status, automatic form-property coverage, and confirmed manual
`resourcestring` wiring are displayed independently. Help, release records,
Word guides, PDFs, and the source distribution are aligned to the proven
offline-first behavior.

## Automatic Agent and Maximized UI Completion

The final user-workflow correction replaces prompt handoff as the normal path
with direct execution of an installed, signed-in Codex CLI or Claude Code
agent. Translate Automatically now creates the recovery boundary, launches the
agent, monitors completion, safely adopts in-place translations, auto-saves,
and validates. Engine Settings provides list-based engine/model selection,
detection, browsing, and installation checking; provider APIs remain optional.

The FMX form now starts maximized and all seven designer-authored workflow
pages use the available desktop area with client alignment and responsive
anchors. Visual page-fit review and all Win32/Win64 Debug/Release builds,
runtime suites, launch tests, and self-localization tests passed on August 7,
2026.
