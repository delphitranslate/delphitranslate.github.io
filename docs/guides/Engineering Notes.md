# Delphi App Translation Studio — Engineering Notes

Last changed: August 10, 2026

## the first VCL pilot FMX Coverage and Context Repair - August 10, 2026

- The form scanner now reads multiline Delphi string expressions from text FMX/DFM resources.
- The Pascal scanner now inventories supported runtime assignments to `Text`, `Caption`, `Header`, `Hint`, and `TextPrompt`, plus `Format` templates used for visible dynamic text.
- SQL statements and HTML row/cell payloads are rejected even when assigned through a property named `Text`.
- Directories containing a separate nested DPROJ or DPR are excluded. Selecting the first VCL pilot therefore no longer includes its independent database-conversion utility.
- The the first VCL pilot test scan now identifies 257 relevant entries: 213 form properties and 44 runtime UI assignments. This count is evidence for the new scanner, not a universal expected count for future the first VCL pilot revisions.
- Vetted terminology now covers definitive desktop commands, media playback, scheduling phrases, weekday abbreviations, dynamic states, grid headings, and the uptime template. It is applied before provider translation and repairs unreviewed machine drafts such as Spanish `Cerca` for Close or `Casarse` for Wed. Reviewed, Approved, and Edited work remains protected.
- Runtime-pack schema version 2 adds keyed source text, exact source-string translations, and source-template translations while retaining the original keyed dictionaries. The loader remains compatible with schema version 1.
- The FMX runtime now translates anonymous runtime-created components by current source text and can translate formatted dynamic captions. `TDATFMXLanguageManager.AutoRefreshDynamicText` and `DynamicRefreshInterval` are Object Inspector properties; their defaults reapply translations to visible forms every second when application timers or code overwrite UI text.
- The Studio displays a designer-authored dimmed backdrop while the modal Setup Wizard is open.
- No universal control resizing is performed. Automatic resizing would be unsafe for carefully designed target layouts; accurate, shorter terminology and complete text capture resolve the demonstrated the first VCL pilot crowding without rearranging the application.

## Contextual Translation Engine - August 10, 2026

- Development-catalog schema version 5 adds `contextKind`, `contextDescription`, `semanticConcept`, and `contextConfidence` to every entry.
- Scan analysis distinguishes UI roles and common ambiguous concepts. `Play` may become `media.play`, `game.play`, `instrument.play`, or `ambiguous.play`; `Schedule` may become a command or a noun.
- Resolution order is contextual translation memory, vetted UI terminology, then the configured provider. Reused terms remain Machine translated and do not inherit approval.
- DeepL requests include the official `context` field. Google Basic v2 receives no unsupported fields; short or unknown-context Google results are marked for review.
- Consistency validation is scoped by source text plus semantic context, so legitimate contextual differences do not create false inconsistency warnings.
- Wizard DPROJ settings are inserted inside Delphi's existing native Base compiler property group. The target project must be closed in RAD Studio first.
- Portable deployment selects a folder containing the exact project EXE and writes only `Localization\Languages` below that folder.

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
`<BackupDrive>:\ProjectName Backup\Translation Integration timestamp`. On systems without a
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
`DelphiAppTranslationStudio/Providers/`. A session-only key remains in process
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
FMXPilot-style DPR fixture protects this layout.

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
FMXPilot-style fixture protects this form-unit layout.

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
compilation, deployed-pack startup, and the real FMXPilot restart with
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

Completion date: August 9, 2026

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

## TDATLanguageManager Phase 2 Shared Core

Completion date: August 8, 2026

The framework-neutral `TDATCustomLanguageManager` core is implemented in
`source/components/DAT.Components.Core.pas`. It owns the existing runtime,
preference loading, language selection, application generations, exclusions,
diagnostics, error policy, and non-owning managed-form tracking. Main-thread and
reentrancy guards protect all state-changing operations. Destruction
notifications remove tracked components without granting the manager ownership.

Phase 1's duplicate-instance defect is addressed by scanner-backed class to
resource-root mappings such as `TfrmOrders=frmOrders`. Catalog lookup no longer
depends on an instance name that Delphi may change to `frmOrders_1`. Blank
Object Inspector string-list rows are ignored; malformed or conflicting
nonblank mappings fail clearly.

The unit imports no VCL or FMX namespaces. An isolated mock-adapter suite passed
under Delphi 37 for Win32 and Win64, covering initialization, language changes,
preferences, stable identities, generations, exclusions, errors, missing-pack
policies, main-thread enforcement, reentrancy, immutable configuration, and
deterministic tracking cleanup. The Phase 1 lifecycle matrix also reran without
regression on both targets. See
`TDATLanguageManager Phase 2 Shared Core Report.md` for the full evidence and
the Phase 3 FMX adapter gate.

## TDATLanguageManager Phase 3 FMX Adapter

Completion date: August 8, 2026

The production `TDATFMXLanguageManager` adapter now joins the Phase 2 shared
core to FireMonkey. It uses additive `TFormBeforeShownMessage` and
`TFormReleasedMessage` subscriptions, stores their identifiers, and
unsubscribes deterministically. It neither replaces a global event nor polls at
idle. New FMX forms translate after streaming and creation but before `OnShow`
and first paint. Visible and optionally hidden forms are inventoried through
`Screen.Forms` and `Screen.PopupForms` for immediate language changes.

`DAT.Runtime.FMX` now offers a backward-compatible overload accepting the
scanner's stable form identity and the state-preservation policy. Duplicate
instances such as `frmOrders_1` therefore use keys rooted at `frmOrders`.
Translated string collections retain `ItemIndex` when preservation is enabled,
and suppress `OnChange` while the items are replaced.

The production suite passed on Win32 and Win64 for before-show timing, inherited
and popup forms, duplicate-instance identity, immediate language switching,
hidden-form catch-up, explicit application, combo-box selection preservation,
and released-form cleanup. Core, runtime, integration, and lifecycle regression
suites also pass. The pristine GA4 application remains untouched. See
`TDATLanguageManager Phase 3 FMX Adapter Report.md` for complete evidence and
the remaining component-product boundaries.

## TDATLanguageManager Phase 4 VCL Adapter

Completion date: August 8, 2026

The production `TDATVCLLanguageManager` uses a private `TApplicationEvents`
instance for additive `OnIdle` and `OnModalBegin` handling. Idle inventory
discovers normal and MDI forms without replacing `Application.OnIdle` or
changing its `Done` flag. Modal inventory occurs before VCL calls `Show`, so a
modal form is translated before `OnShow`. A configurable 100 ms idle throttle
limits repeated inventory overhead.

VCL has no public additive before-show event for every dynamic modeless form.
The production contract therefore preserves the proven boundary: such forms may
paint once in the source language before idle discovery. A strict pre-display
case can call the manager's `ApplyToForm` after construction and before `Show`.
The exclusive `Screen.OnActiveFormChange` signal remains rejected.

