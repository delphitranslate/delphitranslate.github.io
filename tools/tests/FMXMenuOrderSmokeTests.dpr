program FMXMenuOrderSmokeTests;

{ A FireMonkey menu bar reading right to left.

  The VCL twin of this had to work around the framework: VCL mirrors a menu
  only through TMenu.DoBiDiModeChanged, which gives up unless the machine
  itself is Middle Eastern, and the flag it sets governs how submenus cascade
  rather than the order of the bar. FireMonkey has no such flag, so there is
  nothing claiming to mirror a menu while doing something else - the items are
  simply moved, which is where the VCL side ended up too.

  The order is asserted, not toggled, so translating a form twice looks like
  translating it once. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  FMX.Menus,
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

var
  Failures: Integer = 0;
  Form: TForm;
  Menu: TMainMenu;

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

function Order: string;
var
  Index: Integer;
begin
  Result := '';
  for Index := 0 to Menu.ItemsCount - 1 do
    Result := Result + Menu.Items[Index].Name + ' ';
  Result := Trim(Result);
end;

procedure ApplyDirection(const ARightToLeft: Boolean);
const
  Template =
    '{"schemaVersion":3,"applicationId":"MenuProbe",' +
    '"applicationVersion":"1.0","framework":"FMX",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"%s","nativeName":"x","direction":"%s"},' +
    '"locale":{},"strings":{},"sources":{},"layout":[]}';
var
  Pack: TRuntimeLanguagePack;
begin
  if ARightToLeft then
    Pack := TRuntimeLanguagePack.LoadFromJson(Format(Template, ['ar-SA', 'rtl']))
  else
    Pack := TRuntimeLanguagePack.LoadFromJson(Format(Template, ['en-US', 'ltr']));
  try
    TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmMenu', True);
  finally
    Pack.Free;
  end;
end;

var
  Names: array[0..3] of string;
  I: Integer;
  Item: TMenuItem;
begin
  Names[0] := 'mnuFile'; Names[1] := 'mnuSchedule';
  Names[2] := 'mnuSettings'; Names[3] := 'mnuHelp';
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmMenu';
      Menu := TMainMenu.Create(Form);
      Menu.Parent := Form;
      for I := 0 to High(Names) do
      begin
        Item := TMenuItem.Create(Form);
        Item.Parent := Menu;
        Item.Name := Names[I];
        Item.Text := Names[I];
      end;

      Writeln('        designed:      ', Order);
      Check(Order = 'mnuFile mnuSchedule mnuSettings mnuHelp',
        'The bar starts in its designed order.');

      ApplyDirection(True);
      Writeln('        right to left: ', Order);
      Check(Order = 'mnuHelp mnuSettings mnuSchedule mnuFile',
        'The first menu moves to the edge a right-to-left reader starts from.');

      ApplyDirection(True);
      Check(Order = 'mnuHelp mnuSettings mnuSchedule mnuFile',
        'Applying the same direction again changes nothing.');

      ApplyDirection(False);
      Writeln('        back again:    ', Order);
      Check(Order = 'mnuFile mnuSchedule mnuSettings mnuHelp',
        'and a left-to-right language puts the bar back as designed.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX menu order smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('FMX menu order smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('FMX menu order smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
