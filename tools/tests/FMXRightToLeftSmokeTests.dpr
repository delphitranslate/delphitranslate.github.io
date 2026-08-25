program FMXRightToLeftSmokeTests;

{ The right-to-left mirror under FireMonkey.

  The VCL has BiDiMode for reading order and FlipChildren for geometry.
  FireMonkey has neither, which is exactly why the mirror is computed by the
  planner rather than asked of the framework: one implementation, and the
  numbers in the FireMonkey layout contract are identical to the VCL one.

  What is left for the framework here is small and specific - which edge the
  text sits against - and it has to go through TextSettings with StyledSettings
  giving up its claim, or the style puts it back at paint time and the
  assignment looks like it worked. }

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.Types,
  System.UITypes,
  FMX.Forms,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Edit,
  FMX.Types,
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas';

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

{ The same form in English: no direction, no layout rules. Returning to the
  source language has to put every mirrored decision back, or a user who tries
  Hebrew once is left with an English program laid out backwards. }
function EnglishPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"en-US","nativeName":"English","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",","currencySymbol":"$"},' +
    '"strings":{"frmRtl.lblName.Text":"Name"},' +
    '"sources":{},"layout":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

function HebrewPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"he-IL","nativeName":"Hebrew","direction":"rtl"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"NIS"},' +
    '"strings":{"frmRtl.lblName.Text":"\u05E9\u05DD"},' +
    '"sources":{},' +
    '"layout":[' +
    { 400 - (16 + 80) = 304 }
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"Position.X","originalValue":"16",' +
    '"translatedValue":"304","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"TextSettings.HorzAlign","originalValue":"Leading",' +
    '"translatedValue":"Trailing","sourceChecksum":"t"},' +
    { 400 - (104 + 200) = 96 }
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"Position.X","originalValue":"104",' +
    '"translatedValue":"96","sourceChecksum":"t"},' +
    { placed by the framework, so only its edge changes }
    '{"formName":"frmRtl","componentName":"lytNav",' +
    '"propertyName":"Align","originalValue":"Left",' +
    '"translatedValue":"Right","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lytCentered",' +
    '"propertyName":"Position.X","originalValue":"150",' +
    '"translatedValue":"20","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Form: TForm;
  EmailBox: TEdit;
  Name_: TLabel;
  Box: TEdit;
  Nav: TLayout;
  CenteredLayout: TLayout;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmRtl';
      Form.ClientWidth := 400;
      Form.ClientHeight := 300;

      Nav := TLayout.Create(Form);
      Nav.Parent := Form;
      Nav.Name := 'lytNav';
      Nav.SetBounds(0, 0, 100, 300);
      Nav.Align := TAlignLayout.Left;

      Name_ := TLabel.Create(Form);
      Name_.Parent := Form;
      Name_.Name := 'lblName';
      Name_.SetBounds(16, 20, 80, 20);
      Name_.Text := 'Name';
      Name_.TextSettings.HorzAlign := TTextAlign.Leading;

      Box := TEdit.Create(Form);
      Box.Parent := Form;
      Box.Name := 'edtName';
      Box.SetBounds(104, 16, 200, 28);

      EmailBox := TEdit.Create(Form);
      EmailBox.Parent := Form;
      EmailBox.Name := 'edtEmailAddress';
      EmailBox.SetBounds(104, 52, 200, 28);
      EmailBox.Text := 'user@example.com';

      CenteredLayout := TLayout.Create(Form);
      CenteredLayout.Parent := Form;
      CenteredLayout.Name := 'lytCentered';
      CenteredLayout.SetBounds(150, 84, 100, 28);

      Pack := HebrewPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln;
      Writeln(Format('        label  X=%.0f  HorzAlign=%d',
        [Name_.Position.X, Ord(Name_.TextSettings.HorzAlign)]));
      Writeln(Format('        edit   X=%.0f', [Box.Position.X]));
      Writeln(Format('        layout Align=%d (Left=%d, Right=%d)',
        [Ord(Nav.Align), Ord(TAlignLayout.Left), Ord(TAlignLayout.Right)]));
      Writeln;

      Check(Abs(Name_.Position.X - 304) < 1, Format(
        'The caption is mirrored to the right of its box: %.0f, expected 304.',
        [Name_.Position.X]));
      Check(Abs(Box.Position.X - 96) < 1,
        Format('And the box moves with it: %.0f, expected 96.',
          [Box.Position.X]));
      Check(Nav.Align = TAlignLayout.Right,
        'A framework-placed layout is mirrored by its edge.');
      Check(Abs(CenteredLayout.Position.X - 150) < 1,
        'A container centred by the application remains centred after RTL layout.');
      Check(Name_.TextSettings.HorzAlign = TTextAlign.Trailing,
        'The text sits against the opposite edge.');
      Check(EmailBox.TextSettings.HorzAlign = TTextAlign.Leading,
        'An email address keeps its technical left-to-right ordering inside the RTL form.');
      Check(not (TStyledSetting.Other in Name_.StyledSettings),
        'and the style has given up its claim on it, so it survives a repaint.');

      { The numbers match the VCL test exactly. That is the point: the mirror
        is one implementation, not two that happen to agree today. }
      Writeln('  (the same numbers as the VCL test, from the same pass)');
      Writeln;

      Pack := EnglishPack;
      try
        TFMXTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln(Format('        back to English: label X=%.0f  HorzAlign=%d  ' +
        'layout Align=%d',
        [Name_.Position.X, Ord(Name_.TextSettings.HorzAlign),
         Ord(Nav.Align)]));
      Writeln;
      Check(Abs(Name_.Position.X - 16) < 1,
        Format('The caption is back where it was drawn: %.0f, expected 16.',
          [Name_.Position.X]));
      Check(Abs(Box.Position.X - 104) < 1,
        Format('and so is the box: %.0f, expected 104.', [Box.Position.X]));
      Check(Nav.Align = TAlignLayout.Left,
        'The layout returns to its designed edge.');
      Check(Name_.TextSettings.HorzAlign = TTextAlign.Leading,
        'And the text to the edge it was drawn against.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX right-to-left smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('FMX right-to-left smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
