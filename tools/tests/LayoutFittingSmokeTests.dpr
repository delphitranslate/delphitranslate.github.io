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
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Review.Localization in '..\..\source\review\DAT.Review.Localization.pas';

type
  TFormIssues = record
    NewOverlaps: Integer;
    OutOfBounds: Integer;
    ClippedText: Integer;
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
  TotalNew, TotalBounds, TotalClipped: Integer;
  FormWidth, FormHeight: Double;
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
          end;
          FormCount := FormNames.Count;
        finally
          FormNames.Free;
        end;

        Writeln('');
        Writeln(Format('Forms: %d   new overlaps: %d   out of bounds: %d',
          [FormCount, TotalNew, TotalBounds]));
        if (TotalNew = 0) and (TotalBounds = 0) then
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
