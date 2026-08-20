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

### A noun read as a verb

Arabic came back with button captions and menu items in the third person
singular rather than as imperatives or nouns:

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

- **Splash screens.** A form-based splash can be translated by dropping the
  language manager on it; text baked into a bitmap cannot be. Left alone on
  purpose.
- **The formal DOCX and PDF guides** are not to be regenerated until the
  localization-intelligence and iterative-update workflows finish acceptance
  testing.
