# Fix List

Known defects and unfinished work, newest first. Items are removed when fixed,
not struck through. Anything here is deliberately *not* being worked on right
now; the point of the list is that nothing has to be remembered.

Last changed: August 22, 2026 (merged with the notes list)

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

The domain profile settles which *sense* a word carries and does that
correctly - the screens it was tried on read well. What it does not carry
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

### Label layout on a screen of paragraphs and numbered rows

Reported 20 August against the Italian run. The instruction paragraphs and the
numbered rows beneath them read as loose and unevenly spaced; the layout can be
better than the planner currently makes it. No specific defect identified yet -
this is a quality judgement rather than a rule that was broken.

---

### A row at a fixed pitch cannot grow, so its last members are squeezed

Reported 20 August against Vietnamese, whose day abbreviations are longer than
the English Mon, Tue, Wed. On a seven-day schedule row the days are seven
check boxes each with a separate label, laid out at a fixed
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

This is the general case of the cramped caption below, which is the
same thing with two controls instead of fourteen.

### A caption beside a slider is cramped

Reported 20 August against the Spanish run: a caption that grew in
translation crowds the slider beside it. A caption that grew has taken room the control next to it
needed, or the pair were never treated as a row.

---

## Wanted

Everything that was here is done. What comes next is ordered in
`Development Plan.md`, which is built from the competitive analysis
rather than from this list.

## Moved here from the notes list, 22 August

`docs/notes/fix_list.md` ran alongside this one and carried three open
items nobody was reading. They came here, and that file is an archive.
Two of the three are now closed; one remains.

### The runtime harness does not cover a non-default platform style

Low. Narrowed twice. The harness once asserted a single label; it now asserts
a label, a button, a check box and a grid column across all seven layout
properties, plus the round trip home. A check box carries its caption beside a
tick box, so its width means something different from a label's, and a grid
column is not a control in the ordinary sense.

What remains is a control inside a styled container, and a form running under
a platform style other than the default. The second is the more interesting:
the style is what silently overrides a font size or a wrapping setting when
styled settings have not been cleared, which was the trap behind two separate
defects.

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

