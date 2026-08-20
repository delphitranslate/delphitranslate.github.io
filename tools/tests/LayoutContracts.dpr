program LayoutContracts;

{ Evaluates one layout contract.

  A contract names a catalog of translated text for a small purpose-built form
  and states what the analyser must do with it. The assertions are numeric,
  because that is what layout is: a right edge that must not move, a control
  that must keep its place, a caption that must still hold its text.

  Called with the path to an expectation file. Exit code is 0 when every
  assertion holds and 1 when any does not. }

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  FMX.Forms,
  FMX.TextLayout,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Review.Localization in '..\..\source\review\DAT.Review.Localization.pas',
  DAT.Review.TextMeasurement in '..\..\source\review\DAT.Review.TextMeasurement.pas',
  DAT.Review.TextMeasurement.GDI in '..\..\source\review\DAT.Review.TextMeasurement.GDI.pas',
  DAT.Review.TextMeasurement.FMX in '..\..\source\review\DAT.Review.TextMeasurement.FMX.pas';

var
  Failures: TStringList;

function PaddingHorizontal(const AControl: TLayoutControl): Double;
begin
  if ContainsText(AControl.ComponentClassName, 'Button') then
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

{ Which framework the fixture under test describes. A contract that judged a
  VCL layout with FireMonkey metrics would fail a correct plan and pass an
  incorrect one, because the planner and the referee would be measuring with
  different rulers. }
var
  ContractFramework: TTargetFramework = tfFireMonkey;

function WidthOfText(const AText: string; const APointSize: Double): Double;
var
  Measurer: ITextMeasurer;
begin
  if Trim(AText) = '' then
    Exit(0);
  Measurer := TTextMeasurement.Measurer(ContractFramework);
  if Measurer = nil then
    Exit(0);
  Result := Measurer.TextWidth(AText, Max(APointSize, 1), False);
end;

function PlannedFontOf(const AControl: TLayoutControl): Double;
begin
  Result := AControl.PlannedFontSize;
  if Result <= 0 then
    Result := AControl.FontSize;
  if Result <= 0 then
    Result := 12;
end;

{ The translated text still fits inside the control the analyser planned,
  keeping the breathing room its class expects. }
function TextFits(const AControl: TLayoutControl; out AWhy: string): Boolean;
const
  Slack = 2;
var
  TextWidth, Needed: Double;
  Lines: Integer;
begin
  AWhy := '';
  TextWidth := WidthOfText(AControl.TranslatedText, PlannedFontOf(AControl));
  if TextWidth <= 0 then
    Exit(True);
  if not AControl.PlannedWordWrap then
  begin
    Needed := TextWidth + 2 * PaddingHorizontal(AControl);
    Result := Needed <= AControl.PlannedWidth + Slack;
    if not Result then
      AWhy := Format('needs width %.0f with padding, has %.0f',
        [Needed, AControl.PlannedWidth]);
  end
  else
  begin
    Lines := Max(1, Ceil(TextWidth /
      Max(AControl.PlannedWidth - 2 * PaddingHorizontal(AControl), 1)));
    Needed := Lines * PlannedFontOf(AControl) * 1.45 +
      2 * PaddingVertical(AControl);
    Result := Needed <= AControl.PlannedHeight + Slack;
    if not Result then
      AWhy := Format('wraps to %d line(s) needing height %.0f, has %.0f',
        [Lines, Needed, AControl.PlannedHeight]);
  end;
end;

function FindControl(const AReview: TLocalizationReview;
  const AForm, AName: string): TLayoutControl;
var
  Candidate: TLayoutControl;
begin
  Result := nil;
  for Candidate in AReview.Controls do
    if SameText(Candidate.FormName, AForm) and
      SameText(Candidate.ComponentName, AName) then
      Exit(Candidate);
end;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    Failures.Add(AMessage);
end;

function NumberOf(const AObject: TJSONObject; const AName: string;
  out AValue: Double): Boolean;
var
  Value: TJSONValue;
begin
  AValue := 0;
  Value := AObject.GetValue(AName);
  Result := (Value <> nil) and Value.TryGetValue<Double>(AValue);
end;

function FlagOf(const AObject: TJSONObject; const AName: string): Boolean;
var
  Value: TJSONValue;
