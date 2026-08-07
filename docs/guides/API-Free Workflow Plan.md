# Delphi App Translation Studio — API-Free Workflow Plan

Last changed: August 7, 2026

Status: Stages 0 through 4 complete; Stage 5 is next

## Product Definition

Delphi App Translation Studio is an offline-first translation-management,
validation, packaging, and Delphi-integration application for Windows VCL and
FireMonkey projects. It discovers designated source text, maintains
context-aware JSON catalogs, accepts translations prepared by humans, AI
assistants, imported files, or optional online providers, and builds offline
runtime language packs.

Translation management and translation creation are separate responsibilities:

- The Studio inventories, records, validates, reviews, packages, and applies
  translations.
- A human translator, AI assistant, imported catalog, translation memory, or
  optional provider supplies the translated language.

Google and DeepL are optional conveniences. They are not prerequisites for the
core workflow, and translated applications never require Internet access or
provider credentials.

## Approved Milestone

The active milestone is:

**API-Free End-to-End Translation Workflow**

The milestone is complete only after a real FMX application and a real VCL
application have each completed this workflow:

1. Scan.
2. Export a translation catalog.
3. Prepare a non-English translation without a provider API.
4. Import and review the translation.
5. Validate structural correctness and runtime readiness.
6. Export the offline runtime pack.
7. Review exact integration changes.
8. Apply integration transactionally.
9. Build and launch Win32 and Win64.
10. Select the language, restart, and confirm persistence without Internet
    access.

## Architecture to Preserve

The approved direction is refinement, not a rewrite. Preserve:

- Designer-authored FMX Studio forms and Object Inspector ownership.
- Stable JSON development catalogs.
- Compact JSON runtime language packs.
- VCL and FMX form-property scanners.
- Pascal `resourcestring` inventory.
- Source-checksum catalog merge behavior.
- Validation and translation status models.
- Framework-neutral runtime loading and preference persistence.
- Thin VCL and FMX runtime adapters.
- Designer-persisted language menu integration.
- Transactional change sets, backup, rollback, and restore.
- Windows Credential Manager storage.
- Existing Google and DeepL clients as optional functionality.

## Work Requiring Correction

The current foundation requires targeted correction before release:

1. Form-property entries are applied automatically, but scanned
   `resourcestring` entries require an explicit generated `TranslateText` call.
   The UI and validation must not imply automatic runtime coverage.
2. Placeholder validation must understand Delphi sequential and indexed
   `Format` arguments, including valid argument reordering.
3. Translation reuse must become a developer-accepted suggestion. It must not
   automatically copy a translation or approval status between different
   stable keys.
4. Integration review must display exact source and project changes before
   Apply is enabled; a filename-only change list is insufficient.

## Work to Add

Add a dependable API-free interchange path:

- Keep development JSON available as a lossless interchange option.
- Add UTF-8 CSV export and import with stable-key matching.
- Support quoted commas, quotes, Unicode, and embedded line breaks.
- Reject duplicate and unknown keys.
- Report source-text and checksum mismatches.
- Preserve reviewed and approved work unless the developer explicitly chooses
  otherwise.
- Import translated text as unreviewed `Imported` or `Edited` work, never as
  automatically approved work.

## Approved Implementation Stages

### Stage 0 — Baseline and Governance

Status: Complete

Record the approved product definition, preserve current architecture, protect
developer-owned changes, establish the milestone and safeguards, and defer
pilot selection until the pilot gate.

### Stage 1 — Runtime Coverage Contract

Status: Complete

Distinguish automatic form-property application from manual Pascal
`resourcestring` wiring. Provide separate translation-completeness and
runtime-readiness reporting.

### Stage 2 — API-Free Interchange

Status: Complete

Implement robust development JSON and CSV export/import workflows with staged
validation and an import summary.

### Stage 3 — Structural Validation

Status: Complete

Characterize RAD Studio 37 `System.SysUtils.Format` behavior and replace
literal-token comparison with argument-aware placeholder validation.

### Stage 4 — Translation Suggestions

Status: Complete

Remove cross-key automatic reuse. Rank exact-source contextual suggestions and
require explicit acceptance.

### Stage 5 — Exact Integration Review

Status: Pending

Add designer-authored, read-only review of exact `.pas`, `.dpr`, `.dproj`,
`.dfm`, and `.fmx` changes before transactional Apply.

### Stage 6 — Optional Provider Positioning

Status: Pending

Keep provider functionality but remove it from the required linear workflow.
The API-free path must work without visiting Provider Settings.

### Stage 7 — Real FMX Pilot

Status: Pending

Complete and visually review the full API-free workflow on an approved,
backed-up real FMX application.

### Stage 8 — Real VCL Pilot

Status: Pending

Repeat the full API-free workflow on an approved, backed-up real VCL
application.

### Stage 9 — Usability and Linguistic Review

Status: Pending

Separate structural readiness from linguistic certification and visually
inspect translated layouts, menus, dialogs, and persistence behavior.

### Stage 10 — Documentation and Release Alignment

Status: Pending

Update guides, PDFs, help, release notes, and checklists only after the
implemented behavior is proven by both pilots.

## Pilot Selection Gate

Pilot applications are not selected automatically. Before Stage 7 or Stage 8:

1. Identify one FMX and one VCL candidate.
2. Confirm that the developer authorizes each project as a test target.
3. Review existing localization and source-control state.
4. Prefer a clean project without an existing competing localization runtime.
5. Create the required project-specific pre-change backup on `G:\`.
6. Start with a copy or isolated branch when practical.
7. Agree on the target language and the source of linguistic review.

Poker Galaxy is valuable as a reference for `.lng`, dynamic `Translate`
calls, placeholder reordering, and translation coverage. Because it already
has a working `TLang` localization system, it is not the preferred first clean
JSON-runtime FMX integration pilot.

## Per-Stage Engineering Safeguards

Before each approved implementation stage:

1. Review Git status and identify developer-owned changes.
2. State the exact intended file scope.
3. Obtain approval.
4. Create the required pre-change backup under
   `G:\Delphi App Translation Backup`.

After implementation:

1. Validate only the intended behavior.
2. Preserve designer ownership of every UI control.
3. Build elevated so RAD Studio can read its environment data.
4. Build and smoke-test required Win32 and Win64 configurations in proportion
   to the change.
5. Validate complete `.dproj` metadata whenever project files change.
6. Check for and remove only a stale zero-byte `.git\index.lock` when no Git
   process is running.
7. Review Git status, stage only intended files, create a clear commit, and
   update every configured project repository.

## Deferred Work

The following are outside the active milestone:

- Arbitrary Pascal-literal scanning.
- Automatic insertion of `TranslateText` calls.
- Pascal AST work.
- XLIFF.
- FMX `.lng` export.
- Full right-to-left layout behavior.
- Automated layout simulation.
- Additional providers.
- Runtime cloud translation.
- Provider-plan polish not required by a verified account.

## Release Standard

The Studio is not ready for a professional 1.0 claim until:

- API-free translation works end to end.
- JSON and CSV round trips are safe.
- Runtime coverage is reported honestly.
- Placeholder validation matches the Delphi RTL.
- Cross-key reuse requires acceptance.
- Exact integration changes are reviewable.
- Transactional restoration is proven.
- Real VCL and FMX applications pass Win32 and Win64.
- Language choice persists offline.
- Provider credentials never reach target applications.
- Documentation describes proven behavior and explicit limitations.
