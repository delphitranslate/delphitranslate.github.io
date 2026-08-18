# Fix list

Open items, newest first. Nothing here is being worked on unless the developer
says so.

---

## Resolved on 2026-08-17 (build 2026.08.17.111)

Kept here until the developer has seen each one working in the running
application; nothing below is being worked on.

- **1. Executable deployed twice to the outboard drive.** Final processing no
  longer copies the executable at all: it deploys language packs and reports
  what the build step did. The build step is the only path that copies, and it
  now says so in the log. The hand-picked folder button still copies, because
  clicking it is the request.
- **2. Overwrite authorisation sat too low.** Moved up the deployment page to
  sit directly beneath the destination list it governs, at Y=292 instead of
  Y=422, with the buttons and summary below it.
- **2b. Completion page log.** The command box and the four buttons moved to
  the foot of the page and the progress log took the reclaimed height, 130
  pixels instead of 76.
- **3. Build outputs outside the project tree rejected.** The containment test
  now applies only to the conventional folders the tool guesses at. A folder
  the project file names is the project's own answer to where it builds, and a
  project may legitimately build to another drive.
- **4. Space between a grid's bottom edge and the controls beneath it.**
  Genuinely fixed this time; the earlier claim was made on the strength of a
  different form.
- **5. A caption above its field grows down into it.** Fixed as a consequence
  of the rule that a caption drawn level with its field keeps that pairing.
  `lblTestRecipient` takes the empty margin on its left instead of growing
  down into the edit, so it needs no extra height at all and keeps both its
  top and its text size. The three earlier attempts all tried to grow it
  upwards, which was the wrong lever.

---

## Deployment

### 1. Carillon.exe is deployed twice to the outboard drive
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17 (returned; reported previously in the Codex handoff)
**Severity:** high — it is a returning defect, and it wastes a test cycle each
time it appears.

The executable is copied to `F:\` more than once during a Wizard run. The
intended behaviour, from the developer's earlier instruction:

- language packs may deploy to build outputs and to configured application
  destinations at any point;
- the executable is copied **only** in the final build and deploy step, after
  the developer has explicitly authorised create or replace;
- the log states which executable was copied, from where, to where, and the
  verified byte count.

There are three call sites for `TTargetBuildDeployer.DeployBuildOutput` in
`DAT.Studio.SetupWizard.pas`, and two of them can fire in a single run:

- line 382, in the build-now path, after the target is rebuilt;
- line 1505, in `DeployLanguagePacksToConfiguredDestinations`, during final
  processing, for each configured destination;
- line 2022, in `btnDeployApplicationFolderClick`, for a folder chosen by hand.

With "build now" ticked and `F:\` configured as a destination, the first two
both run, which matches what the developer sees. The fix is to copy the
executable once, in the final step, after authorisation, and to have the other
paths deploy language packs only.

Check the reported byte count and timestamp against the source each time, and
say plainly in the log which of the three paths performed the copy.

### 2. The overwrite authorisation control sits too low to be seen
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17
**Severity:** medium — the developer cannot reliably see what he is authorising.

`chkReplaceDeployedExecutable` sits at Y=422 with a height of 54, so its lower
edge is at 476 on a body roughly 496 tall: about twenty pixels of margin, which
is why it reads as buried and has been clipped before. It should move up the
deployment page, next to the destination list it governs. This is a change to
`DAT.Studio.SetupWizard.fmx` geometry, so the page stays editable in the IDE.

### 2b. Completion page: give the log more room
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17
**Severity:** low, but it is the page the developer reads at the end of every run.

On the Processing and completion page the four buttons (Copy Commands,
Redeploy Outputs, Open Kit Folder, Deploy to App Folder) and the troubleshooting
command box sit high enough to squeeze the progress log above them. The log is
the part that matters, and it is currently a few lines tall.

Move the command box and the four buttons as far down the page as the layout
allows, and give the reclaimed height to the log. Geometry only, in
`DAT.Studio.SetupWizard.fmx`, so the page stays editable in the IDE.

### 3. Build output folders outside the project tree are rejected
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17 (carried from the handoff, section 5.8a)
**Severity:** high — silently deploys a stale executable.

`DAT.Integration.BuildDeploy.pas`, `IsUsable` (line ~144) requires the output
directory to sit under the project directory:

```pascal
Result := StartsText(IncludeTrailingPathDelimiter(ProjectDirectory), FullDirectory) and ...
```

A project whose `DCC_ExeOutput` points at another drive has its correct output
silently rejected, and the search falls back to a possibly stale in-tree
folder. This has cost at least two test cycles in this project alone.

---

## Layout

### 4. Space between a grid's bottom edge and the controls beneath it
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17 (item 2 of that day's list)
**Severity:** medium — cosmetic, but the developer has raised it twice.

On the Groups screen the navigator captions and buttons sit hard against the
bottom of the grid. There is ample room below. Belongs to the same family as
item 5 below: neither is about a control being too small, both are about the
space between one control and the next.

### 5. A caption above its field grows down into it
**Status:** resolved 2026-08-17, awaiting the developer's confirmation in the running application.
**Reported:** 2026-08-17 (item 5 of that day's list, and item 4 of the later list)
**Severity:** medium.

`frmEmailSettings.lblTestRecipient` grows from 30 to 54 pixels tall and takes
the extra height downwards, into the edit below it. It should keep its bottom
edge and grow upwards where there is room, and the caption should align with
the left edge of the box it labels.

Attempted once on 2026-08-17 and withdrawn: growing upwards moved captions into
a panel on `Form1` and into the grid on `Groups`, because the room-above
calculation ignored frames and grids. The rule needs to consider everything
above it, and to move only when the whole growth fits.

---

## Coverage

### 6. Text-bearing components the scanner does not read
**Reported:** 2026-08-17
**Severity:** low for this application, high for anyone else's.

See `text_component_coverage_gaps.md` for the full survey. The two that would
most visibly embarrass the tool on somebody else's application:

- `TText` (FMX.Objects) — a graphic text primitive used constantly on styled
  FMX forms instead of `TLabel`, entirely invisible to us.
- `TPanel.Caption` (VCL) — panels are routinely used as captioned headers.

Then `TToolButton`, `TStatusPanel`, `TListColumn`, `TTabControl.Tabs`,
`TTaskDialog` and the dialog `Title` properties.

`TDBGrid` column titles are **unverified**: `Vcl.DBGrids` is not shipped as
source, so the survey could not read it. Likely a real gap; confirm before
acting.

---

## Verification

### 7. Nothing verifies that the runtime applies the plan
**Reported:** 2026-08-17 (carried from the handoff, section 5.2)
**Severity:** medium — it is the largest remaining hole in the test coverage.

Both suites check what the analyser decides. Nothing checks that the runtime
applies it to a live form. Every runtime fix so far has been confirmed only by
the developer looking at the screen. A harness that builds a form in code,
applies a pack and asserts the resulting control geometry would close this.

### 8. No VCL application has been run end to end
**Reported:** 2026-08-17 (carried from the handoff, section 5.5)
**Severity:** medium.

`DAT.Runtime.VCL.pas` has the same ordered application and font handling as the
FireMonkey side and compiles, but no VCL application has been translated and
run. `samples\VCLBasic` and the `WebsiteAnalytics` kit would serve.
