program VCLWrapSmokeTests;

{ Two things a VCL form does that nothing else here covers.

  A label that sizes itself. TLabel.AutoSize is True unless a form says
  otherwise, so setting a longer caption stretches the label before any layout
  rule is applied. The rules then say "stop sizing yourself, wrap, and be 577
  wide" - and whether the label actually ends up wrapped at 577 is the question,
  because the instruction paragraph on the random-directory page did not.

  And a grid heading. A grid keeps its heading on the column's Title, not on the
  column, so the pack carries Columns[0].Title.Caption. Reaching one level in is
  the difference between a translated grid and one whose headings stay English
  while every row around them is translated. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.DBGrids,
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

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

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"WrapSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"es-ES","nativeName":"Espanol","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{' +
    '"frmWrap.lblPara.Caption":' +
    '"Haz clic en el boton Seleccionar directorio aleatorio para cualquier ' +
    'cuadro de directorio, selecciona un directorio y anade las fechas para ' +
    'incluirlo en la rotacion.",' +
    '"frmWrap.grdGroups.Columns[0].Title.Caption":"Grupo",' +
    '"frmWrap.grdGroups.Columns[1].Title.Caption":"Fecha inicial"},' +
    '"sources":{},' +
    '"layout":[' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"AutoSize","originalValue":"True",' +
    '"translatedValue":"False","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"WordWrap","originalValue":"False",' +
    '"translatedValue":"True","sourceChecksum":"t"},' +
    '{"formName":"frmWrap","componentName":"lblPara",' +
    '"propertyName":"Width","originalValue":"577",' +
    '"translatedValue":"577","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Form: TForm;
  Para: TLabel;
  Grid: TDBGrid;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmWrap';
      Form.ClientWidth := 974;
      Form.ClientHeight := 400;

      { Exactly the paragraph from the random-directory page: it sizes itself,
        it does not wrap, and it is drawn 577 wide. }
      Para := TLabel.Create(Form);
      Para.Parent := Form;
      Para.Name := 'lblPara';
      Para.Left := 176;
      Para.Top := 85;
      Para.Width := 577;
      Para.Height := 60;
      Para.Font.Height := -15;
      { Three hard lines, exactly as the real caption is written. A label that
        sizes itself is therefore three lines tall to begin with, and that is
        the height the translation must not be allowed to take away: the
        Spanish carries no line breaks at all, so a label still sizing itself
        collapses to one line the moment the caption is assigned. }
      Para.Caption := 'Click on the " Select Random Directory " button for ' +
        'any directory box, select a directory'#13#10'and add dates to put it ' +
        'into the rotation. Dates should be in the format of month/date'#13#10 +
        'only (example: 04/27), with no year.';

      Grid := TDBGrid.Create(Form);
      Grid.Parent := Form;
      Grid.Name := 'grdGroups';
      Grid.Left := 24;
      Grid.Top := 200;
      Grid.Width := 500;
      Grid.Height := 120;
      Grid.Columns.Add.Title.Caption := 'Group';
      Grid.Columns.Add.Title.Caption := 'Play Date From';

      Check(Para.AutoSize, 'The label sizes itself, as a VCL label does.');

      Pack := TestPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmWrap', True);
      finally
        Pack.Free;
      end;

      Writeln(Format('        label: width %d, height %d, wordwrap %s, ' +
        'autosize %s', [Para.Width, Para.Height,
        BoolToStr(Para.WordWrap, True), BoolToStr(Para.AutoSize, True)]));
      { The height matters as much as the width and is easier to lose. A label
        still sizing itself when a caption without line breaks arrives shrinks
        to a single line before anything can stop it, and switching AutoSize
        off afterwards freezes it that way: the text wraps into a box one line
        tall and two of its three lines are simply not drawn. }
      Check(Para.Height >= 54,
        Format('It keeps room for its wrapped lines: height %d, not one line.',
          [Para.Height]));
      Check(not Para.AutoSize, 'It stops sizing itself.');
      Check(Para.WordWrap, 'It wraps.');
      Check(Para.Width = 577,
        Format('It is back to the width the rule gives it, not %d.',
          [Para.Width]));

      { And again, the way an application does it when the language is chosen
        a second time or the form is shown again. Applying starts by putting
        the form back as it was drawn - which means the label starts sizing
        itself again and stops wrapping - so everything has to be re-decided
        from there, every time. }
      Pack := TestPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmWrap', True);
      finally
        Pack.Free;
      end;
      Writeln(Format('        after a second apply: width %d, wordwrap %s',
        [Para.Width, BoolToStr(Para.WordWrap, True)]));
      Check(Para.WordWrap, 'It still wraps after a second application.');
      Check(Para.Width = 577,
        Format('and is still 577 wide, not %d.', [Para.Width]));

      Writeln(Format('        grid headings: "%s", "%s"',
        [Grid.Columns[0].Title.Caption, Grid.Columns[1].Title.Caption]));
      Check(Grid.Columns[0].Title.Caption = 'Grupo',
        'The first column heading is translated.');
      Check(Grid.Columns[1].Title.Caption = 'Fecha inicial',
        'And the second.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL wrap and grid heading smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('VCL wrap and grid heading smoke tests failed: %d',
      [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
