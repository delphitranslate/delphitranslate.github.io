# TDATLanguageManager Phase 10 Release Decision Report

Completion date: August 8, 2026

## Decision

Phase 10 is complete. Component Integration is approved as the recommended
Delphi App Translation Studio workflow for VCL and FireMonkey applications on
Win32 and Win64. Automatic Source Integration remains available as an
explicitly labeled advanced fallback.

## Release gate

`tools\tests\RunPhase10ReleaseValidation.ps1` completed one uninterrupted pass
of the release matrix:

- Debug and Release core, VCL, and FMX runtime packages.
- Debug and Release VCL and FMX Win32 design packages.
- Win32 and Win64 DFM/FMX streaming and typed selector behavior.
- Win32 and Win64 manager core, FMX lifecycle, and VCL lifecycle suites.
- Foundation, runtime, and integration suites, including component-kit target
  SHA-256 non-mutation proof.
- Studio Debug and Release builds for Win32 and Win64.
- Studio direct form creation/streaming and ordinary launch in all four build
  combinations.
- Italian Studio self-localization in all four build combinations.

The Phase 9 disposable real-application pilots also remain part of the evidence:
The FireMonkey pilot (FMX) and the second VCL pilot (VCL) built and opened with
translated first forms on Win32 and Win64 without editing their originals.

## Defect repaired during the gate

Package streaming fixtures formerly wrote their FMXDesignHost JSON below the
Studio executable's `Localization` directory. That test fixture could shadow
the Studio's own Italian pack during later self-localization tests. Package
test executables and fixtures now use isolated
`bin\tests\packages\<Platform>\<Configuration>` directories. The complete
matrix passed after the repair.

## Supported production path

1. Scan, translate, validate, and export JSON packs in the Studio.
2. Generate Component Integration for the selected VCL or FMX project.
3. Install the matching Win32 design package when needed.
4. Place one framework-specific manager on the primary form in the Delphi Form
   Designer and configure it through the Object Inspector.
5. Optionally place the matching language selector and bind it to the manager.
6. Add the generated component source path or installed source location.
7. Deploy the kit's `Localization\Languages` directory beside each executable.
8. Build and test Win32 and Win64 normally.

The Studio performs no automatic write to the selected target in this mode.

## Documented boundary

FMX provides an additive before-show message and therefore covers dynamically
created normal forms before first paint. VCL has no equivalent public additive
notification for every dynamically created modeless form. The VCL manager
discovers ordinary forms on application idle and handles modal forms before
display; an application that requires a strict no-flicker first display for a
dynamic modeless form calls the manager's `ApplyToForm` before `Show`.

## Release conclusion

The component-first architecture met its code-preservation, package,
lifecycle, state, selector, non-mutation, cross-architecture, and real-app
release gates. No unresolved defect prevents the recommended workflow from
proceeding to user acceptance testing.
