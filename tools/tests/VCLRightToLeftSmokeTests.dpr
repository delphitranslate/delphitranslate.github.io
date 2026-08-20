program VCLRightToLeftSmokeTests;

{ What a right-to-left pack does to a real VCL form.

  The layout contracts prove the planner decides the right numbers. They stop
  there, at a model of a form. This runs the decisions through the applicator
  and onto actual controls, because every gap this project has found so far -
  the grid headings, the duplicate form name, the colour that would not stay -
  lived in exactly that gap.

  Four things have to be true at once, and each was got wrong at least once
  while it was being written:

    - the controls are mirrored, and each within its own parent
    - a control the framework places is mirrored by its Align constant, and
      is NOT also moved, because the two instructions would contradict
    - reading order is right-to-left, but alignment is NOT flipped twice
    - an English pack changes none of it }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  Winapi.Windows,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls,
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

{ A Hebrew pack for the form below. The mirrored positions are the ones the
  planner computes: the container width less the control's right edge. }
function HebrewPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"he-IL","nativeName":"Hebrew","direction":"rtl"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"NIS"},' +
    '"strings":{"frmRtl.lblName.Caption":"\u05E9\u05DD",' +
    '"frmRtl.btnOk.Caption":"\u05D0\u05D9\u05E9\u05D5\u05E8"},' +
    '"sources":{},' +
    '"layout":[' +
    { 400 - (16 + 80) = 304 }
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"Left","originalValue":"16",' +
    '"translatedValue":"304","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"lblName",' +
    '"propertyName":"Alignment","originalValue":"taLeftJustify",' +
    '"translatedValue":"taRightJustify","sourceChecksum":"t"},' +
    { 400 - (104 + 200) = 96 }
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"Left","originalValue":"104",' +
    '"translatedValue":"96","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"Anchors","originalValue":"[akLeft,akTop]",' +
    '"translatedValue":"[akRight,akTop]","sourceChecksum":"t"},' +
    { the button inside the panel mirrors against the panel: 200-(10+75)=115 }
    '{"formName":"frmRtl","componentName":"btnInner",' +
    '"propertyName":"Left","originalValue":"10",' +
    '"translatedValue":"115","sourceChecksum":"t"},' +
    { the navigation strip is placed by the framework, so only its edge changes }
    '{"formName":"frmRtl","componentName":"pnlNav",' +
    '"propertyName":"Align","originalValue":"alLeft",' +
    '"translatedValue":"alRight","sourceChecksum":"t"},' +
    { the grid reads the way its language reads }
    '{"formName":"frmRtl","componentName":"grdData",' +
    '"propertyName":"Columns[0].Width","originalValue":"60",' +
    '"translatedValue":"90","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"grdData",' +
    '"propertyName":"ColumnOrder","originalValue":"designed",' +
    '"translatedValue":"reversed","sourceChecksum":"t"},' +
    { and so does the Tab key: the highest order less each control's own }
    '{"formName":"frmRtl","componentName":"edtName",' +
    '"propertyName":"TabOrder","originalValue":"0",' +
    '"translatedValue":"2","sourceChecksum":"t"},' +
    '{"formName":"frmRtl","componentName":"btnOk",' +
    '"propertyName":"TabOrder","originalValue":"2",' +
    '"translatedValue":"0","sourceChecksum":"t"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

{ The same form in English: no direction, no layout rules. }
function EnglishPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"RtlSample",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"en-US","nativeName":"English","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd/MM/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",","currencySymbol":"$"},' +
    '"strings":{"frmRtl.lblName.Caption":"Name",' +
    '"frmRtl.btnOk.Caption":"OK"},' +
    '"sources":{},"layout":[]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  Form: TForm;
  Name_: TLabel;
  Box: TEdit;
  Ok: TButton;
  Nav: TPanel;
  Inner: TButton;
  Grid: TDBGrid;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Form := TForm.CreateNew(nil);
    try
      Form.Name := 'frmRtl';
      Form.ClientWidth := 400;
      Form.ClientHeight := 300;

      Nav := TPanel.Create(Form);
      Nav.Parent := Form;
      Nav.Name := 'pnlNav';
      Nav.SetBounds(0, 0, 100, 300);
      Nav.Align := alLeft;
      Nav.Caption := '';

      Name_ := TLabel.Create(Form);
      Name_.Parent := Form;
      Name_.Name := 'lblName';
      Name_.AutoSize := False;
      Name_.SetBounds(16, 20, 80, 17);
      Name_.Caption := 'Name';
      Name_.Alignment := taLeftJustify;

      Box := TEdit.Create(Form);
      Box.Parent := Form;
      Box.Name := 'edtName';
      Box.SetBounds(104, 16, 200, 25);
      Box.Anchors := [akLeft, akTop];

      Ok := TButton.Create(Form);
      Ok.Parent := Form;
      Ok.Name := 'btnOk';
      Ok.SetBounds(230, 120, 75, 25);
      Ok.Caption := 'OK';

      Grid := TDBGrid.Create(Form);
      Grid.Parent := Form;
      Grid.Name := 'grdData';
      Grid.SetBounds(20, 180, 360, 90);
      Grid.Columns.Add.Title.Caption := 'First';
      Grid.Columns[0].Width := 60;
      Grid.Columns.Add.Title.Caption := 'Second';
      Grid.Columns.Add.Title.Caption := 'Third';

      Inner := TButton.Create(Form);
      Inner.Parent := Nav;
      Inner.Name := 'btnInner';
      Inner.SetBounds(10, 15, 75, 25);
      Inner.Caption := 'Inner';

      Pack := HebrewPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln;
      Writeln('  after a Hebrew pack:');
      Writeln(Format('        label  Left=%d  Alignment=%d', [Name_.Left,
        Ord(Name_.Alignment)]));
      Writeln(Format('        edit   Left=%d', [Box.Left]));
      Writeln(Format('        panel  Align=%d (alLeft=%d, alRight=%d)',
        [Ord(Nav.Align), Ord(alLeft), Ord(alRight)]));
      Writeln(Format('        inner  Left=%d', [Inner.Left]));
      Writeln;

      Check(Name_.Left = 304, Format(
        'The caption is mirrored to the right of its box: %d, expected 304.',
        [Name_.Left]));
      Check(Box.Left = 96,
        Format('And the box moves with it: %d, expected 96.', [Box.Left]));
      Check(Inner.Left = 115, Format(
        'A control inside a panel mirrors within the panel: %d, expected 115.',
        [Inner.Left]));
      Check(Nav.Align = alRight,
        'A framework-placed strip is mirrored by its edge, not its position.');
      Check(Box.Anchors = [akRight, akTop],
        'An edge anchor follows the edge the reader works from.');

      { The heart of it. bdRightToLeft would flip alignment a second time and
        draw this caption DT_LEFT, undoing the plan without any error. }
      Check(Name_.Alignment = taRightJustify,
        'The caption is right-aligned, as the pack asked.');
      Check(Form.BiDiMode = bdRightToLeftNoAlign,
        'Reading order is right-to-left in the mode that leaves alignment alone.');
      Check((Name_.DrawTextBiDiModeFlags(DT_RIGHT) and DT_RIGHT) <> 0,
        'And it is actually DRAWN right-aligned, not flipped back by BiDiMode.');
      Check((Name_.DrawTextBiDiModeFlags(DT_RIGHT) and DT_RTLREADING) <> 0,
        'while still reading right to left.');
      Check(Form.UseRightToLeftScrollBar,
        'The scroll bar moves to the side the reader starts from.');

      Writeln(Format('        grid   headings: %s, %s, %s   first width %d',
        [Grid.Columns[0].Title.Caption, Grid.Columns[1].Title.Caption,
         Grid.Columns[2].Title.Caption, Grid.Columns[2].Width]));
      Check(Grid.Columns[0].Title.Caption = 'Third',
        'The grid reads right to left: the first column is now last.');
      Check(Grid.Columns[2].Title.Caption = 'First',
        'and the last is first.');
      { The width rule names column 0 as it was designed, and that column is
        now at the other end. Applying the widths before the reversal is what
        keeps the width with its own column instead of with its position. }
      Check(Grid.Columns[2].Width = 90,
        Format('A column keeps its own width through the reversal: %d, ' +
          'expected 90.', [Grid.Columns[2].Width]));
      Check((Box.TabOrder = 2) and (Ok.TabOrder = 0),
        Format('The Tab key follows the reader: edit %d, button %d.',
          [Box.TabOrder, Ok.TabOrder]));

      { And back to English. Returning to the source language has to put every
        one of those decisions back, or a user who tries Hebrew once is left
        with a mirrored English program. }
      Pack := EnglishPack;
      try
        TVCLTranslationApplicator.ApplyToForm(Form, Pack, 'frmRtl', True);
      finally
        Pack.Free;
      end;

      Writeln('  after going back to English:');
      Writeln(Format('        label  Left=%d  Alignment=%d', [Name_.Left,
        Ord(Name_.Alignment)]));
      Writeln(Format('        panel  Align=%d', [Ord(Nav.Align)]));
      Writeln;
      Check(Name_.Left = 16,
        Format('The caption is back where it was drawn: %d, expected 16.',
          [Name_.Left]));
      Check(Box.Left = 104,
        Format('and so is the box: %d, expected 104.', [Box.Left]));
      Check(Inner.Left = 10,
        Format('and the one inside the panel: %d, expected 10.',
          [Inner.Left]));
      Check(Nav.Align = alLeft, 'The strip returns to its designed edge.');
      Check(Name_.Alignment = taLeftJustify, 'Alignment returns too.');
      Check(Box.Anchors = [akLeft, akTop], 'And the anchors.');
      Check(Form.BiDiMode = bdLeftToRight,
        'Reading order returns to left-to-right.');
      Writeln(Format('        grid   headings: %s, %s, %s',
        [Grid.Columns[0].Title.Caption, Grid.Columns[1].Title.Caption,
         Grid.Columns[2].Title.Caption]));
      Check(Grid.Columns[0].Title.Caption = 'First',
        'The grid columns return to their designed order.');
    finally
      Form.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL right-to-left smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('VCL right-to-left smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
