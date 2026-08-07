# Delphi App Translation Studio — Numbered Phase Plan

Last changed: August 6, 2026

## Purpose

This document is the authoritative numbered implementation plan for Delphi App
Translation Studio. A phase is marked complete only after its implementation is
validated and committed. Engineering details and discoveries remain in
`Engineering Notes.md`.

Current status: Phases 1 through 20 are complete. The next approved
implementation tranche will begin with Phase 21.

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

The following work begins after Phase 20 and will receive phase numbers when its
scope is approved:

- Google Cloud Translation and DeepL provider connections.
- Translation batching, retry, cancellation, character counts, and cost review.
- Translation-memory and terminology features.
- Richer reviewer and approval workflow.
- Source-code diagnostic and resourcestring integration improvements.
- Layout overflow and localization quality checks.
- Full Engineering Guide, User Guide, help project, and release packaging.
