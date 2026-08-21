# Fix List

Known defects and unfinished work, newest first. Items are removed when fixed,
not struck through. Anything here is deliberately *not* being worked on right
now; the point of the list is that nothing has to be remembered.

Last changed: August 20, 2026

---

## User interface

### Wizard target-language combo overflows the content card

`cboTargetLanguage` on the Languages page runs off the right-hand edge of the
white card, clipping its dropdown arrow.

The card's usable width is 670 starting at X=8, so the right edge is 678.

| control | X | width | right edge |
|---|---|---|---|
| `cboSourceLanguage` | 8 | 330 | 338 |
| `lblTargetLanguage` | 370 | 280 | 650 |
| `cboTargetLanguage` | 370 | **368** | **738** |

It overflows by 60 pixels. Fix in the designer: set `cboTargetLanguage`
`Size.Width` to 308. Nothing else on the page needs to move.

File: `source/studio/DAT.Studio.SetupWizard.fmx`, around line 537.

---

## Translation quality

### A noun read as a verb — *partly addressed 20 August*

The context now states the part of speech each control needs: a button asks
for an imperative, a menu item for the form that language uses on menus, a
column heading for a noun phrase. Strings are also grouped by shared context
now, so a string's own description reaches the service instead of being
concatenated with forty-nine others. Both changes are untested against a real
service; the entry stays until an Arabic run shows the result.

The original finding:

| shown | Arabic | means |
|---|---|---|
| Help | يساعد | "he helps" |
| Close | يغلق | "he closes" |
| Play | يلعب | "he plays" - a game |
| Stop | قف | "stand!" |
| Play Schedule | جدول المباريات | "fixture list", as in sport |

The domain profile settles which *sense* a word carries and does that
correctly - the liturgical and email screens read well. What it does not carry
is that a button caption is an imperative and a menu item is a noun. The
control class is already known for every string, so this is a matter of saying
so in the context sentence rather than of new machinery.

### Day and month abbreviations translated as words

`Wed` became تزوج ("he married"), `Sat` became قعد ("he sat"), `Sun` became
شمس (the star). Three-letter day and month abbreviations are a closed set and
should be recognised and handled from a table rather than sent to a service at
all - the same reasoning that already stops a bare format string being sent.

---

## Behaviour

### First run shows the source language, whatever the machine is set to

With no preference file the runtime falls back to `SourceLanguage`, and nothing
consults the operating system's UI language. A user in Cairo installing the
application sees English until they find the language menu. A
`FirstRunUsesSystemLanguage` property on the manager would fix it for the whole
product, not just for one screen.

### The settling pass can disturb an image-backed form

Widening a control, levelling a row or growing a font is safe on an ordinary
form and not on one where text sits over artwork - a splash screen, an About
box, a form with a full-size image. Such a form probably wants its words
translated and its geometry frozen.

### Runtime-composed strings are never translated, and nothing says why

Reported again 20 August: the status bar is not translated in any language.

It cannot be, from here. Carillon builds those strings in code:

    StatusBar1.Panels[0].Text := ' Last Song played: ' + LastSongName;
    StatusBar1.Panels[1].Text := 'Songs in Playlist:  ' + PlaylistCount.ToString;
    StatusBar1.Panels[2].Text := 'Songs Played Today:  ' + ...

The English is a literal in the source, concatenated with data and written
whenever the panel refreshes. Anything the pack puts there is overwritten
moments later. The classification is right - `dynamicValue` /
`manualTranslateText` means exactly "the application must ask for this itself"
- and the only fix is a `TranslateText` call in the application, which the
translator is forbidden to make and the application's own developer can make in
a minute.

What is missing is that **the product never says so**. Four entries in Carillon
are in this category and the developer has no way to discover which, or where.

The data to fix that is already held: every such entry carries its source file
and line. A short report - "these strings are composed at run time; wrap them
in TranslateText, here is the file and line for each" - would turn a silent
gap into a five-minute job. That report should be produced by the Wizard and
named in the review, not left in the catalog for someone to notice.

---

## Open and not yet explained

### Right-to-left appears to persist after switching away from Arabic

Reported 20 August. After translating to Arabic and then switching to Italian,
menus appeared still to open right to left, and a restart cleared it.

Not reproduced. Everything checked resets correctly when an Arabic pack is
followed by a left-to-right one, and each of these is now a standing test:

- the form's `BiDiMode` returns to `bdLeftToRight`
- the window's extended style loses `WS_EX_RTLREADING` and
  `WS_EX_LEFTSCROLLBAR`; `WS_EX_LAYOUTRTL` is never set at all
