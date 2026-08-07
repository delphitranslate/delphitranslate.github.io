# Delphi App Translation Studio Help

Last changed: August 7, 2026

## Purpose

Delphi App Translation Studio scans Windows Delphi VCL and FireMonkey projects,
builds editable language catalogs, coordinates direct in-place translation by
Codex or Claude, validates protected data and translation safety, exports
offline JSON packs, and previews or applies target integration. DeepL, Google,
CSV, and manual editing are alternative paths.

## Workflow

1. Open a `.dproj` or `.dpr` under **Project**.
2. Select **Scan** and scan designer text and resourcestrings.
3. Under **Engine Settings**, select an installed Codex CLI or Claude Code
   command. Detect or browse to it, sign in through the vendor command, and use
   **Check Installation**.
4. Under **Translate**, select the target language. The Studio fills its code,
   native name, direction, and locale formats; review them and save the catalog.
5. Select **Translate Automatically**. The Studio saves a recovery snapshot,
   launches the signed-in agent, supplies the complete contract, and monitors
   the process and catalog.
6. On success, the Studio verifies every protected field, adopts safe AI Draft
   translations, saves the catalog, refreshes the page, and runs validation.
7. Resolve structural errors, low-confidence entries, explicit AI review notes,
   terminology inconsistencies, and manual `resourcestring` wiring warnings.
8. Export the offline pack.
9. Under **Integration**, build the preview, select and inspect the complete
   line-numbered diff for every file, then check the final review confirmation
   before applying it.

## In-Place AI Translation

The development catalog remains in `Localization\Development`. Codex or Claude
modifies only `translatedText`, `status`, `translationOrigin`,
`translationConfidence`, and `translationReviewNote`. Stable keys, source text,
checksums, component context, locale metadata, runtime classifications, and
entry order are protected.

While automatic translation is active, Studio catalog editing and saving are
disabled. A designer-owned timer monitors the child process. A zero exit
causes **Reload** logic to parse the complete JSON, compare it with the
pre-session snapshot, reject unauthorized changes, record accepted work as AI
drafts, save, and validate. A failed process or **Cancel Translation** restores
the snapshot. **Prompt** and **Reload** remain recovery controls, not normal
required steps.

Only Needs Translation, Source Changed, Error, and existing AI Draft entries
are eligible. Machine-translated, Imported, Edited, Reviewed, Approved,
Excluded, and Obsolete entries are protected. A metadata-only AI confirmation
can retain an existing translation that remains correct after a source change.
Changed work must identify Codex or Claude and record high, medium, or low
confidence.

`translation-profile.json` records product context, audience, tone, protected
names, and preferred terminology. The generated instruction requires a second
linguistic QA pass and permits safe checkpoints in the same catalog for large
projects.

## CSV/JSON Interchange

The development JSON catalog is the lossless interchange record. **Export CSV**
creates a UTF-8 translator-friendly file. Edit only the Translation column.
**Import CSV** stages changes and reports duplicate or unknown keys, stale
source data, and protected Reviewed/Approved entries before asking whether to
apply. Accepted text is marked Imported and is never approved automatically.

Designer-property entries are applied by the runtime adapter. Pascal
`resourcestring` entries require an explicit generated `TranslateText` call;
mark manual wiring confirmed only after reviewing that code location.

## Engine Settings and Provider Alternative

The Studio starts maximized. Select Codex CLI or Claude Code, keep **Model** at
Default unless a specific installed-agent model is required, and use **Detect**,
**Browse**, or **Check Installation** as needed. The Studio stores only the
engine, executable path, and model choice. Agent authentication remains in the
vendor CLI and is never copied into project files or runtime packs.

The optional provider area selects DeepL or Google Cloud Translation. DeepL users must also select API Free
or API Pro. Paste a key into the masked field. Leave **Remember securely on this
computer** checked to use Windows Credential Manager, or clear it to keep the
key only until the Studio closes. **Replace / Save Key** records the choice,
**Test Connection** makes a small English-to-Italian request, and **Remove Key**
deletes both stored and session copies for the selected provider.

Provider access is used only by the Studio. Exported applications remain
offline and do not contain the API key.

## Files

Development catalogs are written to
`Localization\Development\<Project>.<locale>.translation-project.json`.
Runtime packs are written to `Localization\Languages\<locale>.json`. Integrated
applications read packs beside the executable and save the selected language
under `%LOCALAPPDATA%\<ApplicationId>\language.ini`.

## Safety

Scanning does not alter target source. Integration first produces an in-memory
change set, exact per-file review, and preview package. Apply is gated until
every file is viewed and review is explicitly confirmed. Applying integration
creates a verified backup and manifest. Use **Restore** to return to the
recorded pre-integration files.

## Support

Consult the full User Guide for provider-key acquisition, all fields, status
meanings, troubleshooting, deployment, and self-translation. Consult the
Engineering Guide for schemas, runtime behavior, integration transactions,
security boundaries, and build validation.
