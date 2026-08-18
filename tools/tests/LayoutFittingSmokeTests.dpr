program LayoutFittingSmokeTests;

{ Runs the localization layout analyser over a real translated catalog and
  checks the geometry it plans, without needing the Setup Wizard or the target
  application. The analyser leaves both the designed geometry and its planned
  geometry on every control, so the two can be compared directly.

  What it looks for, per form:

    - overlaps the plan introduces. Controls that already sat on top of one
      another in the designer are ignored, because that arrangement is
      deliberate and pulling it apart is itself a defect.
    - controls planned outside the form.
    - text planned to be clipped: wider than the control that has to hold it
      while wrapping is off.

  Exit code is 0 when the plan is clean and 1 when it is not, so it can gate a
  change before a full translate and deploy cycle. }

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  FMX.Forms,
  FMX.TextLayout,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Review.Localization in '..\..\source\review\DAT.Review.Localization.pas';

type
  TFormIssues = record
    NewOverlaps: Integer;
    OutOfBounds: Integer;
    ClippedText: Integer;
    ShrunkText: Integer;
  end;

function Overlaps(const ALeft, ATop, AWidth, AHeight,
  BLeft, BTop, BWidth, BHeight: Double): Boolean;
const
  Tolerance = 2;
begin
  Result :=
    (Min(ALeft + AWidth, BLeft + BWidth) - Max(ALeft, BLeft) > Tolerance) and
    (Min(ATop + AHeight, BTop + BHeight) - Max(ATop, BTop) > Tolerance);
end;

function DesignedOverlap(const AFirst, ASecond: TLayoutControl): Boolean;
begin
  Result := Overlaps(AFirst.Left, AFirst.Top, AFirst.Width, AFirst.Height,
    ASecond.Left, ASecond.Top, ASecond.Width, ASecond.Height);
end;

function PlannedOverlap(const AFirst, ASecond: TLayoutControl): Boolean;
begin
  Result := Overlaps(AFirst.PlannedLeft, AFirst.PlannedTop,
    AFirst.PlannedWidth, AFirst.PlannedHeight,
    ASecond.PlannedLeft, ASecond.PlannedTop,
    ASecond.PlannedWidth, ASecond.PlannedHeight);
end;

{ Width of this control's translated text at the size it is planned to be
  drawn, measured with the same engine that will render it. }
function MeasuredTextWidth(const AControl: TLayoutControl): Double;
var
  Layout: TTextLayout;
  PointSize: Double;
begin
  if Trim(AControl.TranslatedText) = '' then
    Exit(0);
  PointSize := AControl.PlannedFontSize;
  if PointSize <= 0 then
    PointSize := AControl.FontSize;
  if PointSize <= 0 then
    PointSize := 12;
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.Text := AControl.TranslatedText;
    Layout.Font.Size := PointSize;
    Layout.WordWrap := False;
    Layout.EndUpdate;
    Result := Layout.Width;
  finally
    Layout.Free;
  end;
end;

{ True when the translated text cannot be shown inside the planned control.
  Without wrapping that means the text is wider than the control; with wrapping
  it means the lines it breaks into need more height than the control has. }
{ Breathing room a control of this class must keep between its text and its
  edge. Text reaching within a pixel of the edge fits by arithmetic and looks
  jammed, so these are what "fits" actually means. }
function PaddingHorizontal(const AControl: TLayoutControl): Double;
begin
  { A tick box or radio dot is drawn beside the caption and takes room from the
    same width, so the text has less of the control than its size suggests. }
  if ContainsText(AControl.ComponentClassName, 'CheckBox') or
    ContainsText(AControl.ComponentClassName, 'RadioButton') then
    Result := 6 + 22
  else if ContainsText(AControl.ComponentClassName, 'Button') then
    Result := 12
  else if ContainsText(AControl.ComponentClassName, 'Label') then
    Result := 4
  else
    Result := 6;
end;

function PaddingVertical(const AControl: TLayoutControl): Double;
begin
  if ContainsText(AControl.ComponentClassName, 'Button') then
    Result := 6
  else if ContainsText(AControl.ComponentClassName, 'Label') then
    Result := 2
  else
    Result := 3;
end;

{ Width of arbitrary text at a given size. }
function WidthOfText(const AText: string; const APointSize: Double): Double;
var
  Layout: TTextLayout;
