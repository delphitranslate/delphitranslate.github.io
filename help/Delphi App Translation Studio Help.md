# Delphi App Translation Studio Help

Last changed: August 8, 2026

## Purpose

Delphi App Translation Studio scans Windows Delphi VCL and FireMonkey projects,
builds editable language catalogs, translates unresolved text automatically
through Google Cloud Translation or DeepL, validates translation safety,
exports offline JSON packs, and generates a non-mutating component setup kit.

The developer computer needs Internet access only while using a translation
provider. Finished applications use local JSON packs and remain completely
offline. No API key is added to the target application's source or deployment.

## Workflow

1. Open a `.dproj` or `.dpr` under **Project**.
2. Select **Scan** to inventory designer text and `resourcestring` declarations.
3. Under **Provider Settings**, select Google Cloud Translation or DeepL.
4. Paste the provider API key into the masked field, choose secure remembered
   storage or session-only use, select **Replace / Save Key**, and then select
   **Test Connection**.
5. Under **Translate**, select a target language from the built-in list. Review
   the native name, direction, and locale formats.
6. Select **Translate Automatically**. Confirm the provider and unresolved
   entry count. The Studio translates eligible entries in batches and saves the
   development catalog automatically.
7. Review Machine translated entries for meaning, placeholders, accelerators,
   terminology, tone, and available control space. Use the selected-entry
   actions for focused work, or **Review All** and **Approve All** when one
   confirmed catalog-wide decision is appropriate.
8. Run **Validation**. Errors block export; warnings request review. Double-click
   an issue to open its catalog entry, then export the offline JSON pack.
9. Under **Integration**, leave **Component Integration (Recommended)** selected
   and select **Install / Repair Components** if the Tool Palette is not set up.
   Close RAD Studio when requested; the installer builds, verifies, copies, and
   registers the matching design BPL. Generate the kit, place one manager
   on the primary form, set its `ApplicationId`, add the kit's component source
   path, deploy `Localization\Languages` beside the executable, and build.
10. Optionally place the matching language combo box and assign its
    `LanguageManager` property in the Object Inspector.

## Automatic Provider Translation

Only Needs Translation, Source Changed, and Error entries are sent. Reviewed,
Approved, Excluded, and Obsolete entries are never overwritten automatically.
Each returned value is marked Machine translated and records Google or DeepL
as its origin. Results are not silently approved.

If no key is configured, **Translate Automatically** opens Provider Settings
and explains what is missing. Provider failures are reported without exposing
the key. Existing catalog data remains available for correction or retry.

## Provider Settings

The provider list contains only DeepL and Google Cloud Translation. DeepL users
must also choose API Free or API Pro so the matching endpoint is used. Google
uses Cloud Translation Basic v2, which supports API-key authentication.

The API key field is masked. Leave **Remember securely on this computer**
checked to store the key as a Windows Generic Credential for the current user.
Clear it to use the key only until the Studio closes. **Replace / Save Key**
records the chosen key, **Test Connection** makes a small English-to-Italian
request, and **Remove Key** deletes both stored and session copies for the
selected provider.

Keys are never written to provider settings JSON, language catalogs, exported
runtime packs, source distributions, logs, or Git.

## Optional CSV Interchange

The development JSON catalog is the lossless record. **Export CSV** creates a
UTF-8 translator-friendly file. Edit only the Translation column. **Import
CSV** stages changes and reports duplicate or unknown keys, stale source data,
and protected Reviewed/Approved entries before applying anything. Imported text
is marked Imported and is never approved automatically.

## Files

Development catalogs are written to
`Localization\Development\<Project>.<locale>.translation-project.json`.
Runtime packs are written to `Localization\Languages\<locale>.json`. Integrated
applications read packs beside the executable and save the selected language
under `%LOCALAPPDATA%\<ApplicationId>\language.ini`.

Designer-property entries are applied by the VCL or FMX runtime adapter. Pascal
`resourcestring` entries require an explicit generated `TranslateText` call;
mark manual wiring confirmed only after reviewing that code location.

## Component Integration and Safety

Scanning does not alter target source. Recommended Component Integration writes
only to `export\component-integration`; target project, source, DFM, and FMX
files are not opened for writing. The developer makes the small integration
change in Delphi's Form Designer, where it remains visible and editable.

Never select a `.dpk` in Delphi's **Component > Install Component** wizard.
The `.dpk` is package source. The automated installer registers the compiled
Win32 design `.bpl`; the advanced manual alternative is **Component > Install
Packages > Add**. The design BPL is self-contained with respect to DAT units, so
missing DAT runtime-package search paths cannot prevent the IDE from loading it.
Generated kits include `Install-Components.cmd`; double-click it after closing
RAD Studio. The launcher supplies PowerShell ExecutionPolicy Bypass and leaves
the success or failure message visible.

The component kit creates a complete English runtime pack from the latest scan,
normalizes and de-duplicates language names, and installs all JSON packs. A
language selection immediately refreshes every open form; newly created forms
receive the saved language through the manager's additive lifecycle adapter.

One manager on the primary form covers the application. A language selector is
optional and is also placed and configured in the Form Designer. Automatic
Source Integration remains available as an advanced fallback; it retains the
exact preview, verified backup, atomic Apply, Restore, and Complete Reset safety
workflow.

## Support

Consult the User Guide for detailed Google and DeepL account/key instructions,
all controls, status meanings, troubleshooting, deployment, and
self-translation. Consult the Engineering Guide for provider protocols,
credential storage, schemas, runtime behavior, transactional integration, and
build validation.