- a menu's `BiDiMode` follows the form through `ParentBiDiMode`
- positions, `Align`, `Anchors`, `Alignment` and grid column order all restore
  from the snapshot

Two things learned while looking, both worth keeping in mind:

- `TMenu.DoBiDiModeChanged` in `Vcl.Menus` begins `if (not SysLocale.MiddleEast)
  or (WindowHandle = 0) then Exit`. On a machine whose Windows locale is not
  Middle-Eastern the VCL does not apply right-to-left layout to menus at all,
  whatever `BiDiMode` says. Menu direction may therefore behave differently on
  an Arabic-locale machine than on this one.
- The `multilingual-layout-envelope.json` is written but never read, and is
  marked `advisoryOnly`, so it cannot be carrying decisions between languages.

A speculative fix that forced the menu to rebuild was written and then removed
again, because it could not be shown to change anything and would have masked
the real cause.

**Narrowed, 20 August.** Changing the language to English does *not* clear it;
only closing and reopening the application does. So the residue survives every
subsequent language change within the process.

`SysLocale.MiddleEast` is **True** on the machine where this was seen, which is
why menus mirror at all - the VCL's menu bidi path is gated on it, and on a
machine without Middle-Eastern language support installed none of this would
happen. Worth remembering when reproducing.

The flag Windows actually draws menus from is `MFT_RIGHTORDER or
MFT_RIGHTJUSTIFY` on menu item zero, set by `TMenu.DoBiDiModeChanged`. In an
isolated test that flag is set correctly under Arabic and **cleared correctly**
on returning to a left-to-right pack; that is now a standing assertion. So the
mechanism works in isolation and something about the real application defeats
it - most plausibly the timing of the notification, since the form's window is
recreated when its `BiDiMode` changes and `DoBiDiModeChanged` returns early
when the menu's `WindowHandle` is zero.

Further narrowed, 20 August: starting in English and switching straight to
Italian is **fine**. The residue only appears after leaving a right-to-left
language, and then survives every later change.

A field diagnostic is now in `ApplyReadingOrder`, writing to
`%LOCALAPPDATA%\DelphiAppTranslationStudio
tl-diagnostic.log` with no setup
at all. It began as an environment-variable switch and produced nothing, which
told us only that either the variable had not reached the process or the
routine had not run - the two things the log exists to tell apart. It records, before and after each apply:
the form, the pack's direction, the form's `BiDiMode`, whether
`WS_EX_RTLREADING` is on the window, `SysLocale.MiddleEast`, and for every menu
its `BiDiMode`, `ParentBiDiMode`, `WindowHandle`, menu handle and the native
right-to-left flag on item zero.

**Reading `TMenu.Handle` mid-apply destroys the translated menu captions.**
The first unconditional version of the diagnostic did exactly that and the VCL
runtime smoke test caught it immediately - a diagnostic that changes what it
measures is worse than none. It now asks Windows for the menu already on the
window with `GetMenu`, which creates nothing.

That is worth remembering for its own sake, because `TMenu.DoBiDiModeChanged`
also calls `GetHandle`. Whatever makes menu state fragile at that moment is in
the same neighbourhood as this defect.

The hypothesis it is meant to confirm or kill is that the form's window is
recreated when `BiDiMode` changes, and `TMenu.DoBiDiModeChanged` returns early
because the menu's `WindowHandle` is momentarily zero. If the log shows
`windowHandle=0` on the way back to a left-to-right language, that is the
cause; if it shows a valid handle and `rtlFlag=1` afterwards, the fault is
elsewhere and the guess was wrong.

The available lever either way: have `ApplyReadingOrder` re-assert each menu's
`BiDiMode` explicitly after the form has settled, forcing a real value change
so `DoBiDiModeChanged` runs against a valid window handle. Defensive rather
than aimed, so it waits on the log.

### The window is not restored properly after a right-to-left round trip

Reported 20 August. Going to Arabic and back leaves the main form no longer
filling the screen correctly - a strip of the desktop shows down the left-hand
side where the window should be maximised.

Almost certainly the same root as the menu residue: a form's window is
recreated when its `BiDiMode` changes, and the maximised state is a property of
the window rather than of anything the applicator restores. Worth re-testing
once the reading order is applied before the text rather than after.

### Geometry the application sets in code is overwritten, and never given back

The heading on Carillon's main form goes off centre on any language change and
stays off, including English to Italian and back. It has nothing to do with
right-to-left; that was a coincidence of when it was noticed.

