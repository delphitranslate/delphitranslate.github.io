# Delphi App Translation Studio — Engineering Notes

Last changed: August 6, 2026

## Purpose of This Document

This document records product decisions, feature ideas, technical constraints, and
engineering findings for the proposed Delphi App Translation Studio. It is intended
to guide development and later serve as source material for the full Engineering
Guide and User Guide.

Everything described here is currently a product concept unless explicitly marked
as implemented.

## Current Product Definition

The product is an open-source, standalone Delphi FireMonkey (FMX) Translation
Studio for Windows. The Studio itself is FMX, but it translates both Delphi VCL
and Delphi FireMonkey Windows applications.

The supported compile and target platforms are:

- Win32
- Win64

macOS, iOS, Android, and Linux are outside the current product scope.

It is not currently planned as:

- A component suite.
- A design-time component package.
- A continuously running translation service.
- A runtime Internet service.
- A VCL application.

The Studio itself will be written in Delphi using FireMonkey and advanced,
cross-platform Delphi capabilities where they simplify the design.

A translated application will require a small framework-specific runtime Delphi
unit or generated integration code to load a selected language pack and apply it
as VCL or FMX forms load. This runtime support is not an installable component and
will not appear on the RAD Studio Tool Palette.

The public source repository is:

`https://github.com/tmartindub/DelphiAppTranslationStudio`

## Primary Workflow

1. The developer completes a VCL or FMX Windows application.
2. The developer opens the application project in the Translation Studio.
3. The Studio scans the project for designated translatable text.
4. The Studio creates or updates a development language pack.
5. The Studio reports the scan results.
6. The developer may review the discovered entries before translating.
7. The developer chooses a target language and translation provider.
8. With confirmation, the Studio sends eligible source text to the selected
   Internet translation provider.
9. Returned translations are written to the development language pack and marked
   as machine translated.
10. The developer reviews, corrects, and approves translations.
11. The Studio validates and builds the final offline runtime language pack.
12. The Studio can update the translated application's VCL or FMX
    language-selection menu.
13. The translated application reads the selected language during startup and
    applies the pack once as each form loads.

The deployed application and its language packs must work without Internet access.
Only the Translation Studio's optional translation-provider operation requires an
Internet connection.

## Scan Completion Workflow

After scanning, the Studio should display an informative confirmation instead of a
simple Yes or No prompt. A possible message is:

> Scan complete. 437 translatable entries were found. 391 are new and 46 already
> have translations. Translate the 391 new entries into German using DeepL?

Suggested actions:

- Translate Now
- Review First
- Cancel

Before translation begins, the Studio should show:

- Translation provider.
- Source and target languages.
- Number of eligible entries.
- Total character count.
- Estimated provider cost when available.
- Number of existing translations that will be preserved.
- Number of entries excluded as confidential or "do not translate."

## Internet Translation Providers

The first planned providers are:

- Google Cloud Translation.
- DeepL.

The Studio must use official provider APIs. It must not automate or scrape public
translation websites.

Provider requirements:

- Internet use occurs only after explicit developer confirmation.
- API credentials are stored securely outside application projects and language
  packs.
- API credentials are never compiled into translated applications.
- Existing approved translations are preserved by default.
- Source code is not sent to a provider.
- Only eligible text and the minimum useful context are submitted.
- Entries may be marked confidential or excluded from online translation.
- Translation results are initially marked as machine translated.
- Provider operations support cancellation, retry, batching, and clear error
  reporting.
- The Studio remains usable for manual translation and review without Internet
  access.

## Designated VCL and FMX Content

The scanner will use editable framework-specific extraction rules.

Initial VCL candidates include:

- `TForm.Caption`
- `TLabel.Caption`
- `TButton.Caption`
- `TMenuItem.Caption`
- `TTabSheet.Caption`
- `TCheckBox.Caption`
- `TRadioButton.Caption`
- `TGroupBox.Caption`
- `TEdit.TextHint`
- `TAction.Caption`
- `TAction.Hint`
- List and combo-box design-time items
- Grid column headings
- Hints and instructional text
- Default memo lines when explicitly enabled

Initial FMX candidates include:

- `TLabel.Text`
- `TButton.Text`
- `TMenuItem.Text`
- `TTabItem.Text`
- `TCheckBox.Text`
- `TRadioButton.Text`
- `TGroupBox.Text`
- `TEdit.TextPrompt`
- `TAction.Text`
- `TAction.Hint`
- List and combo-box design-time items
- Grid column headings
- Form titles
- Dialog prompts
- Hints and instructional text
- Default memo lines when explicitly enabled

Rules for third-party FMX controls should be addable without rewriting the scanner.

The following content must not be translated automatically:

- User-entered text.
- Database records.
- Log output.
- Loaded documents.
- Filenames and paths.
- URLs.
- SQL.
- JSON property names.
- Configuration keys.
- Regular expressions.
- Format masks.
- Style names.
- Component identifiers.
- Native API identifiers.

Default memo content is eligible only when it is application-provided text such as
instructions, help, license text, or a prepared template.

## Source-Code Text

Not every quoted Delphi string is user-facing. The Studio may identify likely
source-code candidates, but the developer must review them.

The preferred convention for prompts, error messages, and other source-code UI text
is Delphi `resourcestring`. This provides a standard and identifiable source without
introducing helper code.

The scanner should warn about likely user-facing string literals that are not
declared as resourcestrings, but it should not automatically classify every string
literal as translatable.

## Translation Identity

Each entry needs a stable key. A typical automatically generated key could be:

`MainForm.SaveButton.Text`

Development entries should retain:

- Stable key.
- Source text.
- Translation.
- Source and target language.
- Form or frame.
- Component name and class.
- Property name.
- Translation status.
- Source checksum.
- Developer notes.
- Exclusion flags.
- Placeholder information.

Identical text should not automatically be treated as the same meaning. For example,
"Open" as a menu command may differ from "Open" as a record status.

Exact duplicate requests may be reused when both text and context match, reducing
provider cost and processing time.

## Development and Runtime Language Packs

The development pack may contain source text, translations, review status, notes,
checksums, and other Studio information.

The final runtime pack should contain only what the application needs:

