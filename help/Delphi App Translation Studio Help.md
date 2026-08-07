# Delphi App Translation Studio Help

Last changed: August 7, 2026

## Purpose

Delphi App Translation Studio scans Windows Delphi VCL and FireMonkey projects,
builds editable language catalogs, translates unresolved text automatically
through Google Cloud Translation or DeepL, validates translation safety,
exports offline JSON packs, and previews or applies target integration.

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
   terminology, tone, and available control space. Mark them Reviewed and then
   Approved when appropriate.
8. Run **Validation**, correct every error, and export the offline pack.
9. Under **Integration**, build the preview, inspect the complete line-numbered
   diff for every file, confirm the review, and then apply it.

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

## Safety

Scanning does not alter target source. Integration first produces an in-memory
change set, exact per-file review, and preview package. Apply remains disabled
until every file is viewed and review is explicitly confirmed. Applying creates
a verified backup and manifest. Use **Restore** to recover the recorded
pre-integration files.

If the named Language menu already exists, Integration populates it. If it is
missing, Integration adds a designer-persisted `TMenuBar`/`TMenuItem` for FMX
or `TMainMenu`/`TMenuItem` for VCL to the primary form, together with matching
form-class fields and event wiring. These controls remain editable in Delphi's
Form Designer; the target application does not construct them at runtime.

## Support

Consult the User Guide for detailed Google and DeepL account/key instructions,
all controls, status meanings, troubleshooting, deployment, and
self-translation. Consult the Engineering Guide for provider protocols,
credential storage, schemas, runtime behavior, transactional integration, and
build validation.
