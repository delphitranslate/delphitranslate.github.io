# Fix list

The running record of what has been fixed, what has not, and how well each
claim is actually supported. Nothing here is being worked on unless the
developer says so.

Last reconciled against the source: 2026-08-17, build 2026.08.17.112.

## How to read the status of an item

Three different things have been called "fixed" in this project, and conflating
them has cost real test cycles. They are kept apart here.

| Status | What it means |
| --- | --- |
| **Confirmed** | The developer has seen it working in the running application. |
| **Verified by test** | An automated check proves it, and the check would fail without the fix. Not yet seen on screen. |
| **Believed fixed** | The code changed and it compiles, but nothing proves it. Treat with suspicion. |
| **Open** | Not started, or attempted and withdrawn. |

Everything below marked *Verified by test* is verified against the **plan** the
analyser produces. The runtime is verified separately and thinly: a live form
is built and a pack applied to it, but only the `Width` property is asserted,
so six of the seven layout properties reach the screen unchecked. That is open
item 7, and it is why several items marked fixed in earlier rounds came back.
Until item 7 is widened, *Verified by test* on a layout item means less than it
sounds.

---

## Open

### 7. The runtime harness covers one layout property out of seven
**Status:** open. **Severity:** medium, and it is the largest hole in the
coverage.

**Correction, 2026-08-17.** This item previously read "nothing verifies that
the runtime applies the plan", and that was wrong. `FMXRuntimeSmokeTests` and
`VCLRuntimeSmokeTests` both build a real sample form, apply a language pack to
it and assert the resulting control geometry. Both pass today. The claim was
repeated several times before anyone looked.

What is true is narrower and still serious. Each harness exercises exactly one
layout property:

```
"propertyName":"Width"
```

The runtime applies seven, in this order: `AutoSize`, `FontSize`, `WordWrap`,
`Width`, `Height`, `Position.X`, `Position.Y`. Six of them are asserted
nowhere. Every runtime defect reported on 2026-08-17 lived in those six — a
control pinned with `AutoSize` but given no `Height`, wrapping that never took
effect, a size applied in the wrong order — which is exactly why correct plans
kept reaching the screen broken.

The work is to extend the two existing harnesses to cover the remaining six
properties and the order they are applied in, not to build something new.

### 8. No VCL application has been through the full pipeline
**Status:** open. **Severity:** medium.

**Correction, 2026-08-17.** This item previously read "no VCL application has
been run end to end". A VCL sample form *is* built, translated and asserted in
process by `VCLRuntimeSmokeTests`, which passes. What has never happened is a
VCL project taken through the whole pipeline the way Carillon is: scan,
catalog, review, kit generation, build and deploy, then launched and looked at.
`samples/VCLBasic` and the `WebsiteAnalytics` kit would serve.

`TDBGrid` column titles (item 6b) would be exercised by this.

### 10. The runtime test suite cannot be run
**Status:** open. **Severity:** medium — it is why item 7 went unexamined.
**Found:** 2026-08-17.

`tools/tests/RunRuntimeSmokeTests.ps1` builds `FoundationSmokeTests.dpr`
first, and that file still references units removed in commit `9b0b9e2`
("Remove stale target-edit integration paths"): `DAT.Integration.Plan`,
`.Engine`, `.Reset`, `.Transaction`, `.Types`. The compile fails immediately,
so the runner never reaches the runtime tests below it and the whole suite has
been unrunnable since that commit.

The runtime harnesses themselves are fine — compiled and run directly on
2026-08-17, both pass. Either update `FoundationSmokeTests.dpr` to the units
that still exist, or drop the removed ones from it.

Stale `.dcu` files for those deleted units are still sitting in
`source/integration`. They are untracked leftovers, but they are the reason a
missing source file does not always announce itself.

### 6b. Scanner coverage: Tier 2, and TDBGrid
**Status:** open. **Severity:** low for this application, moderate for others.

Tier 1 is done (see item 6 below). Still outstanding from
`text_component_coverage_gaps.md`:

- Tier 2 in full: `TListView.Items`, `TTreeView.Items`, `TMenu.Items`,
  `TButtonGroup.Items` and similar runtime-populated collections, plus a few
  low-value description properties.
- `TDBGrid` column titles are **unverified**. `Vcl.DBGrids` is not shipped as
  source, so the survey could not read it. A `TColumn.Title.Caption` rule is in
  place on the strength of the documented property, but nothing has confirmed
  it against a real data-aware grid. Item 8 would exercise it.

### 9. Unreferenced control on the Wizard completion page
**Status:** open, awaiting the developer's decision. **Severity:** cosmetic.

`btnFinishLocalizationReview` is declared in `DAT.Studio.SetupWizard.fmx` and
never referenced anywhere in code: permanently hidden and disabled. It was
moved clear of the rebuilt button rows on 2026-08-17 rather than deleted,
because removing a control is more than the geometry work that was approved.
Delete it or keep it, but it is dead weight either way.

---

## Verified by test, not yet confirmed on screen

Everything in this section is waiting on the developer's next Wizard run.

### 1. Carillon.exe deployed twice to the outboard drive
**Fixed:** 2026-08-17, build .111, commit `ea14c91`.

Two steps copied the executable: the build step, and final processing after it.
Final processing now deploys language packs only and reports what the build
step did; the build step is the sole copier and labels its log line. The
hand-picked folder button still copies, because clicking it is the request.

The deeper fault was that a copy made outside the build step can only be of
whatever was built last time — the route by which a stale executable reaches
the drive looking fresh. Where no build has run, the log now says so.