- File-format version.
- Application identifier.
- Application/catalog version.
- Language code.
- Native and display language names.
- Text direction.
- Source catalog checksum.
- Translated keys and values.
- Locale profile.
- Required plural or formatted-message data.
- Compatibility information.
- Integrity checksum.

The runtime pack should not contain:

- Screenshots.
- Source-code excerpts.
- Translation history.
- Translator comments.
- Validation reports.
- Translation-memory data.
- Provider credentials.
- User or database data.

UTF-8 JSON is the preferred initial format because it is inspectable and easy to
diagnose. Compression or a compact binary deployment format can be considered later.

Estimated uncompressed JSON sizes:

| Application Size | Entries | Estimated Pack |
| --- | ---: | ---: |
| Small utility | 100–300 | 10–40 KB |
| Medium application | 500–1,500 | 40–200 KB |
| Large application | 2,000–5,000 | 150–700 KB |
| Very large suite | 10,000 or more | 750 KB–2 MB |

Large memo, license, or help content may dominate pack size. Ordinary labels,
buttons, menus, headings, and prompts require little storage.

## Locale Formatting

Dates, times, numbers, currencies, and percentages are locale values rather than
ordinary translated strings.

Each pack should include or identify a locale profile containing:

- Locale name.
- Short and long date formats.
- Time format.
- Decimal separator.
- Thousands separator.
- Currency symbol and placement.
- Percentage format.
- First day of week.
- Text direction.

The runtime support should create and use locale-specific `TFormatSettings`.

The Studio cannot retroactively control arbitrary formatting code that relies on
the computer's global settings. The scanner should detect and report likely
date/number formatting calls that do not use the application's selected format
settings.

## Application Startup Behavior

Continuous translation is not required.

The intended runtime sequence is:

1. Read the stored language selection.
2. Load the corresponding offline JSON pack.
3. Create locale-specific format settings.
4. Create application forms.
5. Apply translations once after each form finishes loading.
6. Display the translated form.

When the user selects another language, the simplest initial behavior is:

1. Save the new language code.
2. Inform the user that the language changes after restart.
3. Apply the new language during the next startup.

Immediate live switching may be reconsidered later, but it is not part of the
current core concept.

## Automatic Language-Menu Modification

The Translation Studio will include framework-specific features to modify a
translated VCL or FMX application so its menu offers the languages built by the
Studio.

The intended menu might appear as:

```text
Language
├── English
├── Deutsch
├── Français
└── Español
```

Language names should normally be displayed in their native form so users can
recognize them regardless of the application's current language.

This feature changes the developer's application project and therefore requires
strong safeguards:

- The developer explicitly chooses or confirms the target FMX menu.
- The Studio shows a preview of all proposed changes.
- Existing menu items, event handlers, shortcuts, ordering, and formatting are
  preserved.
- The Studio makes the required pre-change backup of the target application.
- The Studio changes only the intended FMX form and supporting integration files.
- The Studio does not use fragile blind text replacement.
- The operation is transactional: either all intended changes succeed or the
  original files remain intact.
- A clear undo or restore path is provided.
- Re-running the operation updates existing language entries rather than creating
  duplicates.
- Source-control state and writable-file status are checked before modification.

The exact integration method remains an engineering decision. Options to evaluate:

1. Modify a developer-designated `TMenuItem` subtree in a `.dfm` or `.fmx` form.
2. Add a designed language-menu placeholder and update its persisted language
   collection.
3. Generate a language manifest and minimal runtime menu integration code.

The preferred solution should keep the menu editable in the appropriate VCL or FMX
designer and its configuration visible through normal RAD Studio design-time
mechanisms.

## Visual Design

The Studio uses the orange-and-blue visual family established by
VCL2FMXConverterV6:

- Primary blue: `#1974DF`
- Deep navy: `#234C80`
- Orange accent: `#FF8800`
- Medium blue: `#3C6CB5`
- Light action blue: `#5A93E8`
- Pale application background: `#F2F7FD`
- Card background: `#FFFFFF`
- Main text: `#163A63`
- Secondary text: `#365674`
- Muted text: `#5D7693`
- Light border: `#D7E5F6`

Orange is reserved for important translation actions and accents. Blue carries
navigation, selection, and structure. Small orange text on white should use a
darker accessible shade rather than `#FF8800`.

## Expected Scan Performance

Normal extraction should parse FMX form data without rendering every form.

Initial engineering targets:

| Form Complexity | Approximate Contents | Target Scan Time |
| --- | --- | ---: |
| Simple | 10–40 components | 5–30 ms |
| Medium | 50–150 components | 20–100 ms |
| Complicated | 150–400 components | 75–300 ms |
| Very large | 500–1,000 or more components | 200–750 ms |

Component-aware inspection involving frames, inherited forms, collections, and
third-party controls may require approximately 100 ms to 4 seconds per form.

Rendering, screenshots, and layout validation are separate operations and may take
approximately 500 ms to 10 seconds per form depending on complexity.

For a typical 50-form application, the target is:

- Under 10 seconds for ordinary extraction.
- Approximately 5–25 seconds for component-aware extraction.
- Rendering and layout validation performed separately.

These are planning estimates, not measured performance claims. They must be
validated with representative benchmark projects before publication.

## Incremental Rescanning

Rescanning a maintained application should merge changes safely:

- Unchanged entry: preserve its translation.
- New entry: mark it untranslated.
- Changed source text: retain the previous translation but mark it for review.
- Removed entry: mark it obsolete rather than deleting it immediately.

File timestamps and checksums should allow unchanged forms and units to be skipped.

## Implemented Scanner Foundation

Implemented on August 6, 2026:

- Read-only scanning of text VCL `.dfm` and FireMonkey `.fmx` resources.
- Framework-specific rules for common form titles, labels, buttons, menus,
  tabs, selection controls, hints, edit prompts, list items, and memo lines.
- Delphi persisted-string decoding, including doubled apostrophes and numeric
  character codes such as `#39`.
- Stable keys based on form, component, property, and collection index.
- Source filename and one-based source line retention for every discovered item.
- `resourcestring` scanning with stable unit-and-symbol keys.
- Project orchestration that inventories the framework-appropriate form
  resources and Delphi source units while excluding build and repository
  folders.
- Incremental catalog merging: new entries need translation, changed source text
  is retained and flagged for review, unchanged translations are preserved, and
  removed entries are marked obsolete.
