# Delphi App Translation Studio - Total Stabilization Contracts

Last changed: August 27, 2026

This document records the architectural contracts enforced by the total stabilization release. These contracts apply to arbitrary Delphi VCL and FMX applications; they are not Carillon- or VCL2FMXConverter-specific fixes.

## Release boundary

- Windows Win32 and Win64 Delphi VCL and FMX applications are supported.
- Runtime translation is offline and consumes validated JSON packs.
- Provider access exists only in the Translation Studio.
- Designer-authored forms remain editable in RAD Studio. No runtime UI is constructed.
- The recommended component kit does not mutate the target project.

## Persistence and recovery

- Catalogs, settings, preferences, packs, layout overrides, glossaries, translation memories, and interchange files are written through staging and atomic replacement.
- A valid prior file is retained as `.previous` when replacement succeeds.
- Invalid current files are quarantined instead of silently accepted.
- Recovery and rejection decisions are diagnostic events.

## Runtime-pack admission

- JSON object keys must be unique.
- The file name must match the locale.
- `applicationId`, framework, format version, locale, and checksum must match the target runtime.
- A translated pack requires a compatible source-language pack.
- A stale saved locale falls back to the validated source language and repairs the saved preference.

## Runtime lifecycle

- One manager owns one runtime registration and releases it deterministically.
- FMX uses the additive before-show lifecycle.
- VCL applies the owner at initialization and retranslates open forms on language changes.
- Delphi VCL has no universal additive before-show hook for every dynamically created modeless form. Applications requiring translation before first paint call `ApplyToForm` immediately before `Show` or `ShowModal`.
- Post-show replay loops, timers, and `Application.ProcessMessages` translation loops are prohibited.

## Direction and layout

- Every language switch restores the designer baseline before applying exactly one LTR or RTL transformation.
- Menu, status, input, grid, and container direction are part of the same switch transaction.
- Only relative, reversible layout proposals may be accepted automatically.
- Absolute geometry, artwork placement, and grid-column widths remain reviewed layout decisions.
- Header fitting may reduce font size within configured limits, then wrap when permitted; it must not overlap or clip.

## Scanner and HTML

- Scans are deterministic, cancellable, and prune generated/output trees.
- Identical duplicate observations are counted and ignored; conflicting duplicate keys remain visible as errors.
- HTML translation changes visible prose only and preserves comments, scripts, styles, protected nodes, product identifiers, technical tokens, and markup structure.

## Integration and deployment

- Component kits are assembled in staging, validated against their manifest and hashes, and published atomically.
- Build/deploy operations use staging, hash verification, and rollback.
- A failed operation cannot publish a partial kit or partial language-pack set.

## Responsiveness and diagnostics

- Scan, provider, build, deployment, and final processing work execute outside the UI thread.
- Progress is queued safely to the UI and cancellation is observed at bounded checkpoints.
- Production source contains no `Application.ProcessMessages` loop.
- Diagnostics record operation, artifact, recovery, and corrective context without credentials or authenticated response bodies.

## Release gate

The release is not eligible for promotion until `tools\verify_all.ps1` and `tools\tests\RunPhase10ReleaseValidation.ps1` complete successfully, including Win32/Win64, Debug/Release, VCL/FMX, package, streaming, launch, self-localization, layout, scanner, persistence, and integration checks.
