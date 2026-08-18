# Fix list

The running record of what has been fixed, what has not, and how well each
claim is actually supported. Nothing here is being worked on unless the
developer says so.

Last reconciled against the source: 2026-08-17, build 2026.08.17.113.

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

### 7b. The runtime harness covers one control on one sample form
**Status:** open, much reduced. **Severity:** low.

Item 7 is done: all seven layout properties are now asserted against a live
form, and doing it uncovered the defect recorded under "Labels never received
their text size" below. What remains is breadth of a different kind. The
assertions run against one label on one purpose-built sample form. There is no
equivalent for a grid column, a check box caption, or a control inside a styled
container, and none for a form under a platform style other than the default.

### 8. No VCL application has been through the full pipeline
**Status:** open. **Severity:** medium.

**Correction, 2026-08-17.** This item previously read "no VCL application has
been run end to end". A VCL sample form *is* built, translated and asserted in
process by `VCLRuntimeSmokeTests`, which passes. What has never happened is a
VCL project taken through the whole pipeline the way Carillon is: scan,
catalog, review, kit generation, build and deploy, then launched and looked at.
`samples/VCLBasic` and the `WebsiteAnalytics` kit would serve.

`TDBGrid` column titles (item 6b) would be exercised by this.

### 10. FoundationSmokeTests still references deleted units
**Status:** open, reduced. **Severity:** low.

`tools/tests/RunRuntimeSmokeTests.ps1` compiles `FoundationSmokeTests.dpr`
first, and that file still uses units removed in commit `9b0b9e2` ("Remove
stale target-edit integration paths"): `DAT.Integration.Plan`, `.Engine`,
`.Reset`, `.Transaction`, `.Types`. It fails there and never reaches the tests
below it.

What needs those units is two whole procedures,
`TestIntegrationPlanningAndPackage` and `TestTargetIntegration`, exercising the
target-editing feature that commit removed. Deleting them is probably right,
but it drops coverage on the strength of a guess about whether that feature is
gone for good, so it is left for the developer to decide.

Nothing is blocked by it: both runtime suites and `StudioFormSmokeTests` build
and pass when built directly, which is how they are run today.

Stale `.dcu` files for the deleted units still sit in `source/integration`.
They are untracked leftovers, and they are why a missing source file does not
always announce itself.

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

### 9. An unfinished feature on the Wizard completion page
**Status:** open, awaiting the developer's decision. **Severity:** cosmetic.

**Correction, 2026-08-17.** This was recorded as an unreferenced dead control
on the strength of grepping a single unit. It is wired:
`btnFinishLocalizationReview` carries `OnClick = btnLocalizationReviewClick` in
the form, and `StudioFormSmokeTests` asserts that wiring. Nothing in the
application ever makes it visible or enabled, so it never reaches the
developer, but that makes it an unfinished feature rather than dead code. It
was briefly deleted on the strength of the wrong reading and put back once the
wiring came to light.

Either finish it, in which case something has to enable it when Localization
Review closes, or remove it together with the assertion that guards it.

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

### Labels never received their text size at run time
**Fixed:** 2026-08-17, build .113.
**Found by:** widening the runtime harness under item 7.

The FireMonkey runtime reached wrapping, text size and font colour through
`AComponent is TTextControl`. There are two families of text control in
FireMonkey and a `TLabel` belongs to the other one: it descends from
`TPresentedTextControl` and is not a `TTextControl` at all. The compiler
refuses to compare those two types directly; written against a `TComponent` the
test compiles and is quietly False for every label on every form.

So for labels, which are most of the text on any form, the runtime read each
font-size rule out of the pack and did nothing with it. The analyser would
decide a caption needed to be a point smaller, write the rule, the runtime
would load it, and the size on screen would not change. That is why font-size
corrections were reported as not applied round after round while the plan was
correct every time.

Both families implement `ITextSettings`, so the runtime asks for the interface
now. On the sample form this took the applied-property count from 24 to 26 and
the restore count from 6 to 8: two rules per control that had been discarded in
silence.

### Wizard pages were laid out against a height they do not have
**Fixed:** 2026-08-17, build .113.

A page's real height is settled at run time, because the tab control fills its
card, and it is nothing like the figure stored in the form file. Pages were
laid out against the stored figure, so content ran past the bottom edge and was
clipped. Both the deployment page and the completion page were over.

`StudioFormSmokeTests` now measures the tab control that is actually there and
fails any page whose content reaches past it, in absolute coordinates, with a
count check so that a walk finding nothing cannot pass for a walk finding no
faults. Verified by reintroducing the overflow and watching it fail.

### The executable was still deployed more than once
**Fixed:** 2026-08-17, build .113.

The earlier fix stopped final processing copying the executable, but the copy
inside the build loop remained, and that loop runs once per selected platform
and configuration. With both platforms selected the same destination was
written twice; with both platforms and both configurations, four times. Each
copy overwrote the last, so what ended up on the drive was whichever
combination finished last rather than anything anyone chose.

Every combination is built first and one is deployed afterwards. The log names
which, and says plainly that the others stayed in their build-output folders.

### Screen defects reported 2026-08-17 (third round)
**Fixed:** build .113.

1. **Completion page buttons partially hidden.** The page-height fault above.
2. **Executable still deployed twice.** The build-loop fault above.
3. **A date caption still lost its first word.** It cannot wrap, because the
   next control sits directly beneath it, and could not grow, so it overran a
   one-line box and, being right-aligned, lost its beginning rather than its
   end. Captions that cannot wrap are now sized against the width actually
   planned, taking any free margin beside them first, with a floor so this
   cannot make text illegible: applied without that floor it reduced a check
   box to sixty per cent of its designed size.
4. **The email caption was too long.** Shortened in the glossary to "Email del
   destinatario:", which needs no layout change at all and sits level with the
   field as drawn.
5. **The folder note was still cut through the middle.** It is prose with
   ninety pixels of empty space below it, and it was being shrunk to force it
   onto one line instead of being allowed to wrap. A size chosen so the words
   only just reach the edge depends on the measurement being exact; where it is
   a shade optimistic the text wraps anyway, into a height fixed for one line.
   Paragraphs with room below now wrap at their designed size.

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