- A designer-authored Studio results area that reports total entries, form
  properties, resource strings, files scanned, elapsed milliseconds, and the
  discovered key/value list.

The scanner does not load forms, instantiate target components, render UI, or
modify the selected application. Binary DFM conversion and inherited/third-party
component ancestry resolution remain later work.

Validation fixtures currently cover both a VCL and FMX application. Scanner tests
compile and pass with both the Win32 and Win64 Delphi compilers. The small sample
projects complete below the timer's one-millisecond reporting resolution on the
development machine; representative medium and large benchmark applications are
still required before replacing the planning estimates above with published
measurements.

## Implemented Offline Catalog Workflow

Implemented on August 6, 2026:

- Active workflow navigation now follows Project, Scan, Languages, Validation,
  and Export. The selected navigation panel changes as the developer moves
  through or performs each step.
- A scan creates or incrementally merges an in-memory development catalog.
  Scanning by itself remains read-only and creates no target-project files.
- The developer explicitly creates or saves a target-language development
  catalog from the Languages page.
- Development catalogs default to:

  `Target Project\Localization\Development\ProjectName.language-code.translation-project.json`

- Runtime packs default to:

  `Target Project\Localization\Languages\language-code.json`

- The Studio creates these folders only during an explicit save or export
  operation.
- Existing development catalogs can be reopened after the matching Delphi
  project is opened.
- The Languages page provides designer-authored controls for source and target
  language codes, native language name, text direction, date/time formats,
  decimal and thousands separators, and currency symbol.
- Blank locale-format fields are populated using Delphi
  `TFormatSettings.Create(target-language-code)` and remain editable.
- A designer-authored entry list and source/translation memo pair supports manual
  translation editing without dynamically constructing UI controls.
- Validation checks catalog identity, framework and language metadata, locale
  settings, duplicate keys, empty translations, changed source text,
  Delphi-format and brace placeholders, accelerator-key counts, and identical
  source/translation text.
- Errors block runtime export. Warnings remain visible but do not block export.
- The runtime exporter writes a compact UTF-8 JSON pack containing application
  identity, framework, source language, target-language metadata, locale
  settings, a source-catalog checksum, and active translated key/value pairs.
- Excluded and obsolete development entries are omitted from runtime packs.
- Automated scanner coverage now includes the Studio project itself in addition
  to the focused VCL and FMX fixtures. This exercises the larger designer-authored
  FMX form and fails on scanner diagnostics with error severity.

Online provider access is intentionally not part of this tranche. Manual editing
and offline pack generation work without an Internet connection.

## Implemented Offline Runtime and Integration Foundation

Implemented on August 6, 2026:

- A framework-neutral runtime loader validates schema version 1 language packs,
  application identity, language metadata, locale settings, and translated
  key/value pairs.
- Runtime language discovery inventories valid JSON packs in
  `Localization\Languages` and ignores malformed or unrelated application packs.
- A runtime manager loads the saved language at application startup, falls back
  to the source language, and exposes pack-specific `TFormatSettings`.
- The selected language is stored in a developer-chosen INI path. The runtime
  makes no Internet request and does not depend on AppData.
- Separate VCL and FMX applicators use published-property RTTI to apply only
  scanned properties to forms and their owned components. VCL and FMX units are
  separate so a target links only its own framework.
- Caption, Text, Hint, TextHint, TextPrompt, Items, and Lines mappings follow the
  scanner's stable keys. An absent translation retains the original
  designer-authored value.
- The Studio's designer-authored Integration page detects an existing language
  menu by component name, lists exported languages in their native names, and
  presents the proposed integration steps.
- The Studio generates a review package under `export\integration`. The package
  contains framework-neutral runtime units, the correct VCL or FMX adapter, a
  target-specific integration unit, the available runtime packs, and a
  `language-menu.json` manifest.
- Package generation does not modify the selected application. Automatic,
  transactional updates to the target project's persisted DFM/FMX menu and
  Pascal event handlers remain the next integration tranche, with the backup and
  preview safeguards described above.
- Regression programs instantiate representative VCL and FMX forms, apply a
  language pack, and verify form titles, labels, menu text, memo lines, and
  preservation of combo-box selections during an immediate language change.
  Indexed list text is replaced in place, while each adapter preserves
  `ItemIndex` and suppresses `OnChange` during localization so application state
  cannot be mistaken for a new user selection. The generated VCL and FMX
  integration units also compile independently.
- `tools\tests\RunRuntimeSmokeTests.ps1` repeats those checks with both the
  Win32 and Win64 Delphi compilers and removes its generated package fixtures
  after validation.

The generated integration unit provides five explicit entry points:

1. `InitializeTranslation` creates the offline runtime and loads the saved
   language.
2. `ApplyTranslation` applies the active pack after a form is created.
3. `SelectLanguage` saves and activates a menu-selected language.
4. `TranslateText` translates scanned resourcestring or other source-code text
   while retaining the supplied source-language fallback.
5. `TranslationRuntime` exposes available-language discovery and locale format
   settings to the application.

This keeps the target application's original DFM/FMX design intact. The
developer places and names the parent Language menu in the designer; the
transactional integration phase described below persists its language children.

## Implemented Transactional Target Integration

Implemented on August 6, 2026:

- The Integration page now separates conceptual planning, exact file preview,
  Apply, and Restore operations.
- A generated preview lists every proposed target file before the target is
  changed.
- VCL language choices are persisted as normal `TMenuItem` children beneath a
  developer-designated menu in the text DFM.
- FMX language choices are persisted the same way in the text FMX.
- Language items use native names and stable `datLanguage_language_code`
  component names. The source language is first and exported languages are
  sorted by native name.
- Re-running integration removes and recreates only Studio-owned
  `datLanguage_` children, preventing duplicates while preserving unrelated
  developer menu items.
- A single form method handles all persisted language items. It converts the
  menu component name back to the language code and saves the preference.
- Runtime units and the target-specific integration unit are installed under
  `Localization\Runtime`.
- The DPR receives explicit unit/file mappings, calls
  `InitializeTranslation` before creating forms, and calls `ApplyTranslation`
  immediately after every statically declared `Application.CreateForm`.
- The DPROJ receives corresponding `DCCReference` entries without reformatting
  the rest of its XML.
