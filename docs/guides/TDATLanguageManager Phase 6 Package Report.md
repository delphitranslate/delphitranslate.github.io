# TDATLanguageManager Phase 6 Package Report

Last changed: August 8, 2026

Status: Implemented and validated

## Outcome

Phase 6 produced a package architecture that keeps shared, VCL, FMX, and
design-time dependencies correctly separated. The manager classes can be
registered on the Delphi Tool Palette without placing design-only units in a
deployed application, and forms containing either manager remain normal
designer-authored DFM or FMX resources.

No package was silently installed into the developer's IDE. Installation is an
explicit developer operation after review.

## Package set

| Package | Purpose | Targets |
| --- | --- | --- |
| `DATLanguageManagerCoreRuntime` | JSON packs, preferences, shared runtime and manager core | Win32, Win64 |
| `DATLanguageManagerVCLRuntime` | VCL applicator and manager | Win32, Win64 |
| `DATLanguageManagerFMXRuntime` | FMX applicator and manager | Win32, Win64 |
| `DATLanguageManagerVCLDesign` | VCL Tool Palette registration | Win32 IDE |
| `DATLanguageManagerFMXDesign` | FMX Tool Palette registration | Win32 IDE |

Both design packages register one component on the `DAT Localization` palette:

- `TDATVCLLanguageManager` for VCL forms;
- `TDATFMXLanguageManager` for FireMonkey forms.

The shared units occur only in the core runtime package, preventing the same
unit from being loaded from two installed BPLs. Framework units occur only in
their matching packages.

## Designer ownership

Normal test forms were created as editable `.dfm` and `.fmx` resources with a
manager persisted as a nonvisual child component. The tests loaded the forms,
confirmed the manager field was present, and verified that `ApplicationId` and
`SourceLanguage` values streamed from the resource. No control or form was
constructed in runtime-only UI code.

## Validation

The automated package runner:

1. builds the common runtime package for Win32 and Win64;
2. builds each framework runtime package for Win32 and Win64;
3. builds both design-time packages for the installed Win32 Delphi IDE;
4. compiles and runs VCL and FMX designer-resource streaming fixtures for
   Win32 and Win64.

Every package and streaming fixture passes with Delphi 37.0. Generated BPL,
DCP, DCU, and executable files remain in the standard `bin` and `dcu` build
trees and are not source-controlled.

## Installation boundary

The design BPLs are build products, not application dependencies. A developer
installs only the VCL and/or FMX design package needed in RAD Studio. The IDE
then exposes the appropriate manager on the palette. Applications may compile
the runtime units statically or use the matching runtime BPLs according to their
normal Delphi build policy.

## Phase 7 gate

The package and streaming gates are clear. Phase 7 may add an optional
designer-owned language selector binding. It must bind existing menu or combo
controls rather than generate a visual selector at runtime, and it must remain
optional so applications can use their own language UI.