Carillon positions that label itself, once, at startup:

    lblMainHeader.Left := (Screen.Width - lblMainHeader.Width) div 2;

`Playlist.pas:1095`. It centres against the **screen**, not the form.

The planner works from the designer geometry - Left 303, Width 545 in a form of
1597 - and proposes Left 303 to 286, Width 545 to 579. Those numbers are
internally right: 303+545/2 and 286+579/2 are both 575.5, so the label's own
centre is held exactly. But 575.5 was never where the label sat at run time,
because the application had already moved it. Applying the rule overwrites the
application's decision, and returning to English restores the *designed* 303
rather than the centre the application computed - and that line of code never
runs again, so nothing puts it right.

Widening the control alone would break it too, since the application's centring
used the old width.

**The fix is not better arithmetic.** A control whose geometry the application
assigns in code should have its text translated and its geometry left alone.
The scanner reads the Pascal source already but looks only for strings; it
would need to notice assignments to `Left`, `Top`, `Width`, `Height`,
`Position.X` and `Position.Y` and mark those controls, and the planner would
need to skip them.

This is the same machinery wanted for an image-backed form - *words yes,
geometry no* - reached from a different direction. Worth building once and
using for both. It is also the same family as the runtime-composed strings
above: three cases now where the application owns something at run time and
the tool assumes the designer owned it.

### Label layout on the random-directory screen

Reported 20 August against the Italian run. The instruction paragraphs and the
numbered directory rows read as loose and unevenly spaced; the layout can be
better than the planner currently makes it. No specific defect identified yet -
this is a quality judgement rather than a rule that was broken.

---

### The system-volume label is cramped

Reported 20 August against the Spanish run: "Volumen del sistema:" crowds the
slider beside it. A caption that grew has taken room the control next to it
needed, or the pair were never treated as a row.

---

## Wanted

### Work the competitive analysis into the development plan

`C:\Downloads\Delphi Localization Tools Competitive Analysis.docx`, 20 August
2026. A read-only survey of the thirteen live products in this market, their
prices, and where this one stands against them.

It should be read properly and turned into an ordered plan rather than left as
a document. Its own conclusions, and the ones worth arguing with:

- **Translation memory is the largest gap.** Every commercial rival has it and
  the strongest free one has it too. It is listed separately below and should
  be first.
- Price band for what exists today is $189-$499; the layout work is the
  argument for the upper end.
- Two former market leaders, Sisulizer and Multilizer, have closed. A
  documented import path for their project files is a direct acquisition
  channel that one competitor already exploits.
- The report was written from the README and therefore misses three things
  this product now does that nothing else in the field does: automatic
  per-string translation context, automatic right-to-left mirroring on both
  frameworks, and format-specifier protection. The README should say so.
- Two of its concessions deserve testing before they are accepted. "No
  C++Builder" - the scanner reads the same `.dfm` and `.fmx` files, so the
  reach may be much closer than assumed. "Windows only" - the Studio is, but
  the FireMonkey runtime may not be, and that is a materially stronger claim
  if it holds.

### Translation memory

Nothing remembers a translation across applications. The shared per-language
dictionaries carry approved *terms*, which is not the same thing: a term is a
word, and a memory is a sentence with the wording that was settled for it.

Every application translated adds to what the product knows, and at present
almost all of it is thrown away. A memory would mean the second application in
a language costs less than the first, the tenth costs very little, and the
wording a developer approved once never has to be approved again. It also
makes the product better the longer it is used, which no amount of engineering
does on its own.

Worth deciding early: whether a memory is per developer, per language, or
shareable between installations, and whether an exact match is applied
silently or offered for review.

### Repositioning at run time, and remembering it

A developer should be able to move and resize the controls on a translated
form while the application is running, see the result immediately, and have
those adjustments remembered - **without the original project's source, forms
or resources being touched**, which is the standing rule the whole product is
built on.

The pieces already exist. The runtime applies `Left`, `Top`, `Width`,
`Height`, alignment and the rest from a pack it reads at startup; the
applicator can already put a form back exactly as it was drawn. What is
missing is a way to capture a change made by hand and write it back into the
pack as an accepted layout decision, so it survives the next run and the next
scan.

This is the natural answer to the cases the planner cannot judge: a splash
screen, a form where text sits over artwork, a layout somebody simply prefers
differently. The planner proposes; a person adjusts; the adjustment is kept.

