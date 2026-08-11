# Release Checklist

Last changed: August 10, 2026

- Confirm `.git/index.lock` is absent or remove it only when zero bytes and no
  Git process is running.
- Confirm no API keys or credential-like values appear in tracked files.
- Build Debug and Release for Win32 and Win64 with the RAD Studio 37.0
  environment.
- Run `tools\tests\RunPhase10ReleaseValidation.ps1` and require one uninterrupted
  pass of the complete Debug/Release Win32/Win64 matrix.
- Confirm core, VCL, FMX, package, designer streaming, selector, foundation,
  runtime, integration, Studio form, launch, and self-localization suites pass.
- Run the deterministic provider-contract VCL and FMX reference pilots under
  Win32 and Win64. Require protected-field review, AI Draft provenance, final
  review/approval, and the Italian title on launch.
- Verify unfinished-session recovery restores the exact pre-AI snapshot and
  that concurrent or protected JSON changes are rejected rather than merged.
- Treat live provider testing as optional external acceptance. If performed,
  use an owner-supplied restricted test key and never store it in fixtures or
  logs.
- When provider instructions change, confirm Google and DeepL endpoint and
  authentication details against current official provider documentation.
- Generate VCL and FMX Component Integration kits and verify their JSON packs,
  English source pack, component/runtime units, manifest, README, component
  installer, verified BPL set, and deployment script.
- Hash every selected target project and form before and after kit generation;
  require byte-for-byte equality and zero target writes.
- Build and stream the matching VCL/FMX Win32 design packages and the Win32 and
  Win64 runtime packages in Debug and Release.
- Confirm each design BPL imports no custom DAT runtime BPL, and verify the
  manual RAD Studio package-installation instructions before an installation
  test. Automatic package installation must remain unavailable.
- Confirm Studio result lists have stable row heights, workflow status guidance
  changes per page, catalog path navigation works, validation issues navigate to
  entries, and large-catalog review/approval actions preserve excluded work.
- Verify the required typed language selector populates validated packs and
  changes the linked manager while preserving inherited `OnChange` behavior.
  A connected designer-authored language menu is the supported alternative.
- Verify the Setup Wizard displays the exact detected `ApplicationId`, adds one
  marked and inherited Search Path/post-build block to the target `.dproj`,
  deploys packs to existing output folders, and does not modify Pascal source,
  form resources, or the `.dpr` file.
- For the advanced fallback, generate VCL and FMX previews and verify the final
  authorization gate, transaction backup, Apply, Restore, and Complete Reset.
- Verify that target preferences are written under `%LOCALAPPDATA%` and packs
  are read from `Localization\Languages` beside the executable.
- Refresh the real TOCs and export guide PDFs through Microsoft Word COM first.
  If Word fails or times out, use the bounded Playwright HTML/CSS fallback.
  Do not use LibreOffice.
- Render and inspect every documentation PDF page.
- Confirm the TOC-to-content transition starts on a new page, page numbering
  restarts correctly, and there are no blank, clipped, or overlapping pages.
- Build the source distribution without `bin`, `dcu`, `export`, credentials, or
  user-specific settings.
- Review Git status, stage only intended files, commit clearly, and push every
  configured public and private remote.
