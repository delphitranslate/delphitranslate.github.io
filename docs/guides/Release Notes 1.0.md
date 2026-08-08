# Delphi App Translation Studio 1.0 Release Notes

Last changed: August 7, 2026

## Release Summary

Version 1.0 delivers a Windows Win32/Win64, offline-first localization workflow
for Delphi VCL and FireMonkey applications. The Studio scans designer text and
Pascal `resourcestring` declarations, maintains development JSON catalogs,
translates unresolved text automatically through Google Cloud Translation or
DeepL, validates Delphi formatting contracts, exports compact runtime packs,
and integrates an offline runtime plus designer-persisted language menu.

Only the Studio uses provider Internet access and credentials. Target
applications do not contain API keys and do not require Internet access.

## Professional Workflow

- Read-only VCL/FMX project detection and text-resource scanning.
- Stable catalog keys and source-checksum incremental merge.
- Built-in Google Cloud Translation Basic v2 and DeepL API Free/Pro clients.
- Masked key entry, session-only use, or Windows Credential Manager storage.
- Provider connection test, bounded batching, retries for transient failures,
  provider provenance, and automatic catalog saving.
- Machine translated, Imported, Edited, Reviewed, and Approved linguistic
  states with explicit review progression.
- Safe UTF-8 CSV interchange as an optional collaboration path.
- Context-ranked exact-source suggestions that require explicit acceptance and
  never inherit approval.
- Delphi argument-aware placeholder and accelerator validation.
- Separate structural, linguistic, automatic-runtime, and manual
  `resourcestring` wiring readiness.
- Exact line-numbered original/proposed integration review for every file.
- Mandatory view-all and final-confirmation gates before transactional Apply.
- Automatic pre-change backup with manifest-recorded SHA-256 verification,
  atomic writes, rollback, and verified Restore.
- Designer-persisted VCL and FMX language menus, created on the primary form
  when the named menu does not already exist.
- DPR integration supports compiler directives such as `{$R *.res}` between
  the `uses` clause and the project `begin` block.
- Form-unit integration supports resource directives between `implementation`
  and an existing implementation `uses` clause without creating a duplicate.
- Multi-form FMX integration applies saved languages from each form's
  designer-persisted `OnCreate`, never from nil pre-`Application.Run` DPR form
  variables, and includes a defensive nil-form guard.
- Studio-created FMX and VCL menu containers include designer-authored
  **File > Exit** and **Language** menus; older generated containers are
  upgraded idempotently.
- The maximized Integration page uses larger designer-persisted gutters around
  planning, exact-review, and authorization controls.
- Offline JSON pack discovery and per-user language preference.
- Complete Reset preview and one-confirmation execution, with automatic
  SHA-256 safety backup, original-source restoration, generated-file cleanup,
  and preservation of unrelated developer files and all backups.

## Provider-Only Automatic Translation

The former command-line Codex/Claude experiment has been removed from the
product UI, project, source distribution, and smoke-test surface. The Studio no
longer asks developers to install or authenticate a separate AI command-line
tool. **Translate Automatically** now means one thing: translate eligible
catalog entries through the configured Google or DeepL API and save them as
Machine translated drafts for review.

## FMX Interface

The Studio starts maximized. All seven designer-authored pages expand into the
available workspace. Provider Settings contains only Google and DeepL controls,
and the Translate page presents a single primary automatic-translation action.
All controls remain persisted in the FMX resource and editable in RAD Studio.

## Validation

The deterministic Win32 and Win64 suites cover project detection, VCL/FMX
scanning, catalog persistence, provider request/response contracts, validation,
runtime export, integration, deployed offline packs, form streaming, launch,
and Studio self-localization. Live provider acceptance requires an
owner-supplied restricted key and is intentionally kept out of automated
fixtures.

## Scope

Supported targets are Delphi VCL and FireMonkey applications for Windows Win32
and Win64. macOS, iOS, Android, Linux, C++Builder, automatic layout reflow,
arbitrary Pascal-literal rewriting, Google Advanced v3, and runtime cloud
translation are outside version 1.0.

Provider connectivity depends on third-party accounts, billing, quotas,
network access, current API behavior, and service terms. Human review remains
required before shipping machine-translated text.
