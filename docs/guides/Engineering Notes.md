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
