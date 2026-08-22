unit DAT.Runtime.SplashTranslation;

{ Forms that appear before any language manager exists.

  A splash screen is the case, and it is not an unusual one. The pattern
  every Delphi application uses looks like this:

    Application.CreateForm(TForm1, Form1);   // the splash
    Form1.Show;
    Form1.Update;
    ... load ...
    Form1.Free;                              // gone
    Application.CreateForm(TfmMain, fmMain); // the manager arrives here

  The splash is created, shown, and destroyed before the form carrying the
  language manager is even constructed. Nothing owner-based can reach it,
  because at the moment it matters there is no owner and no manager - and the
  application cannot be edited to add one, which is the whole premise of this
  product.

  So this unit acts earlier than any component can. It chains itself onto
  Screen.OnActiveFormChange when the unit initialises, which happens before
  the first line of the .dpr body runs, and translates each form that becomes
  active until a real manager takes over.

  Three rules govern everything below, in order of importance:

    1. Never raise. A splash translator that throws during startup turns a
       cosmetic shortcoming into an application that will not launch. Every
       entry point swallows its exceptions, and an untranslated splash is the
       correct failure.

    2. Never steal. Screen.OnActiveFormChange is a single slot the host
       application may already be using. The previous handler is kept and
       called, so installing this is invisible to code that was there first.

    3. Stand down when the real thing arrives. Once a manager initialises it
       knows the application id, the folders and the preferences properly,
       and this unit's inferences are no longer the best available answer.

  What it has to infer, and why that is acceptable here:

  A manager is configured in the Object Inspector - application id, languages
  folder, where preferences live. None of that is available before one exists,
  so the defaults are assumed: the languages folder beside the executable and
  the preference file under LOCALAPPDATA. Those are the defaults the component
  ships with and what the Wizard deploys, so they are right for any
  application that has not deliberately moved them. An application that has
  moved them gets an untranslated splash rather than a wrong one, which is the
  right way round. }

interface

uses
  System.Classes,
  Vcl.Forms;

type
  TDATSplashTranslation = class
  private
    class var FInstalled: Boolean;
    class var FStoodDown: Boolean;
    class var FPreviousHandler: TNotifyEvent;
    class var FResolved: Boolean;
    { Not static: Screen.OnActiveFormChange is a method pointer, and a
      class method satisfies one where a plain procedure does not. }
    class procedure ActiveFormChanged(Sender: TObject);
    class procedure TranslateActiveForm; static;
  public
    { Chains onto Screen.OnActiveFormChange. Called from initialization; safe
      to call more than once. }
    class procedure Install; static;
    { Called by a language manager as it initialises. From here on the manager
      is a better authority than anything this unit can infer. }
    class procedure StandDown; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Controls,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.Preference,
  DAT.Runtime.VCL;

var
  { Held for the life of the process. Loading a pack per form shown would be
    wasteful, and a splash is usually followed immediately by another form. }
  ResolvedPack: TRuntimeLanguagePack = nil;

{ The language the user last chose, or nothing.

  Deliberately not falling back to the system language. A first run has no
  stored preference, and guessing at that moment would mean a splash in one
  language followed by a main window in another - which looks like a fault
  rather than a feature. With no preference the splash stays as designed. }
function StoredLanguageCode(const AApplicationId: string): string;
var
  BaseFolder: string;
begin
  Result := '';
  BaseFolder := GetEnvironmentVariable('LOCALAPPDATA');
  if BaseFolder = '' then
    BaseFolder := ExtractFilePath(ParamStr(0));
  Result := TLanguagePreference.ReadLanguageCode(
    TPath.Combine(TPath.Combine(BaseFolder, AApplicationId), 'language.ini'),
    '');
end;

{ The pack to apply, or nil.

  The folder is read rather than searched for a name, because the application
  id is one of the things not yet known - but any pack in the folder carries
  it, so reading one answers the question that finding it would have required
  knowing. }
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
      { No stored preference means the application has never been switched
        away from the language it was written in. Nothing to do. }
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

class procedure TDATSplashTranslation.TranslateActiveForm;
var
  Form: TCustomForm;
begin
  if FStoodDown then
    Exit;
  Form := Screen.ActiveCustomForm;
  if (Form = nil) or (Form.Name = '') then
    Exit;

  if not FResolved then
  begin
    FResolved := True;
    ResolvedPack := ResolvePack;
  end;
  if ResolvedPack = nil then
    Exit;

  { The same call a manager makes. Control state is not preserved because
    nothing has been typed into a form that has only just appeared, and asking
    to preserve it would mean reading properties off controls mid-construction. }
  TVCLTranslationApplicator.ApplyToForm(Form, ResolvedPack, Form.Name, False);
end;

class procedure TDATSplashTranslation.ActiveFormChanged(Sender: TObject);
begin
  try
    TranslateActiveForm;
  except
    { Rule 1. An untranslated splash is a blemish; an exception here is a
      startup crash, and the application is not ours to crash. }
  end;
  if Assigned(FPreviousHandler) then
    FPreviousHandler(Sender);
end;

class procedure TDATSplashTranslation.Install;
begin
  if FInstalled or (Screen = nil) then
    Exit;
  FInstalled := True;
  FPreviousHandler := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := TDATSplashTranslation.ActiveFormChanged;
end;

class procedure TDATSplashTranslation.StandDown;
begin
  FStoodDown := True;
  FreeAndNil(ResolvedPack);
end;

initialization
  TDATSplashTranslation.Install;

finalization
  ResolvedPack.Free;
  ResolvedPack := nil;

end.
