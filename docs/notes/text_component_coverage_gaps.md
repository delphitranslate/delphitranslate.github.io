# Text-bearing components: what we scan, and what we miss

Compiled 2026-08-17 from the RAD Studio 37 library source shipped on this
machine (`C:\Program Files (x86)\Embarcadero\Studio\37.0\source`), by listing
every class that *publishes* a property carrying user-visible text and
comparing it against the whitelist in `source\scan\DAT.Scan.Rules.pas`.

The docwiki was the intended source but rejects automated requests (HTTP 403).
The shipped source is better evidence in any case: it is the exact version the
translator compiles against, and it shows properties as declared rather than as
documented.

## Headline numbers

| Framework | Classes publishing text | We scan | We miss | Of which mainstream |
| --- | ---: | ---: | ---: | ---: |
| FireMonkey | 51 | 16 | 35 | 18 |
| VCL | 106 | 19 | 87 | 36 |

"Mainstream" excludes 3D, sensors, platform-specific and designtime-only units:
things a normal desktop application would not put on a form.

Counts exclude classes whose only text property is `Hint`, since `Hint` is
declared on every `TControl` and we already scan it everywhere.

---

## Tier 1 — worth adding first

These appear on ordinary business forms and carry text a user reads.

### FireMonkey

| Class | Property | Unit | Why it matters |
| --- | --- | --- | --- |
| `TText` | `Text` | FMX.Objects | A graphic text primitive. Very common on styled FMX forms as an alternative to `TLabel`, and completely invisible to us today. Probably the single largest FMX gap. |
| `TCornerButton` | `Text` | FMX.StdCtrls | Rounded button used throughout modern FMX designs. |
| `TExpander` | `Text` | FMX.StdCtrls | Collapsible section header. |
| `TExpanderButton` | `Text` | FMX.StdCtrls | Its button. |
| `TListBoxItem` | `Text` | FMX.ListBox | Items placed at design time. We scan `TListBox.Items.Strings` but not item objects. |
| `TTreeViewItem` | `Text` | FMX.TreeView | Every tree node authored in the designer. |
| `THeaderItem` | `Text` | FMX.Header | Header strip captions. |
| `TColumn` | `Header` | FMX.Grid | We list the seven concrete column types but not the base class, so a custom or unlisted column is skipped. |
| `TMaskEdit` | `Text`, `TextPrompt` | FMX.MaskEdit | Present in VCL list, absent from the FMX one. |
| `TEditButton` | `Text` | FMX.Edit | Buttons embedded in an edit. |
| `TControlAction` | `Text` | FMX.Controls | Actions drive menu and button captions. |
| `TMetropolisUIListBoxItem` | `Title`, `Description` | FMX.ListBox | Two visible strings per item. |
| `TOpenDialog` / save dialogs | `Title` | FMX.Dialogs | Dialog captions are user-visible and currently English. |

### VCL

| Class | Property | Unit | Why it matters |
| --- | --- | --- | --- |
| `TPanel` | `Caption` | Vcl.ExtCtrls | Extremely common, and panels are routinely used as captioned headers. |
| `TCategoryPanel` | `Caption` | Vcl.ExtCtrls | Category panel group headers. |
| `TFlowPanel`, `TGridPanel` | `Caption` | Vcl.ExtCtrls | Same. |
| `TLinkLabel` | `Caption` | Vcl.ExtCtrls | Hyperlink text, including its markup. |
| `TBoundLabel` | `Caption` | Vcl.ExtCtrls | The label half of `TLabeledEdit`. We scan the edit, not its label. |
| `TButtonedEdit` | `Text`, `TextHint` | Vcl.ExtCtrls | |
| `TToolButton` | `Caption` | Vcl.ComCtrls | Toolbar captions. |
| `TToolBar` | `Caption` | Vcl.ComCtrls | |
| `TStatusPanel` | `Text` | Vcl.ComCtrls | Status bar panels, authored at design time. |
| `THeaderSection` | `Text` | Vcl.ComCtrls | |
| `TListColumn` | `Caption` | Vcl.ComCtrls | `TListView` column headings — the VCL equivalent of the grid-header problem we already fought in FMX. |
| `TListGroup` | `Header` | Vcl.ComCtrls | |
| `TCoolBand` | `Text` | Vcl.ComCtrls | |
| `TTabControl` | `Tabs` | Vcl.ComCtrls | A whole string list of tab captions. |
| `TTabSet` | `Tabs` | Vcl.Tabs | Same. |
| `TComboBoxEx` | `Text` | Vcl.ComCtrls | |
| `TNumberBox` | `TextHint` | Vcl.NumberBox | |
| `TPage` | `Caption` | Vcl.ExtCtrls | Notebook pages. |
| `TTaskDialog` | `Caption`, `Text`, `Title`, `FooterText` | Vcl.Dialogs | Four visible strings, and task dialogs are usually the most prominent text in an application. |
| `TOpenDialog`, `TFileOpenDialog`, `TFileSaveDialog` | `Title` | Vcl.Dialogs | |
| `TActionClientItem`, `TActionListItem` | `Caption` | Vcl.ActnMan | Action manager captions drive ribbons and menus. |
| `TBaseButtonItem`, `TButtonCategory` | `Caption` | Vcl.CategoryButtons | |
| `TControlAction` | `Caption` | Vcl.Controls | |

