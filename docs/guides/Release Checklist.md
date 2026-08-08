# Release Checklist

Last changed: August 8, 2026

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
  English source pack, component/runtime units, manifest, README, and deployment
  script.
- Hash every selected target project and form before and after kit generation;
  require byte-for-byte equality and zero target writes.
- Build and stream the matching VCL/FMX Win32 design packages and the Win32 and
  Win64 runtime packages in Debug and Release.
- Verify the optional typed language selector populates validated packs and
  changes the linked manager while preserving inherited `OnChange` behavior.
- For the advanced fallback, generate VCL and FMX previews and verify the final
  authorization gate, transaction backup, Apply, Restore, and Complete Reset.
- Verify that target preferences are written under `%LOCALAPPDATA%` and packs
  are read from `Localization\Languages` beside the executable.
- Update the real Word TOCs, repaginate, and export both guide PDFs through
  Microsoft Word.
- Render and inspect every documentation PDF page.
- Confirm the TOC-to-content transition starts on a new page, page numbering
  restarts correctly, and there are no blank, clipped, or overlapping pages.
- Build the source distribution without `bin`, `dcu`, `export`, credentials, or
  user-specific settings.
- Review Git status, stage only intended files, commit clearly, and push every
  configured public and private remote.
