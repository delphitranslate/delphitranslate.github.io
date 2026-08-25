# Future Plan: Multi-Language Batch Addition

**Status:** Approved as a future objective; not implemented  
**Recorded:** August 25, 2026  
**Applies to:** Delphi App Translation Studio, VCL targets, FireMonkey targets, and future Delphi applications using its translation packages

## Objective

Add a discoverable workflow to the Studio welcome page that lets a developer add many target languages to one Delphi application in a single operation. The result must perform the same substantive work as running the current Setup Wizard manually for each language, while preserving review, validation, backup, deployment, VCL/FMX parity, and right-to-left behavior.

This feature must not automate mouse clicks through the existing Wizard and must not become project-specific code. It must use one reusable translation workflow shared by the one-language Setup Wizard, the new multi-language form, and the command-line batch application.

## Deep-Dive Conclusion

The feature is feasible and worthwhile, but it is not a simple welcome-page button change.

The graphical Setup Wizard currently owns one target-language combo box, one active catalog, one review output directory, and one final-processing pass. Changing the target language clears that state. The existing `DATBatch` application already accepts a list of language codes and scans the project once, which is the correct starting architecture, but it is not equivalent to the Setup Wizard.

In particular, the present `DATBatch` parses provider and API-key arguments but does not call the translation provider. It also omits parts of the graphical workflow, including the shared dictionary, required interactive terminology/layout review, pre-processing backup, target rebuild, deployment, and the complete Wizard report. Existing tests run it with `--no-translate`, so they do not establish true provider-backed multi-language processing.

The batch executable must therefore not be launched unchanged from a new GUI button.

## Recommended Welcome-Page Change

Add a third designer-owned button:

**Add Multiple Languages**

The button should open a new designer-editable FMX form. All permanent controls, sizes, anchors, alignments, captions, and other visual parameters must remain available in the RAD Studio Object Inspector. Language data may populate a designer-owned list or grid at runtime; controls must not be constructed dynamically.

The existing **Run Setup Wizard** button should remain available for simple one-language work.

## Proposed Multi-Language Form

### 1. Project

- Select the Delphi project.
- Detect VCL or FireMonkey using the existing project detector.
- Load current workspace and deployment destinations.
- Confirm that the project source has been saved before scanning.

### 2. Languages

Provide a searchable, multi-select list with these columns:

- Selected
- Language
- Locale code
- Native name
- LTR or RTL
- New, existing, or needs updating
- Selected provider support
- Preflight status

Useful selection actions:

- Select All
- Clear All
- Select LTR
- Select RTL
- Select New Only

Right-to-left direction must come from locale metadata, not from a short hard-coded list of languages.

### 3. Translation Settings

- Source language
- Google or DeepL
- Saved provider credential
- Create new catalogs or update existing catalogs
- Preserve all reviewed and approved translations
- Apply shared dictionary, project glossary, translation memory, authoritative terminology, hyphenation information, and domain information exactly as the single-language workflow does

The first version should process languages sequentially. It should not issue parallel provider requests.

### 4. Preflight

Before translation begins, report for every selected language:

- Existing translations preserved
- Entries resolved by terminology, glossary, and memory
- Entries requiring provider translation
- Estimated provider characters
- Provider/language compatibility
- Locale availability
- Existing unresolved validation problems
- Whether the language is new or being updated

Provider code normalization is not sufficient proof that a service supports a language. Unsupported provider/language combinations must be identified before work begins.

### 5. Processing and Review Queue

- Scan the Delphi project once.
- Create or merge one independent catalog per selected language.
- Translate only unresolved eligible entries.
- Show per-language and overall progress.
- Permit safe cancellation between provider batches.
- Save resumable status without saving API credentials in the run manifest.
- Generate all automatic drafts first.
- Present each language through the existing Localization Review workflow.
- Provide clear **Previous Language** and **Next Language** navigation.
- Preserve previous terminology and layout decisions.
- Validate each reviewed language.
- Promote and deploy only the complete validated set.

Human terminology and layout review cannot truthfully be replaced by automation. The time-saving goal is to generate and organize all drafts in one operation and turn review into a queue rather than require the developer to repeat the complete Wizard setup for every language.

## Shared Workflow Architecture

Create one specifically named domain workflow, not a generic Helper class. A suitable responsibility-oriented name would be:

- `TLanguagePackWorkflow` for one target language
- `TLanguageBatchWorkflow` for coordinating multiple one-language runs

The one-language workflow should own the authoritative sequence:

1. Detect the target project.
2. Use the supplied shared scan result.
3. Load or create the target catalog.
4. Apply Windows locale facts and text direction.
5. Merge the scan while preserving reviewed and approved work.
6. Apply the shared dictionary.
7. Apply project glossary terms.
8. Apply translation memory.
9. Apply authoritative terminology and calendar terms.
10. Install/use applicable hyphenation and domain information.
11. Translate unresolved eligible entries through the selected provider.
12. Generate review artifacts and layout proposals.
13. Apply saved human review decisions.
14. Validate the development catalog.
15. Export the runtime pack to staging.
16. Produce a per-language result and report.