The VCL applicator now accepts stable scanner identity and the preservation
policy while retaining its original overload. Production Win32/Win64 tests pass
for discovery, modal pre-show application, duplicate instances, immediate
switching, hidden forms, selection preservation, independent application-event
subscribers, explicit pre-display application, and deterministic cleanup. See
`TDATLanguageManager Phase 4 VCL Adapter Report.md` for the full bounded
contract and Phase 5 gate.

## TDATLanguageManager Phase 5 Control-State Hardening

Completion date: August 8, 2026

Both applicators now implement the manager's `PreserveControlState` policy as a
concrete cross-framework contract. Writable FMX edit text and writable FMX/VCL
memo lines are treated as live user data and are not replaced; read-only memo
instructions remain translatable. Edit and memo selection ranges, current
focus, and list/combo `ItemIndex` are restored. `OnChange` remains detached and
restored around translated string-collection replacement.

The FMX and VCL production suites populate editable text and memo data, select
text ranges, focus the edit, attach change handlers, and switch languages. On
Win32 and Win64, both retain the data, selections, focus, and date-range index;
the selected item changes language in place and no protected change handler
fires. The full runtime and integration suite also passes on both targets. See
`TDATLanguageManager Phase 5 Control State Report.md` for the exact contract,
test evidence, opt-out behavior, and custom-control boundary.

## TDATLanguageManager Phase 6 Runtime and Design Packages

Completion date: August 8, 2026

The distributable package graph now uses one shared runtime package, separate
VCL and FMX runtime packages, and separate VCL and FMX design-time packages.
This prevents duplicate common units and prevents either framework from leaking
into the other package. The design registration units expose the applicable
manager on the `DAT Localization` Tool Palette page.

All runtime packages build for Win32 and Win64. Both design packages build for
the installed Win32 RAD Studio IDE. Designer-authored DFM and FMX host fixtures
containing the manager compile and stream their Object Inspector values on both
application architectures. Packages were built and tested but were not silently
installed into RAD Studio. See `TDATLanguageManager Phase 6 Package Report.md`.

## TDATLanguageManager Phase 7 Optional Language Selectors

Completion date: August 8, 2026

The VCL and FMX packages now include framework-native language combo boxes.
They are ordinary designer-owned controls whose `LanguageManager`,
`AutoPopulate`, and `ShowLanguageCode` properties are configured in the Object
Inspector. No visual UI is created in code.

At runtime the selectors populate from the manager's validated JSON pack
descriptors, display canonical native language names, select the active locale,
and call `SelectLanguage` when the user chooses another locale. Their inherited
change notification remains available to the application. Public refresh and
code-selection methods cover late pack deployment and custom navigation.

Win32 and Win64 tests prove package compilation, DFM/FMX streaming, typed
manager-reference streaming, two-pack discovery, and language selection. See
`TDATLanguageManager Phase 7 Language Selector Report.md`.

## TDATLanguageManager Phase 8 Non-Mutating Studio Integration

Completion date: August 8, 2026

The Studio's Integration page now defaults to Component Integration. It creates
a self-contained kit under `export\component-integration` containing validated
JSON packs, the English source pack, applicable runtime/component units, a JSON
manifest, deployment script, and ordered IDE instructions. It performs no write
inside the selected target project.

Automatic Source Integration remains available as an explicitly labeled
advanced fallback. Its transactional safety model is unchanged. In Component
Integration mode, the mutation, authorization, restore, and automatic-build
controls are hidden, while generated files can be inspected in the existing
read-only preview area.

Win32/Win64 foundation tests compare SHA-256 hashes of VCL and FMX sample
project/form files before and after kit generation. All hashes remain equal.
Both Studio architectures build, stream the designer-authored form, and pass
launch smoke testing. See
`TDATLanguageManager Phase 8 Component Integration Report.md`.

## TDATLanguageManager Phase 9 Real Application Pilots

Completion date: August 8, 2026

Disposable real-application copies proved the component-first workflow without
generated translation units or project startup edits. The pristine Website
Analytics FMX application built on Win32 and Win64 and displayed its first form
as `Analítica del sitio web`. The second VCL pilot built on both architectures
and displayed its primary VCL form as `Lector de PDF del periódico`.

Each pilot used one designer-streamed manager on the primary form, copied
component/runtime units, validated English and Spanish JSON packs, and an
executable-folder preference for deterministic testing. Ordinary forms were
unchanged. The original applications were accessed read-only and the disposable
copies were removed after testing.

An attempted the first VCL pilot VCL runtime pilot exposed an unrelated missing SQLite
deployment database after compiling successfully on both architectures. It was
replaced with the self-contained VCL pilot rather than weakening or bypassing
The first VCL pilot's startup contract. See
`TDATLanguageManager Phase 9 Real Application Pilot Report.md`.

## TDATLanguageManager Phase 10 Release Decision

Completed August 8, 2026.

Component Integration is now the recommended production workflow. Automatic
Source Integration remains an advanced fallback. The complete release harness
passed in one uninterrupted run across Debug and Release, Win32 and Win64,
runtime/design packages, selector streaming and behavior, component core, FMX
and VCL lifecycle suites, foundation/runtime/integration suites, Studio form
streaming, ordinary launch, and Italian self-localization.

During the gate, package fixture executables were isolated below
`bin\tests\packages\<Platform>\<Configuration>`. This prevents their local
FMXDesignHost JSON fixture from shadowing the Studio's own localization pack.
The final repair and validation evidence is recorded in
`TDATLanguageManager Phase 10 Release Decision Report.md`.

## Testing Corrections and Seamless Component Setup

Completion date: August 8, 2026

The post-release manual test pass identified usability and installation defects
that automated functional tests had not exposed. The Studio now changes the
bottom status guidance with every workflow page, uses explicit list-row heights
to prevent scroll repaint overlap, presents encoding-safe language names,
exposes the full JSON catalog path as a File Explorer link, spaces the locale
and action rows, wraps the integration summary, and offers confirmed catalog-
wide Review All and Approve All operations. Validation explains severity and
opens an entry on Translate when its issue is double-clicked.

The earlier README instruction to install a `.dpk` was incorrect and led users
into Delphi's Install Component wizard. A `.dpk` is package source; Delphi
installs a compiled Win32 design `.bpl` through Install Packages. More
importantly, the former design BPL imported DAT core and framework runtime BPLs,
so the IDE could report "specified module could not be found" even when the
design BPL itself existed. Each design package now contains the DAT runtime and
component units directly and imports only Embarcadero runtime/framework BPLs.

Automatic BPL installation is retired from the product workflow. It is not
shown in the Studio UI, is not copied into generated component kits, and is not
documented as an end-user option. The Studio does not copy BPLs into Delphi
folders and does not write BDS Known Packages registry values. RAD Studio owns
registration through `Component > Install Packages > Add`.

