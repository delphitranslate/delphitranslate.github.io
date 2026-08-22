# Development Plan

Ordered work, derived from the competitive analysis of 20 August 2026 and from
what the product has been measured to do since.

Last changed: August 22, 2026

The analysis surveyed thirteen live products and made six recommendations. This
turns them into an order of work rather than leaving them as a document, marks
what is now done, and records two of its conclusions that were tested and turned
out to be understated.

---

## What the analysis got right, and what has since changed

It made six recommendations. Two are now closed.

| Recommendation | Status |
|---|---|
| Close the translation-memory gap first | **Done** — memory plus TMX and TBX |
| Add a headless command-line build path | **Done** — `DATBatch` |
| Free translator-facing editor for the JSON catalog | Open, ranked 1 below |
| Position against the Sisulizer and Multilizer vacuum | Open, ranked 2 below |
| Lead marketing with layout remediation and offline JSON packs | Open, ranked 4 below |
| Price in the $189–$499 band | Open, ranked 6 below |

It was written from the README, so it missed three things nothing else in the
field does: automatic per-string translation context, automatic right-to-left
mirroring on both frameworks, and format-specifier protection. The README should
say so; that is ranked 4 below.

---

## Two concessions it made that were not tested, and should not have been conceded

The analysis accepted "Windows only" and "no C++Builder" from the README. Both
were checked against the code rather than the documentation.

### "Windows only" is true of the Studio and not of the runtime

What ships inside a customer's application is `source\runtime` and
`source\components`. Every one of those units was inspected for a dependency on
`Winapi.*` or `Vcl.*`:

| Unit | Windows dependency |
|---|---|
| `DAT.Runtime.LanguagePack` | none |
| `DAT.Runtime.Preference` | none |
| `DAT.Runtime.LayoutOverrides` | none |
| `DAT.Runtime.FMX` | none |
| `DAT.Components.Core` | none |
| `DAT.Components.FMX` | none |
| `DAT.Components.FMX.LanguageSelector` | none |
| `DAT.Runtime.Manager` | one call, already inside `{$IFDEF MSWINDOWS}` |
| `DAT.Runtime.VCL` | Windows throughout, and correctly so — the VCL is Windows |

So the FireMonkey runtime path has no Windows dependency at all. The claim
available is materially stronger than the one being made: **the Studio runs on
Windows; a FireMonkey application carrying this runtime is not obviously
restricted to it.**

What that is not yet: a compile for macOS, iOS, Android, or Linux, or any test
on one. Reading the uses clauses proves nothing is obviously in the way. It does
not prove the thing runs. That compile is ranked 3 below, and until it is done
the honest claim is "no known Windows dependency in the FireMonkey runtime",
not "cross-platform".

### "No C++Builder" is broader than it sounds

C++Builder shares the form files. `.dfm` and `.fmx` are the same format written
by the same designer, and the scanner reads the file rather than the language.
The parts that would not carry across are narrower than the concession
suggests:

| Stage | C++Builder |
|---|---|
| Form scanning (`.dfm`, `.fmx`) | Should work unchanged — same files |
| Pascal scanning (`.pas`) | Does not apply; a C++Builder project has `.cpp` |
| Project detection (`.dproj`) | Needs `.cbproj` added |
| Layout planning | Framework-neutral; works on what the scan produced |
| Runtime component | Delphi code, and C++Builder links Delphi units |

That is a smaller job than "add C++Builder support" implies, and it is
untested. Ranked 5 below.

---

## The order

### 1. A translator-facing editor for the catalog

The largest remaining commercial gap now that memory is closed. Soluling,
Passolo, Lingobit, and Alchemy all ship a separate translator client, frequently
free, and that is how they reach professional linguists and agencies. A
developer-only tool cannot serve a team whose translator is not a Delphi
developer.

The catalog is already an open, documented JSON file, so this is a reader and an
editor over a format that exists rather than new machinery. It should be
separate from the Studio, free, and able to open a catalog with no project, no
Delphi, and no key.

### 2. A documented import path for stranded Sisulizer and Multilizer projects

Both were market leaders and both have ceased operations. Soluling already
markets itself as the migration path and ships a converter for Sisulizer `.slp`
files. That population is actively looking, and an import path is a direct
acquisition channel rather than a feature.

TMX import already covers anyone who can export TMX from their old tool, which
is the cheap half and is done. The remaining work is reading the native project
formats for people who cannot.

### 3. Compile the FireMonkey runtime for one non-Windows target

To settle section two above. One successful compile and one language switch on
macOS or Android converts a concession into a claim. Until then the platform
statement stays as it is.

### 4. Correct the README, then lead marketing with what is actually unmatched

Three capabilities the analysis did not know about, because they postdate the
README: automatic per-string translation context, automatic right-to-left
mirroring on both frameworks, and format-specifier protection. Together with the
two it did identify — automated layout remediation and the offline JSON pack —
those are the claims no competitor can currently make.

The README should be corrected first. Marketing that leads with a claim the
documentation does not support fails the first time somebody checks.

### 5. Establish how far C++Builder reach actually goes

Scan one C++Builder project. The answer decides whether this is a small piece of
work on project detection or a real one, and the analysis conceded it without
anybody looking.

### 6. Pricing, once the layout work is reliable

The analysis puts the product in the $189–$499 band as built, with layout
remediation as the argument for the upper end or above it. That argument depends
on the layout work being dependable, which is exactly what the Fix List still
records open questions about. Price when those close, not before.

Recurring-revenue precedent is uniform across the field: renewals at roughly a
quarter of licence price per year.

### 7. XLIFF

The analysis names TMX, TBX, and XLIFF together. TMX and TBX are done; XLIFF is
not. It matters least of the three for this product — XLIFF carries documents
through a translation workflow, where TMX carries the memory that makes the
second release cheap — but it is the format an agency is most likely to ask for
by name.

---

## What is deliberately not on this plan

**Competing on price with the free tier.** BTM, dxgettext, DKLang, i18n,
Kryvich, and the bundled RAD Studio ITE are credible and maintained. A paid
product has to beat them on convenience and completeness, not on price, and any
plan that tries to undercut zero is not a plan.

**Becoming a generalist tool.** Soluling, Lingobit, Passolo, and Alchemy earn
their €690–€1,990 by covering dozens of formats. Following them means competing
on their ground with none of their history. The Delphi-specific band is where
this product's advantages are advantages.
