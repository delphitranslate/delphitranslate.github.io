# Release Checklist

Last changed: August 7, 2026

- Confirm `.git/index.lock` is absent or remove it only when zero bytes and no
  Git process is running.
- Confirm no API keys or credential-like values appear in tracked files.
- Build Debug and Release for Win32 and Win64 with the RAD Studio 37.0
  environment.
- Run foundation, runtime, VCL, FMX, self-localization, and direct FMX
  form-streaming smoke tests.
- Run the deterministic API-free CSV/JSON VCL and FMX reference pilots under
  Win32 and Win64; require the Italian title on launch.
- Treat live provider testing as optional external acceptance. If performed,
  use an owner-supplied restricted test key and never store it in fixtures or
  logs.
- Confirm Google and DeepL endpoint/authentication instructions against current
  official provider documentation.
- Generate VCL and FMX integration previews; view every exact file diff and
  verify Apply remains disabled until all files are viewed and the final review
  confirmation is checked.
- Verify the deployment script, language manifest, JSON packs, generated unit,
  runtime units, VCL DPR startup, and FMX designer-persisted OnCreate wiring.
- Verify that target preferences are written under `%LOCALAPPDATA%` and packs
  are read from `Localization\Languages` beside the executable.
- Update the real Word TOCs, repaginate, and export both guide PDFs through
  Microsoft Word.
- Render and inspect every documentation PDF page.
- Confirm the TOC-to-content transition has no blank page and page numbering
  restarts correctly.
- Build the source distribution without `bin`, `dcu`, `export`, credentials, or
  user-specific settings.
- Review Git status, stage only intended files, commit clearly, and push every
  configured public and private remote.
