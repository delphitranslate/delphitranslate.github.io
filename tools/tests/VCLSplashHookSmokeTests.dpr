program VCLSplashHookSmokeTests;

{ A splash translated before any language manager exists.

  VCLSplashSmokeTests covers the case where a manager sits on the splash and
  therefore lives as long as it does. This covers the harder one, which is what
  real applications actually do:

    Application.CreateForm(TForm1, Form1);   // splash
    Form1.Show;
    Form1.Free;                              // gone
    Application.CreateForm(TfmMain, fmMain); // manager arrives here

  The splash is created, shown and destroyed before the manager is
  constructed. No component can reach it, and the application cannot be edited
  to add one. DAT.Runtime.SplashTranslation hooks Screen.OnActiveFormChange at
  unit initialisation instead, which happens before the .dpr body runs.

  Everything here is set up the way a deployed application looks - a pack in
  Localization\Languages beside the executable, a preference under
  LOCALAPPDATA - because the hook infers those locations rather than being
  told them, and a test that told it would prove nothing about an application
  that cannot. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls,
  DAT.Runtime.SplashTranslation.VCL in
    '..\..\source\runtime\DAT.Runtime.SplashTranslation.VCL.pas',
  DAT.Runtime.SplashTranslation in
    '..\..\source\runtime\DAT.Runtime.SplashTranslation.pas',
  DAT.Runtime.VCL in '..\..\source\runtime\DAT.Runtime.VCL.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

const
  ApplicationIdentifier = 'SplashHookProbe';
  PackJson =
    '{"schemaVersion":3,"applicationId":"SplashHookProbe",' +
    '"applicationVersion":"1.0","framework":"VCL",' +
    '"sourceLanguage":"en-US","sourceCatalogChecksum":"t",' +
    '"language":{"code":"de-DE","nativeName":"Deutsch","direction":"ltr"},' +
    '"locale":{},' +
    '"strings":{"Form1.lblTitle.Caption":"Wird geladen",' +
    '"Form1.lblOrgName.Caption":"Beliebiger Name"},' +
    '"sources":{"Form1.lblTitle.Caption":"Loading",' +
    '"Form1.lblOrgName.Caption":"Any Organization Name"},' +
    '"layout":[{"formName":"Form1","componentName":"lblOrgName",' +
    '"propertyName":"Width","originalValue":"220",' +
    '"translatedValue":"80","sourceChecksum":"t"}]}';

var
  Failures: Integer = 0;
  OrganizationAfterShowing: string = '';
  OrganizationWidthAfterShowing: Integer = 0;

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
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'Localization\Languages');
end;

function PreferenceFolder: string;
var
  BaseFolder: string;
begin
  BaseFolder := GetEnvironmentVariable('LOCALAPPDATA');
  if BaseFolder = '' then
    BaseFolder := ExtractFilePath(ParamStr(0));
  Result := TPath.Combine(BaseFolder, ApplicationIdentifier);
end;

procedure DeployLikeAnInstalledApplication;
begin
  TDirectory.CreateDirectory(LanguagesFolder);
  TFile.WriteAllText(TPath.Combine(LanguagesFolder, 'de-DE.json'), PackJson,
    TEncoding.UTF8);
  TDirectory.CreateDirectory(PreferenceFolder);
  TLanguagePreference.WriteLanguageCode(
    TPath.Combine(PreferenceFolder, 'language.ini'), 'de-DE');
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

{ A splash: no manager on it, nothing owning it, shown and then dropped. }
function ShowSplashAndReadTitle: string;
var
  Splash: TForm;
  Organization: TLabel;
  Title: TLabel;
begin
  Splash := TForm.CreateNew(nil);
  try
    Splash.Name := 'Form1';
    Title := TLabel.Create(Splash);
    Title.Parent := Splash;
    Title.Name := 'lblTitle';
    Title.Caption := 'Loading';
    Organization := TLabel.Create(Splash);
    Organization.Parent := Splash;
    Organization.Name := 'lblOrgName';
    Organization.AutoSize := False;
    Organization.Width := 220;
    { Live data has replaced the designer placeholder before localization. }
    Organization.Caption := 'Saint Mark Church';
    Splash.Show;
    Splash.Update;
    Application.ProcessMessages;
    Result := Title.Caption;
    OrganizationAfterShowing := Organization.Caption;
    OrganizationWidthAfterShowing := Organization.Width;
  finally
    Splash.Free;
  end;
end;

var
  TitleAfterShowing: string;
begin
  try
    Application.Initialize;
    RemoveWhatWasDeployed;
    DeployLikeAnInstalledApplication;
    try
      { The hook resolves lazily, on the first form to become active, so the
        files above must exist before this and not before the unit loaded. }
      TitleAfterShowing := ShowSplashAndReadTitle;
      Writeln('        splash title after showing: ', TitleAfterShowing);
      Check(TitleAfterShowing = 'Wird geladen',
        'A splash shown before any manager exists is translated.');
      Check(OrganizationAfterShowing = 'Saint Mark Church',
        'Live splash data is preserved instead of replacing it with a ' +
        'translated designer placeholder.');
      Check(OrganizationWidthAfterShowing = 220,
        'Layout planned for a placeholder does not resize live splash data.');

      { Rule 3: once a manager is doing the work, the hook stops guessing. }
      TDATSplashTranslation.StandDown;
      Check(ShowSplashAndReadTitle = 'Loading',
        'After standing down it leaves forms alone for the manager.');
    finally
      RemoveWhatWasDeployed;
    end;

    if Failures = 0 then
    begin
      Writeln('VCL splash hook smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('VCL splash hook smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('VCL splash hook smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
