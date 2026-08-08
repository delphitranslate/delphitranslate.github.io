# TDATLanguageManager Phase 2 Shared Core Report

Last changed: August 8, 2026

Status: Implemented and validated for Win32 and Win64

## Outcome

Phase 2 produced the framework-neutral foundation for the component-first
localization architecture. The new abstract `TDATCustomLanguageManager` owns
language-pack loading, language selection, preferences, stable form identity,
application generations, exclusion rules, diagnostics, error policy, and
lifetime tracking. It deliberately contains no VCL or FireMonkey references.

This phase does not yet place a component on a form, register a palette item,
or discover framework forms. Those are adapter responsibilities for the next
phases. It also makes no change to the pristine GA4 test application or to any
other target application's DPR, DPROJ, PAS, FMX, or DFM files.

## Deliverables

- `source/components/DAT.Components.Core.pas`
- `tools/tests/LanguageManagerCoreTests.dpr`
- `tools/tests/RunLanguageManagerCoreTests.ps1`

The core reuses the established `DAT.Runtime.LanguagePack` and
`DAT.Runtime.Manager` units. It does not duplicate JSON parsing or translation
application logic.

## Public component model

The abstract manager exposes Object Inspector-compatible configuration for:

- application identity and language-pack folder;
- source language and preferred-language loading;
- automatic owner, new-form, and open-form behavior;
- hidden-form and control-state policies for framework adapters;
- preference location and preference filename;
- missing-pack and error behavior;
- excluded forms;
- scanner-backed form class to resource-root mappings;
- diagnostics and lifecycle events.

Configuration that determines runtime construction is locked after successful
initialization. This avoids partially reconfiguring a live manager. Language
selection and translation application remain runtime operations.

## Stable form identity

The Phase 1 spike proved that Delphi can rename a second live instance of a
form, for example from `frmOrders` to `frmOrders_1`. Catalog keys based on that
mutable instance name therefore fail for duplicate form instances.

Phase 2 resolves this with an explicit class-to-resource-root map, represented
as Object Inspector string entries such as:

`TfrmOrders=frmOrders`

The scanner or framework adapter can register these mappings before manager
initialization. Translation lookup then uses the stable streamed resource root,
while exclusions may match the stable identity, instance name, or class name.
Blank lines are tolerated for safe editing in Delphi's string-list editor;
malformed or conflicting nonblank mappings are rejected.

## Runtime ownership and generation tracking

The manager owns exactly one `TTranslationRuntime`. Initialization resolves the
pack and preference locations, loads the preferred or source language, and
starts the first application generation. A successful language change advances
the generation. Each managed object records the generation last applied.

This makes repeated lifecycle signals inexpensive and idempotent: an object is
not translated twice during the same generation unless forced. A newly created
form is translated in the current generation, while a language change makes all
tracked forms eligible for the new generation.

The tracking dictionary is non-owning. When a tracked `TComponent` is destroyed,
`FreeNotification` removes it deterministically. The manager neither owns nor
frees application forms.

## Safety and event policy

All initialization, selection, translation, and tracking operations enforce the
Delphi main thread. Calls from a worker thread raise
`EDATLanguageManagerMainThreadError` before touching UI-facing state.

Application is protected against recursive entry. Event code cannot start a
second selection or translation pass while one is active. Expected internal
selection-to-application flow remains permitted.

The manager supports raise, notify-and-continue, and source-language fallback
policies. Events cover language changing/cancellation, language changed,
managed-object translation, translation errors, and missing translations.
Framework adapters receive abstract hooks for discovery, identity, translation,
and locale application without introducing framework dependencies into the
shared unit.

## Validation

The isolated test executable supplies mock components and a mock adapter; it
does not link VCL or FMX. It creates temporary English and German JSON packs and
validates:

- initialization and source-language application;
- automatic and explicit language selection;
- preference persistence and reload;
- translation and locale lookup;
- language-change cancellation;
- missing-pack keep-current and source fallback policies;
- stable identity for duplicate instances;
- exclusion by mapped resource identity;
- generation idempotence and forced application;
- translation error notification;
- main-thread rejection;
- reentrancy rejection;
- immutable initialized configuration;
- non-owning tracking and deterministic destruction removal;
- language-pack discovery.

Results with Delphi 37.0:

| Target | Core tests | Framework references |
| --- | --- | --- |
| Win32 | Pass | None |
| Win64 | Pass | None |

The Phase 1 VCL and FMX lifecycle spike was also rebuilt and rerun for Win32 and
Win64 after the core was added. It retained its prior results: FMX passes the
before-first-paint lifecycle gate; VCL idle discovery remains functional but is
not sufficient for a no-flicker first display.

## Boundaries retained for later phases

Phase 2 intentionally does not decide framework-specific form discovery or
control-state restoration. The FMX adapter can now use the proven additive
before-show message and delegate all policy to this core. The VCL adapter still
needs a professional first-display strategy; the Phase 1 report's warning must
not be hidden by the existence of the shared core.

Design-time registration, palette packages, optional language-selector binding,
Studio component-integration mode, and disposable real-application pilots also
remain later-phase work.

## Phase 3 gate

The shared core is ready for the FireMonkey production adapter. Phase 3 should
implement `TDATFMXLanguageManager` as a normal designer component, subscribe to
the additive FMX lifecycle messages, map forms to scanner identities, preserve
selected control state, and prove immediate language changes without editing
ordinary form source files.