The coordinating batch workflow should scan once, call the one-language workflow sequentially, maintain the run manifest, coordinate the review queue, and promote the complete validated result.

The existing Setup Wizard should call the one-language workflow with one target. The new batch form should call the batch workflow with many targets. `DATBatch` should eventually call the same workflow for unattended operation. Translation rules must not be copied among three entry points.

## Backup and Transaction Requirements

Before processing begins:

- Back up the Delphi project.
- Back up the associated translation workspace under Local AppData.
- Record the selected project, source checksum, languages, provider, and starting catalog checksums in a run manifest.

During processing:

- Write catalogs, glossaries, proposals, reports, and packs into a run-specific staging directory.
- Do not overwrite live language packs one by one.
- Include existing valid language packs in the staged complete set.
- Preserve the last deployed set if any selected language fails.
- Allow a stopped run to resume without retranslating completed languages.

After all required reviews and validations pass:

- Promote the staged catalogs and runtime packs.
- Generate the component integration kit once.
- Rebuild requested targets once.
- Deploy the complete language set to existing outputs and configured destinations.
- Write one overall completion report plus per-language results.

This transaction is essential because the component-kit generator discovers and copies every current language pack. Partial live writes could otherwise combine old and new packs.

## Required Parity With the Current Manual Workflow

The completed feature must provide all of the following for every language:

- Project detection
- One shared source scan
- Per-language catalog creation or merge
- Locale defaults and RTL/LTR direction
- Project glossary
- Shared dictionary
- Translation memory
- Authoritative terminology
- Provider translation
- Hyphenation/domain processing
- Terminology and layout review
- Saved review decisions
- Catalog validation
- Runtime-pack export
- Application-owned-string reporting
- Component-kit generation
- Project and workspace backup
- Selected builds
- Deployment to all configured destinations
- Completion reporting

No language should be described as successfully added if any required step was skipped.

## Validation Plan

### Workflow parity

- Compare a one-language run through the shared workflow with the existing Setup Wizard.
- Confirm equivalent catalog, validation, layout proposal, runtime pack, kit, and deployment results.

### Multi-language behavior

- Add several new LTR languages in one run.
- Add LTR and RTL languages together.
- Mix new and existing languages.
- Preserve reviewed and approved translations during updates.
- Confirm that each provider request uses the correct target language.
- Confirm that glossary and memory content cannot cross language boundaries.

### Failure safety

- Simulate provider failure on a middle language.
- Simulate invalid provider/language selection.
- Cancel during provider batching.
- Resume the stopped run.
- Confirm that failed or canceled processing leaves live packs and deployed applications unchanged.
- Confirm restoration from both the project and translation-workspace backups.

### VCL and FireMonkey

- Run equivalent VCL and FMX samples.
- Verify language selectors, menus, status bars, dialogs, grids, edits, memo controls, splash screens, wrapping, layout overrides, and runtime-created controls.
- Verify full RTL behavior including alignment, reading order, grid column reversal, edit direction, tab order, and protected media-control order.

### Deployment

- Confirm that the final kit contains English, all existing languages, and every newly validated language.
- Confirm Win32 and Win64 deployment where configured.
- Confirm configured external/application destinations receive the same complete set.

## Implementation Sequence

1. Extract and validate the shared one-language workflow without changing observable Setup Wizard behavior.
2. Add translation-workspace backup, staging, transaction manifest, cancellation, and resume.
3. Convert `DATBatch` to use the shared workflow and add provider-backed batch tests.
4. Add the designer-owned multi-language form and welcome-page button.
5. Add the review queue and complete-set promotion.
6. Complete VCL, FMX, LTR, RTL, failure, resume, and deployment regression testing.
7. Update Engineering Guide, User Guide, help content, and release notes before promotion.

## Acceptance Criteria

The future feature is complete only when:

- A developer can select many languages once and avoid repeating project, provider, scan, backup, build, and deployment setup.
- Every selected language receives the same substantive processing as a correct manual Setup Wizard run.
- Existing reviewed translation work is preserved.
- The user can cancel and resume safely.
- No partial run changes the live/deployed language set.
- VCL and FMX use the same generated language packs and contracts.
- LTR and RTL languages work in the same batch.
- Forms remain editable in the IDE and no runtime UI construction is introduced.
- No generic Helper code or project-specific translation path is introduced.
- The single-language Wizard, multi-language GUI, and command-line batch path share the same authoritative workflow.

## Current Decision

Retain this as an approved future plan. Do not implement it while current Arabic and other language-pack regression testing is in progress. Begin only after the developer explicitly authorizes implementation and a new pre-change backup has been made.
