program FMXDialogTranslationSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Types,
  System.UITypes,
  Winapi.Windows,
  FMX.Dialogs,
  FMX.DialogService,
  FMX.Forms,
  FMX.Platform,
  DAT.Core.AtomicFile in '..\..\source\core\DAT.Core.AtomicFile.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Components.Core in '..\..\source\components\DAT.Components.Core.pas',
  DAT.Components.FMX in '..\..\source\components\DAT.Components.FMX.pas';

type
  TRecordingDialogService = class(TInterfacedObject, IFMXDialogServiceSync)
  public
    LastCaption: string;
    LastMessage: string;
    LastPrompt: string;
    procedure ShowMessageSync(const AMessage: string);
    function MessageDialogSync(const AMessage: string;
      const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
      const ADefaultButton: TMsgDlgBtn;
      const AHelpCtx: THelpContext): Integer;
    function InputQuerySync(const ACaption: string;
      const APrompts: array of string; var AValues: array of string): Boolean;
  end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure WritePack(const AFileName, ALanguageCode, ANativeName,
  AMessage, ACaption, APrompt: string);
var
  JsonText: string;
begin
  JsonText :=
    '{"schemaVersion":3,"applicationId":"DialogTranslationTest",' +
    '"applicationVersion":"1.0","framework":"FireMonkey",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"dialog",' +
    '"language":{"code":"' + ALanguageCode + '","nativeName":"' +
    ANativeName + '","direction":"ltr"},' +
    '"locale":{"shortDateFormat":"dd.MM.yyyy",' +
    '"longDateFormat":"","shortTimeFormat":"HH:mm",' +
    '"longTimeFormat":"HH:mm:ss","decimalSeparator":",",' +
    '"thousandSeparator":".","currencySymbol":"EUR"},' +
    '"strings":{},"templates":{},"sourceStrings":{},' +
    '"sourceTemplates":{' +
    '"Please select a source folder.":"' + AMessage + '",' +
    '"Project question":"' + ACaption + '",' +
    '"Project name:":"' + APrompt + '"},"sources":{}}';
  TFile.WriteAllText(AFileName, JsonText, TEncoding.UTF8);
end;

procedure TRecordingDialogService.ShowMessageSync(const AMessage: string);
begin
  LastMessage := AMessage;
end;

function TRecordingDialogService.MessageDialogSync(const AMessage: string;
  const ADialogType: TMsgDlgType; const AButtons: TMsgDlgButtons;
  const ADefaultButton: TMsgDlgBtn;
  const AHelpCtx: THelpContext): Integer;
begin
  LastMessage := AMessage;
  Result := mrOk;
end;

function TRecordingDialogService.InputQuerySync(const ACaption: string;
  const APrompts: array of string; var AValues: array of string): Boolean;
begin
  LastCaption := ACaption;
  if Length(APrompts) > 0 then
    LastPrompt := APrompts[0];
  Result := True;
end;

var
  DialogService: IFMXDialogServiceSync;
  LanguagesDirectory: string;
  Manager: TDATFMXLanguageManager;
  PreferenceDirectory: string;
  RecordingObject: TRecordingDialogService;
  RecordingService: IFMXDialogServiceSync;
  RootDirectory: string;
  SecondManager: TDATFMXLanguageManager;
  Values: TArray<string>;
begin
  RootDirectory := GetEnvironmentVariable('TEMP');
  if RootDirectory = '' then
    RootDirectory := ExtractFilePath(ParamStr(0));
  RootDirectory := TPath.Combine(RootDirectory,
    'DAT_FMX_Dialog_' + IntToStr(GetTickCount64));
  LanguagesDirectory := TPath.Combine(RootDirectory, 'Languages');
  PreferenceDirectory := TPath.Combine(RootDirectory, 'Preferences');
  TDirectory.CreateDirectory(LanguagesDirectory);
  TDirectory.CreateDirectory(PreferenceDirectory);
  WritePack(TPath.Combine(LanguagesDirectory, 'en-US.json'), 'en-US',
    'English', 'Please select a source folder.', 'Project question',
    'Project name:');
  WritePack(TPath.Combine(LanguagesDirectory, 'de-DE.json'), 'de-DE',
    'Deutsch', 'Bitte w'#$00E4'hlen Sie einen Quellordner aus.', 'Projektfrage',
    'Projektname:');

  Application.Initialize;
  TPlatformServices.Current.RemovePlatformService(IFMXDialogService);
  TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceAsync);
  TPlatformServices.Current.RemovePlatformService(IFMXDialogServiceSync);
  RecordingObject := TRecordingDialogService.Create;
  RecordingService := RecordingObject;
  TPlatformServices.Current.AddPlatformService(IFMXDialogServiceSync,
    RecordingService);

  Manager := TDATFMXLanguageManager.Create(nil);
  SecondManager := TDATFMXLanguageManager.Create(nil);
  try
    Manager.ApplicationId := 'DialogTranslationTest';
    Manager.LanguagesFolder := LanguagesDirectory;
    Manager.SourceLanguage := 'en-US';
    Manager.AutoLoadPreferred := False;
    Manager.PreferenceLocation := plCustomFolder;
    Manager.CustomPreferenceFolder := PreferenceDirectory;
    Require(Manager.Initialize, 'FMX manager initialization failed.');
    Require(Manager.SelectLanguage('de-DE'),
      'German dialog pack could not be selected.');
    Require(TPlatformServices.Current.SupportsPlatformService(
      IFMXDialogServiceSync, DialogService),
      'The translated dialog service was not installed.');

    { Exercise the same public Delphi API used by a target application. Calling
      the replacement interface directly let the first regression test pass
      even when the real dialog path still displayed English. }
    TDialogService.ShowMessage('Please select a source folder.');
    Require(RecordingObject.LastMessage =
      'Bitte w'#$00E4'hlen Sie einen Quellordner aus.',
      'ShowMessage text did not reach the platform service in German.');

    TDialogService.MessageDialog('Please select a source folder.',
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
      TInputCloseDialogProc(nil));
    Require(RecordingObject.LastMessage =
      'Bitte w'#$00E4'hlen Sie einen Quellordner aus.',
      'MessageDialog text did not reach the platform service in German.');

    SetLength(Values, 1);
    Values[0] := '';
    TDialogService.InputQuery('Project question', ['Project name:'], Values,
      TInputCloseQueryProc(nil));
    Require(RecordingObject.LastCaption = 'Projektfrage',
      'InputQuery caption was not translated.');
    Require(RecordingObject.LastPrompt = 'Projektname:',
      'InputQuery prompt was not translated.');
    Manager.Free;
    Manager := nil;
    Require(TPlatformServices.Current.SupportsPlatformService(
      IFMXDialogServiceSync, DialogService) and
      (Pointer(DialogService) <> Pointer(RecordingService)),
      'Destroying one FMX manager removed the shared dialog proxy.');
    SecondManager.Free;
    SecondManager := nil;
    Require(TPlatformServices.Current.SupportsPlatformService(
      IFMXDialogServiceSync, DialogService) and
      (Pointer(DialogService) = Pointer(RecordingService)),
      'Destroying the final FMX manager did not restore the platform service.');
  finally
    SecondManager.Free;
    Manager.Free;
  end;
  Writeln('RESULT: pass - FMX platform dialogs translate messages and prompts.');
end.
