# Release Checklist

Last changed: August 6, 2026

- Confirm `.git/index.lock` is absent or remove it only when zero bytes and no
  Git process is running.
- Confirm no API keys or credential-like values appear in tracked files.
- Build Debug and Release for Win32 and Win64 with the RAD Studio 37.0
  environment.
- Run foundation, runtime, VCL, FMX, self-localization, and direct FMX
  form-streaming smoke tests.
- Test provider connections manually with owner-supplied restricted test keys;
  do not store those keys in fixtures or logs.
- Confirm Google and DeepL endpoint/authentication instructions against current
  official provider documentation.
- Generate a VCL and an FMX integration preview and verify the deployment script,
  language manifest, JSON packs, generated unit, and runtime units.
- Verify that target preferences are written under `%LOCALAPPDATA%` and packs
  are read from `Localization\Languages` beside the executable.
- Update the real Word TOCs, repaginate, and export both guide PDFs through
  Microsoft Word.
- Render and inspect every documentation PDF page.
- Build the source distribution without `bin`, `dcu`, `export`, credentials, or
  user-specific settings.
- Review Git status, stage only intended files, commit clearly, and push every
  configured public and private remote.