- Dynamically created forms still require an explicit `ApplyTranslation` call
  after construction. The generated function is available for that purpose.

Integration application is transactional:

1. Validate that every target remains inside the selected project.
2. Reject read-only target files and active `.git\index.lock` state.
3. Create a manifest-driven pre-change backup.
4. Record and verify the SHA-256 digest of every copied original before any
   target file is written.
5. Write each replacement through a temporary file.
6. Roll back already-written files automatically if a later write fails.
7. Retain the backup path for the Integration page's Restore action.

On this development system, automatic target backups default to
`G:\ProjectName Backup\Translation Integration timestamp`. On systems without a
`G:` drive, the portable fallback is
`Target Project\Localization\Integration Backups`. The backup manifest records
whether the target is a Git repository, whether each changed file existed
before integration, and the SHA-256 digest of every preserved original.
Restore preflights every path and backup digest before overwriting any
developer source, then verifies each restored target. A missing, damaged, or
altered backup therefore stops Restore safely. Manifests from the earlier size-only schema
remain restorable for backward compatibility, but all new backups use schema 2
and exact content verification.

The supported automatic source pattern is a conventional Delphi application
with:

- A text DFM or FMX resource.
- An existing developer-designated `TMenuItem` parent.
- A matching Pascal form class.
- A normal DPR `uses` block and `Application.Initialize`.
- Optional DPROJ metadata.

Binary form resources and unusually generated or macro-driven DPR/Pascal source
remain preview-only/manual integration cases until dedicated parsers are added.

## Implemented Studio Self-Localization

The Studio now initializes its own offline FMX runtime before creating the main
form and applies the selected pack during `TfrmTranslationStudio.FormCreate`.
Its Language menu and English item are designer-authored in the main FMX form.

When the Studio project is selected as its own target, integration recognizes
the existing self-localization runtime and plans only the persisted language-menu
update. It does not install a second generated runtime or duplicate startup
wiring. This permits the following bootstrap:

1. Run the current English Studio.
2. Scan `DelphiAppTranslationStudio.dproj`.
3. Create, translate, validate, and export `it-IT.json`.
4. Generate the integration preview for `mnuLanguage`.
5. Apply the single FMX menu-resource change.
6. Rebuild the Studio into its normal output folder.
7. Select Italiano and restart.

The running executable is never overwritten. JSON packs and the saved
preference are separate files, and the rebuilt executable is used on the next
launch.

The controlled self-localization fixture at
`samples\StudioSelfLocalization\it-IT.json` translates the actual Studio window
title and principal navigation text. The repeatable smoke test temporarily
installs that pack, launches all Win32/Win64 Debug/Release executables, verifies
the Italian main-window title, and restores the prior local language state.

## Phase 20 Integration Validation

`tools\tests\RunRuntimeSmokeTests.ps1` now performs the complete integration
regression under both Delphi compilers:

- Runtime pack load, discovery, preference, locale, and fallback tests.
- Direct VCL and FMX component-application tests.
- Generated VCL and FMX integration-unit compilation.
- Disposable copies of the VCL and FMX sample projects.
- Italian pack export and native language-menu persistence.
- Transaction application, manifest backup, restore, and repeated-preview
  idempotency.
- Integrated VCL and FMX project builds for Win32 and Win64.
- Launch checks confirming all four integrated sample forms stream correctly.
- Exact cleanup of generated integration fixtures and build output.

`tools\tests\RunStudioSelfLocalizationSmokeTest.ps1` validates the real Studio
in Italian. `tools\tests\RunStudioLaunchSmokeTests.ps1` then confirms the normal
English launch state remains intact.

## FMX Form-Streaming Validation

FMX application validation must include launching the compiled executable. A
successful compile does not prove that every persisted form property can be read
at runtime.

On August 6, 2026, the initial Studio form failed during startup because the
nonvisual `TOpenDialog.Left` and `TOpenDialog.Top` properties were stored with
floating-point FMX values. These inherited design-position properties require
integer values. The form resource was corrected, and the project metadata now
explicitly identifies the main form as `FormType=fmx` with `DesignClass=TForm`.
The standard project resource directive is also present in the DPR.

Future release validation must therefore include:

- Debug and Release compilation for Win32 and Win64.
- Scanner smoke tests under both compilers.
- Launch tests for Win32 and Win64 that verify the expected main-window title,
  not merely that the process remains running. A modal startup error can also
  leave a process running and must not be mistaken for a successful launch.

The repeatable launch check is maintained at
`tools\tests\RunStudioLaunchSmokeTests.ps1` and covers Debug and Release for both
Win32 and Win64.

## Project Icon Configuration

On August 6, 2026, an attempted automatic icon/logo update produced malformed
`.dproj` XML. The generated markup placed indentation between an opening `<`
character and an element name, and it omitted `<` characters from closing
`PropertyGroup` and `BorlandProject` tags. RAD Studio consequently reported
`Whitespace is not allowed at this location` at line 13, column 4.

The form resource was not involved. The project file was repaired and now
contains valid `Icon_MainIcon`, `UWP_DelphiLogo44`, and `UWP_DelphiLogo150`
properties pointing to the project icon and files under `images and icons`. The
logo deployment entries remain under the `BorlandProject` deployment section.

Icon changes require more than a successful XML parse. Validation must also:

- Confirm that every configured asset path exists.
- Rebuild Debug and Release for Win32 and Win64.
- Extract the associated icon from a rebuilt executable and visually confirm
  that the custom icon was embedded.
- Run the four-configuration Studio launch smoke test.

## Deferred Ideas

The following ideas are retained for possible later evaluation but are not part of
the current core product:

- Installable localization components.
- A component-palette suite.
- Continuous end-user translation.
- Mandatory Internet connectivity.
- Runtime cloud translation.
- Automatic acceptance of machine translations.
- Immediate live language switching.
- Fully automatic control repositioning.
- Non-Windows Studio targets.
- Non-Windows translated-application targets.
- C++Builder target projects.

## Documentation Practice

Engineering decisions, constraints, benchmarks, file formats, provider behavior,
menu-modification rules, and important implementation discoveries should be added
to this document throughout development.

When the full guides are requested:

- Engineering Guide content will be based on the actual source, project files,
  forms, runtime behavior, and these verified notes.
