unit DAT.Runtime.SplashTranslation;

{ Forms that appear before any language manager exists - the part that is the
  same in both frameworks.

  A splash screen is the case, and it is not an unusual one:

    Application.CreateForm(TForm1, Form1);   // the splash
    Form1.Show;
    ... load ...
    Form1.Free;                              // gone
    Application.CreateForm(TfmMain, fmMain); // the manager arrives here

  The splash is created, shown, and destroyed before the form carrying the
  language manager is even constructed. Nothing owner-based can reach it,
  because at the moment it matters there is no owner and no manager - and the
  application cannot be edited to add one, which is the premise of this
  product.

  So something has to act earlier than any component can. That something
  differs by framework and lives next door, in
  DAT.Runtime.SplashTranslation.VCL and DAT.Runtime.SplashTranslation.FMX:
  VCL chains Screen.OnActiveFormChange, FMX subscribes to
  TFormBeforeShownMessage. What does NOT differ is deciding which pack to
  apply and when to stop, and that is here so there is one answer rather than
  two that drift.

  Three rules govern all of it, in order of importance:

    1. Never raise. A splash translator that throws during startup turns a
       cosmetic shortcoming into an application that will not launch. An
       untranslated splash is the correct failure.

    2. Never steal. Whatever hook a framework offers may already be in use by
       the host application, and installing this must be invisible to code
       that was there first.

    3. Stand down when the real thing arrives. Once a manager initialises it
       knows the application id, the folders and the preferences properly, and
       these inferences are no longer the best available answer.

  What has to be inferred, and why that is acceptable:

  A manager is configured in the Object Inspector - application id, languages
  folder, where preferences live. None of that exists before one does, so the
  shipping defaults are assumed: the languages folder beside the executable,
  the preference file under LOCALAPPDATA. Those are what the component ships
  with and what the Wizard deploys, so they are right for any application that
  has not deliberately moved them. One that has gets an untranslated splash
  rather than a wrong one, which is the right way round. }

interface

uses
  DAT.Runtime.LanguagePack;

type
  TDATSplashTranslation = class
  private
    class var FStoodDown: Boolean;
    class var FResolved: Boolean;
    class var FPack: TRuntimeLanguagePack;
  public
    { The pack to apply to a form appearing this early, or nil if there is
      none, the preference has never been set, or a manager has taken over.
      Resolved once and kept: a splash is usually followed straight away by
      another form, and reading the folder per form would be waste.

      The returned pack belongs to this class. Callers apply it and forget it. }
    class function PackForEarlyForms: TRuntimeLanguagePack; static;
    { Whether the framework hooks should still be doing anything. }
    class function Active: Boolean; static;
    { Called by a language manager as it applies. From here on the manager is
      a better authority than anything inferred here. }
    class procedure StandDown; static;
    class procedure Cleanup; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  DAT.Runtime.Preference;

{ The language the user last chose, or nothing.

  Deliberately not falling back to the system language. A first run has no
  stored preference, and guessing at that moment would mean a splash in one
  language followed by a main window in another - which reads as a fault
  rather than a feature. With no preference the splash stays as designed. }
function StoredLanguageCode(const AApplicationId: string): string;
var
  BaseFolder: string;
begin
  BaseFolder := GetEnvironmentVariable('LOCALAPPDATA');
  if BaseFolder = '' then
    BaseFolder := ExtractFilePath(ParamStr(0));
  Result := TLanguagePreference.ReadLanguageCode(
    TPath.Combine(TPath.Combine(BaseFolder, AApplicationId), 'language.ini'),
    '');
end;

{ The folder is read rather than searched for a name, because the application
  id is one of the things not yet known - but every pack carries it, so
  reading one answers the question that finding it would have required knowing. }
function ResolvePack: TRuntimeLanguagePack;
var
  Folder: string;
  FileName: string;
  Candidate: TRuntimeLanguagePack;
  Wanted: string;
begin
  Result := nil;
  Folder := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'Localization\Languages');
  if not TDirectory.Exists(Folder) then
    Exit;

  Wanted := '';
  for FileName in TDirectory.GetFiles(Folder, '*.json') do
  begin
    Candidate := nil;
    try
      Candidate := TRuntimeLanguagePack.LoadFromFile(FileName);
      if Wanted = '' then
        Wanted := StoredLanguageCode(Candidate.ApplicationId);
      if Wanted = '' then
      begin
        Candidate.Free;
        Exit;
      end;
      if SameText(Candidate.LanguageCode, Wanted) then
        Exit(Candidate);
      Candidate.Free;
    except
      { A malformed or foreign pack is skipped rather than fatal. }
      Candidate.Free;
    end;
  end;
end;

class function TDATSplashTranslation.Active: Boolean;
begin
  Result := not FStoodDown;
end;

class function TDATSplashTranslation.PackForEarlyForms: TRuntimeLanguagePack;
begin
  Result := nil;
  if FStoodDown then
    Exit;
  if not FResolved then
  begin
    FResolved := True;
    try
      FPack := ResolvePack;
    except
      FPack := nil;
    end;
  end;
  Result := FPack;
end;

class procedure TDATSplashTranslation.StandDown;
begin
  FStoodDown := True;
  FreeAndNil(FPack);
end;

class procedure TDATSplashTranslation.Cleanup;
begin
  FreeAndNil(FPack);
end;

end.
