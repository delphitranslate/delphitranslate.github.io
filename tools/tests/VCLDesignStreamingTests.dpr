program VCLDesignStreamingTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Forms,
  VCLDesignHost in 'design\VCLDesignHost.pas' {frmVCLDesignHost},
  DAT.Core.AtomicFile in '..\..\source\core\DAT.Core.AtomicFile.pas',
  DAT.Core.Diagnostics in '..\..\source\core\DAT.Core.Diagnostics.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.VCL in '..\..\source\components\DAT.Components.VCL.pas',
  DAT.Components.VCL.LanguageSelector in '..\..\source\components\DAT.Components.VCL.LanguageSelector.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure WritePack(const ADirectory, AApplicationId, ALanguageCode,
  ANativeName: string);
var
  JsonText: string;
begin
  ForceDirectories(ADirectory);
  JsonText := '{"schemaVersion":1,"applicationId":"' +
    AApplicationId + '","applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"phase7",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},"locale":{' +
    '"shortDateFormat":"M/d/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"h:mm","longTimeFormat":"h:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",",' +
    '"currencySymbol":"$"},"strings":{"probe.Caption":"Probe"}}';
  TFile.WriteAllText(TPath.Combine(ADirectory,
    ALanguageCode + '.json'), JsonText, TEncoding.UTF8);
end;

var
  Form: TfrmVCLDesignHost;
  LanguagesDirectory: string;
begin
  try
    LanguagesDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'Localization\Languages');
    WritePack(LanguagesDirectory, 'VCLDesignHost', 'en-US', 'English');
    WritePack(LanguagesDirectory, 'VCLDesignHost', 'de-DE', 'Deutsch');
    Application.Initialize;
    Form := TfrmVCLDesignHost.Create(nil);
    try
      Require(Form.DATLanguageManager <> nil,
        'The VCL manager did not stream from the DFM resource.');
      Require(Form.DATLanguageManager.ApplicationId = 'VCLDesignHost',
        'The VCL manager Object Inspector properties did not stream.');
      Require(Form.DATLanguageManager.SourceLanguage = 'en-US',
        'The VCL source language did not stream.');
      Require(Form.LanguageSelector <> nil,
        'The VCL language selector did not stream from the DFM resource.');
      Require(Form.LanguageSelector.LanguageManager = Form.DATLanguageManager,
        'The VCL selector-to-manager reference did not stream.');
      Require(Form.LanguageSelector.Items.Count = 2,
        'The VCL selector did not populate both validated packs.');
      Require(Form.LanguageSelector.SelectLanguageCode('de-DE'),
        'The VCL selector could not select German.');
      Require(Form.DATLanguageManager.ActiveLanguage = 'de-DE',
        'The VCL selector did not change the manager language.');
    finally
      Form.Free;
    end;
    Writeln('VCL_DESIGN_STREAMING=PASS');
  except
    on E: Exception do
    begin
      Writeln('VCL_DESIGN_STREAMING=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
