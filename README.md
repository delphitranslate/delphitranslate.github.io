# Delphi App Translation Studio

Delphi App Translation Studio is a Windows translation workspace for Delphi VCL
and FireMonkey applications. The Studio is written in Delphi with a
designer-authored FireMonkey interface and is intended to build offline JSON
language packs for Win32 and Win64 applications.

## Product Definition

The Studio is an offline-first translation-management, validation, packaging,
and Delphi-integration application. Its primary translation workflow is
automatic, in-place catalog translation through Google Cloud Translation or
DeepL from the developer's connected Studio. CSV, JSON, suggestions, and
manual editing remain specialist interchange and fallback paths.

Translated applications load local language packs and do not require Internet
access or provider credentials. Provider credentials never enter the target
project or its runtime language packs.

## Current Status

The project now has a working offline translation workflow. The current source
provides:

- An FMX Studio shell using the orange-and-blue VCL2FMXConverterV6 visual family.
- Delphi `.dproj` and `.dpr` project selection.
- Automatic VCL versus FireMonkey detection.
- Win32 and Win64 target detection.
- Initial shared translation catalog and locale types.
- Versioned development-project and runtime-pack JSON schemas.
- Schema version 3 translation provenance for Codex, Claude, Google, DeepL,
  human, imported, and suggestion sources, separate from linguistic status.
- Designer-authored VCL and FMX sample applications.
- Text `.dfm` scanning for designated VCL captions, hints, prompts, lists, and
  memo content.
- Text `.fmx` scanning for designated FMX text, hints, prompts, lists, and memo
  content.
- Delphi `resourcestring` extraction with stable unit-and-symbol keys.
- Stable form/component/property keys and source-file line locations.
- Incremental catalog merging that preserves unchanged translations, flags
  changed source text, and marks removed entries obsolete.
- A designer-authored scan-results area in the Studio.
- Project-local development catalogs under
  `Localization\Development`.
- Manual language metadata, locale-format, and translation editing.
- Explicit runtime coverage for automatically applied form properties and
  manually wired Pascal `resourcestring` entries.
- Separate translation-completeness and manual-wiring readiness summaries.
- Designer-authored Begin AI Mode, Copy Prompt, and Reload AI Work controls.
- A project-local terminology profile, exact pre-AI recovery snapshot, and
  generated agent instruction contract.
- Checksum protection against overwriting an externally modified catalog.
- Stable external-change detection and protected-field verification before
  in-place AI work is adopted.
- Eligible-status enforcement protects machine-translated, imported, edited,
  reviewed, approved, excluded, and obsolete work from an AI session while
  allowing metadata-only confirmation of still-valid source-changed text.
- UTF-8 CSV export/import with stable-key matching, multiline fields, stale
  source detection, duplicate/unknown-key reporting, and reviewed-work
  protection.
- Catalog validation for missing translations, duplicate keys, changed source
  text, Delphi indexed/sequential placeholders, accelerator keys, and manual
  runtime-wiring warnings.
- Context-ranked exact-source translation suggestions that require explicit
  acceptance and never inherit approval status.
- Explicit Mark Reviewed and Approve actions with enforced status progression.
- Compact offline runtime packs under `Localization\Languages`.
- Active workflow navigation for Project, Scan, Translate, Validation, Export,
  Integration, and Provider Settings.
- DeepL API Free/API Pro and Google Cloud Translation Basic v2 provider support.
- Masked API-key entry, Windows Credential Manager persistence, session-only
  keys, replacement, removal, and connection testing.
- Implemented optional batched provider translation that preserves reviewed
  work and marks provider results as machine translated.
- Offline VCL and FMX runtime loading, designer-persisted language menus,
  transactional integration, rollback, and deployment scripting.
- Optional complete line-numbered original/proposed integration diffs and one
  explicit authorization before transactional Apply.
- Automatic normalized English source-pack creation during integration.
- Canonical, de-duplicated native-language menus without malformed metadata.
- Immediate application of a newly selected language to every open form.
- Optional elevated Win32/Win64 Debug/Release build and JSON deployment after
  Apply; the target is never launched automatically.