Design questions worth settling before any code: how the mode is entered and
left, whether it is available in a shipped application or only in a build the
developer runs, how an adjustment is attributed to a language, and what
happens to it when the text later changes.

### Buying back the speed lost to per-string context

Giving each string its own context turned about six requests per run into
about 297. It is correct, it is paid once per language, and since the retry
work it is slow rather than fatal - but a DeepL run of a Carillon-sized
application now takes minutes where it took seconds.

Two ways out, either of which would recover most of it:

- **Send several requests at once.** DeepL permits concurrency; a handful in
  flight cuts wall-clock time roughly in proportion, with no change in cost or
  in what is sent.
- **Give individual context only to short strings.** Precision matters for
  Help, Close, Play, Wed - a forty-word sentence is its own context and gains
  nothing from being isolated. Long strings could batch as they used to.

Neither is built. Both are cheap.

### DeepL server-side glossaries

DeepL can hold a glossary on its side and enforce it during translation, which
is stronger than sending terminology as context and hoping. The shared
per-language dictionaries this product already keeps are the obvious source
for one. Worth doing after the per-string context work has been measured, so
the two are not confused with one another.

---

## Not yet verified

- **Right-to-left grid column reversal** has not been seen working in a real
  application. The rule is planned, exported and applied by test, but the first
  two Arabic runs did not carry it for reasons since fixed.
- **Right-to-left generally** has one real run behind it, on one application.
- **CJK** - Chinese, Japanese and Korean - is entirely untested. Those
  languages do not wrap on spaces and do not hyphenate, and they usually run
  shorter than English rather than longer, so the settling pass would be
  exercised in a direction it has never seen.

---

## To strip before release

### The right-to-left field diagnostic

`LogReadingOrder` in `DAT.Runtime.VCL` writes a line to
`%LOCALAPPDATA%\DelphiAppTranslationStudio
tl-diagnostic.log` on every
apply. It exists to catch the menu residue above and has no business in a
shipped runtime, because it writes to a user's disk unasked from inside their
application.

Remove it, or return it to the environment-variable gate it started with, as
soon as the menu defect is understood. Nothing else depends on it.

### Nothing else, and that is worth saying

The eight probes written while chasing these defects - BiDiProbe, FlipProbe,
GridReverseProbe, GroupsReplicaProbe, BidiNumeralProbe, SoftHyphenProbe,
FMXSoftHyphenProbe, ShowValidation - live in a scratch directory outside the
repository and are tracked by nothing. They need no cleanup; they will vanish
with the session.

The 28 harnesses under `tools	ests` and the 52 layout contracts are **not**
clutter and should not be pruned. Every one encodes a defect that actually
happened: the grid headings, the duplicate form name, the colour that would not
stay, the encoding that arrived wrong, the placeholders a service ate, the
language code a service refused, the rate limit treated as a failure, the
property list that existed in four places. They are the reason those defects
cannot come back quietly, and each one cost a real debugging session to learn.

---

## Deferred by decision

- **The formal DOCX and PDF guides** are not to be regenerated until the
  localization-intelligence and iterative-update workflows finish acceptance
  testing.

---

## Splash screens

Splash text and labels are not translated. Requested 20 August 2026.

Three separate cases, and only the first is straightforward:

1. **A form-based splash with real labels.** Dropping the language manager on
   the splash form should be enough - `Loaded` fires when the form is
   constructed, and `Initialize` reads the language preference from disk with
   no dependence on the main form or on `Application.Run`. What is not yet
   proved is whether the applicator ever *fires* for such a form: a splash is
   usually shown and then blocked on, so `OnIdle` may never run and a
   borderless window may never raise an active-form change. If it does not,
   applying to the owner form at the end of `Initialize` is the fix, and it
   belongs in the shared core rather than in either adapter. FireMonkey
   already has the right hook in `TFormBeforeShownMessage`; the VCL has
   nothing equivalent.

2. **Text drawn onto the splash at run time** with `Canvas.TextOut`. Not
   harvested by the scanner since 14 August, deliberately, because such calls
   are usually data.

3. **Text baked into the splash bitmap.** Cannot be translated at all - there
   is nothing to scan, and the target application's resources are read-only by
   standing rule. The honest handling is to detect it and say so: a form with
   a full-size image and no translatable captions probably has its words in
   the picture.

Carillon's own splash is `CarillonSplash.dfm`, root object `Form1`, and the
catalog holds four entries for it.

A related risk is listed above under *Behaviour*: the settling pass can widen
and re-level controls on a form where text sits over artwork, which is exactly
what a splash is.
