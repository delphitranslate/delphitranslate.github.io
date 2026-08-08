program FMXDesignStreamingTests;

{$APPTYPE CONSOLE}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.IOUtils,
  FMX.Forms,
  FMXDesignHost in 'design\FMXDesignHost.pas' {frmFMXDesignHost},
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.FMX in '..\..\source\components\DAT.Components.FMX.pas',
  DAT.Components.FMX.LanguageSelector in '..\..\source\components\DAT.Components.FMX.LanguageSelector.pas';

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
    AApplicationId + '","applicationVersion":"1.0","framework":"FMX",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"phase7",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},"locale":{' +
    '"shortDateFormat":"M/d/yyyy","longDateFormat":"",' +
    '"shortTimeFormat":"h:mm","longTimeFormat":"h:mm:ss",' +
    '"decimalSeparator":".","thousandSeparator":",",' +
    '"currencySymbol":"$"},"strings":{"probe.Text":"Probe"}}';
  TFile.WriteAllText(TPath.Combine(ADirectory,
    ALanguageCode + '.json'), JsonText, TEncoding.UTF8);
end;

var
  Form: TfrmFMXDesignHost;
  LanguagesDirectory: string;
begin
  try
    LanguagesDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'Localization\Languages');
    WritePack(LanguagesDirectory, 'FMXDesignHost', 'en-US', 'English');
    WritePack(LanguagesDirectory, 'FMXDesignHost', 'de-DE', 'Deutsch');
    Application.Initialize;
    Form := TfrmFMXDesignHost.Create(nil);
    try
      Require(Form.DATLanguageManager <> nil,
        'The FMX manager did not stream from the FMX resource.');
      Require(Form.DATLanguageManager.ApplicationId = 'FMXDesignHost',
        'The FMX manager Object Inspector properties did not stream.');
      Require(Form.DATLanguageManager.SourceLanguage = 'en-US',
        'The FMX source language did not stream.');
      Require(Form.LanguageSelector <> nil,
        'The FMX language selector did not stream from the FMX resource.');
      Require(Form.LanguageSelector.LanguageManager = Form.DATLanguageManager,
        'The FMX selector-to-manager reference did not stream.');
      Require(Form.LanguageSelector.Items.Count = 2,
        'The FMX selector did not populate both validated packs.');
      Require(Form.LanguageSelector.SelectLanguageCode('de-DE'),
        'The FMX selector could not select German.');
      Require(Form.DATLanguageManager.ActiveLanguage = 'de-DE',
        'The FMX selector did not change the manager language.');
    finally
      Form.Free;
    end;
    Writeln('FMX_DESIGN_STREAMING=PASS');
  except
    on E: Exception do
    begin
      Writeln('FMX_DESIGN_STREAMING=FAIL');
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
