# TDATLanguageManager Phase 1 Lifecycle Spike Report

Last changed: August 8, 2026

Status: Phase 1 complete. Prototype evidence only; these spike classes are not
production components and are not installed in RAD Studio.

## Executive result

The lifecycle spike produced a clear, split result:

- **FireMonkey passed the manager-only lifecycle test.** A single nonvisual
  manager received `TFormBeforeShownMessage`, applied the JSON pack before
  `OnShow`, and completed before the first observed paint. This held for
  auto-created, dynamically created, modeless, modal, ownerless, inherited,
  and popup-style forms on Win32 and Win64.
- **VCL form discovery passed, but idle-based first-display translation
  failed.** A single manager using the public, multicasting
  `TApplicationEvents.OnIdle` discovered and translated every tested form,
  including MDI forms. In every tested case, however, `OnShow` and the first
  paint occurred in the source language before the idle callback applied the
  pack. The result was a second translated paint.
- **VCL exposes a pre-paint active-form signal, but it is not a safe default
  integration point.** `TScreen.OnActiveFormChange` fired after `OnShow` and
  before the first paint in the normal, dynamic, ownerless, inherited,
  stay-on-top, and modal cases. It is a single exclusive event property, not a
  multicast service. A manager would have to own or chain that event, making
  it vulnerable to ordering and replacement by other libraries. Phase 1
  therefore does not promote it to the production design.
- **A separate stable-form-identity problem was confirmed in both
  frameworks.** A second live instance of the same form resource is renamed
  by Delphi, for example from `frmFMXLifecycle` to
  `frmFMXLifecycle_1`. Current JSON keys use the runtime form `Name`, so the
  manager discovers the second instance but finds no matching translations.
  Production work must resolve form identity independently of a mutable or
  auto-suffixed instance name.

The Phase 1 exit condition is therefore satisfied: FMX has a reliable
manager-only lifecycle, while VCL's public nonexclusive discovery mechanism
has a documented first-paint limitation. No GA4 source was modified.

## Scope and environment

| Item | Value |
|---|---|
| RAD Studio | Version 37.0 toolchain and framework source |
| Platforms | Windows Win32 and Win64 |
| Compilers | `dcc32` and `dcc64` |
| Frameworks | FireMonkey and VCL |
| Runtime data | In-memory schema-version-1 JSON packs |
| Existing code reused | `DAT.Runtime.LanguagePack`, `DAT.Runtime.FMX`, and `DAT.Runtime.VCL` |
| Production target modified | None |
| GA4 pristine pilot modified | No |

The forms used for instrumentation are normal designer-editable `.fmx` and
`.dfm` resources. Test-only code controls creation categories and records
framework events; the visual form definitions were not built exclusively at
runtime.

## Prototype boundaries

Two intentionally temporary component classes were created:

- `TDATFMXLanguageManagerSpike` subscribes to FMX form-handle,
  before-show, activation, and release messages. It applies each live form
  once through the existing FMX runtime applicator.
- `TDATVCLLanguageManagerSpike` owns a `TApplicationEvents` instance. Its idle
  callback inventories `Screen.CustomForms`, applies newly discovered forms
  through the existing VCL runtime applicator, and uses `FreeNotification` to
  remove destroyed forms.

Neither class contains the Phase 2 shared core, published Object Inspector
contract, language generations, preference handling, package registration,
or production error policy. They exist solely to answer lifecycle questions.

## FireMonkey evidence

### Observed order

The representative FMX order was:

1. Handle-created message. The streamed form name can still be empty here.
2. Form `Loaded`.
3. Form `OnCreate`.
4. Form `AfterConstruction`.
5. `TFormBeforeShownMessage`.
6. Manager applies the language pack.
7. Form `OnShow` sees translated text.
8. Form activation.
9. First observed paint sees translated text.

The before-show message is the decisive point. It is additive, contains the
form reference, occurs after streaming and `OnCreate`, and precedes both
`OnShow` and paint. The earlier handle-created message is useful for
instrumentation but is too early to rely on the final streamed `Name`.

### Scenario matrix

| FMX scenario | Discovered | Translated before `OnShow` | First paint translated | Result |
|---|---:|---:|---:|---|
| Auto-created main form | Yes | Yes | Yes | Pass |
| Dynamic modeless form | Yes | Yes | Yes | Pass |
| Ownerless form | Yes | Yes | Yes | Pass |
| Inherited form | Yes | Yes | Yes | Pass |
| Popup-style form | Yes | Yes | Yes | Pass |
| Modal form | Yes | Yes | Yes | Pass |

The matrix passed identically on Win32 and Win64. Modal display generated the
before-show notification more than once in the observed implementation, but
the manager's applied-form dictionary prevented duplicate property work.

### FMX conclusion

FMX clears the lifecycle gate for a one-manager design. Phase 2 may treat the
FMX before-show subscription as the reference lifecycle. The production class
must keep the stored subscription identifiers, unsubscribe deterministically,
apply only on the main UI thread, and retain generation-based idempotence.

## VCL evidence

### Idle-discovery order

The representative VCL order was:

1. Form `Loaded`.
2. Form `OnCreate`.
3. Form `AfterConstruction`.
4. Form `OnShow` sees source text.
5. Form activation.
6. First paint shows source text.
7. `TApplicationEvents.OnIdle` inventories open forms.
8. Manager applies the pack.
9. A second paint shows translated text.

This is deterministic evidence against advertising idle inventory as
flicker-free first-display localization. It is useful as a fallback discovery
and cleanup mechanism, but not as the only display-time trigger.

### Scenario matrix

