# Fix List

Known defects and unfinished work, newest first. Items are removed when fixed,
not struck through. Anything here is deliberately *not* being worked on right
now; the point of the list is that nothing has to be remembered.

Last changed: August 21, 2026 (evening)

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

## Behaviour

### The settling pass can disturb an image-backed form

Widening a control, levelling a row or growing a font is safe on an ordinary
form and not on one where text sits over artwork - a splash screen, an About
box, a form with a full-size image. Such a form probably wants its words
translated and its geometry frozen.

### Runtime-composed strings need a call in the application

A caption an application builds in code and reassigns whenever the display
refreshes cannot be translated by a pack: anything written there is
overwritten moments later.

    StatusBar1.Panels[1].Text := 'Items in list:  ' + ItemCount.ToString;

The classification is right - the string genuinely belongs to the application
- and the only fix is a `TranslateText` call in the application, which the
translator is forbidden to make and the application's own developer can make
in a minute.

**The reporting half of this was closed on 21 August.** The review now writes
`application-owned-strings.md` beside `localization-review.html`, naming every
such string with its source file, its line, and the exact literal to wrap, and
the review says so on screen when there are any. A clean application gets no
report, and a stale one from a previous run is deleted rather than left to be
read as current. `DAT.Review.ApplicationStrings`, covered by
`ApplicationStringSmokeTests`.

What remains is the part the standing rule reserves for the developer: making
the call. That is not a defect and is not going to change.

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

A field diagnostic was written into `ApplyReadingOrder` while chasing this,
logging before and after each apply: the form, the pack's direction, the
form's `BiDiMode`, whether `WS_EX_RTLREADING` is on the window,
`SysLocale.MiddleEast`, and for every menu its `BiDiMode`,
`ParentBiDiMode`, `WindowHandle`, menu handle and the native right-to-left
flag on item zero.

**It has since been removed**, and the runtime writes nothing to a user's
disk. Anyone picking this up again will want to put it back temporarily -
`LogReadingOrder` in `DAT.Runtime.VCL`, behind an environment-variable gate
rather than unconditional, since it has no business in a shipped runtime.

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

### Label layout on the random-directory screen

Reported 20 August against the Italian run. The instruction paragraphs and the
numbered directory rows read as loose and unevenly spaced; the layout can be
better than the planner currently makes it. No specific defect identified yet -
this is a quality judgement rather than a rule that was broken.

---

### A row at a fixed pitch cannot grow, so its last members are squeezed

Reported 20 August against Vietnamese, whose day abbreviations are longer than
the English Mon, Tue, Wed. On Carillon's "Play on the following days" the seven
days are seven check boxes each with a separate label, laid out at a fixed
pitch: Lefts 78, 158, 236, 318, 398, 462 and 534, gaps of 80, 78, 82, 80, 64
and 72.

The planner widened what it could and then ran out of room:

| label | width | outcome |
|---|---|---|
| Label5 | 16 to 56 | spans 398-454, eight pixels short of the next |
| Label6 | 21 to 21 | **no room at all** - wrapped instead |
| Label7 | 24 to 37 | wrapped, height 20 to 35 |

Each decision is defensible on its own: widen where there is room, wrap where
there is not, shrink the font a little. Together they produce a row where five
days read normally and two are cramped onto two lines.

The right answer is to treat the row as a row. Seven pairs at an even pitch,
needing more width per pair than the pitch allows, should be **re-pitched
across the space the row actually has** - moving the check boxes with their
labels - rather than each label fighting for room inside a slot that was sized
for English.

There is already a pass that recognises an evenly pitched row of captions and
*preserves* the pitch. What is missing is letting the pitch itself grow when
the contents demand it and the parent has the room.

This is the general case of the cramped system-volume label below, which is the
same thing with two controls instead of fourteen.

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

### Add several languages in one pass, without a person driving it

Adding a language today means a whole wizard run: scan, translate, review,
export, deploy. Shipping ten common languages means doing that ten times, and
most of it is wasted - **the scan is language-independent.** Reading the forms,
working out what is translatable, building the domain profile and resolving
word senses do not change between Spanish and Swedish, yet they are paid for
every time.

What differs per language is small and already exists as library calls: build
the catalog from the scan, translate, validate, run the layout review, export
the pack. A batch runner would be orchestration rather than new capability.

Cost is not the obstacle. Carillon is about 6,500 billable characters per
language, so ten languages is roughly 65,000 - about six per cent of DeepL's
one-time Developer credit, with re-runs free because a translated string is
never sent twice. Time is the real cost: a few hundred requests per language,
so ten is perhaps half an hour unattended.

**The obstacle is that batching hides per-language quality.** The validator
catches structural damage - it is what stopped the Arabic run when format
specifiers were eaten - but nothing structural was wrong with a Help menu
reading "he helps". Ten packs produced unattended may contain that class of
error and look perfectly healthy.

So it should stop on a language that fails validation, carry on with the rest,
and end with a per-language summary naming whatever needs a person's eye -
rather than reporting silent success.

Worth building as a **headless command-line runner** rather than another wizard
page. That also closes a gap the competitive analysis names: every serious
rival ships a CLI for build servers and this does not. Two gaps, one piece of
work.

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

## Nothing waiting to be stripped before release

The eight probes written while chasing these defects - BiDiProbe, FlipProbe,
GridReverseProbe, GroupsReplicaProbe, BidiNumeralProbe, SoftHyphenProbe,
FMXSoftHyphenProbe, ShowValidation - live in a scratch directory outside the
repository and are tracked by nothing. They need no cleanup; they will vanish
with the session.

The 32 harnesses under `tools\tests` and the 64 layout contracts are **not**
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