begin
  Value := AObject.GetValue(AName);
  Result := (Value is TJSONBool) and TJSONBool(Value).AsBoolean;
end;

procedure CheckControlBoundsExpectation(const AReview: TLocalizationReview;
  const AExpectation: TJSONObject; const AControl: TLayoutControl);
var
  BoundName: string;
  BoundControl: TLayoutControl;
  Expected: Double;
begin
  if NumberOf(AExpectation, 'planned_left_at_least', Expected) then
    Check(AControl.PlannedLeft >= Expected - 1,
      Format('%s.%s left is %.0f, expected at least %.0f',
        [AControl.FormName, AControl.ComponentName, AControl.PlannedLeft,
         Expected]));

  if NumberOf(AExpectation, 'planned_top_at_least', Expected) then
    Check(AControl.PlannedTop >= Expected - 1,
      Format('%s.%s top is %.0f, expected at least %.0f',
        [AControl.FormName, AControl.ComponentName, AControl.PlannedTop,
         Expected]));

  if NumberOf(AExpectation, 'planned_width_at_most', Expected) then
    Check(AControl.PlannedWidth <= Expected + 1,
      Format('%s.%s width is %.0f, expected no more than %.0f',
        [AControl.FormName, AControl.ComponentName, AControl.PlannedWidth,
         Expected]));

  if NumberOf(AExpectation, 'planned_height_at_least', Expected) then
    Check(AControl.PlannedHeight >= Expected - 1,
      Format('%s.%s height is %.0f, expected at least %.0f',
        [AControl.FormName, AControl.ComponentName, AControl.PlannedHeight,
         Expected]));

  if NumberOf(AExpectation, 'planned_height_at_most', Expected) then
    Check(AControl.PlannedHeight <= Expected + 1,
      Format('%s.%s height is %.0f, expected no more than %.0f',
        [AControl.FormName, AControl.ComponentName, AControl.PlannedHeight,
         Expected]));

  if NumberOf(AExpectation, 'planned_right_at_most', Expected) then
    Check(AControl.PlannedLeft + AControl.PlannedWidth <= Expected + 1,
      Format('%s.%s right edge is %.0f, expected no more than %.0f',
        [AControl.FormName, AControl.ComponentName,
         AControl.PlannedLeft + AControl.PlannedWidth, Expected]));

  if NumberOf(AExpectation, 'planned_bottom_at_most', Expected) then
    Check(AControl.PlannedTop + AControl.PlannedHeight <= Expected + 1,
      Format('%s.%s bottom edge is %.0f, expected no more than %.0f',
        [AControl.FormName, AControl.ComponentName,
         AControl.PlannedTop + AControl.PlannedHeight, Expected]));

  BoundName := AExpectation.GetValue<string>('inside_control', '');
  if BoundName <> '' then
  begin
    BoundControl := FindControl(AReview, AControl.FormName, BoundName);
    if BoundControl = nil then
      Failures.Add(Format('%s.%s inside bound %s was not found',
        [AControl.FormName, AControl.ComponentName, BoundName]))
    else
    begin
      Check(AControl.PlannedLeft >= BoundControl.PlannedLeft - 1,
        Format('%s.%s left %.0f is outside %s left %.0f',
          [AControl.FormName, AControl.ComponentName, AControl.PlannedLeft,
           BoundName, BoundControl.PlannedLeft]));
      Check(AControl.PlannedTop >= BoundControl.PlannedTop - 1,
        Format('%s.%s top %.0f is outside %s top %.0f',
          [AControl.FormName, AControl.ComponentName, AControl.PlannedTop,
           BoundName, BoundControl.PlannedTop]));
      Check(AControl.PlannedLeft + AControl.PlannedWidth <=
          BoundControl.PlannedLeft + BoundControl.PlannedWidth + 1,
        Format('%s.%s right %.0f is outside %s right %.0f',
          [AControl.FormName, AControl.ComponentName,
           AControl.PlannedLeft + AControl.PlannedWidth, BoundName,
           BoundControl.PlannedLeft + BoundControl.PlannedWidth]));
      Check(AControl.PlannedTop + AControl.PlannedHeight <=
          BoundControl.PlannedTop + BoundControl.PlannedHeight + 1,
        Format('%s.%s bottom %.0f is outside %s bottom %.0f',
          [AControl.FormName, AControl.ComponentName,
           AControl.PlannedTop + AControl.PlannedHeight, BoundName,
           BoundControl.PlannedTop + BoundControl.PlannedHeight]));
    end;
  end;
