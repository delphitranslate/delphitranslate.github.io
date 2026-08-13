# Delphi App Translation Studio

![ALPHA RELEASE - controlled technical evaluation](images%20and%20icons/README-Caution-Banner.svg)

> [!CAUTION]
> **Alpha release - for controlled technical evaluation only.**
>
> Due to the ongoing development, there is no guarantee that this software always function
> or provide any usable results at ths time. Therefore, users who download this software will be
> using it at their own risk.
>
> When this software finally provides consistent results, it will be upgraded to a
> Beta testing status.
>
> This is actively changing pre-release software. There is no supported
> installer, stable binary distribution, or 1.0 release. Use a disposable,
> version-controlled or independently backed-up copy of every Delphi project.
> Verify every generated catalog, language pack, component setting, and
> translated runtime screen before wider use.
>
> Comments about this alpha software are welcome and should be sent to:
> churchesite@gmail.com  

## What it is

Delphi App Translation Studio helps a developer use a Delphi application in
the language they know best. For example, a developer who receives an English
business application but works in Greek can scan the application, create a
Greek language pack, and run the application with its labels, buttons, menus,
headings, dates, times, and other supported interface text in Greek. The same
process can create Spanish, French, German, or other language packs, so the
application can be adapted for the developer's own language or for the people
who use it.

The Studio is a Windows desktop tool for Delphi VCL and FireMonkey
applications. It scans saved designer-authored forms and selected Delphi
resources, creates an editable JSON catalog, translates eligible interface
text through Google Cloud Translation or DeepL, validates the result, and
exports offline JSON language packs. The developer's Studio computer needs
Internet access only while calling the selected provider. After deployment,
the target application reads its local language packs and does not need
Internet access or an API key at runtime.

## Alpha scope

- Delphi VCL and FMX target applications on Windows Win32 and Win64.
- Translation Studio builds for Win32 and Win64, Debug and Release.
- Google Cloud Translation Basic v2 and DeepL API providers.
- Windows Credential Manager storage or session-only provider keys.
- Incremental catalogs, terminology review, validation, layout proposals,
  immediate language switching, and offline runtime packs.
- A Setup Wizard that leads a first-time project through scanning, translation,
  validation, component-kit generation, deployment, and optional builds.

macOS, iOS, Android, Linux, C++Builder, and runtime cloud translation are not
part of the current alpha scope. Delphi 12.x and clean-machine installation
remain compatibility items to be tested.

## Recommended first-time workflow

1. Make a pristine copy and a separate disposable test copy of the target
   Delphi project. Confirm the test copy builds before localization.
2. Install the matching DAT Language Manager design-time package through RAD
   Studio's normal **Component > Install Packages > Add** command.
3. In the target Form Designer, place one language manager and one connected
   visible language selector on the primary form. Add supporting labels or
   menu items, set ApplicationId/LanguagesFolder/SourceLanguage, and choose
   **File > Save All**.
4. Close the target project and start the Studio. Choose **Run Setup Wizard**.
5. Select the project, source and target languages, provider, and deployment
   destinations. The Wizard scans the saved project and translates unresolved
   entries during its single controlled processing pass.
6. Review the generated catalog, terminology, validation results, layout
   proposals, safety backup, and component kit. Final processing does not
   rewrite Pascal, DFM, FMX, or DPR source.
7. On the final page, optionally authorize creating/replacing the deployed
   application executable, select Win32/Win64 and Debug/Release targets, and
   choose the build action. JSON packs are written beside each successful
   executable under `Localization\\Languages`.
8. Build and run the selected target copies. Test every language, form,
   restart/persistence path, dynamic-data screen, and translated layout.

For existing catalogs or maintenance work, choose **Open Maintenance Studio**
instead of the Wizard. The maintenance workflow provides direct Project, Scan,
Translate, Validation, Export, Integration, and Provider Settings pages.

## Safety model

Scanning is read-only. The Wizard creates a timestamped safety backup before
final processing and uses a marked, transactional DPROJ configuration block for
the ComponentSource Search Path and post-build pack deployment. The recommended
Component Integration path does not rewrite target Pascal, DFM, FMX, or DPR
files.

Deployment is destination-specific. JSON packs may be created or replaced in a
selected application folder. The application `.exe` is created or replaced
only when the developer explicitly checks the executable deployment
authorization. The source project is not replaced by that operation.

## Known alpha limitations

- Dynamic runtime text requires explicit application integration; it is not
  always discoverable as static form text.
- A translation can be wider than its English source. Word wrapping,
  AutoSize, control dimensions, grid columns, charts, and complex forms may
  need developer review.
- Translation-provider wording and terminology still require human review,
  especially for short ambiguous words such as Play, Close, Schedule, or
  Activate.
- External HTML help is a separate localization concern.
- Removable drives can take time to wake. The Wizard retries pack deployment,
  but destination availability and write permissions still matter.
- Provider charges, quotas, API restrictions, and account security are the
  developer's responsibility.

## Building from source

The verified development toolchain is RAD Studio 13 Florence with Win32 and
Win64 compilers. Open `DelphiAppTranslationStudio.dproj` in RAD Studio and
build the desired platform/configuration. Local executables are written under
`bin\\<Platform>\\<Configuration>` and compiler units under `dcu`.

The repository does not currently publish a supported installer. Source users
should build locally and evaluate with a clean test project.

## Repository layout

```text
bin/                 Local executables; not a stable binary distribution
dcu/                 Local compiler output
docs/guides/         User, Setup Wizard, and Engineering guides
docs/pdf/            Companion PDFs
export/              Generated catalogs and component kits
help/                Help source
images and icons/    Product artwork and repository banner
packages/            Delphi runtime/design package source
samples/             VCL and FMX fixtures
source/              Studio, scanner, catalog, provider, and runtime source
tools/tests/         Automated validation and smoke tests
```

## Documentation

- [Setup Wizard Guide](docs/guides/Delphi%20App%20Translation%20Studio%20Setup%20Wizard%20Guide.docx)
- [User Guide](docs/guides/Delphi%20App%20Translation%20Studio%20User%20Guide.docx)
- [Engineering Guide](docs/guides/Delphi%20App%20Translation%20Studio%20Engineering%20Guide.docx)
- Companion PDFs are in [`docs/pdf`](docs/pdf/).
- Engineering history is in [`docs/guides/Engineering Notes.md`](docs/guides/Engineering%20Notes.md).

## Reporting alpha feedback

Please include the RAD Studio/Delphi version, VCL or FMX, Win32 or Win64,
Debug or Release, exact Wizard step, expected and actual behavior, screenshots,
and relevant catalog counts or paths. Never publish API keys, credentials,
private source, customer data, or proprietary language packs.

## Release decision

This repository is suitable for a limited technical alpha and contributor
feedback. It is not a production release. Version 1.0 requires a clean-clone
build, clean IDE package-installation test, VCL and FMX acceptance, Win32 and
Win64 validation, removable-drive deployment testing, documentation review,
license selection, and a complete source-distribution audit.