Each newly generated component kit replaces its previous output directory so
obsolete files cannot survive from an older kit. Per-project kits contain no
BPLs. Delphi instead registers the applicable, verified, self-contained Win32
design BPL from the stable Studio build tree under
`bin\packages\Win32\Release`. This separation prevents Delphi from depending on
a volatile export path and lets the Studio regenerate kits without encountering
a loaded-package file lock. Runtime BPLs are unnecessary because normally
linked target projects compile the kit's `ComponentSource` units into the
executable. The Studio's `Show Design BPL` action selects the exact stable file
in Explorer; `Open Kit Folder` opens the separate non-mutating kit. Instructions
explicitly prohibit Delphi's Install Component wizard and `.dpk` package-source
selection.

The older internal installer tooling remains in `tools` only for engineering
history and controlled diagnostics. It is unsupported, hidden, and excluded
from all generated kits. It must not be invoked by the Studio or by acceptance
instructions.

## Remediation Group 1: Runtime Lifecycle and State Ownership

Completion date: August 9, 2026

The development catalog contract described in this earlier milestone was schema version 4. The current contextual catalog is schema version 5. Every entry records a
runtime text role: static text, dynamic value, runtime template, data value,
identifier, or excluded content. The scanner assigns conservative roles during
form and resourcestring extraction. Catalog merge maps those roles to automatic,
manual, or not-applied runtime behavior.

Runtime packs retain schema version 1 compatibility. The existing `strings`
object now contains only static interface text that the FMX/VCL form applicators
may write automatically. The optional `templates` object contains dynamic and
runtime-message translations for explicit `Translate` or `FormatTemplate` use.
Data, identifiers, and excluded content are omitted from runtime application.

The FMX lifecycle handler performs a forced static-text pass at
`TFormBeforeShownMessage`. This corrects late startup assignments before first
display without advancing the language generation. Dynamic and data state are
safe because their keys are not present in the automatic dictionary. Existing
editable-value, selection, focus, combo selection, and event-suppression
protections remain in force.

Foundation, shared-core, FMX, VCL, package, design-streaming, Studio build, and
Studio launch validation passed for Win32 and Win64. The the FireMonkey pilot pilot
was not modified. Full implementation evidence and developer validation steps
are recorded in `Translation Studio Group 1 Runtime Lifecycle and State
Ownership Report.md`.

### Group 1 acceptance correction: scan preview and translation counts

Completion date: August 9, 2026

The scan-result list now flattens embedded CR/LF characters only in its visual
preview. The catalog retains the exact source text. This prevents multiline
values from painting over the next fixed-height FMX list row while preserving
the data used for translation and runtime keys.

The Translate page gives the clickable JSON catalog path a dedicated full-width
row and places automatic-translation and CSV actions on a separate row. Form
smoke tests enforce clearance between the catalog path, action row, and catalog
entry list.

The automatic-translation confirmation now reports active catalog entries,
unresolved translation candidates, protected/non-translatable entries, and
already-resolved entries separately. In the clean the FireMonkey pilot acceptance
catalog, the 173 scanned entries comprise 151 static text entries, 4 dynamic
values, 7 data values, and 11 explicitly excluded entries. The resulting
statuses are 155 `needsTranslation` and 18 `excluded`; the lower API candidate
count is deliberate runtime-state protection, not a scan loss.

The complete Debug/Release, Win32/Win64 release validation passed after these
corrections, including form streaming, Studio launch, and self-localization.

### Export-result accuracy and navigation

Completion date: August 9, 2026

The Export page reports the number of entries actually written to the runtime
pack rather than the total number of development-catalog entries. Protected,
excluded, and obsolete entries are not included in that success count. For the
The FireMonkey pilot acceptance catalog, the correct result is 155 runtime entries
(151 static strings and 4 runtime templates), not the 173-entry development
catalog total.

The generated runtime-pack path is displayed as a larger blue active link.
Selecting it opens File Explorer with the exact JSON file selected. Studio form
smoke tests require the link to remain readable, clickable, and designer-wired.

### Manual component-integration save checkpoint

Completion date: August 10, 2026

Acceptance testing confirmed that building and deploying packs is insufficient
if newly placed designer components were not first persisted. The supported
manual workflow now requires `File > Save All`, closing and reopening the
primary form, confirming that the manager and selector remain visible with
their Object Inspector properties, and inspecting the on-disk Git diff before
the first target build. Expected changed files include the primary `.fmx`, its
`.pas` unit, and the `.dproj` search-path metadata. Testing must stop if those
files do not contain the component integration.

The deployment instructions now use an explicit PowerShell executable with
`-NoProfile -ExecutionPolicy Bypass -File`, preventing the documented local
execution-policy failure.

### the FireMonkey pilot untranslated-text deep dive

Completion date: August 10, 2026

The third pilot pass confirmed that the runtime pack was loading successfully;
the remaining English was not a provider or JSON failure. The target form's
startup, data-refresh, chart-paint, and authentication routines assigned English
literals after the component had applied the static form translations. Those
assignments included selector items, status text, tile headings, date-range
headings, owner-drawn empty-state messages, and grid headings.

The supported ownership rule is now explicit in the pilot: designer-owned text
is applied automatically, while application-owned text is declared as Delphi
`resourcestring` content and requested through `Translate` or
`FormatTemplate` at the point where the application writes it. A visible-form
guard protects the target's `OnLanguageChanged` refresh from running during FMX
form streaming. This keeps first paint deterministic and still refreshes
application-owned presentation when a user changes language later.

FMX `TStringColumn` and related grid-column `Header` properties are now included
in both form scanning and runtime application. This closes the separate grid
coverage gap; it does not change or translate row data. Foundation regression
tests assert the new scanner rule, and the Win32/Win64 runtime suites cover the
unchanged component-state protections.

# Setup Wizard (2026-08-10)

The recommended first-run path is now the designer-authored FMX Setup
Wizard (`DAT.Studio.SetupWizard.pas/.fmx`). It is opened by **Start Setup
Wizard** on the Studio's Project page. The existing seven-page Studio workflow
remains available as the advanced/manual fallback.

The wizard has eight controlled steps: Welcome, Delphi Project, Languages,
Translation Service, Scan Project, Delphi Component, Review and Authorize, and
Process and Finish. Completed steps are selectable in the left rail; future
steps cannot be skipped. Back and Cancel remain available until the developer
authorizes final processing. During final processing the rail, Back, Cancel,
and window closing are disabled. If processing stops on an error, the wizard
returns control without automatically editing Delphi Pascal, form, or DPR
files. A DPROJ configuration change is allowed only during authorized final
processing and is transactionally backed up.

Final processing performs these operations in order:

1. Create a required timestamped ZIP under the user's Documents folder.
2. Send only unresolved, eligible entries to Google Cloud Translation or
   DeepL; reviewed and approved work is preserved.
3. Save the development JSON catalog.
4. Validate the catalog and stop on blocking errors.
5. Export the offline runtime JSON pack.
6. Generate the component integration kit under the Studio `export` folder.
7. Deploy packs to existing detected output folders.
8. Add one marked DPROJ block that inherits the generated ComponentSource
   Search Path through all configurations/platforms and runs pack deployment
   after each future build.
9. Write a completion report and manual fallback PowerShell commands using
   `-NoProfile -ExecutionPolicy Bypass`.

