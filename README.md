# Delphi App Translation Studio

Delphi App Translation Studio is a Windows translation workspace for Delphi VCL
and FireMonkey applications. The Studio is written in Delphi with a
designer-authored FireMonkey interface and is intended to build offline JSON
language packs for Win32 and Win64 applications.

## Current Status

The project now has a working foundation and initial read-only scanner. The
current source provides:

- An FMX Studio shell using the orange-and-blue VCL2FMXConverterV6 visual family.
- Delphi `.dproj` and `.dpr` project selection.
- Automatic VCL versus FireMonkey detection.
- Win32 and Win64 target detection.
- Initial shared translation catalog and locale types.
- Versioned development-project and runtime-pack JSON schemas.
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
- Win32 and Win64 foundation and scanner smoke tests.

Binary DFM conversion, editable custom extraction rules, online provider
integration, runtime language application, and automatic menu integration remain
planned phases.

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
source/providers/      Translation provider implementations
source/runtime/        Generated/runtime language support
source/scan/           VCL, FMX, and Delphi source scanners
source/schemas/        Versioned JSON schemas
source/studio/         Designer-authored FMX Studio interface
source/validation/     Catalog and integration validation
tools/tests/           Foundation smoke tests
```

## Design Principle

Normal project scanning and translation-pack building are read-only with respect to
the target application. Runtime and language-menu integration will be a separate,
previewed, backed-up, developer-confirmed operation.

## Documentation

The current product decisions and engineering findings are maintained in
[`docs/guides/Engineering Notes.md`](docs/guides/Engineering%20Notes.md).

## License

An open-source license will be added after the project owner selects the license.