- User Guide content will describe the final implemented workflow rather than
  unimplemented concepts.
- Both guides will be produced as editable `.docx` files and companion `.pdf`
  files with a title page, last-changed date, and table of contents.

## Phases 21-30: Provider Translation and Release Completion

The developer Studio now supports DeepL API Free, DeepL API Pro, and Google
Cloud Translation Basic v2. Provider access is intentionally isolated from the
translated application. The Studio sends source strings only after the
developer confirms the count. The target VCL or FMX executable receives only
validated offline JSON packs.

Nonsecret choices are saved under
`%LOCALAPPDATA%\DelphiAppTranslationStudio\provider-settings.json`. A remembered
API key is a Windows Generic Credential whose target begins with
`TMartinDub/DelphiAppTranslationStudio/`. A session-only key remains in process
memory and is forgotten at shutdown. Keys are not written into a catalog,
runtime pack, project, integration package, diagnostic, or repository file.

DeepL requests use the current `Authorization: DeepL-Auth-Key` header and the
plan-specific endpoint. Google requests use Cloud Translation Basic v2 with the
`X-Goog-Api-Key` header. Provider errors report the HTTP status and corrective
categories without logging request headers or response bodies. Requests are
limited to 1-50 strings per batch, have a configurable 5-300 second timeout,
retry HTTP 429 and server failures, validate response counts, and expose a
cancellation check between batches.

Bulk translation does not overwrite excluded or obsolete entries, nor does it
replace complete reviewed/approved work. Results are recorded with
`machine-translated` status so validation and human review remain mandatory.
The Studio continues to support manual edits and all existing status values:
needs translation, machine translated, edited, reviewed, approved, source
changed, excluded, obsolete, and error.

Generated integration units now store the selected-language preference under
`%LOCALAPPDATA%\<ApplicationId>\language.ini`, avoiding installed-folder write
failures. Runtime JSON packs remain beside the executable under
`Localization\Languages`. Each preview package includes
`Deploy-LanguagePacks.ps1` for copying those packs beside a chosen executable.
The Studio's own language preference follows the same per-user rule.

Release documentation must explain that provider accounts, billing, quotas,
pricing, and supported languages are controlled by Google or DeepL and can
change. Key-acquisition instructions therefore name the official console pages
and recommend checking the provider's current documentation. Google keys should
be restricted to the Cloud Translation API. DeepL users must select API Free or
API Pro in the Studio to match their account endpoint.

## FMX Workflow Label Hit Testing

On August 6, 2026, testing found that the left workflow labels displayed their
assigned `OnClick` events in the FMX resource but did not respond to the mouse.
The cause was FireMonkey's `TLabel` default: `HitTest` is `False`, so pointer
events pass through the label even when an `OnClick` handler is assigned.

All seven workflow labels now persist `HitTest = True` in
`DAT.Studio.MainForm.fmx`. This keeps the setting visible and editable in the
Object Inspector and requires no runtime UI construction. The direct FMX form
smoke test verifies every workflow label's hit-test state, verifies the
navigation event wiring, and activates the Languages page through its persisted
label event.

## Approved API-Free Product Direction

On August 7, 2026, the developer approved a professional refinement plan after
an architectural comparison with Poker Galaxy and a written Codex/Claude
review.

The Studio's product is translation management, validation, packaging, and
Delphi integration. Translation creation is a separate input supplied by a
human, AI assistant, imported file, translation memory, or optional provider.
Provider accounts are not prerequisites for the core workflow, and translated
applications remain entirely offline.

The existing JSON catalog, runtime packs, scanners, VCL and FMX adapters,
transactional integration, credential security, and provider clients are
preserved. This is a targeted correction and proof program, not a rewrite.

The review identified four release-significant gaps:

1. Designer-property entries are applied automatically, while scanned Pascal
   `resourcestring` entries require explicit developer calls to the generated
   `TranslateText` function. Catalog completeness must not imply automatic
   runtime coverage.
2. The current literal placeholder signature does not correctly model valid
   sequential-to-indexed Delphi `Format` argument reordering.
3. Exact-source translation reuse currently applies work across stable keys
   automatically. Cross-key reuse must become a ranked suggestion requiring
   explicit acceptance and must never copy approval status automatically.
4. Integration currently presents affected files and descriptions but not a
   complete exact textual review. Pascal and project changes require a
   read-only exact diff before Apply can be described as safely reviewable.

The active milestone adds robust development JSON and UTF-8 CSV interchange,
then proves the entire API-free workflow on one authorized real FMX project and
one authorized real VCL project under Win32 and Win64. Provider functionality
remains available but will be positioned as optional.

The authoritative staged plan and release gates are recorded in
`API-Free Workflow Plan.md`.

## Implemented API-Free Stages 1-4

Stages 1 through 4 were implemented and validated on August 7, 2026.

### Runtime Coverage Contract

Development catalog schema version 2 adds `runtimeApplication` and
`runtimeWiringConfirmed` to each entry. Form properties are classified as
automatic and are applied by the framework adapter. Pascal `resourcestring`
entries are classified as `manualTranslateText`; the developer must call the
generated `TranslateText` function explicitly and can record that wiring as
confirmed.

The Languages page displays the selected entry's runtime mode, persists a
designer-owned manual-wiring checkbox, and reports separate translated-entry,
automatic-runtime, and confirmed-manual-wiring totals. Unconfirmed manual
wiring produces a validation warning rather than silently implying runtime
coverage or blocking an intentional pack export. Existing schema version 1
catalogs derive the runtime mode from their recorded source kind when loaded.

### CSV Interchange

The existing development JSON remains the lossless canonical catalog. The
Languages page now also contains designer-owned Export CSV and Import CSV
controls and configured FMX file dialogs.

CSV export uses UTF-8 with a BOM and quotes every field. Its stable columns are
Key, SourceText, Translation, Status, Context, SourceChecksum, and
RuntimeApplication. The parser supports commas, escaped quotes, Unicode, and
embedded CR/LF text.

Import is analyzed in memory before the developer is offered Apply. It matches
only by stable key, reports duplicate and unknown keys, rejects stale source
text/checksums, preserves missing rows, and protects Reviewed and Approved
entries. Accepted text is marked Imported, never Approved. A malformed or
canceled import makes no catalog changes.

