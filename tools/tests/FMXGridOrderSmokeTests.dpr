program FMXGridOrderSmokeTests;

{ A FireMonkey grid reading right to left.

  The VCL side has had this for a while; FMX had nothing at all, which under
  the standing rule that the two frameworks match is a defect rather than a
  backlog item.

  The mechanics differ and the behaviour must not. VCL moves TCollectionItems
  in a TCollection; a FireMonkey TColumn is a child object of the grid and its
  place is its Index among the grid's children. Both state the target order
  rather than toggling, so applying twice is the same as applying once - the
  property a toggle cannot have. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  FMX.Grid,
  FMX.Grid.Style,
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

const
  PackJson =
    '{"schemaVersion":3,"applicationId":"GridProbe",' +
    '"applicationVersion":"1.0","framework":"FMX",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"ar-SA","nativeName":"Arabic","direction":"rtl"},' +
    '"locale":{},"strings":{},"sources":{},' +
    '"layout":[{"formName":"Groups","componentName":"Grid1",' +
    '"propertyName":"ColumnOrder","originalValue":"designed",' +
    '"translatedValue":"reversed","sourceChecksum":"t"}]}';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

var
  Form: TForm;
  Grid: TGrid;
  Headers: array[0..3] of string;
  I: Integer;

function Order: string;
var
  K: Integer;
begin
  Result := '';
  for K := 0 to Grid.ColumnCount - 1 do
    Result := Result + Grid.Columns[K].Header + ' ';
  Result := Trim(Result);
end;

procedure ApplyPack(const AReversed: Boolean);
var
  Local: TRuntimeLanguagePack;
  Json: string;
begin
  Json := PackJson;
  if not AReversed then
    Json := StringReplace(Json, '"translatedValue":"reversed"',
      '"translatedValue":"designed"', []);
  Local := TRuntimeLanguagePack.LoadFromJson(Json);
  try
    TFMXTranslationApplicator.ApplyLayoutToForm(Form, Local, 'Groups', True);
  finally
    Local.Free;
  end;
end;

begin
  Headers[0] := 'Group'; Headers[1] := 'From';
  Headers[2] := 'To';    Headers[3] := 'Time';
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'Groups';
      Grid := TGrid.Create(Form);
      Grid.Parent := Form;
      Grid.Name := 'Grid1';
      for I := 0 to High(Headers) do
        with TStringColumn.Create(Grid) do
        begin
          Parent := Grid;
          Header := Headers[I];
        end;

      Writeln('        designed:    ', Order);
      Check(Order = 'Group From To Time', 'The grid starts in its designed order.');

      ApplyPack(True);
      Writeln('        reversed:    ', Order);
      Check(Order = 'Time To From Group',
        'A right-to-left pack puts the first column at the edge the reader starts from.');

      ApplyPack(True);
      Writeln('        applied again:', Order);
      Check(Order = 'Time To From Group',
        'Applying the same pack again changes nothing, so the order cannot drift.');

      ApplyPack(False);
      Writeln('        restored:    ', Order);
      Check(Order = 'Group From To Time',
        'Asking for the designed order puts it back.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX grid order smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('FMX grid order smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('FMX grid order smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
