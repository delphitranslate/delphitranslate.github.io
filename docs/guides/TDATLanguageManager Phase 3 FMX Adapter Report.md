# TDATLanguageManager Phase 3 FMX Adapter Report

Last changed: August 8, 2026

Status: Implemented and validated for Win32 and Win64

## Outcome

Phase 3 produced the production FireMonkey runtime adapter,
`TDATFMXLanguageManager`. One manager can serve an FMX application without a
component on every form. It listens to FireMonkey's additive lifecycle message
service, applies the active JSON pack before a form's `OnShow` event and first
paint, reapplies all eligible open forms after an immediate language change,
and removes destroyed forms from the shared manager's non-owning tracking table.

The implementation does not generate visual controls at runtime and does not
modify a target application's DPR, DPROJ, PAS, or FMX resources. The manager is
a normal `TComponent` descendant with inherited published properties suitable
for the Object Inspector. Palette registration and design-time packages remain
a later phase.

The pristine GA4 pilot application was not modified during this phase.

## Deliverables

- `source/components/DAT.Components.FMX.pas`
- stable-identity overloads in `source/runtime/DAT.Runtime.FMX.pas`
- `tools/tests/FMXLanguageManagerTests.dpr`
- `tools/tests/RunFMXLanguageManagerTests.ps1`

## Lifecycle architecture

The adapter subscribes to two public FireMonkey messages:

- `TFormBeforeShownMessage` applies the current generation to a form after its
  resource and `OnCreate` work are complete but before `OnShow` and painting.
- `TFormReleasedMessage` removes the form from tracking during destruction.

Subscription identifiers are retained and unsubscribed deterministically in
the component destructor. No exclusive application or screen event is replaced.
No idle polling, Windows hook, form inheritance requirement, or per-form helper
component is used.

`Screen.Forms` and `Screen.PopupForms` provide the inventory for instant
language changes. Duplicate references are suppressed. With
`TranslateHiddenForms=False`, a hidden form is intentionally skipped during an
immediate global change and is brought to the active generation by its next
before-show message. Setting the property to `True` includes hidden forms in
the global pass.

`AutoTranslateNewForms=False` disables lifecycle application without disabling
the public `ApplyToForm` method. This gives an application an explicit-control
option while preserving the one-manager architecture.

## Stable form identity

The FMX applicator now accepts a stable form identity separately from the live
form object. Component keys are composed with that identity, not with the live
form's mutable `Name`.

For example, both live instances below resolve to the same scanned resource:

- runtime `frmOrders` -> catalog root `frmOrders`;
- runtime `frmOrders_1` -> catalog root `frmOrders`.

The mapping is supplied through the Phase 2 class-to-resource-root metadata,
for example `TfrmOrders=frmOrders`. Existing callers of the original two-argument
FMX applicator remain source compatible and continue to use the form name.

## State preservation

The production adapter passes its inherited `PreserveControlState` setting to
the FMX applicator. When enabled, translated `Items` collections retain the
existing `ItemIndex`; the corresponding selected item changes language in place
rather than becoming blank or moving to a default. `OnChange` remains suppressed
during the collection replacement and is restored afterward so localization
does not trigger application business logic.

The tests exercise the date-range case directly: index 2 remains selected while
its visible value changes between `Letzte 28 Tage` and `Last 28 days`.

## Object Inspector contract

The adapter inherits the shared manager's published properties, including:

- `ApplicationId`, `LanguagesFolder`, and `SourceLanguage`;
- preferred-language and preference-storage settings;
- automatic owner, new-form, and open-form behavior;
- hidden-form and state-preservation policy;
- missing-pack and error behavior;
- exclusions and scanner-backed form identity mappings;
- diagnostics and language/translation events.

The adapter registers its runtime class for FMX resource streaming. The future
design-time package will register it on the Tool Palette; this phase does not
install anything into RAD Studio.

## Validation matrix

The production test uses ordinary designer-authored FMX forms and real temporary
JSON packs. It validates:

- auto-created form translation before `OnShow` and first paint;
- inherited and popup-style form coverage;
- duplicate simultaneous instances through stable identity;
- immediate English/German switching across visible forms;
- hidden-form generation behavior and translation at the next show;
- explicit application when automatic new-form handling is disabled;
- combo-box selection preservation across language changes;
- deterministic removal of every released form.

Results with Delphi 37.0:

| Target | Production FMX manager | Runtime regressions | Core regressions |
| --- | --- | --- | --- |
| Win32 | Pass | Pass | Pass |
| Win64 | Pass | Pass | Pass |

The Phase 1 lifecycle matrix was rerun after implementation. Its FMX scenarios
remain successful and its VCL findings remain unchanged. The older spike still
reports the duplicate-key limitation by design; the production adapter test
proves that the Phase 2 identity mapping resolves that limitation.

## Safety and compatibility

- No target application source or form resource was rewritten.
- The existing two-argument FMX applicator API remains available.
- Existing runtime and integration smoke suites pass on Win32 and Win64.
- The shared core remains free of VCL and FMX references.
- Application forms remain owned by their original owners, never by the manager.
- All UI application continues to use the shared core's main-thread and
  reentrancy guards.

## Remaining boundaries

This phase is the production FMX runtime layer, not the complete distributable
component product. It does not yet include:

- a VCL production adapter;
- design-time BPL/DCP packages and Tool Palette registration;
- an optional language-selector binding component;
- Studio generation of the manager configuration and identity metadata;
- real-application pilot deployment into the pristine GA4 copy.

Those boundaries are intentional. Phase 4 should investigate and implement the
VCL adapter only within the first-display limitations established by Phase 1,
or explicitly document any professional limitation that cannot be removed
without invasive target code.
