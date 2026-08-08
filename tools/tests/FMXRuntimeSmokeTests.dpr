program FMXRuntimeSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  FMX.Forms,
  SampleFMX.MainForm in '..\..\samples\FMXBasic\SampleFMX.MainForm.pas'
    {frmFMXSample},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function TestPack: TRuntimeLanguagePack;
const
  JsonText =
    '{"schemaVersion":1,"applicationId":"SampleFMXApp",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"test",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"HH:mm","longTimeFormat":"HH:mm:ss",' +
    '"decimalSeparator":",","thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{"frmFMXSample.Caption":"FMX Beispiel",' +
    '"frmFMXSample.lblHeading.Text":"Kundendaten",' +
    '"frmFMXSample.lblCustomerName.Text":"Kundenname",' +
    '"frmFMXSample.edtCustomerName.TextPrompt":"Vollst\u00e4ndiger Name",' +
    '"frmFMXSample.btnSave.Text":"Kunde speichern",' +
    '"frmFMXSample.mnuFile.Text":"Datei",' +
    '"frmFMXSample.mnuExit.Text":"Beenden",' +
    '"frmFMXSample.mnuLanguage.Text":"Sprache",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.0":"Heute",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.1":"Letzte 7 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.2":"Letzte 28 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.3":"Letzte 90 Tage",' +
    '"frmFMXSample.cmbDateRange.Items.Strings.4":"Dieses Jahr",' +
    '"frmFMXSample.memInstructions.Lines.Strings.0":"Erste Zeile",' +
    '"frmFMXSample.memInstructions.Lines.Strings.1":"Zweite Zeile"}}';
begin
  Result := TRuntimeLanguagePack.LoadFromJson(JsonText);
end;

var
  AppliedCount: Integer;
  Pack: TRuntimeLanguagePack;
begin
  try
    Application.Initialize;
    frmFMXSample := TfrmFMXSample.Create(nil);
    Pack := TestPack;
    try
      AppliedCount := TFMXTranslationApplicator.ApplyToForm(
        frmFMXSample, Pack);
      Require(AppliedCount = 15, 'Unexpected FMX applied-property count.');
      Require(frmFMXSample.Caption = 'FMX Beispiel',
        'The FMX form caption was not translated.');
      Require(frmFMXSample.lblHeading.Text = 'Kundendaten',
        'The FMX label was not translated.');
      Require(frmFMXSample.mnuLanguage.Text = 'Sprache',
        'The FMX menu was not translated.');
      Require(frmFMXSample.cmbDateRange.ItemIndex = 2,
        'The FMX combo-box selection changed during translation.');
      Require(frmFMXSample.cmbDateRange.Selected.Text = 'Letzte 28 Tage',
        'The selected FMX combo-box item was not translated in place.');
      Require((frmFMXSample.memInstructions.Lines.Count = 2) and
        (frmFMXSample.memInstructions.Lines[1] = 'Zweite Zeile'),
        'The FMX memo lines were not translated.');
    finally
      Pack.Free;
      frmFMXSample.Free;
    end;
    Writeln('FMX runtime translation smoke test passed.');
  except
    on E: Exception do
    begin
      Writeln('FMX runtime translation smoke test failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