The wizard does not automate RAD Studio design-package registration. It opens
the exact verified Win32 Release design BPL and instructs the developer to use
**Component > Install Packages > Add**. It also does not place controls on a
target form; those edits remain visible, designer-authored Delphi changes.

The Finish page can repeat pack deployment for build output folders that
already exist. Normal future deployment is automatic through the active
`DCC_ExeOutput`, covering Win32/Win64 and Debug/Release without four manual
commands. Every command remains visible and copyable as a fallback.

The Wizard displays the detected `ApplicationId` explicitly and provides a
Copy ID action. A visible language choice is required: the supplied language
combo box is the default, while a connected Language menu is the supported
alternative. Calling the selector simply optional is prohibited because it
would leave ordinary users unable to change languages.

# Localization Intelligence and Iterative Update Workflow (2026-08-11)

The Setup Wizard now distinguishes **Create New Translation** from **Update
Existing Translation**, with **Automatic (Recommended)** selecting the safe
choice from the detected project/language catalog. Update mode preserves
reviewed, approved, and otherwise resolved entries while scanning and
translating only new or source-changed work.

The designer-authored FMX Localization Review Center adds seven coordinated
capabilities without automatically rewriting target forms or Pascal source:

1. explicit existing-translation update workflow;
2. read-only DFM/FMX layout inventory and overflow/overlap estimates;
3. approved project glossary overrides with semantic concepts;
4. confidence, untranslated-text, and disagreement findings;
5. self-contained HTML visual-review packages for fluent reviewers;
6. a common multilingual estimated-width envelope across project catalogs;
7. checksum-backed layout proposals with pending, accepted, rejected, and
   manual decisions.

Review packages and layout decisions are stored below the Studio's
`export\localization-review` directory. Layout results are advisory estimates;
they are intentionally separated from runtime language packs. Project glossary
terms are staged outside the target before authorization, applied ahead of
built-in terminology and provider translation, and persisted under the target's
`Localization\Glossaries` directory only during authorized final processing.

## Documentation backlog

Formal User Guide, Setup Wizard Guide, Engineering Guide, and test-guide
revisions are intentionally deferred until the localization-intelligence and
iterative-update workflows complete acceptance testing. Do not regenerate the
DOCX/PDF guides before that checkpoint. Provide current, chat-based test
instructions on request in the meantime.

## Future: Full Reset

A future Full Reset command should provide a conservative, preview-first way
to start a localization project again. It may remove only Studio-owned
development catalogs, runtime packs, generated component kits, review
decisions, saved language preferences, and deployment caches selected by the
developer. It must never delete or rewrite developer-owned PAS, FMX, DFM, DPR,
or DPROJ files. Before reset, the Studio should show the exact paths and files,
create a timestamped safety backup, and offer narrower choices such as Reset
One Language and Reset Generated Output Only. Git or a pristine project copy
remains the authoritative recovery mechanism.

## Wizard acceptance corrections (2026-08-11)

Manual component instructions now state explicitly that the displayed project
path, Application ID, and executable name are detected from the project the
developer selected; example or private project names are not embedded in the
instructions. The manual RAD Studio phase explains the boundary between Wizard
automation and the approved Delphi designer workflow. Its required confirmation
uses an orange notice and displays a modal explanation if Next is selected
without confirmation.

Multilingual envelope generation now merges values in an unsorted list and
sorts only after all width updates are complete. This prevents the Delphi
`Operation not allowed on sorted list` exception observed during Wizard final
processing. Foundation regression coverage contains two entries for the same
control and verifies that the larger envelope value can replace the first.

# Single-Pass Wizard Review and Finalization (2026-08-12)

The Setup Wizard now keeps one protected final-processing session active from
automatic translation through developer review and definitive output. After
the development catalog and initial review artifacts are created, the Wizard
opens the modal Localization Review Center. Back, Cancel, and the setup-step
rail remain unavailable during this interval; closing the Review Center does
not cancel processing.

When review closes, the same processing call reloads the saved project
glossary, applies approved terminology to the in-memory catalog, reapplies
authoritative terminology, saves the reviewed development catalog, and
regenerates review/layout artifacts while preserving checksum-backed layout
decisions. Only then does it run final validation, export the runtime JSON pack,
generate the component kit, and configure deployment. A second Wizard pass is
no longer part of the normal workflow.

The completion report records that localization review occurred inside the
same Wizard processing pass before final export. The completion-page review
button is retained as a disabled `Review Completed` indicator, preventing a
post-export review from being mistaken for part of the completed transaction.

# Complete To-Do Repair Pass (2026-08-14)

This pass addresses the active acceptance-test backlog as a single repair
batch rather than a narrowed subset. The implemented changes are:

1. Wizard final-processing and optional build controls now hold Finish disabled
   while build/deploy work is in progress, and the finish page is widened so
   command buttons and build controls are not clipped.
2. Build commands are launched through a hidden `CreateProcess` path with
   `CREATE_NO_WINDOW` to avoid visible command processor popups.
3. Deployment to configured application folders now deploys JSON language
   packs every time and copies the executable when the destination executable
   is missing or when the developer explicitly authorizes replacement.
4. Runtime source-text restore and dynamic replacement use whole-term matching
   so a translation is not inserted inside a larger English word.
5. Scanning intentionally does not sweep every standalone HTML file under the
   selected project tree. Web sites, help pages, release notes, and download
   pages are separate localization assets and should not inflate the app UI
   catalog. Pascal-assembled browser UI can still be scanned from explicit
   runtime HTML text.
6. Accepted layout proposals may now carry bounded position adjustments
   (`Left`, `Top`, `Position.X`, `Position.Y`) as well as safe size/wrap rules.
   The exporter and FMX/VCL runtime loaders both preserve and apply those
   accepted rules.
7. Layout review now proposes conservative horizontal and vertical separation
   moves when translated controls overlap and the target control is movable.
8. Pre-change backup ZIP files are ignored by Git so safety backups are kept
   locally without being accidentally published.

RAD Studio package rebuilds must be performed with the IDE closed. If
`bds.exe` has a design package loaded, Windows locks the design BPL and the
package output cannot be replaced safely.

# Scan and Layout Correction Pass (2026-08-14)

The the first VCL pilot acceptance test exposed two root causes that made the previous
repair appear to do nothing:

1. the scanner was over-collecting project-folder material, producing thousands
   of non-UI strings from old tools, generated HTML, web pages, logs, and data
   population calls; and
2. layout review could propose useful move adjustments, but accepted move
   decisions were not marked as runtime-eligible and therefore were not exported
   into the offline JSON pack.

The scanner is now limited to project-referenced source units and designer
resources. Broad `Items.Add`, `Items.AddObject`, `Lines.Add`, `Strings.Add`,
`FillText`, and `TextOut` harvesting is disabled because those calls commonly
represent data rows, filenames, logs, owner-drawn values, or generated content
rather than stable application captions. Designer-authored Items and Lines
remain covered through FMX/DFM resource scanning.

