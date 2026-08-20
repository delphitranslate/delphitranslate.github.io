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

### Status bar panels need a call in the target application

`StatusBar1.Panels[n].Text` is classified `dynamicValue` /
`manualTranslateText` because the application rebuilds those strings whenever
it likes; stamping a translation once would be overwritten immediately. The
translations are in the pack and ready. This is correct behaviour but it is not
documented anywhere a developer would find it, and in Carillon it looks like a
missing translation.

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

The available lever, if the cause stays hidden: have `ApplyReadingOrder`
re-assert each menu's `BiDiMode` explicitly after the form has settled, forcing
a real value change so `DoBiDiModeChanged` is guaranteed to run against a valid
window handle. That is defensive rather than a fix for a known cause, so it has
not been written.

### Label layout on the random-directory screen

Reported 20 August against the Italian run. The instruction paragraphs and the
numbered directory rows read as loose and unevenly spaced; the layout can be
better than the planner currently makes it. No specific defect identified yet -
this is a quality judgement rather than a rule that was broken.

---

## Wanted

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