begin
  if Trim(AText) = '' then
    Exit(0);
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.Text := AText;
    Layout.Font.Size := Max(APointSize, 1);
    Layout.WordWrap := False;
    Layout.EndUpdate;
    Result := Layout.Width;
  finally
    Layout.Free;
  end;
end;

{ True when the control was already too tight for its own source text in the
  designer. Several forms letter their rows with labels barely wider than the
  digit they hold, and a control that never had room to begin with is not
  something translation broke. }
function AlreadyTightByDesign(const AControl: TLayoutControl): Boolean;
begin
  Result := (Trim(AControl.SourceText) <> '') and (AControl.Width > 0) and
    (WidthOfText(AControl.SourceText, Max(AControl.FontSize, 9)) +
      2 * PaddingHorizontal(AControl) > AControl.Width);
end;

const
  { How far short of the full padding a control may fall before it reads as
    crowded. }
  PaddingSlack = 2;

function TextIsClipped(const AControl: TLayoutControl;
  out ANeeded, AHave: Double; out AWhat: string): Boolean;
var
  TextWidth, LineHeight, PointSize: Double;
  Lines: Integer;
begin
  ANeeded := 0;
  AHave := 0;
  AWhat := '';
  Result := False;
  if Trim(AControl.TranslatedText) = '' then
    Exit;
  if AControl.PlannedWidth <= 0 then
    Exit;
  if AlreadyTightByDesign(AControl) then
    Exit;
  TextWidth := MeasuredTextWidth(AControl);
  if TextWidth <= 0 then
    Exit;
  PointSize := AControl.PlannedFontSize;
  if PointSize <= 0 then
    PointSize := AControl.FontSize;
  if PointSize <= 0 then
    PointSize := 12;
  LineHeight := PointSize * 1.45;
  { The padding is a target rather than a hard edge, so allow a shortfall of a
    pixel or two before calling it crowded. This is not the old hairline
    tolerance: the requirement being tested already includes the full padding,
    so falling a pixel short means slightly tight padding, not text against the
    edge. }
  if not AControl.PlannedWordWrap then
  begin
    AWhat := 'width';
    ANeeded := TextWidth + 2 * PaddingHorizontal(AControl);
    AHave := AControl.PlannedWidth;
    Result := ANeeded > AControl.PlannedWidth + PaddingSlack;
  end
  else
  begin
    Lines := Max(1, Ceil(TextWidth /
      Max(AControl.PlannedWidth - 2 * PaddingHorizontal(AControl), 1)));
    AWhat := 'height';
    ANeeded := Lines * LineHeight + 2 * PaddingVertical(AControl);
    AHave := AControl.PlannedHeight;
    Result := ANeeded > AControl.PlannedHeight + PaddingSlack;
  end;
end;

{ A caption reduced far below the size it was drawn at reads as noticeably
  smaller than everything around it, which is a defect whether or not the text
  happens to fit.

  The comparison the reader actually makes is with the neighbours, so a row
  that shrinks together does not trip this: six navigator captions all at the
  same smaller size still read as one row, and holding them at a size that
  clips their text would be the worse fault. What must never happen is a
  control shrinking alone while the row around it keeps its size. Legibility
  still has a floor, and that applies to a set as much as to a lone caption. }
function FontReducedTooFar(const AControl: TLayoutControl;
  const AControls: TList<TLayoutControl>;
  out APlanned, ADesigned: Double): Boolean;
const
  MinimumRatio = 0.85;
  RowTolerance = 3;
  LegibilityFloor = 9;
var
  Other: TLayoutControl;
  SharedWithRow: Boolean;
  Neighbours: Integer;
begin
  APlanned := AControl.PlannedFontSize;
  ADesigned := AControl.FontSize;
  Result := (ADesigned > 0) and (APlanned > 0) and
    (APlanned < ADesigned * MinimumRatio - 0.01);
  if not Result then
    Exit;
  if APlanned < LegibilityFloor - 0.01 then
    Exit;
  SharedWithRow := True;
  Neighbours := 0;
  for Other in AControls do
  begin
    if (Other = AControl) or (Other.TranslatedText = '') then
      Continue;
    if not SameText(Other.ParentName, AControl.ParentName) then
      Continue;
    if (Abs(Other.Top - AControl.Top) > RowTolerance) or
      (Abs(Other.Height - AControl.Height) > RowTolerance) then
      Continue;
    Inc(Neighbours);
    if Abs(Other.PlannedFontSize - APlanned) > 0.05 then
      SharedWithRow := False;
  end;
  if (Neighbours > 0) and SharedWithRow then
    Result := False;