Layout overlap analysis now checks translated labels against untranslated
neighbor controls as blockers, so labels are no longer allowed to expand under
edit boxes, combo boxes, grids, or other non-translated controls. Accepted safe
move proposals (`Left`, `Top`, `Position.X`, and `Position.Y`) are exported and
applied at runtime along with width, height, word-wrap, and autosize decisions.

The Setup Wizard geometry was also constrained to its visible content card so
project, deployment, scan, and finish pages do not clip controls on normal
desktop screens.

# Framework Parity, Layout Settling, and Grid Columns (2026-08-15 to 2026-08-18)

The VCL side reached parity with FireMonkey. Measurement moved behind a seam so
the analyser measures with the framework the application actually uses: GDI
(`GetTextExtentPoint32`) for VCL, `TTextLayout` for FMX, with DPI pinned to 96
because that is the basis a form was designed at.

Several VCL-specific facts had to be taught to the analyser, each of which had
produced wrong layouts:

1. `TLabel.AutoSize` defaults to True and `WordWrap` to False, the opposite of
   an FMX label. A translated caption therefore stretches a VCL label before any
   rule is applied, and AutoSize has to be cleared before the text is assigned
   rather than after.
2. A `.dfm` records fonts as `Font.Height` in negative pixels, not `Font.Size`
   in points. The conversion is `Round(-Height * 72 / 96)`, matching what
   `TFont` itself does, and fonts inherit down the object tree.
3. A second instance of a form is named `Name_1` by the VCL. The first VCL pilot dialogs
   were left untranslated because the runtime looked up the instance name rather
   than the form identity.
4. Collections (`Columns = <item ... end>`) nest, so a collection `end` must not
   pop the object stack. A `TDBGrid` keeps its headings at
   `Columns[i].Title.Caption`, one level further in than the column itself.

Grid columns are now planned end to end. The analyser measures a heading against
its column and proposes `Columns[i].Width`; the pack carries the rule as a path
rather than a property name; and the VCL applicator resolves the path. Column
widths are applied last, after the grid has its own size.

A settling pass was added after the per-control decisions: rows are levelled,
headings widened and re-centred, lone buttons widened to a comfortable width
(rightward only - a button keeps its place), paragraphs standing together are
given one font size, and wrapped text is narrowed to the width its wrap actually
uses so a block does not read as ragged. Every step is trial-and-revert: a
change that breaks a contract is undone rather than kept.

Two contracts were found to be vacuous and were rebuilt to fail first. Contract
count is now 48 (19 FMX, 29 VCL) plus 3 form-scan and 9 pascal-scan fixtures.

Shared per-language dictionaries were added at
`C:\Users\Public\Documents\Delphi App Translation\Dictionaries`, so approved
wording earned on one application is available to every later one. The shared
dictionary speaks first and the project glossary overrides it.

## Colour is never restored

Restoring a form to its design-time state used to stamp design-time colours back
over an application's own theming, which broke the the first VCL pilot `ApplyTheme` method.
Colour was removed from the snapshot: the translator restores words and
geometry, never appearance.

# Source Encoding Guard (2026-08-19)

Delphi reads a `.pas` without a byte order mark in the ANSI codepage, so a UTF-8
literal saved without a BOM arrives corrupted. This had already produced wrong
text once. `tools/check_source_encoding.ps1` now fails the build if any
`.pas`, `.dpr` or `.dpk` holds a character outside ASCII without a BOM, and it
runs as part of Phase 10 validation.

It has since caught two real defects that would otherwise have shipped: the
German and Spanish vowel sets in the hyphenation dictionaries, and a test
fixture's soft hyphens. Both are written as escapes now.

# Translation Context (2026-08-19)

A provider sees one string at a time. Told only "text used in a desktop
application", it read "Play Date From" as an afternoon arranged between children
and produced Spielverabredungen for a column of bell timings; in Spanish it read
"Close" as the adjective and produced cerca, meaning nearby.

`TScanContextAnalyzer.Enrich` now runs once the scan is complete and writes a
context sentence for every string from what the scan already knows: what kind of
control it is, which screen it is on, the neighbouring column headings of the
same grid, and the semantic concept. No person types anything.

# Hyphenation (2026-08-19)

German builds one word where English uses three, and a single word cannot wrap:
there is no space in Benachrichtigungseinstellungen for a label or a column
heading to break at, so it is simply cut off.

Adding a language now installs a companion hyphenation dictionary beside the
shared terminology, at `...\Delphi App Translation\Hyphenation\<code>.json`. A
dictionary states which letters are vowels in that language, which consonant
groups are one sound and must never be split, how much of a word must be left
whole at each end, and any words whose breaks are known outright. German,
Spanish and French have real rules; any other language gets a conservative
starting file. The files are plain JSON and are meant to be corrected by hand.

The runtime pack carries a soft hyphen (U+00AD) at every allowed break, because
nothing at build time knows how wide a control will end up. Captions only:
format strings are left exactly as written, since their text goes on to be
filled with data and may be compared or parsed.

**The two frameworks differ, and this was measured rather than assumed.**

- FireMonkey honours soft hyphens. A marked word measures exactly as wide as an
  unmarked one (168.5 either way), and breaks at a mark when it has to. Nothing
  needed doing.
- GDI does not. It draws U+00AD as an ordinary hyphen and `DrawText` will not
  break a line at one. The same word measured 205px marked against 170px plain,
  and stayed on one line.

`DAT.Runtime.VCL` therefore resolves the marks itself, in a final pass after
every layout rule has been applied and each control is the size it will really
be. A control that wraps is given a real hyphen and a real line break at the
last mark that fits its width; one that cannot wrap is given the plain word with
the marks removed. No soft hyphen ever reaches a VCL caption.

A `TDBGrid` heading cannot wrap at all, so hyphenation cannot help there - only
the column width can, which the `Columns[i].Width` planning already does.

# Application Domain Profile (2026-08-19)

The first version of the context work recognised six subjects - music,
scheduling, business records, clinical records, email, backups - from keyword
lists. It read the first VCL pilot correctly and would have failed almost everything else:
file and disk utilities, database administration tools, point of sale,
inventory, engineering and instrumentation, laboratory systems, reporting tools,
and the rest of the long tail that Delphi is mostly used for. A recogniser can
only recognise what somebody already thought of, which is the opposite of what
the feature was for.

`DAT.Scan.DomainProfile` replaces it. Nothing is recognised; the application is
read.

**Note on providers.** The original plan was to ask the translation provider to
characterise the application. That is not possible here: the only live providers
are DeepL and Google Translate, which are translation APIs and cannot answer a
question about an application. There is no LLM client in the product - the AI
path in `DAT.Core.AITranslation` is the copy-and-paste workflow, which is human
intervention by definition. The profile is therefore derived offline, which also
means it is deterministic and can be used inside a contract.

Two things come out of reading an application:

1. **Its own vocabulary.** Word frequencies across every scanned string, with
   the furniture of every user interface (File, Edit, Cancel, Save, OK, Close)
   set aside. What remains is characteristic: song, playlist, chime, bell for
   the first VCL pilot; rename, mask, extension, folder for a file renamer. The context
   sentence quotes it directly rather than naming a category.