- FMX form translation through designer-persisted `OnCreate` handlers after
  form streaming; VCL startup wiring remains in the DPR.
- Win32 and Win64 VCL/FMX reference pilots covering scan, in-place
  provider translation, protected-field review, validation,
  export, integration, build, deployment, and Italian offline launch behavior.

## Current Studio Workflow

1. Open a VCL or FireMonkey `.dproj` or `.dpr`.
2. Scan the project.
3. Open **Translate**, enter the target code and native language name, and create
   the development catalog.
4. Configure Google or DeepL under **Provider Settings**, test the connection,
   and return to **Translate**.
5. Choose **Translate Automatically**. Eligible strings are translated in
   bounded batches and the catalog is saved automatically.
6. Resolve the focused exception queue. CSV, suggestions, and manual editing
   remain available alternatives.
7. For cataloged Pascal `resourcestring` entries, add the documented
   `TranslateText` call at each intended call site and mark manual wiring
   confirmed. The Studio does not rewrite Pascal call sites.
8. Run **Validation**.
9. When there are no validation errors, use **Export** to create the offline
   runtime JSON pack.
10. Use **Integration** to generate the package, optionally inspect any exact
    diff, authorize once, and apply or restore the target-project runtime,
    JSON packs, and designer-authored language menu changes. Optionally build
    and deploy the selected Windows target without launching it.

Scanning remains read-only. The `Localization` folder is created only when the
developer explicitly saves a catalog or exports a runtime pack.

## Supported Development Targets

- Translation Studio: Windows Win32 and Win64
- Translated VCL applications: Windows Win32 and Win64
- Translated FireMonkey applications: Windows Win32 and Win64

macOS, iOS, Android, Linux, and C++Builder are outside the current scope.

## Requirements

- Delphi 13 / RAD Studio 13 Florence
- Windows
- Win32 and Win64 Delphi compilers

Compatibility with other Delphi releases will be evaluated after the foundation is
stable.

## Build

Open `DelphiAppTranslationStudio.dproj` in RAD Studio and select either Win32 or
Win64.

Command-line builds can be run after loading the RAD Studio environment:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild DelphiAppTranslationStudio.dproj /t:Build /p:Config=Debug /p:Platform=Win32
msbuild DelphiAppTranslationStudio.dproj /t:Build /p:Config=Debug /p:Platform=Win64
```

Build output is written under `bin`, and compiler units are written under `dcu`.

After building all four configurations, run the FMX startup smoke test from
PowerShell:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\tests\RunStudioLaunchSmokeTests.ps1
```

The test launches each Win32/Win64 Debug/Release executable, rejects startup
error dialogs, verifies the expected main-form title, and closes the test process.

## Repository Layout

```text
bin/                   Build output
dcu/                   Compiler unit output
docs/guides/           Engineering and user-facing source notes
docs/pdf/              Companion PDF documentation
export/                Generated language-pack output
help/                  Application help
images and icons/      Product artwork
samples/               VCL and FireMonkey scanner fixtures
source/core/           Framework-neutral catalog and project model
source/integration/    Target-project integration
source/provider/       Translation provider implementations
source/runtime/        Generated/runtime language support
source/scan/           VCL, FMX, and Delphi source scanners
source/schemas/        Versioned JSON schemas
source/studio/         Designer-authored FMX Studio interface
source/validation/     Catalog and integration validation
tools/tests/           Automated workflow and launch smoke tests
```

## Design Principle

Normal project scanning, translation interchange, and language-pack building are
read-only with respect to target source. Runtime and language-menu integration
is a separate exactly previewed, backed-up, developer-confirmed operation. Integrated
applications use only local JSON packs and never contain provider credentials.

## Documentation

The current product decisions and engineering findings are maintained in
[`docs/guides/Engineering Notes.md`](docs/guides/Engineering%20Notes.md).

## License

An open-source license will be added after the project owner selects the license.
