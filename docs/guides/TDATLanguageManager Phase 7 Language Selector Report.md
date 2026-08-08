# TDATLanguageManager Phase 7 Language Selector Report

Completion date: August 8, 2026

## Outcome

Phase 7 is complete. The component suite now includes optional, framework-native
language selectors for both VCL and FireMonkey:

- `TDATVCLLanguageComboBox`
- `TDATFMXLanguageComboBox`

Both controls are placed, sized, aligned, and configured in the Delphi Form
Designer. No visual control is constructed at runtime. A developer connects the
selector's `LanguageManager` property to the form's manager in the Object
Inspector.

## Runtime contract

At runtime, `AutoPopulate=True` calls `RefreshLanguages`. The selector asks the
manager for its validated language-pack descriptors, shows the canonical native
language name, and optionally appends the locale code. Invalid, empty,
wrong-application, and duplicate packs remain excluded by the shared discovery
engine.

Selecting an item calls the linked manager's `SelectLanguage`, which preserves
the established immediate reapplication and preference behavior. The inherited
change notification is still dispatched, so a developer may use the ordinary
`OnChange` event without the selector taking ownership of that event slot.

Public `RefreshLanguages` supports applications that deploy packs after form
loading. Public `SelectLanguageCode` provides an explicit code-based selection
operation. `ShowLanguageCode` and `AutoPopulate` are editable in the Object
Inspector.

## Design-time integration

The VCL and FMX runtime packages contain only their applicable selector. The two
design packages register each manager and selector together on the
`DAT Localization` Tool Palette page. DFM and FMX fixtures prove that the
selector and its typed reference to the manager stream normally.

## Validation

The elevated Delphi package suite passed for:

- Core, VCL, and FMX runtime packages on Win32 and Win64.
- VCL and FMX design-time packages for the Win32 RAD Studio IDE.
- VCL DFM and FMX resource streaming on Win32 and Win64.
- Discovery and display of two valid JSON language packs.
- Programmatic German selection and propagation to the linked manager.
- Typed selector-to-manager references streamed from designer resources.

## Boundaries

The selector does not create a menu, toolbar, or other UI. It is an optional
designer-owned control for applications that want a ready-made language list.
If packs are added after startup, the application calls `RefreshLanguages`.
Applications with custom navigation may use the manager directly and omit this
control.