2. **Which sense of an ambiguous word this application means.** This is the part
   that matters, because most mistranslations are word-sense mistakes rather
   than domain mistakes. A shared list at
   `...\Delphi App Translation\Terms\ambiguous-terms.json` names the English
   words that are ambiguous in a user interface and gives each sense the
   evidence words that would be present if it were the one meant. The
   application's own vocabulary casts the vote.

   Volume is loudness in the first VCL pilot (which says mute, speaker, audio) and a disk
   in a file utility (which says partition, format, drive). Mask is a filename
   pattern where the application talks about filenames. Date is a calendar date.
   Nothing has to know what kind of application it is looking at.

   Where the application settles nothing, nothing is said. A guess between two
   senses is worse than silence: it is a confident instruction to be wrong. A
   word with a single listed sense (close) is always stated, because it is on
   the list for being got wrong rather than for being ambiguous.

The list is about English, the source language, so there is one of it rather
than one per target language.

`ContextSmokeTests` was rewritten to test shape rather than wording - that a
domain sentence is present, that an ambiguous word carries an explicit sense -
because the wording is now read from each application rather than written in the
source. It covers the first VCL pilot, a file-renaming utility that no domain list would
have held, and an application that settles nothing.

# Right-to-Left Mirroring (2026-08-20)

Arabic, Hebrew, Farsi and Urdu were offered by the wizard and marked `rtl` in
the catalog, and the value travelled all the way into the runtime pack as
`direction` - where nothing read it. `BiDiMode` appeared nowhere in the source.
A user could pick Arabic, get a clean run, and receive an application with
Arabic text laid out left to right: labels on the wrong side, controls in Latin
order, alignment reversed. That is worse than refusing, because it looks like
it worked.

A right-to-left interface is a reflected interface, not merely reversed text.

## Measured before it was designed

Two experiments settled the shape of the work. Both are worth repeating if this
is ever revisited.

**BiDiMode.** The obvious choice is the wrong one.

| Mode | Flips alignment | RTL reading | Left scroll bar |
|---|---|---|---|
| `bdRightToLeft` | yes | yes | yes |
| `bdRightToLeftNoAlign` | no | yes | yes |
| `bdRightToLeftReadingOnly` | no | yes | no |

A label set `taLeftJustify` draws as `DT_RIGHT` under `bdRightToLeft`. Since
the planner already decides alignment for every control and states it in the
pack, that flip would land on top of ours and undo it - `taRightJustify` drawn
as `DT_LEFT`, silently. `bdRightToLeftNoAlign` gives the same reading order and
the same scroll bar and leaves alignment alone, so one side owns the decision.

`BiDiMode` does not move child controls in any mode, so it neither duplicates
nor fights the mirrored coordinates.

**Numerals.** Nothing needed doing, and this was checked rather than assumed.
Given a Hebrew word followed by `2026`, GDI reorders the letters and leaves the
digits: logical `[05E9][05DC][05D5][05DD]_2026` becomes visual
`2026_[05DD][05D5][05DC][05E9]`. FireMonkey agrees - the digits occupy one
unbroken run. Both renderers implement the Unicode bidirectional algorithm, so
version strings, times and quantities look after themselves.

**FlipChildren**, measured for completeness, computes exactly
`Parent.ClientWidth - Left - Width`, mirrors within each parent, and swaps
`Align` - but not `Anchors`.

## Mirrored by the planner, not by either framework

The VCL has `BiDiMode` and `FlipChildren`. FireMonkey has neither. Leaning on
the VCL's mechanism would mean writing the FireMonkey half separately and
getting different behaviour on each; mirroring in the planner is one
implementation, emits the `Left`/`Position.X` rules the runtime already
applies, and goes through the same contract harness as everything else. The
FireMonkey and VCL mirroring contracts assert identical numbers because they
come from the same pass.

`TLocalizationReview.TextDirection` carries the fact from the catalog, the way
`Framework` already did. Phase 3e runs last, after the settling pass, so it
reflects final geometry and no earlier pass has to know it exists. The
transform is parent-relative, which handles nesting without recursion:

    MirroredLeft := ParentInnerWidth - (PlannedLeft + PlannedWidth)

## What mirrors

- **Coordinates**, each control within its own parent.
- **`Align`**, for controls the framework places. Reflecting the coordinate of
  an `alLeft` control does nothing at all - the framework re-places it - so the
  constant changes instead, and the coordinate is deliberately left alone so
  the two instructions cannot contradict.
- **`Anchors`**, where exactly one horizontal edge is anchored. Anchored to
  both the control stretches, which is symmetrical already.
- **Text alignment**, `taLeftJustify`/`taRightJustify` and
  `Leading`/`Trailing`. Centre is centre in every language.
- **Grid column order**, stated once for the grid rather than once per column,
  because reversing a collection one index at a time depends on the order the
  moves are made in.
- **Tab order**, which is reading order by another name.
- **Reading order and scroll bar side** on the VCL.

## What does not

- **Transport controls.** Rewind, play and stop refer to the direction a tape
  moves, not the direction a language is read. The group moves to the mirrored
  side as a block and keeps its internal order. Microsoft's and Apple's
  guidance agree.
- **Numbers, times, versions and paths**, handled by the renderers.
- **Images.** The transform only moves controls, never flips their content, so
  logos and photographs are safe by construction.

Everything the mirror decides is an ordinary layout proposal and can be
rejected in review, which is the opt-out.

## Ordering, which is most of the difficulty

Column widths are applied before the column order, because a width names a
column by the index it was designed at and reversing first would put every
width on the wrong column. Alignment and `Align` are applied before width and
height, so measurement reflects reality. `Anchors` is applied after position,
so the distances it captures are the final ones. Reading order is applied
before the layout rules, so the alignment rules have the last word.

## Three defects the tests caught

Each was found by a test rather than by reading, and each would have shipped.

1. **The mirror was not restored.** Geometry came back when returning to
   English but `Align`, `Alignment`, `Anchors` and the column order did not -
   they were not in the snapshot. A user who tried Hebrew once would have been
   left with an English program laid out backwards. Reversal is its own
   opposite, so a grid is put back by reversing it again, which needs the
   applicator to remember that it reversed one.

2. **FireMonkey never restored at all.** `RestoreOriginalGeometry` existed but
   was only called from `RestoreSourceLanguage`, not from `ApplyToForm` as it
   is on the VCL side. Hebrew to Spanish would have left the Spanish form
   mirrored, because the Spanish pack says nothing about `Align` - it needs
   nothing said - and silence cannot put an edge back. FireMonkey now restores
   first, exactly as the VCL does.

3. **The FireMonkey property whitelist silently dropped the new rules.**
   `IsRuntimeLayoutProperty` listed nine properties; the mirror adds three.
   The rules were carried in the pack, matched by the ordered pass, and
   discarded without a word - the precise drift that list was written to
   prevent. The VCL applicator has no such gate, which is why it worked first
   time and FireMonkey did not.

