# Delphi App Translation Studio

![CAUTION - Pre-release development project; not ready for production use](images%20and%20icons/README-Caution-Banner.svg)

> [!CAUTION]
> **Pre-release development project - not ready for production use.**
>
> This repository contains actively changing source code and engineering
> material. There is no supported installer, stable binary release, or version
> 1.0 package. Do not run the Studio against the only copy of an important
> Delphi project. Evaluate it with a clean, version-controlled test copy and
> verify every result before considering wider use.

## Release status

The project is currently undergoing controlled acceptance testing. A public
GitHub repository does **not** mean that the software has been released.

- No GitHub Release should be treated as available unless it is explicitly
  published and identified as supported.
- The current `main` branch is a development branch and may change without
  backward-compatibility guarantees.
- Existing guides are engineering snapshots and may temporarily lag the latest
  accepted workflow.
- The source has been validated with Delphi 13 / RAD Studio 13 Florence.
  Compatibility with Delphi 12, 12.1, and Community Edition has not yet been
  confirmed.
- A formal open-source license has not yet been selected. Until a license is
  added, the public source is viewable but should not be assumed to grant
  redistribution or modification rights.

## What the project is intended to do

Delphi App Translation Studio is a Windows desktop localization workspace for
Delphi VCL and FireMonkey applications. It scans designer-authored forms and
selected Delphi resources, builds versioned JSON development catalogs, sends
eligible interface text to Google Cloud Translation or DeepL, validates the
results, and exports compact JSON runtime language packs.

The developer's Studio computer uses the Internet only while communicating
with the selected translation provider. A translated target application loads
local JSON packs and does not need Internet access or an API key at runtime.

Current target scope:

- Delphi VCL applications for Windows Win32 and Win64.
- Delphi FireMonkey applications for Windows Win32 and Win64.
- Translation Studio builds for Windows Win32 and Win64.

macOS, iOS, Android, Linux, and C++Builder are outside the current scope.

## Current safety model

Project scanning is read-only. Saving a development catalog or exporting a
runtime pack can create a `Localization` folder under the selected test
project, but scanning alone should not modify its source.

The recommended integration path is **Component Integration**:

1. The Studio generates a component kit under its own `export` folder.
2. The developer manually installs the applicable Win32 design-time BPL through
   RAD Studio's **Component > Install Packages > Add** command.
3. The developer places one language-manager component, plus an optional
   selector, on the target application's primary form in Delphi's Form Designer.
4. The developer deploys the generated JSON language packs beside each target
   executable.

This recommended path does not authorize the Studio to rewrite target Pascal,
DFM, FMX, DPR, or DPROJ files. Earlier source-integration experiments and
advanced mutation paths are not the recommended pre-release workflow and
should not be used on valuable projects.

Before evaluation:

- Commit the target project and confirm `git status --short` is clean.
- Keep an independent backup.
- Use a disposable project copy.
- Review the generated JSON catalogs and component kit.
- Build and test both Win32 and Win64 before drawing conclusions.

## Current capabilities under test

- VCL `.dfm` and FireMonkey `.fmx` form scanning.
- Delphi `resourcestring` extraction.
- Stable catalog keys and incremental JSON catalog merging.
- Google Cloud Translation Basic v2 and DeepL API translation.
- API keys stored in Windows Credential Manager or held for one session only.
- Protected runtime-text classifications that prevent live data, identifiers,
  and excluded content from being automatically overwritten.
- Catalog validation, review, approval, JSON runtime-pack export, and offline
  loading.
- VCL and FMX language-manager components with immediate language switching.
- Win32 and Win64 Debug/Release build and smoke-test coverage.

Automatic-translation counts can be lower than scan counts. For example, an
acceptance catalog may contain 173 scanned entries while only 155 require
translation; the remaining entries are deliberately protected dynamic data,
identifiers, or excluded content. The Studio reports these categories before
sending text to a provider.

## Known pre-release limitations

- Dynamic runtime messages require explicit application integration and are
  not automatically rewritten as static component text.
- Translated text can be longer than the original and may expose target-form
  sizing, wrapping, or truncation problems that require developer review.
- External HTML help is a separate localization concern and is not currently
  translated by the runtime component.
- Delphi 12.x compatibility and clean-machine installation have not completed
  acceptance testing.
- Provider use may incur Google Cloud or DeepL charges. Developers are
  responsible for account security, billing, quotas, and API-key restrictions.
- The user and engineering guides will be finalized only after acceptance
  testing and the supported installation procedure are complete.

## Safe developer build

The currently validated toolchain is Delphi 13 / RAD Studio 13 Florence on
Windows with both Win32 and Win64 compilers installed.

Open `DelphiAppTranslationStudio.dproj` in RAD Studio and build the desired
platform. Command-line builds must first load the matching RAD Studio
environment. Generated binaries and compiler output belong under `bin` and
`dcu`; they are intentionally excluded from Git.

The complete automated release gate is:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\tests\RunPhase10ReleaseValidation.ps1
```

Passing automation is necessary but does not make the current development
branch a supported release.

## Repository layout

```text
bin/                   Local build output; not distributed through Git
dcu/                   Local compiler output
docs/guides/           Engineering and user documentation
docs/pdf/              Companion PDF documentation
export/                Local generated catalogs and integration kits
help/                  Application help source
images and icons/      Product artwork
packages/              Delphi runtime and design package source
samples/               VCL and FireMonkey fixtures
source/                Studio, scanner, catalog, provider, and runtime source
tools/tests/           Automated validation and smoke tests
```

## Documentation and issue reporting

Engineering history is maintained in
[`docs/guides/Engineering Notes.md`](docs/guides/Engineering%20Notes.md).
Pre-release testers should record the exact Delphi version, target framework,
platform, build configuration, reproduction steps, screenshots, and relevant
catalog entries when reporting a defect. Never publish an API key, credential,
private source file, or customer data in an issue.

## Intended release gate

Version 1.0 will not be declared until the repository has passed a clean-clone
build, clean IDE package-installation test, VCL and FMX acceptance testing,
Win32 and Win64 validation, documentation review, license selection, and a
complete source-distribution audit.