## Tier 2 — real but lower value

- `TListView.Items`, `TTreeView.Items`, `TMenu.Items`, `TButtonGroup.Items`,
  `TJumpCategoryItem.Items` (VCL): collection contents authored at design time.
  Worth doing after the single-property classes.
- `TImageCollectionItem.Description`, `TSeStyleSource.Description`: shown in
  some UIs, absent from most.
- `TDdeClientItem`/`TDdeServerItem` `Lines`/`Text`: legacy, rarely user-visible.

## Tier 3 — deliberately excluded

- 3D text (`TText3D`, `TTextLayer3D`, `TForm3D.Caption`): real text, but a 3D
  scene is not the kind of application this tool targets.
- Platform-specific units (Android, iOS, Win-only dialog shims).
- `TStyleDescription.Title`, designtime-only and editor-facing strings.
- `TAppletModule.Caption` (control panel applets).

## Notable absence the survey cannot show

`Vcl.DBGrids` is **not shipped as source** with this installation, so the survey
could not read it. From the documented API, `TColumn.Title.Caption` carries the
column heading of a data-aware grid. That is the same class of defect we spent
a long time on for FMX grids, and it is very likely unhandled. It needs
confirming against the DCU or the documentation before being acted on — I have
not verified it.

## What this application actually uses

Component classes counted across the Carillon test target's form files, as a
sanity check on priorities:

```
105 TLabel      45 TEdit       34 TMenuItem   33 TButton     20 TCheckBox
 12 TTimeField   9 TTimer       7 TRectangle   6 TDateEdit    6 TBindNavigator
  4 TPanel       4 TImage       3 TOpenDialog  3 TMenuBar     3 TLayout
  2 TStringGrid  2 TMemo        2 TGroupBox    1 TStatusBar   1 TComboEdit
  1 TTrackBar    1 TMediaPlayer
```

Two gaps show up in this list specifically:

- `TOpenDialog.Title` (three instances) — dialog captions stay English.
- `TComboEdit` — we scan its `TextPrompt` but not its `Items.Strings`.

Everything else this application uses is already covered, which is consistent
with the translation quality being good and the remaining defects being layout
rather than coverage. A different application, particularly a VCL one using
panels, toolbars, list views or task dialogs, would fare considerably worse.

## Suggested order of work

1. `TText` (FMX) — largest single FMX gap, trivial to add to the whitelist.
2. VCL `TPanel`, `TToolButton`, `TStatusPanel`, `TListColumn`, `TTabControl.Tabs`
   — the common VCL surface, and the reason a VCL application would look
   half-translated today.
3. `TTaskDialog` (four properties) and the dialog `Title` properties.
4. `TCornerButton`, `TExpander`, `TListBoxItem`, `TTreeViewItem` (FMX).
5. Collection properties (`Items`, `Tabs`) as a group, since they share one
   mechanism.
6. Confirm and then handle `TDBGrid` column titles.

Each addition is a line in the class lists in `DAT.Scan.Rules.pas` and, for
anything that affects layout, a contract in `contracts\layout`.