A fourth was caught while writing the transport grouping: the block bounds were
being measured while its members were already being moved, so the second and
third buttons reflected against a shape that was half in its old place. The
group is gathered before any of it moves.

## Not done

Phase 9 of the plan - a real Hebrew or Arabic pack against the first VCL pilot, with
screenshots. Everything above is proved by contract and by applicator test on
purpose-built forms. It has not been seen on a real application in a real
language, and every significant defect this project has found came from exactly
that step.

`TAlignLayout.Left` is 5 and `Right` is 9 in this version, not 2 and 3. Read
them rather than assuming.

# Protecting Format Specifiers from the Translator (2026-08-20)

The first Arabic run of the first VCL pilot stopped with two blocking validation errors.
Both were the same thing: the provider had destroyed the printf specifiers.

    source:      %.2f GB used / %.2f GB free of %.2f GB (%.1f%%)
    came back:   ... 0.2f ... 0.2f ... 0.2f ... (0.1f%)

Every % became a 0, and %% collapsed to %. The Arabic itself was good - it
reads "used N gigabytes / N gigabytes available of N gigabytes" - and only the
specifiers were hurt.

The cause was proved rather than guessed, by comparing the same strings in the
catalogs already on disk:

| language | entries with % in source | specifier mismatches |
|---|---|---|
| de-DE | 6 | 0 |
| es-ES | 6 | 0 |
| ar-SA | 6 | 2 |

Same code, same day, same settings; only the target language differs. So the
engine mangles specifiers on Arabic output. The validator caught both, and
nothing slipped past it - which is the guard working exactly as intended, and
the only reason this was ever noticed. It had worked twice and then quietly
stopped working.

`DAT.Provider.Placeholders` now stands between every caller and the service.
Specifiers are lifted out before a request is built and replaced by a token -
`ZQPH0ZQPH` - which carries its own index, so a token the engine moves still
comes back as the specifier it stood for. Right-to-left languages move things.
Identical specifiers get separate tokens, because "%.2f GB used / %.2f GB free"
has three of them and a search-and-replace cannot tell them apart.

Afterwards the specifiers are put back and the result is checked against the
source. Where they still do not match, the source text is returned instead of
the translation: an English string among Arabic ones is visible in review,
whereas a broken format string is invisible until a customer sees it.

A string that is nothing but specifiers is never sent at all. `%.2d/%.2d` is a
date, not a sentence - there is nothing in it to translate, the engine can only
damage it, and asking costs money.

`TranslateBatch` does the protecting and `PostBatch` does the HTTP, so no
caller can reach the service unprotected by accident.

The two damaged the first VCL pilot entries were repaired by hand and marked reviewed, so
a re-run leaves them alone. Their Arabic wording is the provider's own; only
the % signs were restored.

# One List, Not Three (2026-08-20)

The first Arabic run of the first VCL pilot worked: the forms mirrored, the transport
buttons kept their order, checkbox captions moved to the left of their boxes.
Two things did not. The grids kept their designed column order, and label
alignment never flipped.

The planner had decided both correctly - the layout proposal held eight
`Alignment` decisions and two `ColumnOrder` ones. The deployed pack held none
of either. They were dropped by a property whitelist in the pack exporter, in
silence, with no error anywhere.

That is the second time in one day. The FireMonkey applicator had its own copy
of the same list and dropped every right-to-left rule the same way. The
comment above the FireMonkey copy said, in as many words, that two lists had
drifted apart once already.

There were three copies. There is now one, in `DAT.Runtime.LanguagePack`,
which the exporter and both applicators already share. The FireMonkey copy and
the exporter's inline list are gone.

The list also now admits `Columns[...]`, which it never did. Grid column widths
have therefore never reached a pack through the normal pipeline - the feature
was proved by contract and by an applicator test fed a hand-written pack, and
the seam between them was never crossed. The first VCL pilot has not needed one yet, so
nothing was visibly wrong.

`PackLayoutSmokeTests` guards that seam now. It writes a layout proposal
containing one accepted decision of every kind, serializes a pack, and checks
each one arrives. It is the only test that goes proposal-to-pack: the planner's
contracts pass because the plan is right, and the applicator tests pass because
they are handed a pack written by hand. Neither can see a hole in between.

## What the Arabic run showed about translation quality

Rendering, shaping and mirroring were all correct. The words were the problem,
and in one specific way: **English words that are both noun and verb came back
as verbs.**

| shown | Arabic | means |
|---|---|---|
| Help | يساعد | "he helps" |
| Close | يغلق | "he closes" |
| Play | يلعب | "he plays" (a game) |
| Stop | قف | "stand!" |
| Wed | تزوج | "he married" |
| Sat | قعد | "he sat" |
| Sun | شمس | the star |
| Play Schedule | جدول المباريات | "fixture list" (sport) |

The domain profile settles which *sense* a word carries and did so correctly
elsewhere in the same run - the email and liturgical screens are good, and
"Ash Wednesday", "Maundy Thursday" and "All Souls Day" are all right. What it
does not carry is that a button caption is an imperative and a menu item is a
noun, nor that a three-letter day abbreviation is a day rather than a verb.

Both are worth fixing and neither is a defect in what exists: the context is
about meaning, and this is about part of speech and about abbreviation.

## The fourth copy (2026-08-20, later)

Fixing the exporter was not enough, and the reason is worth recording because
it was invisible from every angle that had been checked.

The Arabic pack was rebuilt with the exporter fix in place and still carried no
`Alignment` and no `ColumnOrder`. The proposal file explained it: 400 decisions
accepted, 10 pending, and the ten pending were exactly the mirror decisions.
The exporter only exports what is accepted.

`AddProposal` held a fourth copy of the nine-property list, deciding which
proposals start accepted. A proposal left pending is dropped later without a
word, so that list quietly governs whether anything ships at all. Every
right-to-left decision the planner made was created pending and thrown away -
the plan was right, the pack was empty, and nothing anywhere said so.

Four copies of one list, in four units, each one silently able to delete a
feature. All four are gone; `IsRuntimeLayoutProperty` in
`DAT.Runtime.LanguagePack` is the only one left.

The layout contract harness can now assert a proposal's decision as well as its
value, and `vcl_32` requires the mirror decisions to start accepted. That
assertion was checked by disabling the auto-accept and confirming the contract
fails.

The lesson is not about lists. It is that a value can be correct at both ends
of a pipeline and absent in the middle, and no test that looks at either end
will ever see it. Two tests now cross seams rather than sit at ends:
`PackLayoutSmokeTests` goes proposal-to-pack, and the contract decision
assertion goes analysis-to-proposal.

## Pending is not a decision (2026-08-20, later still)

Two fixes in, the Arabic pack still shipped without its mirror rules. The
exporter carried them; the analyser accepted them; the pack was still empty.

`RestoreDecisions` reads the proposal file from the previous run and copies
each saved decision over the analyser's. That exists so a rejection made in
review is not undone by the next scan, and that part is right. But the file
also records every proposal that was merely *pending* - and pending is not a
decision, it is the absence of one.