end;

procedure CheckControlExpectation(const AReview: TLocalizationReview;
  const AExpectation: TJSONObject);
var
  FormName, ControlName, Why: string;
  Control: TLayoutControl;
  Expected: Double;
  Fits: Boolean;
begin
  FormName := AExpectation.GetValue<string>('form', '');
  ControlName := AExpectation.GetValue<string>('name', '');
  Control := FindControl(AReview, FormName, ControlName);
  if Control = nil then
  begin
    Failures.Add(Format('%s.%s was not found in the scanned model',
      [FormName, ControlName]));
    Exit;
  end;

  if FlagOf(AExpectation, 'text_fits') then
  begin
    { Called on its own line: as one expression the reason was read before the
      test had written it, so every failure of this kind reported blank. }
    Fits := TextFits(Control, Why);
    Check(Fits, Format('%s.%s does not hold its text: %s',
      [FormName, ControlName, Why]));
  end;

  if FlagOf(AExpectation, 'right_edge_unchanged') then
    Check(Abs((Control.PlannedLeft + Control.PlannedWidth) -
      (Control.Left + Control.Width)) <= 1,
      Format('%s.%s right edge moved from %.0f to %.0f',
        [FormName, ControlName, Control.Left + Control.Width,
         Control.PlannedLeft + Control.PlannedWidth]));

  if FlagOf(AExpectation, 'centre_unchanged') then
    Check(Abs((Control.PlannedLeft + Control.PlannedWidth / 2) -
      (Control.Left + Control.Width / 2)) <= 2,
      Format('%s.%s centre moved from %.0f to %.0f',
        [FormName, ControlName, Control.Left + Control.Width / 2,
         Control.PlannedLeft + Control.PlannedWidth / 2]));

  if NumberOf(AExpectation, 'planned_left_equals', Expected) then
    Check(Abs(Control.PlannedLeft - Expected) <= 1,
      Format('%s.%s left is %.0f, expected %.0f',
        [FormName, ControlName, Control.PlannedLeft, Expected]));

  if NumberOf(AExpectation, 'planned_top_equals', Expected) then
    Check(Abs(Control.PlannedTop - Expected) <= 1,
      Format('%s.%s top is %.0f, expected %.0f',
        [FormName, ControlName, Control.PlannedTop, Expected]));

  if NumberOf(AExpectation, 'planned_height_equals', Expected) then
    Check(Abs(Control.PlannedHeight - Expected) <= 1,
      Format('%s.%s height is %.0f, expected %.0f',
        [FormName, ControlName, Control.PlannedHeight, Expected]));

  if NumberOf(AExpectation, 'planned_width_equals', Expected) then
    Check(Abs(Control.PlannedWidth - Expected) <= 1,
      Format('%s.%s width is %.0f, expected %.0f',
        [FormName, ControlName, Control.PlannedWidth, Expected]));

  if NumberOf(AExpectation, 'planned_left_at_most', Expected) then
    Check(Control.PlannedLeft <= Expected + 1,
      Format('%s.%s left is %.0f, expected no more than %.0f',
        [FormName, ControlName, Control.PlannedLeft, Expected]));

  CheckControlBoundsExpectation(AReview, AExpectation, Control);

  if NumberOf(AExpectation, 'font_at_least', Expected) then
    Check(PlannedFontOf(Control) >= Expected - 0.01,
      Format('%s.%s font is %.1f, expected at least %.1f',
        [FormName, ControlName, PlannedFontOf(Control), Expected]));

  if NumberOf(AExpectation, 'font_at_most', Expected) then
    Check(PlannedFontOf(Control) <= Expected + 0.01,
      Format('%s.%s font is %.1f, expected no more than %.1f',
        [FormName, ControlName, PlannedFontOf(Control), Expected]));
end;

