# TDATLanguageManager Phase 4 VCL Adapter Report

Last changed: August 8, 2026

Status: Implemented and validated with an explicit modeless first-display boundary

## Outcome

Phase 4 produced the production VCL runtime adapter,
`TDATVCLLanguageManager`. One manager can serve a VCL application, discover
ordinary and MDI forms without replacing application-wide events, translate
modal forms before `OnShow`, apply stable catalog identities to duplicate form
instances, switch eligible open forms immediately, and release tracked forms
without assuming ownership.

Phase 4 is successful under the gate established before implementation. It does
not claim an impossible guarantee: stock VCL has no public additive notification
equivalent to FireMonkey's before-show message for every dynamic modeless form.
A newly shown modeless form discovered at idle can paint once in the source
language. This limitation is exposed in tests and in the component contract.

The pristine GA4 pilot application was not modified.

## Deliverables

- `source/components/DAT.Components.VCL.pas`
- stable-identity overloads in `source/runtime/DAT.Runtime.VCL.pas`
- `tools/tests/VCLLanguageManagerTests.dpr`
- `tools/tests/RunVCLLanguageManagerTests.ps1`

## Safe discovery architecture

The adapter owns a private `TApplicationEvents` instance. It uses:

- `OnIdle` for safe, nonexclusive inventory of `Screen.CustomForms`;
- `OnModalBegin` to inventory hidden forms immediately before VCL calls the
  modal form's `Show` method.

The adapter never assigns `Application.OnIdle`, `Screen.OnActiveFormChange`, or
another exclusive global event. A second independent `TApplicationEvents`
subscriber continues to receive idle events in the production test.

Idle inventory is throttled by the published `IdleScanInterval`, which defaults
to 100 milliseconds. Setting it to zero scans every idle notification. The
handler does not alter VCL's `Done` flag. `AutoDiscoverForms=False` disables
idle and modal discovery while retaining explicit application and immediate
language operations.

## First-display behavior

The VCL behavior is deliberately divided into cases:

| Form case | Default timing |
| --- | --- |
| Manager's owner form | Applied during manager initialization/loading |
| Modal form | Applied from additive `OnModalBegin`, before `OnShow` |
| Existing visible forms on language change | Applied immediately |
| Dynamic modeless form | Discovered at idle; first source-language paint is possible |
| Dynamic modeless form requiring pre-display translation | Call `ApplyToForm` after creation and before `Show` |

The explicit call is a normal public component operation, not generated form UI
or hidden source rewriting. The Studio can document or optionally generate this
single call only when an application requires a strict no-flicker guarantee for
a dynamic modeless form.

The favorable Phase 1 timing of `Screen.OnActiveFormChange` was not used because
it is an exclusive event property and cannot be made reliably composable with
unrelated libraries.

## Stable identity and state

The VCL applicator now has a backward-compatible overload accepting the stable
scanner identity independently of the live form name. A second live instance
renamed by Delphi to `frmOrders_1` therefore continues to use catalog keys under
`frmOrders` when the mapping contains `TfrmOrders=frmOrders`.

The manager passes `PreserveControlState` to the applicator. Translated list
content retains `ItemIndex`, and `OnChange` is suppressed and restored around
the replacement. Production testing confirms that date-range index 2 remains
selected while its displayed item changes between German and English.

## Validation

The production suite uses designer-authored VCL forms and real temporary JSON
packs. It validates:

- modeless idle discovery and the documented first-display boundary;
- inherited form discovery;
- modal translation before `OnShow`;
- duplicate simultaneous instances through stable identity;
- immediate English/German switching;
- hidden-form generation behavior;
- explicit application before modeless display;
- combo-box selection preservation;
- coexistence with an independent `TApplicationEvents` subscriber;
- deterministic removal of released forms.

Results with Delphi 37.0:

| Target | Production VCL manager | Runtime regressions |
| --- | --- | --- |
| Win32 | Pass | Pass |
| Win64 | Pass | Pass |

The earlier VCL normal and MDI lifecycle matrix remains the authoritative
evidence for first-paint behavior. The production adapter accepts that evidence
rather than introducing an invasive hook to hide it.

## Safety and compatibility

- No target form, DPR, DPROJ, or source unit was modified.
- Existing two-argument VCL applicator calls remain compatible.
- The manager never owns or frees application forms.
- Main-thread and reentrancy protection comes from the shared core.
- Form tracking is generation-based and uses destruction notifications.
- No component is required on ordinary forms.

## Phase 5 gate

Phase 4 meets the approved bounded VCL gate, so Phase 5 may proceed. Phase 5
should harden cross-framework preservation of live application state during
language changes, with explicit tests for selections, editable text, focus,
caret/selection ranges, and event suppression where the frameworks expose safe
public state.
