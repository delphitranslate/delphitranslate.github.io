# Delphi App Translation Studio 1.0.0 Release Notes

Last changed: September 30, 2026

## Release status and scope

Version 1.0.0 is the production release for Delphi VCL and FireMonkey
applications developed on Windows with RAD Studio 13 Florence (Studio 37.0).
The target application can use offline JSON language packs on Win32 and Win64.
The included Studio executables and component packages were freshly built
with that toolchain. Other IDE versions and target operating systems are not
claimed as validated by this release.

## What is in the download

`DelphiAppTranslationStudio-1.0.0-Windows.zip` contains Win32 and Win64
Release Studio executables, the matched Win32 Release runtime and design-time
BPL set, Win64 Release runtime BPLs, product and package source, sample
projects, schemas, current guides in DOCX and PDF, this release note, README,
and the Apache 2.0 license. There is no separate installer. Extract the whole
archive into a new folder; do not mix its BPLs with packages from older builds.
Install only the appropriate **Win32 design-time BPL** in the RAD Studio IDE
using **Component > Install Packages > Add**. See the User and Setup Wizard
guides before installing components or processing a target project.

## Main workflow

The Studio scans saved Delphi projects, creates an incremental catalog,
translates eligible text through DeepL or Google Cloud Translation, supports
terminology correction and review, validates the result, and exports compact
runtime language packs. The Setup Wizard guides first-time setup; Maintenance
Studio supports subsequent scans, glossary edits, and deployment. The
project-local `dependencies\DelphiAppTranslation` tree is created and
maintained as a matched source set. The Studio does not rewrite target Pascal,
DFM, FMX, DPR, or DPROJ files. Developers add the documented compiler Search
path in RAD Studio for ordinary IDE builds.

Provider keys remain on the developer computer; the target application does
not need cloud access or a provider key at runtime. The release includes
right-to-left handling for supported languages and the corrected RAD Studio
package-shutdown behavior from the preceding maintenance work.

## Validation performed

The repository's `tools\verify_all.ps1` gate passed on September 30, 2026:
package and Studio builds, source-encoding and source/scan contracts, smoke
and runtime harnesses, an end-to-end VCL sample, build-path and shipped-unit
checks, and freshness checks for compiled artifacts. One layout-fitting
smoke test reported **skipped, cannot run here**; no claim is made that this
environment ran that test. The Win64 Release Studio was also built separately.
Live provider acceptance and every target application's visual/linguistic
behavior are not covered by the automated gate.

## Developer responsibilities

This is a development tool, not a translator for a finished EXE. Keep the
target project under version control and preserve backups. Machine
translation is a useful first draft, not a guarantee of correct meaning.
Review terminology, placeholders, dynamic text, RTL behavior, custom
controls, layout, all selected languages, and the final deployed application.
Report reproducible defects through GitHub Issues without posting keys,
private source, customer data, or unreviewed screenshots.

## License

Apache License 2.0; see `LICENSE` for the complete terms. Third-party tools
and translation-provider services retain their own terms and costs.