end;

function Positioned(const AControl: TLayoutControl): Boolean;
begin
  Result := AControl.HasPosition and AControl.HasSize and
    (SameText(Trim(AControl.Align), '') or
     SameText(Trim(AControl.Align), 'None'));
end;

var
  CatalogFileName: string;
  Catalog: TTranslationCatalog;
  Review: TLocalizationReview;
  Control, Other, FormControl: TLayoutControl;
  FormNames: TStringList;
  FormName: string;
  Issues: TFormIssues;
  TotalNew, TotalBounds, TotalClipped, TotalShrunk: Integer;
  FormWidth, FormHeight: Double;
  NeededSize, HaveSize: Double;
  ClipWhat: string;
  DumpFilter: string;
  Index, Scan, FormCount: Integer;
  Controls: TList<TLayoutControl>;
begin
  try
    if ParamCount >= 1 then
      CatalogFileName := ParamStr(1)
    else
      CatalogFileName := TPath.Combine(
        TPath.Combine(TPath.GetHomePath,
          'DelphiAppTranslationStudio\Workspaces\Carillon\Development'),
        'Carillon.es-ES.translation-project.json');

    { An optional second argument names controls to describe rather than judge.
      Seeing what the analyser decided for one control is usually the quickest
      way to understand why a screen looks wrong. }
    DumpFilter := '';
    if ParamCount >= 2 then
      DumpFilter := LowerCase(ParamStr(2));

    if not TFile.Exists(CatalogFileName) then
    begin
      Writeln('Catalog not found: ' + CatalogFileName);
      Writeln('Usage: LayoutFittingSmokeTests [catalog.json]');
      ExitCode := 2;
      Exit;
    end;

    Writeln('Layout fitting smoke test');
    Writeln('Catalog: ' + CatalogFileName);
    Writeln('');

    Catalog := TCatalogJson.LoadFromFile(CatalogFileName);
    try
      Review := TLocalizationReviewer.Analyze(Catalog);
      try
        TotalNew := 0;
        TotalBounds := 0;
        TotalClipped := 0;
        TotalShrunk := 0;

        FormNames := TStringList.Create;
        try
          FormNames.Sorted := True;
          FormNames.Duplicates := dupIgnore;
          for Control in Review.Controls do
            if Trim(Control.FormName) <> '' then
              FormNames.Add(Control.FormName);

          for FormName in FormNames do
          begin
            Issues := Default(TFormIssues);
            FormWidth := 0;
            FormHeight := 0;
            Controls := TList<TLayoutControl>.Create;
            try
              for Control in Review.Controls do
              begin
                if not SameText(Control.FormName, FormName) then
                  Continue;
                if SameText(Control.ComponentName, FormName) then
                begin
                  FormWidth := Control.Width;
                  FormHeight := Control.Height;
                  Continue;
                end;
                if Positioned(Control) then
                  Controls.Add(Control);
              end;

              for Index := 0 to Controls.Count - 1 do
              begin
                Control := Controls[Index];

                if (FormWidth > 0) and
                  (Control.PlannedLeft + Control.PlannedWidth > FormWidth + 1) then
                begin
                  Inc(Issues.OutOfBounds);
                  Writeln(Format('  BOUNDS  %s.%s right edge %.0f exceeds form width %.0f',
                    [FormName, Control.ComponentName,
                     Control.PlannedLeft + Control.PlannedWidth, FormWidth]));
                end;
                if (FormHeight > 0) and
                  (Control.PlannedTop + Control.PlannedHeight > FormHeight + 1) then
                begin
                  Inc(Issues.OutOfBounds);
                  Writeln(Format('  BOUNDS  %s.%s bottom edge %.0f exceeds form height %.0f',
                    [FormName, Control.ComponentName,
                     Control.PlannedTop + Control.PlannedHeight, FormHeight]));
                end;

                if (DumpFilter <> '') and
                  (ContainsText(LowerCase(Control.ComponentName), DumpFilter) or
                   ContainsText(LowerCase(FormName), DumpFilter)) then
                begin
                  Writeln(Format('  %s.%s (%s)', [FormName,
                    Control.ComponentName, Control.ComponentClassName]));
                  Writeln(Format('      designed %.0f,%.0f %.0fx%.0f  font %.1f  align %s',
                    [Control.Left, Control.Top, Control.Width, Control.Height,
                     Control.FontSize, Control.HorzAlign]));
                  Writeln(Format('      planned  %.0f,%.0f %.0fx%.0f  font %.1f  wrap %s',
                    [Control.PlannedLeft, Control.PlannedTop,
                     Control.PlannedWidth, Control.PlannedHeight,
                     Control.PlannedFontSize,
                     IfThen(Control.PlannedWordWrap, 'yes', 'no')]));
                  Writeln(Format('      text     %s', [Control.TranslatedText]));
                end;

                if TextIsClipped(Control, NeededSize, HaveSize, ClipWhat) then
                begin
                  Inc(Issues.ClippedText);
                  Writeln(Format('  CLIP    %s.%s needs %s %.0f but has %.0f%s  "%s"',
                    [FormName, Control.ComponentName, ClipWhat, NeededSize,
                     HaveSize, IfThen(Control.PlannedWordWrap, ' (wrapped)', ''),
                     Copy(Control.TranslatedText, 1, 42)]));
                end;

                if FontReducedTooFar(Control, Controls, NeededSize, HaveSize) then
                begin
                  Inc(Issues.ShrunkText);
                  Writeln(Format('  FONT    %s.%s reduced to %.1f from %.1f (%.0f%% of designed)  "%s"',
                    [FormName, Control.ComponentName, NeededSize, HaveSize,
                     100 * NeededSize / HaveSize,
                     Copy(Control.TranslatedText, 1, 42)]));
                end;

                for Scan := Index + 1 to Controls.Count - 1 do
                begin
                  Other := Controls[Scan];
                  if not SameText(Control.ParentName, Other.ParentName) then
                    Continue;
                  if not PlannedOverlap(Control, Other) then
                    Continue;
                  if DesignedOverlap(Control, Other) then
                    Continue;
                  Inc(Issues.NewOverlaps);
                  Writeln(Format('  OVERLAP %s: %s intersects %s',
                    [FormName, Control.ComponentName, Other.ComponentName]));
                  Writeln(Format('            %-22s designed %.0f,%.0f %.0fx%.0f  planned %.0f,%.0f %.0fx%.0f',
                    [Control.ComponentName, Control.Left, Control.Top,
                     Control.Width, Control.Height, Control.PlannedLeft,
                     Control.PlannedTop, Control.PlannedWidth,
                     Control.PlannedHeight]));
                  Writeln(Format('            %-22s designed %.0f,%.0f %.0fx%.0f  planned %.0f,%.0f %.0fx%.0f',
                    [Other.ComponentName, Other.Left, Other.Top,
                     Other.Width, Other.Height, Other.PlannedLeft,
                     Other.PlannedTop, Other.PlannedWidth,
                     Other.PlannedHeight]));
                end;
              end;
            finally
              Controls.Free;
            end;

            if (Issues.NewOverlaps = 0) and (Issues.OutOfBounds = 0) and
              (Issues.ClippedText = 0) then
              Writeln(Format('  ok      %s', [FormName]))
            else
              Writeln(Format('  FAIL    %s (%d new overlap(s), %d out of bounds)',
                [FormName, Issues.NewOverlaps, Issues.OutOfBounds]));

            Inc(TotalNew, Issues.NewOverlaps);
            Inc(TotalBounds, Issues.OutOfBounds);
            Inc(TotalClipped, Issues.ClippedText);
            Inc(TotalShrunk, Issues.ShrunkText);
          end;
          FormCount := FormNames.Count;
        finally
          FormNames.Free;
        end;

        Writeln('');
        Writeln(Format('Forms: %d   new overlaps: %d   out of bounds: %d',
          [FormCount, TotalNew, TotalBounds]));
        if (TotalNew = 0) and (TotalBounds = 0) and (TotalClipped = 0) and
          (TotalShrunk = 0) then
        begin
          Writeln('RESULT: pass');
          ExitCode := 0;
        end
        else
        begin
          Writeln('RESULT: fail');
          ExitCode := 1;
        end;
      finally
        Review.Free;
      end;
    finally
      Catalog.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 3;
    end;
  end;
end.
