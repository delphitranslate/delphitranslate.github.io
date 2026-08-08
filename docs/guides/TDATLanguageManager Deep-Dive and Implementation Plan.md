# TDATLanguageManager Deep-Dive and Implementation Plan

Last changed: August 8, 2026

Status: Implemented and release-validated. Component Integration is the
recommended workflow; Automatic Source Integration is retained as an advanced
fallback.

The printable DOCX and PDF are the authoritative review copies. This Markdown
record preserves the decision summary and implementation sequence in the source
tree.

## Executive finding

A component-first architecture is technically credible and offers a much better
trust model than automatic source rewriting. It is not a zero-change approach:
Delphi must still persist a component and link runtime units. Most current Studio
subsystems remain reusable. The recommended course is an additive proof of
concept, not immediate removal of the working integration engine.

FireMonkey exposes additive form lifecycle messages, including before-show and
release notifications, making a one-manager design promising. VCL exposes live
form collections and multicasting application idle events but no equivalent
public before-show broadcast. VCL first-paint timing and event coexistence are
release-gate questions.

## Recommended architecture

- `TDATCustomLanguageManager`: framework-neutral configuration, runtime
  ownership, generation tracking, events, and error policy.
- `TDATVCLLanguageManager`: VCL discovery and application bridge.
- `TDATFMXLanguageManager`: FMX message-based lifecycle bridge.
- Separate VCL and FMX design-time packages.
- Existing JSON packs, runtime core, scanner, providers, and validation retained.
- One manager per application; no required component on ordinary forms.

## Completed controlled phases

1. Preserve the current baseline and isolate the proof.
2. Instrument FMX and VCL lifecycle timing.
3. Build the shared manager core.
4. Complete FMX manager coverage.
5. Complete or explicitly bound VCL manager coverage.
6. Build and test the runtime and design-time package graph.
7. Add and test optional VCL and FMX language-selector controls.
8. Add non-mutating Component Integration mode to the Studio.
9. Test disposable copies of real FMX and VCL applications.
10. Complete the release decision after Debug/Release Win32/Win64 validation.

## Recommendation

The proof passed its lifecycle, coexistence, state-preservation, package,
streaming, selector, non-mutation, real-application, and complete release tests.
Component Integration is therefore the recommended path. Automatic Source
Integration remains available as an explicitly labeled advanced fallback.