The proposal file on disk had been written by a build that did not know
`Alignment` or `ColumnOrder` existed, so it recorded them as pending. Every
run since restored that pending over a freshly accepted decision. The feature
was vetoed in perpetuity by a stale file, and no rebuild of the analyser could
ever have fixed it.

A saved decision now overrides the analyser only when it is an actual decision.
An empty or pending entry leaves the analyser's judgement standing; a rejection
is obeyed exactly as before.

`ProposalDecisionSmokeTests` analyses a fixture, writes a proposal file with
the mirror decision pending and one real rejection, re-analyses, restores, and
checks that the pending one survived as accepted while the rejection held. It
reproduced the defect before the fix.

### Three bugs, one shape

Every one of the three failures on this feature had the same shape: a value
correct at both ends of a pipeline and absent in the middle.

1. The FireMonkey applicator's copy of the property list dropped the rules.
2. The exporter's copy dropped them.
3. The auto-accept copy created them pending, and the restore made that
   permanent.

Each was invisible to every test that existed, because the tests sat at the
ends - the contracts prove the plan, the applicator tests are handed a pack
written by hand - and nothing crossed the joins. Three tests now cross them:
`PackLayoutSmokeTests` (proposal to pack), the contract harness's decision
assertion (analysis to proposal), and `ProposalDecisionSmokeTests` (run to
run).

# Context That Reaches the String It Describes (2026-08-20)

The context work was correct and was being wasted.

A service takes one `context` per request. `TranslateWithContexts` batched
fifty strings and concatenated all fifty of their contexts into that one
field, so "Help" arrived wearing forty-nine descriptions of other controls.
The context was generated, sent, and diluted into uselessness - the likeliest
reason the Arabic run still returned Help, Close and Play as third-person
statements.

The economics make the fix free. **Billing is per translated character, not
per request.** Measured on the first VCL pilot:

| | characters |
|---|---|
| source text, billed | 6,471 |
| context, not billed by DeepL | 65,466 |

So the whole application costs 6,471 characters whether it is sent as six
requests or as 297. Grouping by shared context therefore costs nothing but
round trips - about a minute, once per language, for a result that is stored.
DeepL's free tier of 500,000 characters a month is roughly seventy-seven
runs of the first VCL pilot's size.

`DAT.Provider.Batching` groups strings by identical context. Where a context
is unique the group holds one string; where many share a context, or have
none, they travel together as before, and the batch ceiling still holds.

## Part of speech

A button says what pressing it will do, so its caption is an instruction. A
menu item names a thing. English hides the difference - its imperative and its
dictionary form are the same word - so a service given "Help" alone may
reasonably return a statement, and Arabic did: the third person singular, for
Help, Close and Play alike. Grammatical, and useless on a button.

The context now says which is wanted, chosen from the control class, which
every string already carries. A button asks for an imperative "in the form
that language uses on buttons"; a menu item for the form that language uses
on menus; a column heading for a noun phrase; a check box for the name of an
option.

Neither change has been tested against a real service yet. Both are aimed at
a defect seen once, in one language, and the fix list keeps the entry open
until an Arabic run shows the result.

# The Language Code DeepL Would Not Take (2026-08-20)

The first DeepL run stopped on the 280th unresolved entry with

    STOPPED: DeepL rejected the request (HTTP 400 Bad Request). Check the key,
    plan, billing, quota, language codes, and network connection.

Six possibilities, one of them right, and nothing to say which. The key was
good and the request was well formed. The target language was `ar-SA`, and
DeepL's target list has `AR`.

A catalog names languages the way Windows does - ar-SA, es-ES, he-IL. DeepL
accepts two-letter codes plus a short published list of regional variants:
EN-GB, EN-US, PT-BR, PT-PT, ZH-HANS, ZH-HANT, ES-419, DE-DE, DE-CH, FR-CA,
FR-FR. Anything else is a 400. The old normaliser uppercased the catalog code
and passed the region straight through, so German worked - DE-DE happens to be
on the list - and Arabic, Spanish, Hebrew and most others could not have.

`DAT.Provider.LanguageCodes` keeps a region only where the service is known to
accept it and drops it everywhere else. Dropping is the safe direction: the
general code is accepted for every language DeepL supports, so a language added
after this was written still works, just without its variant.

## Saying what the service said

The message above named six causes because the code that raised it knew
nothing. Both services return an explanation in the response body and it was
being discarded. Rejections now quote it, and add one line of interpretation
where the status code carries meaning of its own - that a 400 is a malformed
request rather than a refused key, that a 401 or 403 is as likely to be a free
key sent to the paid endpoint as a wrong one, that 456 is the quota.

## Plans

DeepL restructured its API plans in July 2026. API Free and API Pro can no
longer be bought; new customers get Developer, Growth or Enterprise. Developer
is free and carries a **one-time** credit of one million characters, one API
key and one glossary.

At 6,471 characters for a the first VCL pilot-sized application in one language, and with
the wizard never re-translating a string that already has a translation, that
credit is roughly 150 new application-languages with re-runs costing nothing.
The single glossary is enough to build and test DeepL server-side glossary
support without paying for it.

# A Rate Limit Is an Instruction (2026-08-20)

The DeepL run stopped again, twenty-nine seconds in:

    STOPPED: DeepL rejected the request (HTTP 429 Too Many Requests).

Nothing was wrong. This was self-inflicted, and by a change made the same
afternoon: giving each string its own context turned roughly six requests into
roughly 297, and the client then gave up after three attempts and waits of 300
and 600 milliseconds. Against a rate limit that is not waiting at all.

A 429 is not a failure, it is the service asking for a slower pace, and the
only wrong answer is to stop. `DAT.Provider.Retry` now decides the waits:

- six attempts rather than three
- one second, then two, four, eight, sixteen - thirty-one seconds of patience
  in total, against the old nine hundred milliseconds
- `Retry-After` obeyed exactly when the service sends it, capped at thirty
  seconds, and treated as absent when it is a date form or a zero rather than
  guessed at
- 429 and 5xx retried; 400, 403 and 456 not, because a malformed request, a
  refused key and an exhausted quota will all come back just as fast

The waits are computed in a unit of their own so they can be checked without a
network or a clock.

## Not provoking it in the first place

Recovering from a rate limit costs seconds each time. Not tripping it costs
milliseconds. The client now keeps a pacing delay that starts at zero and
grows by 250 milliseconds each time a 429 is met, to a ceiling of one second,
and holds it for the rest of the run. A run that is never refused pays
nothing; a run that is refused once slows down instead of arguing.

## The standing cost

Grouping by context is still roughly fifty times the round trips of the old
batching. That is the price of a context that reaches the string it describes,
it is paid once per language because re-runs never resend a translated string,
and it is now slow rather than fatal. Two ways to buy the speed back are on
the fix list rather than built: sending several requests concurrently, and
giving individual context only to short strings, which are the ambiguous ones.