| VCL scenario | Eventually discovered | `OnShow` translated | First paint translated | Result |
|---|---:|---:|---:|---|
| Auto-created main form | Yes | No | No | Discovery only |
| Dynamic modeless form | Yes | No | No | Discovery only |
| Ownerless form | Yes | No | No | Discovery only |
| Inherited form | Yes | No | No | Discovery only |
| Stay-on-top form | Yes | No | No | Discovery only |
| Modal form | Yes | No | No | Discovery only |
| MDI main form | Yes | Not used as gate | No | Discovery only |
| MDI child form | Yes | Not used as gate | No | Discovery only |

The matrix behaved the same on Win32 and Win64.

### Active-form timing experiment

The test temporarily observed the developer-facing
`Screen.OnActiveFormChange` property without making it part of the manager.
For every non-MDI scenario in the primary matrix, that signal occurred after
the form's `OnShow` handler but before its first paint. Applying translation
there could prevent a visible source-language paint for active forms.

That timing result does not make the signal an acceptable default:

- It is one exclusive event slot rather than a multicaster.
- A manager installed after another library must preserve and call the prior
  handler.
- A library installed later can replace the manager's handler entirely.
- Safe restoration becomes ambiguous if the handler chain changes while the
  manager is alive.
- It does not give application `OnShow` handlers translated text.
- Hidden or nonactive forms still require inventory or an explicit call.

The plan's rule was to reject VCL strategies that depend on overwriting an
exclusive application event. The active-form signal remains documented
evidence, not an approved production mechanism.

### Idle overhead and coexistence

The prototype used `TApplicationEvents`, not `Application.OnIdle`, and a
second independent `TApplicationEvents.OnIdle` subscriber continued to run.
The manager also left the shared `Done` flag unchanged. This demonstrated
basic multicaster coexistence without creating a busy idle loop.

Even with an O(1) applied-generation check, enumerating every live form on
every idle notification is persistent work. A production VCL design should
not promise zero idle cost if this remains its discovery method. If retained,
inventory should be narrowly scheduled or used only as a safety net.

## Stable form identity finding

Both framework tests kept two instances of the same form class alive. Delphi
renamed the second instances to `frmFMXLifecycle_1` and
`frmVCLLifecycle_1`. The manager observed both instances, but the second form
did not translate because the pack contains keys beginning with the streamed
root name, not the auto-suffixed runtime name.

Production code must not solve this by blindly stripping a numeric suffix.
An application may intentionally use such a name. The preferred Phase 2
design is an explicit form-identity resolver backed by scanner-produced
metadata that maps runtime class identity to the catalog's resource-root
identity. The mapping can be optional and backward compatible for existing
packs. A controlled, documented class-name convention may be a fallback, but
not the only rule.

## Rejected approaches

- **Direct `Application.OnIdle` assignment:** rejected because it replaces an
  application-wide event and is unnecessary when `TApplicationEvents`
  exists.
- **Idle inventory as the only VCL trigger:** rejected as the professional
  default because first paint occurred in the source language.
- **Unqualified `Screen.OnActiveFormChange` ownership:** rejected because it
  depends on an exclusive event slot despite favorable pre-paint timing.
- **Windows CBT or call-window hooks:** not implemented; rejected as hidden,
  invasive, message-order-sensitive integration.
- **One component on every form:** not pursued because it fails the large
  project usability requirement.

## Phase 1 decision

### Approved technical direction from the evidence

1. Continue with a framework-neutral Phase 2 core.
2. Use FMX before-show messages as the proven automatic lifecycle.
3. Keep the VCL lifecycle behind an interface so no unproven trigger becomes
   embedded in the core.
4. Add stable form identity to the Phase 2 design before production adapters
   are built.
5. Preserve the current transactional integration system as the working VCL
   fallback.

### VCL decision still required later

VCL cannot yet meet all three desired properties simultaneously using the
tested public, nonexclusive mechanism:

- one manager for the whole application;
- no source modification or per-form integration;
- translation before first visible paint.

The professional choices to evaluate after the shared core are:

1. A minimal call in a centralized form factory or common base form.
2. An explicitly opt-in, carefully chained active-form strategy with strong
   coexistence warnings and an idle safety net.
3. The existing transactional integration path for VCL projects that demand
   deterministic before-show behavior.

No choice should be hidden from the developer or marketed as zero-risk.

## Reproduction

Run the following elevated so RAD Studio can read its environment files:

```powershell
powershell.exe -ExecutionPolicy Bypass -File `
  "C:\New Delphi Projects\Delphi App Translation\tools\tests\RunLanguageManagerLifecycleSpike.ps1"
```

The runner compiles and executes these programs for Win32 and Win64:

- `FMXManagerLifecycleSpikeTests.dpr`
- `VCLManagerLifecycleSpikeTests.dpr`
- `VCLManagerMDILifecycleSpikeTests.dpr`

Expected terminal markers include:

```text
FMX_LIFECYCLE_SPIKE=PASS
VCL_MANAGER_DISCOVERY=PASS
VCL_BEFORE_SHOW_GUARANTEE=NOT_AVAILABLE
VCL_COEXISTING_IDLE=PASS
VCL_MDI_DISCOVERY=PASS
FMX_DUPLICATE_INSTANCE_KEY=UNRESOLVED
VCL_DUPLICATE_INSTANCE_KEY=UNRESOLVED
```

## Phase 1 exit status

**Complete.** The evidence supports production-oriented FMX work, rejects VCL
idle discovery as a flicker-free default, identifies a possible but exclusive
VCL pre-paint signal, confirms VCL MDI discovery, verifies basic idle-event
coexistence, and exposes the duplicate-instance identity requirement before
Phase 2 begins.
