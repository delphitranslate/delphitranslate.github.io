# TDATLanguageManager Phase 5 Control State Report

Last changed: August 8, 2026

Status: Implemented and validated for VCL and FireMonkey, Win32 and Win64

## Outcome

Phase 5 hardened language changes so localization updates the interface without
damaging live user state. Both runtime applicators now distinguish translatable
designer content from writable user data when `PreserveControlState=True`, and
they snapshot and restore focus, text selection, caret position, selected list
index, and event handlers around a translation pass.

This phase changes runtime behavior only. It does not add visual controls,
modify target forms or source files, or alter the pristine GA4 pilot.

## Preservation contract

With `PreserveControlState=True`, which remains the manager default:

- writable FMX edit `Text` is treated as user data and is not replaced by a
  language-pack value;
- writable FMX and VCL memo `Lines` are treated as user data and are not
  replaced;
- read-only memo lines remain translatable, supporting instructional and
  informational memo controls;
- edit and memo `SelStart` and `SelLength` are restored after localization;
- the focused FMX control or focused VCL windowed control is restored;
- list and combo `ItemIndex` is restored after translated items are installed;
- a selected item therefore changes language in place rather than becoming
  blank or moving to a default;
- `OnChange` is temporarily detached while translated string collections are
  replaced and restored afterward.

Prompts, hints, captions, button text, labels, menu items, and read-only
instructional content continue to translate normally.

Setting `PreserveControlState=False` retains the explicit opt-out behavior for
applications that deliberately want pack content to replace editable designer
content. String-collection change events remain suppressed during the internal
replacement because localization should not impersonate user input.

## Why writable data is protected

An edit box or writable memo often contains customer names, notes, search text,
or other application data. That text is not interface chrome and must not be
sent back to a designer-authored default merely because the user changes the
interface language. Read-only memo text, by contrast, commonly represents
instructions and is a legitimate translation target.

This rule also avoids requiring fragile guesses based on whether a control is
currently focused or whether a framework happens to expose a `Modified` flag.
The public `ReadOnly` contract provides a stable and understandable boundary.

## Framework behavior

### FireMonkey

The FMX applicator preserves the form's `IControl` focus reference and restores
it after all properties and collections are processed. It snapshots selection
ranges for `TCustomEdit` and `TCustomMemo`. Writable edit text and writable memo
lines are skipped while static properties such as `TextPrompt` continue to
translate.

### VCL

The VCL applicator records the form's active control and whether it actually
held Windows focus. It restores focus only when the control is still focusable.
Selection ranges are retained for `TCustomEdit` descendants, including edits
and memos. Writable memo lines are protected; VCL edit content was never part
of the normal text-property translation list.

## Validation

The FMX and VCL production manager suites now enter real user-like state into
designer-authored sample forms before an instant German-to-English change:

- edit text: `Alice Martin`;
- edit selection: start 1, length 4;
- writable memo text: `Private user notes`;
- memo selection: start 2, length 5;
- date-range combo selection: index 2;
- keyboard focus: customer-name edit;
- `OnChange` handlers: attached to edit, memo, and combo.

After translation, both frameworks retain the editable text, memo text,
selection ranges, selected date-range index, and focus. The selected date-range
label changes language correctly, and no protected `OnChange` handler fires.

Results with Delphi 37.0:

| Target | FMX state suite | VCL state suite | Full runtime/integration suite |
| --- | --- | --- | --- |
| Win32 | Pass | Pass | Pass |
| Win64 | Pass | Pass | Pass |

The production suites also continue to pass their lifecycle, stable identity,
instant switching, hidden-form, explicit application, coexistence, and cleanup
checks.

## Deliberate boundaries

The preservation contract covers standard Delphi text, memo, and indexed
string controls handled by the current translation applicators. A custom control
that mutates unrelated application state from a property setter remains the
custom control author's responsibility. Future adapters should add explicit,
tested preservation for new translated property families rather than using a
broad binary snapshot of arbitrary control internals.

## Next gate

The runtime managers and their standard state-preservation layer are ready for
the next controlled phase: separate design-time packages and Tool Palette
registration. Package work must keep VCL and FMX dependencies isolated and must
prove that forms containing the manager remain fully editable in the Delphi IDE.
