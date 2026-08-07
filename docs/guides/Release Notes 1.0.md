# Delphi App Translation Studio 1.0 Release Notes

Last changed: August 7, 2026

## Release Summary

Version 1.0 delivers a Windows Win32/Win64, offline-first localization workflow
for Delphi VCL and FireMonkey applications. The Studio scans designer text and
Pascal `resourcestring` declarations, maintains development JSON catalogs,
supports automatic in-place Codex/Claude translation, safe UTF-8 CSV
interchange, validates Delphi formatting contracts,
exports compact runtime packs, and integrates an offline runtime plus
designer-persisted language menu.

Codex or Claude can edit the development catalog directly in the project
workspace without a translation-provider key. DeepL and Google Cloud
Translation remain alternative Studio-only inputs. Target applications do not
contain API keys and do not require Internet access.

## Professional Workflow

- Read-only VCL/FMX project detection and text-resource scanning.
- Stable catalog keys and source-checksum incremental merge.
- Schema version 3 provenance separate from linguistic status.
- Designer-authored AI Translation Mode with generated instructions and
  terminology profile.
- Pre-session recovery snapshot, local-edit lock, stable file-change detection,
  protected-field comparison, and safe reload.
- Checksum conflict prevention that stops stale Studio data from overwriting
  external work.
- Exception-focused QA for low confidence, AI review notes, inconsistent
  repeated terminology, placeholders, accelerators, and runtime wiring.
- API-free development JSON and UTF-8 CSV export/import.
- Staged import with duplicate, unknown-key, stale-source, and protected-work
  reporting.
- Imported, Edited, Machine translated, Reviewed, and Approved linguistic
  states with explicit review progression.
- Context-ranked exact-source suggestions that require explicit acceptance and
  never inherit approval.
- Delphi argument-aware placeholder validation, including valid indexed
  reordering.
- Separate structural, linguistic, automatic-runtime, and manual
  `resourcestring` wiring readiness.
- Exact line-numbered original/proposed integration review for every file.
- Mandatory view-all and final-confirmation gates before transactional Apply.
- Verified backup, atomic writes, rollback, manifest, and Restore.
- Designer-persisted VCL and FMX language menu items.
- Offline JSON pack discovery and per-user language preference.

## FMX Lifecycle

FMX target integration applies translations from a designer-persisted form
`OnCreate` handler after form streaming. Existing root handlers are preserved.
VCL target integration retains its DPR startup application path.

## Validation

The controlled VCL and FMX reference applications completed the in-place AI
workflow with both Win32 and Win64 compilers: scan, deterministic Italian
Codex/Claude-style direct catalog modification, protected-field validation,
translation provenance, validation, runtime export,
integration, build, deployment, and offline launch with a required Italian
title. Representative translated forms were visually reviewed for clipping,
overlap, and untranslated designated properties.

## Scope

Supported targets are Delphi VCL and FireMonkey applications for Windows Win32
and Win64. macOS, iOS, Android, Linux, C++Builder, automatic layout reflow,
arbitrary Pascal-literal rewriting, and runtime cloud translation are outside
version 1.0.

Optional provider connectivity depends on third-party accounts, billing,
quotas, network access, and current service terms; it is not required for the
core workflow.

## Automatic Agent and UI Update

- Added one-button automatic in-place translation through an installed,
  signed-in Codex CLI or Claude Code command.
- Added safe child-process monitoring, diagnostic logs, automatic protected
  reload/save/validation, cancellation, and exact snapshot restoration.
- Added Engine Settings with engine/model lists, executable detection,
  browsing, and installation checks; agent credentials remain vendor-owned.
- Added built-in source and target language lists with locale defaults.
- The Studio now starts maximized. All seven designer-authored pages expand
  professionally and passed visual fit review without bottom clipping.