{ Every named control ends up the same width, and spaced at one even pitch. }
{ What actually reaches the pack.

  The expectations above describe the plan, and for a long time that was all
  anything checked. The plan and the pack are not the same thing: a value is
  planned, and then a separate pass decides whether to write it down. Twice now
  a correct plan has been silently not written - wrapping that matched what the
  framework was assumed to do, and a frame enlarged to hold its contents, which
  carries no text of its own and so fell outside the rule that only controls
  with translated text have their size stated. Both looked perfect in the plan
  and did nothing on screen.

  A contract may therefore carry a "proposals" array, each entry naming a
  component and a property that must appear among the emitted proposals. }
procedure CheckProposals(const AReview: TLocalizationReview;
  const ARoot: TJSONObject; const AFormName: string);
var
  Expectations: TJSONArray;
  Item: TJSONValue;
  Expectation: TJSONObject;
  ComponentName: string;
  PropertyName: string;
  Proposal: TLayoutProposal;
  Found: Boolean;
  ExpectedValue: string;
  ActualValue: string;
begin
  Expectations := ARoot.GetValue('proposals') as TJSONArray;
  if Expectations = nil then
    Exit;
  for Item in Expectations do
  begin
    if not (Item is TJSONObject) then
      Continue;
    Expectation := TJSONObject(Item);
    ComponentName := Expectation.GetValue<string>('name', '');
    PropertyName := Expectation.GetValue<string>('property', '');
    { A value may be named as well as a property. Some decisions are not
      numbers - which way a control is anchored, which edge its text sits
      against - and for those the property existing says nothing useful. }
    ExpectedValue := Expectation.GetValue<string>('value', '');
    Found := False;
    ActualValue := '';
    for Proposal in AReview.Proposals do
      if SameText(Proposal.ComponentName, ComponentName) and
        SameText(Proposal.PropertyName, PropertyName) then
      begin
        ActualValue := Proposal.ProposedValue;
        Found := (ExpectedValue = '') or
          SameText(Proposal.ProposedValue, ExpectedValue);
        if Found then
          Break;
      end;
    if not Found then
      if ActualValue <> '' then
        Failures.Add(Format('%s.%s proposes %s = %s, expected %s',
          [AFormName, ComponentName, PropertyName, ActualValue,
           ExpectedValue]))
      else
        Failures.Add(Format('%s.%s has no %s proposal; the plan may be right ' +
          'and the pack still silent.',
          [AFormName, ComponentName, PropertyName]));
  end;
end;

procedure CheckGroups(const AReview: TLocalizationReview;
  const ARoot: TJSONObject; const AFormName: string);
var
  Names: TJSONArray;
  Item: TJSONValue;
  Control, Previous: TLayoutControl;
  FirstWidth, Pitch, ThisPitch: Double;
  Index: Integer;
begin
  Names := ARoot.GetValue('uniform_width_group') as TJSONArray;
  if Names <> nil then
  begin
    FirstWidth := -1;
    for Item in Names do
    begin
      Control := FindControl(AReview, AFormName, Item.Value);
      if Control = nil then
        Continue;
      if FirstWidth < 0 then
        FirstWidth := Control.PlannedWidth
      else
        Check(Abs(Control.PlannedWidth - FirstWidth) <= 1,
          Format('%s width is %.0f but the row settled on %.0f',
            [Item.Value, Control.PlannedWidth, FirstWidth]));
    end;
  end;

  Names := ARoot.GetValue('even_pitch_group') as TJSONArray;
  if Names <> nil then
  begin
    Previous := nil;
    Pitch := -1;
    Index := 0;
    for Item in Names do
    begin
      Control := FindControl(AReview, AFormName, Item.Value);
      if Control = nil then
        Continue;
      if Previous <> nil then
      begin
        ThisPitch := Control.PlannedLeft - Previous.PlannedLeft;
        Check(ThisPitch > 0,
          Format('%s starts at %.0f which is not to the right of %s at %.0f',
            [Item.Value, Control.PlannedLeft, Previous.ComponentName,
             Previous.PlannedLeft]));
        Check(Control.PlannedLeft >=
          Previous.PlannedLeft + Previous.PlannedWidth,
          Format('%s overlaps %s', [Item.Value, Previous.ComponentName]));
        if Pitch < 0 then
          Pitch := ThisPitch
        else
          Check(Abs(ThisPitch - Pitch) <= 1,
            Format('%s sits %.0f from its neighbour but the row pitch is %.0f',
              [Item.Value, ThisPitch, Pitch]));
      end;
      Previous := Control;
      Inc(Index);
    end;
  end;
