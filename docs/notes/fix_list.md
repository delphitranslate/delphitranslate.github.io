# Fix list

The running record of what has been fixed, what has not, and how well each
claim is actually supported. Nothing here is being worked on unless the
developer says so.

Last reconciled against the source: 2026-08-18, build 2026.08.18.116.

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

### 11. The final build card duplicates work already done, and is misnamed
**Status:** open. **Severity:** medium. Nothing is broken, but the step is
confusing at exactly the point the developer is deciding what reaches the drive.
**Raised:** 2026-08-17 by the developer, from a Wizard log.

Final processing already compiles everything. `RebuildAllTargetConfigurations`
walks all four platform and configuration pairs that have an output folder and
calls the same `BuildAndDeploy` the card would:

```
22:04:27  Rebuilding Win32 Debug before deployment...
22:04:30  Win32 Debug built. Language packs deployed to ...\Win32\Debug\...
          (and the same for Win32 Release, Win64 Debug, Win64 Release)
22:04:36  4 target configuration(s) rebuilt with the current runtime.
```

The completion page then presents "Build the application now?" with platform
and configuration selectors and a Build and Deploy Selected Targets button.
Ticking it recompiles those same four configurations a second time.

The card does have one job nothing else does. After final processing the
position is: four configurations compiled, language packs in all four build
outputs, language packs in the configured destinations, and the new executable
**nowhere but its build folder**. Copying the executable to the folders on the
Deployment page happens only here, behind the authorisation control. That is
what the card is for, and its title says nothing about it.

Three separate faults, in order of how much they mislead:

1. **It is named for the half that is redundant.** Its unique function is
   deploying the executable. The build step repeats work finished seconds
   earlier.
2. **It offers four builds where one executable can land.** A destination
   folder holds one `Carillon.exe`. Copying all four over each other was fixed
   on 2026-08-17 - one is deployed and the log names it - but offering the
   choice at all still suggests four outcomes that cannot exist.
3. **Its selectors are the only way to build a configuration that has never
   been built.** `RebuildAllTargetConfigurations` skips any pair without an
   existing output folder, so a genuinely new configuration can only be
   produced here. That is a second, unrelated job sharing one control, and it
   is why the card cannot simply be deleted.

Suggested shape, for the developer to accept or change:

- Rename it for what it does: deploying the built application to the folders
  entered in Step 3.
- Replace the build step with a "rebuild first" tick, off by default, since
  final processing has already built everything in the ordinary case.
- Reduce the two selectors to one choice of which build to deploy, because one
  is all that can land.
- Give the "build a configuration I have never built" case its own control, or
  move it to the Build page where it belongs.

### 12. A filename is being translated
**Status:** open. **Severity:** high if the application opens that file by name.
**Found:** 2026-08-17, while tracing an unrelated label.

The pack contains:

```
LogManager.Runtime.Result.60 = registrosCarillonPlayLog.txt
```

A word has been prepended to what looks like a log filename. Whatever the
source literal was, a name ending `.txt` returned from a function is a path,
not a caption, and translating it will send the application looking for a file
that does not exist. The scanner's runtime-literal classification needs a rule
that a literal carrying a file extension is not user-facing text, and the
existing entry needs correcting.

### 13. Controls the application builds in code get no layout attention
**Status:** open. **Severity:** low, but it is visible to the developer today.
**Raised:** 2026-08-17 by the developer, "very tiny script; needs to be 1-2 pts
larger".

`LogViewerForm.FHeaderLabel` and `FStatusLabel` are created in code, not drawn
on a form, so they reach the catalog as `Runtime.` entries and their text is
translated correctly. They have no designed geometry, so the layout analyser
never sees them and no size, width or wrapping rule is ever written for them.
Their appearance is entirely the application's own choice.

Two ways out, for the developer to pick:

- Have the application draw them at a larger size, which is a change to
  Carillon rather than to the translator.
- Teach the runtime to accept layout rules for controls it can find by name
  even when the analyser has no designed geometry for them, sized from the
  translated text alone. That is real work and it applies to any application
  that builds part of its interface in code.

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

### FireMonkey labels wrap unless told not to, and we assumed the opposite
**Fixed:** 2026-08-17, build .114.