### Delphi Placeholder Validation

Placeholder validation now resolves Delphi `Format` arguments by identity
instead of comparing literal token strings. Sequential arguments advance from
the current index; an explicit `N:` index selects argument N and advances the
next argument to N+1, matching RAD Studio 37 behavior characterized against
`System.SysUtils.Format`.

The validator accepts valid reordering such as three sequential `%s`
placeholders becoming `%2:s`, `%0:s`, `%1:s`. It rejects missing, additional,
or incompatible integer, float, pointer, and string argument groups. Escaped
`%%`, literal width, and precision text do not create translation arguments.

### Explicit Translation Suggestions

The prior provider path automatically copied exact reviewed translations by
source text across stable keys. That behavior was removed.

For the selected entry, the Languages page now ranks exact-source Reviewed or
Approved entries using same-form, same-component-class/property,
same-property, and same-source-kind signals. The Studio changes nothing until
the developer clicks the designer-owned Accept button. Acceptance copies only
the translated text, records Edited status, and never copies Reviewed or
Approved status.

Optional provider translation now sends every unresolved eligible string after
confirmation and does not perform any hidden local cross-key reuse.

### Stage 1-4 Validation

The foundation suite verifies:

- Schema version 2 JSON round trips and runtime-wiring persistence.
- UTF-8 BOM CSV export.
- Quoted commas, quotes, Unicode, and embedded line breaks.
- Staged import and Imported status.
- Reviewed/Approved protection.
- Stale checksum rejection.
- Valid indexed placeholder reordering.
- Incompatible and missing placeholder rejection.
- Nonblocking manual-wiring warnings.

The full foundation, VCL runtime, FMX runtime, generated integration, and
transactional integration suite passed under Win32 and Win64. The updated FMX
form streamed successfully under both architectures. Debug and Release builds
and launch smoke tests passed for Win32 and Win64.

## Completed Professional Validation Stages 5-10

Stages 5 through 10 were implemented and validated on August 7, 2026.

### Exact Integration Review

`TIntegrationFileChange.ExactReviewText` now produces a complete line-numbered
original/proposed diff using a longest-common-subsequence comparison. Removed,
added, and unchanged lines remain visible; newly generated files are shown in
full. The Integration page owns a designer-authored read-only monospace review
memo and final review checkbox.

Selecting a changed file records it as viewed. The checkbox remains disabled
until every changed file has been viewed, and Apply remains disabled until the
developer explicitly checks the confirmation. Rebuilding or restoring a plan
clears this state.

### Optional Provider Positioning

The six required workflow pages remain Project, Scan, Languages, Validation,
Export, and Integration. Provider configuration is labeled Optional Provider,
and provider translation is labeled Optional Provider Translation. The UI and
documentation state that no provider or key is required for CSV/JSON
interchange or offline target execution.

### Linguistic State and Runtime Readiness

The Languages page now provides designer-authored Mark Reviewed and Approve
actions. A blank translation cannot be reviewed, and approval requires Reviewed
status first. The readiness summary reports translated count, Reviewed-or-
better count, Approved count, automatic runtime coverage, and confirmed manual
wiring independently. Structural validity never grants linguistic approval.

### FMX and VCL API-Free Reference Pilots

The foundation workflow scans each real compilable sample project, creates a
catalog, exports deterministic Italian UTF-8 CSV, imports it into a fresh
catalog as Imported, explicitly advances entries through Reviewed and Approved,
validates them, saves development JSON, and exports the runtime pack.

`RunRuntimeSmokeTests.ps1` then generates and applies integration, builds the
integrated VCL and FMX targets with Win32 and Win64, deploys the Italian pack,
writes a temporary `it-IT` preference, launches each executable without an
Internet dependency, and requires the Italian main-window title. The script
restores any prior per-user preferences and cleans temporary output.

Representative VCL and FMX forms were captured and visually inspected. Titles,
headings, labels, buttons, memo text, and the visible FMX Language menu were
translated without observed clipping or overlap.

### FMX Form Lifecycle Correction

The FMX pilot exposed a real lifecycle defect: applying translation to the
first FMX form in the DPR immediately after `Application.CreateForm` could
produce an asynchronous access violation even though an in-memory adapter test
passed.

FMX integration now preserves an existing root `OnCreate` handler or persists
`OnCreate = datTranslationFormCreate` in the FMX resource. It adds
`ApplyTranslation(Self)` to the corresponding Pascal handler and skips the
unsafe first-form DPR call. This keeps the event designer-visible and applies
text only after FMX has completed streaming. VCL continues to apply its first
form through the DPR startup path.

### Stage 5-10 Validation

The strengthened Win32 and Win64 runtime suite passed:

- Project detection and real VCL/FMX scanning.
- Development JSON and UTF-8 CSV round trips.
- Imported, Reviewed, and Approved state progression.
- Structural validation and runtime-pack export.
- Exact integration diff and review-control assertions.
- Generated application/runtime units.
- Integrated VCL and FMX builds.
- Offline Italian deployment, preference persistence, and launch-title checks.
- Representative full-form VCL and FMX property application.

Optional live-provider testing remains an external acceptance activity and is
not a release blocker for the API-free workflow.

## In-Place Codex and Claude Translation Architecture

Implemented on August 7, 2026.

The primary workflow no longer assumes a CSV round trip or translation-provider
API. `DAT.Core.AITranslation` coordinates direct edits to the existing
development catalog. The Studio persists all controls in the FMX resource.

### Schema and Provenance

Development schema version 3 adds `translationOrigin`,
`translationConfidence`, and `translationReviewNote`. Origin is independent of
status. An AI result is `aiDraft` with `codex` or `claude` origin; it is not
silently Reviewed or Approved. Legacy catalogs migrate to version 3 in memory.

### Session Safety

Beginning AI Mode first saves the catalog, records its SHA-256 fingerprint,
writes an exact `.pre-ai.json` recovery snapshot, ensures the project-local
`translation-profile.json`, and writes `.ai-instructions.md`. Studio editing,
provider translation, CSV operations, and saving are disabled during the
session.

A designer-owned 1.5-second `TTimer` observes the file fingerprint. Reload is
enabled only after the same changed hash is observed twice. The Studio never
adopts a change merely because the file changed.

