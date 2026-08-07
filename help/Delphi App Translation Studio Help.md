# Delphi App Translation Studio Help

Last changed: August 6, 2026

## Purpose

Delphi App Translation Studio scans Windows Delphi VCL and FireMonkey projects,
builds editable language catalogs, optionally requests draft translations from
DeepL or Google, validates them, exports offline JSON packs, and previews or
applies target integration.

## Workflow

1. Open a `.dproj` or `.dpr` under **Project**.
2. Select **Scan** and scan designer text and resourcestrings.
3. Under **Languages**, enter the target locale and native name, then save the
   catalog.
4. Translate manually or configure a provider under **Provider Settings**.
5. Review all machine translations and run **Validation**.
6. Export the offline pack.
7. Under **Integration**, build and inspect the preview before applying it.

## Provider Settings

Select DeepL or Google Cloud Translation. DeepL users must also select API Free
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
change set and a preview package. Applying integration creates a verified backup
and manifest. Use **Restore** to return to the recorded pre-integration files.

## Support

Consult the full User Guide for provider-key acquisition, all fields, status
meanings, troubleshooting, deployment, and self-translation. Consult the
Engineering Guide for schemas, runtime behavior, integration transactions,
security boundaries, and build validation.
