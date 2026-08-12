# Stages 4-10 Runtime Layout Engineering Notes

Last changed: August 11, 2026

## Outcome

Delphi App Translation Studio can now persist approved, language-specific layout adjustments inside each offline runtime JSON pack and apply them through the existing VCL or FireMonkey language-manager component. Delphi Pascal, DFM, FMX, DPR, and DPROJ source files are not edited by this feature.

## Runtime pack schema

Runtime language packs now use schema version 3. The optional `layout` array contains only accepted rules for these safe properties:

- `Width`
- `Height`
- `WordWrap`
- `AutoSize`

Each rule records the form, component, property, designer/original value, translated-language value, and source checksum. Older schema versions 1 and 2 remain loadable.

## Decision and export workflow

The Localization Review Center regenerates proposals from the current saved Delphi resources and catalog. A prior decision is restored only when form, component, property, and source checksum all match. This makes changed or deleted controls fall back to Pending instead of silently reusing a stale decision.

The Review Center supports individual decisions plus `Accept All Safe Proposals` and `Reset All to Pending`. Only accepted safe properties are embedded during runtime-pack export. Pending, rejected, manual, unsupported, wrong-application, and wrong-language proposals are not exported.

## Runtime behavior

When selecting another language, the manager first restores the outgoing pack's recorded original layout values on each managed form. It then loads the new language pack and applies translated text followed by its accepted layout values. This prevents cumulative growth when repeatedly switching languages and restores designer dimensions when returning to the source language.

Values are type checked and bounded. Missing forms, controls, or properties are skipped. Existing focus, selection, editable text, item selection, and event-suppression protections remain active.

## Framework coverage

Both adapters implement the same neutral layout rules:

- `DAT.Runtime.FMX` supports floating-point sizes and Boolean properties.
- `DAT.Runtime.VCL` supports integer sizes and Boolean properties.

The generated component integration kit already copies these runtime units, so newly generated kits include the feature without modifying target source.

## Verification

The August 11, 2026 complete release gate passed:

- package builds and designer streaming, Debug and Release;
- Win32 and Win64 core manager tests;
- FMX and VCL manager lifecycle and instant-switch tests;
- FMX and VCL runtime smoke tests, including layout apply and restore;
- foundation, scanner, catalog, runtime-pack, validation, and export tests;
- sample integration and language-pack deployment tests;
- Studio FMX form creation and streaming;
- Studio Win32/Win64 Debug/Release builds and launch tests;
- Studio self-localization tests.

## Deliberate boundaries

Automatic position movement, font changes, arbitrary RTTI properties, and source-form rewriting remain excluded. Complex collisions, graphs, grids, and substantial redesigns still require developer review. This boundary keeps automatic layout repair conservative and reversible.

Formal User and Engineering Guide regeneration remains deferred until the workflow stabilizes, as previously agreed. These notes are the authoritative implementation record for Stages 4-10 in the interim.
