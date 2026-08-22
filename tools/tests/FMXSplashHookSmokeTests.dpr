program FMXSplashHookSmokeTests;

{ The FireMonkey twin of VCLSplashHookSmokeTests.

  Same situation: a splash created, shown and freed before the form carrying
  the language manager is constructed, in an application that cannot be edited
  to add one. Different hook, because FMX has no Screen.OnActiveFormChange -
  it publishes TFormBeforeShownMessage through TMessageManager instead.

  One assertion here has no VCL counterpart and is the reason this file is
  worth having rather than assuming parity: FMX sends its message *before* the
  window is shown, so the translated text is in place the first time anything
  is painted. The VCL hook fires on activation, which is afterwards. Both end
  up translated; only one is guaranteed never to flash the designed language
  at the user, and it should stay that way.

  Everything is set up the way a deployed application looks - a pack in
  Localization\Languages beside the executable, a preference under
  LOCALAPPDATA - because the hook infers those rather than being told them. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  { Qualified at every use below: FMX.Types declares a TPath of its own - a
    drawing path - and it wins the name here. }
  System.IOUtils,
  System.Messaging,
  FMX.Forms,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.Objects,
  DAT.Runtime.SplashTranslation.FMX in
    '..\..\source\runtime\DAT.Runtime.SplashTranslation.FMX.pas',
  DAT.Runtime.SplashTranslation in
    '..\..\source\runtime\DAT.Runtime.SplashTranslation.pas',
  DAT.Runtime.FMX in '..\..\source\runtime\DAT.Runtime.FMX.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

const
  ApplicationIdentifier = 'FMXSplashHookProbe';
  PackJson =
    '{"schemaVersion":3,"applicationId":"FMXSplashHookProbe",' +
    '"applicationVersion":"1.0","framework":"FMX",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{},' +
    '"strings":{"Form1.lblTitle.Text":"Wird geladen"},' +
    '"sources":{},"layout":[]}';

var
  Failures: Integer = 0;
  TextWhenMessageArrived: string = '(no message seen)';
  WitnessId: Integer;

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

function LanguagesFolder: string;
begin
  Result := System.IOUtils.TPath.Combine(ExtractFilePath(ParamStr(0)),
    'Localization\Languages');
end;

function PreferenceFolder: string;
var
  BaseFolder: string;
begin
  BaseFolder := GetEnvironmentVariable('LOCALAPPDATA');
  if BaseFolder = '' then
    BaseFolder := ExtractFilePath(ParamStr(0));
  Result := System.IOUtils.TPath.Combine(BaseFolder, ApplicationIdentifier);
end;

procedure DeployLikeAnInstalledApplication;
begin
  TDirectory.CreateDirectory(LanguagesFolder);
  TFile.WriteAllText(System.IOUtils.TPath.Combine(LanguagesFolder, 'de-DE.json'), PackJson,
    TEncoding.UTF8);
  TDirectory.CreateDirectory(PreferenceFolder);
  TLanguagePreference.WriteLanguageCode(
    System.IOUtils.TPath.Combine(PreferenceFolder, 'language.ini'), 'de-DE');
end;

procedure RemoveWhatWasDeployed;
begin
  try
    if TDirectory.Exists(LanguagesFolder) then
      TDirectory.Delete(LanguagesFolder, True);
    if TDirectory.Exists(PreferenceFolder) then
      TDirectory.Delete(PreferenceFolder, True);
  except
  end;
end;

{ A splash: no manager on it, nothing owning it, shown and then dropped.

  The label is found by name after the fact rather than kept in a variable,
  because the witness below runs while the form is still being shown. }
function ShowSplashAndReadText: string;
var
  Splash: TForm;
  Title: TLabel;
begin
  Splash := TForm.CreateNew(nil);
  try
    Splash.Name := 'Form1';
    Title := TLabel.Create(Splash);
    Title.Parent := Splash;
    Title.Name := 'lblTitle';
    Title.Text := 'Loading';
    Splash.Show;
    Application.ProcessMessages;
    Result := Title.Text;
  finally
    Splash.Free;
  end;
end;

{ Subscribed after the translator, so it sees the label as the translator left
  it - at the moment FMX is about to put the window on screen. If the text is
  already German here, nothing was ever painted in English. }
type
  TWitness = class
    class procedure FormBeforeShown(const ASender: TObject;
      const AMessage: System.Messaging.TMessage);
  end;

class procedure TWitness.FormBeforeShown(const ASender: TObject;
  const AMessage: System.Messaging.TMessage);
var
  Form: TCommonCustomForm;
  Found: TFmxObject;
begin
  if not (AMessage is TFormBeforeShownMessage) then
    Exit;
  Form := TFormBeforeShownMessage(AMessage).Value;
  if Form = nil then
    Exit;
  Found := Form.FindComponent('lblTitle') as TFmxObject;
  if Found is TLabel then
    TextWhenMessageArrived := TLabel(Found).Text;
end;

var
  TextAfterShowing: string;
begin
  try
    Application.Initialize;
    RemoveWhatWasDeployed;
    DeployLikeAnInstalledApplication;
    WitnessId := TMessageManager.DefaultManager.SubscribeToMessage(
      TFormBeforeShownMessage, TWitness.FormBeforeShown);
    try
      TextAfterShowing := ShowSplashAndReadText;
      Writeln('        splash text after showing:   ', TextAfterShowing);
      Writeln('        splash text before shown:    ', TextWhenMessageArrived);

      Check(TextAfterShowing = 'Wird geladen',
        'A splash shown before any manager exists is translated.');
      { The one that is not merely parity with VCL. }
      Check(TextWhenMessageArrived = 'Wird geladen',
        'and it was already translated before the window was shown.');

      TDATSplashTranslation.StandDown;
      Check(ShowSplashAndReadText = 'Loading',
        'After standing down it leaves forms alone for the manager.');
    finally
      TMessageManager.DefaultManager.Unsubscribe(
        TFormBeforeShownMessage, WitnessId);
      RemoveWhatWasDeployed;
    end;

    if Failures = 0 then
    begin
      Writeln('FMX splash hook smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('FMX splash hook smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('FMX splash hook smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