Normal catalog saves compare the current disk hash with the hash recorded at
load or save. A mismatch stops the save, preventing stale in-memory data from
overwriting external work.

### Protected Reload

Reload parses both the original snapshot and external catalog. Application,
framework, language, locale formats, entry count/order, stable keys, source
text/checksums, source locations, component context, developer notes, runtime
classification, and wiring confirmation are immutable. Only Needs Translation,
Source Changed, Error, and existing AI Draft entries are eligible.
Machine-translated, Imported, Edited, Reviewed, Approved, Excluded, and
Obsolete entries are protected.

Only translated text, origin, confidence, and review notes are adopted.
Accepted changes are normalized to AI Draft. Any protected mutation rejects the
entire reload and leaves the session active for correction or restore.
Metadata-only confirmation is adopted when an existing translation remains
valid after a source change. Changed entries must identify Codex or Claude and
record high, medium, or low confidence.

### Context and QA

The terminology profile records application description, domain, audience,
tone, formality, protected terms, preferred terminology, and additional
instructions. The generated prompt requires context-aware translation,
placeholder and accelerator preservation, consistent terminology, valid JSON
checkpoints, a second linguistic pass, and final counts.

Validation remains structural and exception-focused. It reports low-confidence
entries, explicit AI review notes, inconsistent translations for repeated
source text, placeholder and accelerator defects, source changes, and manual
runtime wiring. A structurally valid AI draft does not flood the exception list
solely because it has not been marked Reviewed.

### In-Place Release Validation

The August 7, 2026 gate passed:

- Schema version 3, provenance, migration, snapshot, generated contract, valid
  reload, and protected mutation rejection passed in the foundation suite.
- Real VCL and FMX samples completed direct canonical-JSON translation,
  protected reload, AI Draft provenance, review, approval, validation, runtime
  pack export, integration, build, deployment, and Italian launch under Win32
  and Win64.
- The Studio built with zero warnings and errors in Win32/Win64 Debug and
  Release.
- Direct FMX form streaming passed under Win32 and Win64.
- Normal launch and Italian self-localization passed in all four Studio
  configurations.

## Automatic Agent Execution and Maximized UI Revision

`DAT.Agent.Execution` implements the Poker Galaxy principle as an actual
Studio workflow: an already installed and signed-in Codex CLI or Claude Code
process receives the complete translation contract through standard input,
edits the canonical development JSON in the target workspace, and writes
stdout/stderr to a diagnostic log. The designer-owned timer polls the process.
A zero exit triggers protected reload, canonical save, UI refresh, and
validation. Failure or cancellation restores the exact snapshot. Only
non-secret engine, executable-path, and model settings are persisted.

`DAT.Studio.MainForm.fmx` now persists `WindowState = wsMaximized`. Project
details and every workflow page use client alignment; lists, memos, summaries,
buttons, and status areas use designer-persisted anchors. Source language,
target language, text direction, engine, model, provider, and DeepL plan are
list selections. The August 7 visual audit covered Project/Scan, Translate,
Validation, Export, Integration, and Engine Settings at 1600x900 with no
control extending below its page.

## Provider-Only Automatic Translation Revision

Decision date: August 7, 2026

The command-line Codex/Claude experiment is retired. It required developers to
install, locate, authenticate, and maintain another vendor program, which made
the primary workflow harder to understand and support. `DAT.Agent.Execution`,
its smoke test, the process monitor, Prompt/Reload/Cancel controls, executable
and model controls, and project references were removed.

The product now has one automatic translation contract. Provider Settings
selects Google Cloud Translation Basic v2 or DeepL API Free/Pro, manages a
masked key through Windows Credential Manager or process memory, and tests the
connection. Translate Automatically counts eligible unresolved entries, names
the selected provider in its confirmation, translates in bounded batches,
records Google or DeepL provenance, marks results Machine translated, and
saves the canonical development catalog automatically.

`DAT.Studio.MainForm.fmx` remains the sole UI authority. Provider Settings was
re-laid out to use the upper workspace professionally, and Translate now has a
single primary automatic action. No CLI, model, executable, agent status,
Prompt, Reload, cancellation, or monitoring controls remain in the form.

Backward catalog compatibility is preserved: schema values for historical AI
Draft/Codex/Claude provenance can still round-trip, but the Studio no longer
creates them. Existing foundation tests for schema compatibility remain useful
and do not represent a supported current translation path.

## Missing Designer Menu Integration Correction

Correction date: August 7, 2026

The Integration planner already promised to add the named Language menu when
it was absent, but the resource editor previously supported only population of
an existing menu. Package preview therefore failed after reporting
`Existing menu: False`.

`DAT.Integration.MenuResource` now locates the primary form from the first
`Application.CreateForm` call in the DPR. When the named menu is absent, it
reuses an existing framework menu container or persists a new FMX `TMenuBar`
or VCL `TMainMenu`, then adds the named `TMenuItem` and generated language
items. `DAT.Integration.DelphiSource` adds matching form-class component fields
and the appropriate interface menu unit so VCL and FMX resources stream and
remain editable in the Delphi Form Designer. No menu UI is constructed at
runtime.

The planner summary now distinguishes between populating an existing designer
menu and adding one to the primary form. Deterministic regression fixtures
remove all designer menus from the VCL and FMX samples, run transactional
integration, compile the modified targets under Win32 and Win64, deploy their
JSON runtime packs, and verify translated application startup.

## DPR Directive and Integration Page Spacing Correction

Correction date: August 7, 2026

`TDelphiIntegrationSourceEditor.AddProjectUnitReference` previously assumed
that the line immediately before the DPR `begin` was the final `uses` entry.
Normal Delphi projects may place `{$R *.res}` or another compiler directive
between the terminated `uses` clause and `begin`. The editor now searches
backward for the actual semicolon-terminated unit reference, changes that
terminator to a comma, inserts the generated translation unit before the
directive, and leaves the directive in its original position. A deterministic
WebsiteAnalytics-style DPR fixture protects this layout.

The designer-authored Integration page now provides larger gutters between
the menu-name field, Build Integration Plan button, plan list, Exact changes
heading, exact-diff memo, and review controls. The list and memo retain bottom
anchors and expand with the maximized window. `StudioFormSmokeTests` asserts
the minimum vertical and horizontal separation under Win32 and Win64.

