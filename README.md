# Delphi App Translation Studio

![ALPHA TEST - testing and feedback welcome](images%20and%20icons/README-Alpha-Test-Banner.svg)

> [!IMPORTANT]
> **Alpha testing is open.** You may download, build, use, evaluate, and fork
> Delphi App Translation Studio. Active development is still underway, so a
> feature may be incomplete, may change without notice, or may not behave as
> an alpha tester expects. Use test copies of Delphi projects, keep them under
> version control, and verify every generated catalog, language pack, component
> setting, and translated screen before relying on the result.
>
> Alpha feedback is welcome at **churchesite@gmail.com**. Reports are most
> useful when they include the Delphi version, framework, platform, exact steps,
> expected result, actual result, and screenshots. Do not send API keys,
> credentials, customer data, or proprietary source code.

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

## Downloading the alpha source

### Download a ZIP archive

1. On the repository's GitHub page, choose **Code**.
2. Choose **Download ZIP**.
3. Extract the entire archive to a normal development folder. Do not build
   directly inside the ZIP archive or a temporary preview folder.
4. Keep the extracted repository structure intact so package, source,
   documentation, and localization paths continue to resolve correctly.

### Clone or fork with Git

Clone the repository when you want to receive later alpha updates:

```text
git clone https://github.com/tmartindub/DelphiAppTranslationStudio.git
```

You are also welcome to fork the repository through GitHub and develop or test
against your own fork. Keep local work on a separate branch so upstream alpha
changes can be reviewed before they are merged.

## Installing and starting the alpha

There is no supported binary installer yet. Build the Studio and its design
packages from source with RAD Studio 13 Florence:

1. Open `DelphiAppTranslationStudio.dproj` in RAD Studio.
2. Select Win32 or Win64 and Debug or Release, then build the project.
3. Run the generated Studio executable from
   `bin\<Platform>\<Configuration>`.
4. Build the VCL or FMX DAT Language Manager runtime and design packages needed
   by the target application.
5. In RAD Studio, choose **Component > Install Packages > Add** and select the
   matching Win32 Release design BPL from `bin\packages\Win32\Release`.
   Do not use **Install Component** and do not select a `.dpk` file there.
6. Open a disposable copy of the target Delphi project, place the appropriate
   DAT language manager and connected language selector on its primary form,
   save the project, and follow the Setup Wizard.

The installed design package must match the RAD Studio version used to build
it. If package loading fails, remove the older package entry, rebuild the
packages with the active toolchain, and add the newly built BPL.

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

Documentation was reviewed and regenerated with LibreOffice on
**August 25, 2026**. The DOCX guides contain real generated tables of contents;
matching PDFs are provided for convenient reading.

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
