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
    '{"schemaVersion":1,"applicationId":"SampleVCLApp",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmVCLSample.Caption":"VCL Beispiel",' +
    '"frmVCLSample.lblHeading.Caption":"Kundendaten",' +
    '"frmVCLSample.mnuLanguage.Caption":"Sprache",' +
    '"frmVCLSample.memInstructions.Lines.Strings.0":"Erste Zeile",' +
    '"frmVCLSample.memInstructions.Lines.Strings.1":"Zweite Zeile"}}';
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
      Require(AppliedCount = 5, 'Unexpected VCL applied-property count.');
      Require(frmVCLSample.Caption = 'VCL Beispiel',
        'The VCL form caption was not translated.');
      Require(frmVCLSample.lblHeading.Caption = 'Kundendaten',
        'The VCL label was not translated.');
      Require(frmVCLSample.mnuLanguage.Caption = 'Sprache',
        'The VCL menu was not translated.');
      Require((frmVCLSample.memInstructions.Lines.Count = 2) and
        (frmVCLSample.memInstructions.Lines[1] = 'Zweite Zeile'),
        'The VCL memo lines were not translated.');
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