## Implementation Uses and Backup Integrity Correction

Correction date: August 7, 2026

Some conventional form units place `{$R *.fmx}` or `{$R *.dfm}` immediately
after `implementation` and put their implementation `uses` clause below that
directive. The integration source editor previously stopped at the resource
directive and inserted a second `uses` clause. It now scans past compiler
directives, merges the generated translation unit into the existing clause,
and stops only at a real implementation declaration. A deterministic
WebsiteAnalytics-style fixture protects this form-unit layout.

Transactional integration backup verification now uses SHA-256 rather than
file length. Apply hashes each original, copies it to the backup, and refuses
the first target write unless the copy matches exactly. The manifest records
those hashes. Restore preflights the entire preserved set before touching
source and verifies each restored file afterward. The integration suite deliberately
alters a backup and confirms that Restore rejects it under Win32 and Win64.

## Complete Reset

Implementation date: August 7, 2026

The Integration page includes a designer-authored **Prepare Complete Reset**
control. Reset preparation is read-only. It searches the external project
backup folder and the portable in-project fallback for the newest manifest
that matches the selected project directory and represents the beginning of
an integration cycle. It refuses to guess when no original pre-integration
baseline exists.

The preview identifies the baseline, every original source file to restore,
every generated integration file to remove, and the Studio-owned
`Localization\Development`, `Localization\Languages`, and
`Localization\Runtime` folders. One final confirmation is required; there is
no per-file reset approval loop.

Before reset mutation, `DAT.Integration.Reset` creates a separate
SHA-256-verified **Complete Reset Safety** backup of the project's current
integrated state. It then restores the original transactional baseline and
removes only the three Studio-owned translation folders. Integration backup
folders and unrelated developer files are retained. Any failure invokes the
safety backup automatically. The deterministic reset fixture integrates an
FMX project, resets it, verifies the original form, confirms all three
translation folders are gone, and confirms an unrelated developer file is
unchanged under Win32 and Win64.

## FMX Deferred Form Creation and Generated File Menu

Correction date: August 7, 2026

FireMonkey queues DPR `Application.CreateForm` registrations until
`Application.Run` invokes `RealCreateForms`. Form variables are therefore nil
immediately after DPR `CreateForm` calls. The earlier generator inserted
`ApplyTranslation(FormVariable)` at that unsafe point for secondary forms.
The defect remained hidden while the source language was active, then raised
`EArgumentNilException` after a non-source language was saved and loaded at
the next startup.

FMX integration now removes every DPR form-translation call and retains only
early runtime initialization. Every text FMX form resource receives a
designer-persisted `OnCreate` event. Its existing handler is preserved and
extended when present; otherwise the Studio adds a narrowly scoped
`datTranslationFormCreate` method containing `ApplyTranslation(Self)`. The
generated application wrapper also treats a nil form as a defensive no-op.
VCL retains its safe post-`CreateForm` behavior.

When the Studio creates a new FMX `TMenuBar` or VCL `TMainMenu`, it now adds a
designer-authored **File > Exit** menu before **Language** and generates a
form-owned `Close` handler. Re-integration upgrades an older Studio-generated
menu container that lacks File/Exit without duplicating it. Developer-authored
existing menus are not given new unrelated items automatically.

Regression coverage verifies removal of all multi-form FMX DPR translation
calls, designer startup wiring for secondary forms, nil-safe generated
wrappers, File/Exit fields and events, idempotent re-integration, Win32/Win64
compilation, deployed-pack startup, and the real WebsiteAnalytics restart with
`Selected=es-ES`.

## Runtime Language Refresh and Streamlined Integration

Completion date: August 7, 2026

Integration now scans the selected target while generating its package and
builds `en-US.json` automatically from designer source text. The source locale
therefore behaves like every other real pack: returning from Spanish, French,
or another locale restores every scanned English property deterministically.
Older deployments without an English pack retain the designer-text fallback.

Pack discovery rejects invalid or empty packs, validates application identity,
canonicalizes common native language names, removes duplicate locale codes,
and suppresses a generic language code when a regional pack exists. This keeps
designer-persisted language menus clean and prevents damaged metadata from
surfacing as mojibake.

The generated application unit exposes `ApplyTranslationToOpenForms` and calls
it after each successful selection. Existing VCL and FMX forms change
immediately; later FMX forms continue to use their designer-persisted OnCreate
translation handler. Language choice remains stored per user.

The exact change text remains available for inspection but is no longer a
mandatory file-by-file ceremony. One authorization enables transactional Apply.
Language packs are part of the same verified change set. The designer-authored
Integration page also offers an opt-in platform/configuration build. It invokes
Delphi 37 elevated, deploys package JSON below the standardized executable
folder, reports build/deploy failure separately from successful source
integration, and never launches the target.

## TDATLanguageManager Phase 1 Lifecycle Spike

Completion date: August 8, 2026

The component-first investigation now has compiled Win32 and Win64 lifecycle
evidence. `TDATFMXLanguageManagerSpike` used FireMonkey's additive
`TFormBeforeShownMessage` and translated auto-created, dynamic, modeless,
modal, ownerless, inherited, and popup-style forms after streaming and
`OnCreate` but before `OnShow` and first paint. FMX therefore passed the
one-manager lifecycle gate.

`TDATVCLLanguageManagerSpike` used a private `TApplicationEvents` instance to
inventory `Screen.CustomForms`. It discovered and eventually translated all
normal and MDI cases without replacing `Application.OnIdle`, and a second
`TApplicationEvents` subscriber continued to operate. Every VCL scenario
painted once in the source language before idle application, so idle inventory
is rejected as the sole professional first-display trigger.

An instrumentation-only `Screen.OnActiveFormChange` handler fired after
`OnShow` and before first paint in the primary VCL matrix. Its favorable timing
does not remove the event's single-slot coexistence risk, so it is not approved
as a production default. Windows hooks and per-form components remain rejected.

Both frameworks renamed a second simultaneous instance of the same form
resource with an `_1` suffix. Current runtime keys use the mutable instance
`Name`; the second form was discovered but could not match its catalog keys.
Phase 2 must introduce a scanner-backed stable form identity before production
manager adapters are attempted. Full evidence and reproduction steps are in
`TDATLanguageManager Phase 1 Lifecycle Spike Report.md`.
