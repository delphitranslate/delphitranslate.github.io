# Layout Contracts

Each contract states one rule about how translated text is fitted, and proves it
on a form built for that purpose rather than on any particular application. The
rules are the point; Carillon is only one place they happen to apply.

A contract is three files sharing a name:

| File | Holds |
| --- | --- |
| `<name>.fmx` | a small form containing just the arrangement under test |
| `<name>.catalog.json` | the translated text for that form |
| `<name>.expected.json` | what the analyser must do with them |

The catalog refers to its form as `{FIXTUREDIR}\<name>.fmx`, so the fixtures can
live anywhere.

Translations are deliberately long — German-length words against English
originals — because a rule that only holds for Spanish is not a rule.

## Assertions

Numeric, because that is what layout is.

| Assertion | Meaning |
| --- | --- |
| `text_fits` | the translated text sits inside the planned control, keeping the breathing room its class expects |
| `right_edge_unchanged` | the control's right edge is where the designer put it |
| `centre_unchanged` | the control still sits about its designed centre |
| `planned_left_equals` / `planned_top_equals` / `planned_width_equals` | an exact placement or size |
| `planned_left_at_most` / `planned_height_at_most` | a bound |
| `font_at_least` | the text was not reduced past this size |
| `uniform_width_group` | every named control settles on one width |
| `even_pitch_group` | the named controls are evenly spaced, in order, without overlapping |

## Running them

```
powershell -ExecutionPolicy Bypass -File tools\build_layout_contracts.ps1
powershell -ExecutionPolicy Bypass -File tools\run_layout_contracts.ps1
```

The runner refuses to report on a harness older than the analyser it exercises,
and fails when a fixture has no expectation file. Both guards exist because a
result that describes code you are no longer running is worse than no result.

## Adding one

Add the three files. Coverage enforcement will fail the run until the
expectation exists, which is the point: a rule without a contract is a rule that
can quietly stop working.