A property absent from a form file is not a property set to False: it is the
framework's default, and the two frameworks disagree. A FireMonkey label wraps
unless told otherwise; a VCL one does not. The analyser read the absence as
False, so every FireMonkey caption was believed not to wrap.

The consequence was silent. A plan that kept a caption on one line matched what
we thought the form already did, so no rule was written - there was nothing to
change - and the label wrapped at run time regardless, into whatever height it
already had. The hero banner is the clearest case: planned as one line at 27.2
points, drawn as two inside a box built for one, losing the top and bottom of
both. The same fault explains a navigator caption sitting higher than its
neighbours: "Cancelar" is the only word in that row long enough to reach the
edge of its 63-pixel box, and two lines centred in eighteen pixels ride up.

The default is now taken from the file extension, and switching wrapping off is
stated explicitly rather than left to be inferred.

### Bold text was measured as though it were regular
**Fixed:** 2026-08-17, build .114.

Every measurement went through a layout with the point size set and the weight
left alone, so a bold caption was measured light and reported as fitting a box
it overruns. FireMonkey writes the weight as a binary record rather than a
readable set; the second byte carries it on the TFontWeight scale, where
Regular is four and Bold is seven. The VCL writes a readable set. Both are read
now, and semi-bold and heavier are measured as bold.

### The glossary fix was written where the Wizard overwrites it
**Fixed:** 2026-08-17, build .114.

The shortened email caption was put into the workspace glossary under AppData
and lost on the next run, because the Wizard prefers a staged glossary in
`export/localization-review/<project>/<language>/project-glossary.json` and
saves that over the workspace copy. The staged file is the durable one, and it
is in the repository where it belongs.

The term also named a semantic concept. A term that names one only matches an
entry carrying the same concept, and this entry carries none, so it would never
have matched even had it survived. Left blank now.

### A hard line break counted for nothing
**Fixed:** 2026-08-18, build .116.
**Raised:** 2026-08-17 by the developer as "image 3, text not aligned", on the
liturgical silence page.

The silencing note beside its check box is two sentences with a line break
between them, written into the form file as one string carrying `#13#10`. Both
measurements treated it as a single run of text, so the analyser asked how wide
that run was and divided by the control's width to count lines. That answers a
question the control never asks. A line the author wrote cannot share a line
with the next one, however much room is left over.

The note was planned at two lines and drawn at four, which is why it appeared
with its head and feet cut off: 240 by 47 pixels where it needed 240 by 90.

Both measurements now split on the breaks the author wrote. Width is the widest
authored line rather than all of them end to end, which would report a caption
needing the room of a paragraph. Line count is the sum over the pieces, each
wrapping on its own.

Worth noting for anything similar: `lblLogNote` on the same page reads as two
sentences but has no break in it, only a space, so it wraps as one run and its
three-line plan was right all along. The two look identical on screen and are
not the same thing at all.

### Deployment sent the debug build to the drive
**Fixed:** 2026-08-18, build .115.
**Raised:** 2026-08-17 by the developer, from executable sizes on the drive
varying between roughly 28 and 55 million bytes between runs.

The varying size was never corruption. It was different build configurations
reaching the same folder:

```
Win32 Debug     58,224,025
Win32 Release   21,430,272
Win64 Debug     67,637,817
Win64 Release   29,532,672
```

The executable on the drive matched Win32 Debug to the byte, and the remembered
28 million is Win64 Release. Before the deploy-once fix the copy sat inside the
platform and configuration loop, so the last combination built won, which is
Win64 Release. After it, the first won, which is Win32 Debug. Neither was a
choice anybody made, and the size moved because the rule moved.

Release is now preferred wherever it was built, on the build page and on the
hand-picked folder button alike. What reaches the drive should be what a user
of the application would be given: a debug build is about two and a half times
the size, carries a symbol table naming every routine and variable, links the
unoptimised runtime, and turns range and overflow checking on, so it can raise
where a release build carries on.

The platform is still the first selected rather than chosen, and the log now
states it. That matters more than it looks: the developer's drive carries
`libeay32.dll` and `ssleay32.dll`, which are thirty-two bit, so a sixty-four
bit executable deployed there could not load them and anything using TLS would
fail. Any run that ended on Win64 Release put exactly that on the drive.
Choosing the platform deliberately, or refusing to change the architecture of
an existing deployment without saying so, is left as part of item 11.

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