**Behaviour change to watch:** a run with "build now" unticked no longer
deploys an executable at all. That is deliberate, and it is logged.

### 2. Overwrite authorisation control sat too low to be seen
**Fixed:** 2026-08-17, build .111, commit `ea14c91`.

Moved from Y=422 to Y=292 on the deployment page, directly beneath the
destination list it governs, with the buttons and summary below it. Geometry in
the `.fmx`, so the page stays editable in the IDE.

### 2b. Completion page: the progress log had no room
**Fixed:** 2026-08-17, build .111, commit `ea14c91`.

The command box and the four buttons moved to the foot of the page; the log
took the reclaimed height, 130 pixels instead of 76.

### 3. Build output folders outside the project tree were rejected
**Fixed:** 2026-08-17, build .111, commit `ea14c91`.

`FindBuildOutputDirectory` required every candidate to sit inside the project
tree. That test belongs to the folders the tool guesses at; a folder the
project file names is the project's own answer to where it builds, and a
project may legitimately build to another drive. Rejecting it fell back to a
stale in-tree copy — failure disguised as success. Declared paths are trusted
now, guessed ones still are not.

### 4. No space between a grid's bottom edge and the controls beneath it
**Fixed:** 2026-08-17, build .109.

Marked fixed once before on the strength of a different form, which was wrong.
Checked against the Groups and Playlist forms this time.

### 5. A caption above its field grew down into it
**Fixed:** 2026-08-17, build .111, commit `a075157`.

Attempted three times before and withdrawn each time, always by trying to grow
the caption *upwards*, which moved captions into a panel on `Form1` and into
the grid on `Groups`. The lever was wrong. Holding a caption level with the
field it labels removes the need to grow it at all: `lblTestRecipient` takes
the empty margin on its left and keeps its top, its height and its text size.

### 6. Text-bearing components the scanner did not read (Tier 1)
**Fixed:** 2026-08-17, build .112, commit `b53716b`.
**Proved by:** `contracts/formscan`, `tools/run_form_scan_contracts.ps1`.

Every Tier 1 class from the survey is now read on both frameworks: `TText`,
`TPanel.Caption`, `TCornerButton`, `TExpander`, designer-authored list and tree
items, base column classes, `TToolButton`, `TStatusPanel`, `TListColumn`,
`THeaderSection`, `TListGroup`, `TCoolBand`, `TTaskDialog`, `Tabs.Strings`, and
file-dialog `Title`.

The larger find was structural. DFM collections were not understood at all, so
the `end` closing a collection item closed the component that *owned* the
collection; every property after the first collection on a form was
misattributed, and once the stack unwound past the form the rest of the file
was skipped in silence. Any VCL form with a status bar or list view near the
top was quietly losing text below it.

Remaining scope moved to item 6b above.

### Screen defects reported 2026-08-17 (second round)
**Fixed:** build .110, commit `b7cbb40`.

1. **Media button row: one button larger than the others.** The row shared a
   width but not a height or text size, so the longest caption alone wrapped
   and stood twice as tall. Two causes: the fitting size was solved by scaling
   the whole measured width, but padding does not shrink with point size, so
   the text stayed a fraction too wide and wrapped anyway; and wrapping was
   decided per button rather than for the row.
2. **Stacked buttons of different widths.** Vertical stacks were never
   collected as sets at all — only horizontal rows were.
3. **Navigator captions not aligned.** The Silence Schedule caption row drifted
   right of the buttons it names, cumulatively, worst at the last caption.
   Underneath was a false statement in the code: `LinesFittingBelow` measured
   the room below a control and then discarded its own answer, reporting at
   least two lines however little room it found.
4. **Settings captions truncated from the left.** Pinned `AutoSize` controls
   were given no height, so they kept the single line the form was drawn for.
   A right-aligned caption loses its *beginning* that way.
5. **Paragraph did not fit.** Same root cause as 4.

### Screen defects reported 2026-08-17 (first round)
**Fixed:** builds .105 to .109, commits `5753746`, `5e31620`.

Text overflowing its container; grid-bottom spacing; over-wrapped long text;
glossary term for "Usuario"; caption alignment and padding; compaction of a
wrapped block; and the untranslated word "Song" — a scan-key collision in which
both arms of a conditional keyed the same catalog entry, so the second was
discarded as a duplicate. The scanner had been finding it all along.

---

## Known-good regression suites

| Suite | Covers | Run with |
| --- | --- | --- |
| Layout contracts (16) | Analyser decisions on purpose-built forms | `tools/run_layout_contracts.ps1` |
| Carillon layout smoke (9 forms) | Analyser decisions on the real catalog | `bin/Tests/Win32/LayoutFittingSmokeTests.exe <catalog>` |
| Form scan contracts (2) | What the scanner reads out of a form | `tools/run_form_scan_contracts.ps1` |
| Scanner smoke | What the Pascal scanner claims from one unit | `bin/Tests/Win32/ScannerSmokeTests.exe <file.pas>` |

The layout and form-scan runners reject a stale harness: if a source file is
newer than the built executable the run stops rather than reporting on code
that is no longer the code being changed.

| FMX runtime smoke | A pack applied to a live FMX form | `tools/tests/FMXRuntimeSmokeTests.dpr` |
| VCL runtime smoke | A pack applied to a live VCL form | `tools/tests/VCLRuntimeSmokeTests.dpr` |

The two runtime suites are **not currently reachable through their runner**:
`RunRuntimeSmokeTests.ps1` fails on an unrelated rotted test before it gets to
them. See open item 10. They compile and pass when built directly.

**What no suite covers well:** the runtime, beyond the `Width` property. See
open item 7.
