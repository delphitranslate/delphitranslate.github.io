program VCLRuntimeSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Forms,
  SampleVCL.MainForm in '..\..\samples\VCLBasic\SampleVCL.MainForm.pas'
    {frmVCLSample},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":3,"applicationId":"SampleVCLApp",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmVCLSample.Caption":"VCL Beispiel",' +
    '"frmVCLSample.lblHeading.Caption":"Kundendaten",' +
    '"frmVCLSample.mnuLanguage.Caption":"Sprache",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.0":"Heute",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.1":"Letzte 7 Tage",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.2":"Letzte 28 Tage",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.3":"Letzte 90 Tage",' +
    '"frmVCLSample.cmbDateRange.Items.Strings.4":"Dieses Jahr",' +
    '"frmVCLSample.memInstructions.Lines.Strings.0":"Erste Zeile",' +
    '"frmVCLSample.memInstructions.Lines.Strings.1":"Zweite Zeile"},' +
    { The source text for each key, which is what a return to the original
      language reads. Left empty, the words stay translated however well the
      geometry is put back. }
    '"sources":{"frmVCLSample.Caption":"Customer Manager",' +
    '"frmVCLSample.lblHeading.Caption":"Customer Account Details"},' +
    '"layout":[{"formName":"frmVCLSample",' +
    '"componentName":"lblHeading","propertyName":"Width",' +
    '"originalValue":"227","translatedValue":"327",' +
    '"sourceChecksum":"layout-test"}]}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  AppliedCount: Integer;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    Application.CreateForm(TfrmVCLSample, frmVCLSample);
    Pack := TestPack;
    try
      AppliedCount := TVCLTranslationApplicator.ApplyToForm(
        frmVCLSample, Pack);
      Require(AppliedCount = 11, 'Unexpected VCL applied-property count: ' +
        IntToStr(AppliedCount));
      Require(frmVCLSample.Caption = 'VCL Beispiel',
        'The VCL form caption was not translated.');
      Require(frmVCLSample.lblHeading.Caption = 'Kundendaten',
        'The VCL label was not translated.');
      Require(frmVCLSample.lblHeading.Width = 327,
        'The VCL translated-language layout rule was not applied.');
      Require(TVCLTranslationApplicator.ApplyLayoutToForm(frmVCLSample,
        Pack, 'frmVCLSample', False) = 1,
        'The VCL source-layout restore rule was not applied.');
      Require(frmVCLSample.lblHeading.Width = 227,
        'The VCL source layout was not restored.');
      Require(frmVCLSample.mnuLanguage.Caption = 'Sprache',
        'The VCL menu was not translated.');
      Require(frmVCLSample.cmbDateRange.ItemIndex = 2,
        'The VCL combo-box selection changed during translation.');
      Require(frmVCLSample.cmbDateRange.Text = 'Letzte 28 Tage',
        'The selected VCL combo-box item was not translated in place.');
      Require((frmVCLSample.memInstructions.Lines.Count = 2) and
        (frmVCLSample.memInstructions.Lines[1] = 'Zweite Zeile'),
        'The VCL memo lines were not translated.');

      { Going back to the language the application was written in must give the
        form back, not only its words. The edit is the point of it: nothing in
        the pack mentions that control, so a restore built out of rule original
        values has nothing to say about it, and before the snapshot there was
        no record of what it had been. It is knocked out of shape by hand
        first, standing in for whatever else may move a control. }
      frmVCLSample.edtCustomerName.Width := 111;
      frmVCLSample.edtCustomerName.Height := 44;
      frmVCLSample.lblHeading.Left := 99;
      TVCLTranslationApplicator.RestoreSourceLanguage(frmVCLSample, Pack,
        frmVCLSample.Name);
      Require(frmVCLSample.lblHeading.Caption = 'Customer Account Details',
        'Returning to the source language did not restore the text.');
      Require(frmVCLSample.edtCustomerName.Width = 360,
        'A control with no layout rule was not restored from the snapshot.');
      Require(frmVCLSample.edtCustomerName.Height = 23,
        'A control with no layout rule was not restored from the snapshot.');
      Require(frmVCLSample.lblHeading.Left = 32,
        'A position was not restored from the snapshot.');
    finally
      Pack.Free;
      frmVCLSample.Free;
    end;
    Writeln('VCL runtime translation smoke test passed.');
  except
    on E: Exception do
    begin
      Writeln('VCL runtime translation smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