end;

var
  ExpectationFileName, FixtureDirectory, CatalogFileName, CatalogText: string;
  TemporaryCatalog, ContractName, FormName: string;
  Root, ControlExpectation: TJSONObject;
  Controls: TJSONArray;
  Item: TJSONValue;
  Catalog: TTranslationCatalog;
  Review: TLocalizationReview;
  Message: string;
begin
  ExitCode := 0;
  Failures := TStringList.Create;
  TemporaryCatalog := '';
  try
    try
      if ParamCount < 1 then
      begin
        Writeln('Usage: LayoutContracts <expectation.json>');
        ExitCode := 2;
        Exit;
      end;

      ExpectationFileName := ParamStr(1);
      if not TFile.Exists(ExpectationFileName) then
      begin
        Writeln('Expectation not found: ' + ExpectationFileName);
        ExitCode := 2;
        Exit;
      end;

      ContractName := TPath.GetFileNameWithoutExtension(
        TPath.GetFileNameWithoutExtension(ExpectationFileName));
      FixtureDirectory := TPath.GetDirectoryName(
        TPath.GetFullPath(ExpectationFileName));

      Root := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(ExpectationFileName, TEncoding.UTF8)) as TJSONObject;
      if Root = nil then
      begin
        Writeln('Expectation is not valid JSON: ' + ExpectationFileName);
        ExitCode := 2;
        Exit;
      end;
      try
        CatalogFileName := TPath.Combine(FixtureDirectory,
          Root.GetValue<string>('catalog_file', ''));
        if not TFile.Exists(CatalogFileName) then
        begin
          Writeln('Catalog not found: ' + CatalogFileName);
          ExitCode := 2;
          Exit;
        end;

        { The catalog points at its form through a placeholder so the fixtures
          can be checked out anywhere. Resolve it into a copy. }
        CatalogText := TFile.ReadAllText(CatalogFileName, TEncoding.UTF8);
        CatalogText := StringReplace(CatalogText, '{FIXTUREDIR}',
          StringReplace(FixtureDirectory, '\', '\\', [rfReplaceAll]),
          [rfReplaceAll]);
        TemporaryCatalog := TPath.Combine(TPath.GetTempPath,
          Format('dat_contract_%s_%d.json', [ContractName, TThread.GetTickCount]));
        TFile.WriteAllText(TemporaryCatalog, CatalogText, TEncoding.UTF8);

        Catalog := TCatalogJson.LoadFromFile(TemporaryCatalog);
        try
          ContractFramework := Catalog.Framework;
          Review := TLocalizationReviewer.Analyze(Catalog);
          try
            FormName := '';
            Controls := Root.GetValue('controls') as TJSONArray;
            if Controls <> nil then
              for Item in Controls do
                if Item is TJSONObject then
                begin
                  ControlExpectation := TJSONObject(Item);
                  if FormName = '' then
                    FormName := ControlExpectation.GetValue<string>('form', '');
                  CheckControlExpectation(Review, ControlExpectation);
                end;
            if FormName = '' then
              FormName := 'ContractForm';
            CheckProposals(Review, Root, FormName);
            CheckGroups(Review, Root, FormName);
          finally
            Review.Free;
          end;
        finally
          Catalog.Free;
        end;
      finally
        Root.Free;
      end;

      if Failures.Count = 0 then
        Writeln(Format('  ok    %s', [ContractName]))
      else
      begin
        Writeln(Format('  FAIL  %s', [ContractName]));
        for Message in Failures do
          Writeln('          ' + Message);
        ExitCode := 1;
      end;
    except
      on E: Exception do
      begin
        Writeln(Format('  ERROR %s: %s: %s',
          [ContractName, E.ClassName, E.Message]));
        ExitCode := 3;
      end;
    end;
  finally
    if (TemporaryCatalog <> '') and TFile.Exists(TemporaryCatalog) then
      TFile.Delete(TemporaryCatalog);
    Failures.Free;
  end;
end.
