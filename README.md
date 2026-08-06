# Delphi App Translation Studio

Delphi App Translation Studio is a Windows translation workspace for Delphi VCL
and FireMonkey applications. The Studio is written in Delphi with a
designer-authored FireMonkey interface and is intended to build offline JSON
language packs for Win32 and Win64 applications.

## Current Status

The project is in its foundation stage. The current source provides:

- An FMX Studio shell using the orange-and-blue VCL2FMXConverterV6 visual family.
- Delphi `.dproj` and `.dpr` project selection.
- Automatic VCL versus FireMonkey detection.
- Win32 and Win64 target detection.
- Initial shared translation catalog and locale types.
- Versioned development-project and runtime-pack JSON schemas.
- Designer-authored VCL and FMX sample applications.
- Win32 and Win64 foundation smoke tests.

Scanning form content, online provider integration, runtime language application,
and automatic menu integration are planned phases and are not implemented yet.

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
