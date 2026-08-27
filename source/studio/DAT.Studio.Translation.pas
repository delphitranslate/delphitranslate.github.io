unit DAT.Studio.Translation;

interface

uses
  FMX.Forms,
  DAT.Runtime.Manager;

procedure InitializeStudioTranslation;
procedure ApplyStudioTranslation(const AForm: TCommonCustomForm);
function SelectStudioLanguageMenuItem(
  const AMenuItemName: string): Boolean;
function StudioTranslationRuntime: TTranslationRuntime;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Runtime.FMX;

var
  TranslationRuntimeInstance: TTranslationRuntime;

function FindStudioApplicationDirectory: string;
var
  CandidateDirectory: string;
  ParentDirectory: string;
begin
  CandidateDirectory := TPath.GetFullPath(
    ExtractFilePath(ParamStr(0)));
  if TDirectory.Exists(TPath.Combine(
    CandidateDirectory, 'Localization\Languages')) then
    Exit(CandidateDirectory);

  while CandidateDirectory <> '' do
  begin
    if TFile.Exists(TPath.Combine(CandidateDirectory,
      'DelphiAppTranslationStudio.dproj')) then
      Exit(CandidateDirectory);
    ParentDirectory := TPath.GetDirectoryName(CandidateDirectory);
    if SameText(ParentDirectory, CandidateDirectory) then
      Break;
    CandidateDirectory := ParentDirectory;
  end;
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)));
end;

procedure InitializeStudioTranslation;
var
  ApplicationDirectory: string;
  LocalApplicationData: string;
  PreferenceDirectory: string;
begin
  ApplicationDirectory := FindStudioApplicationDirectory;
  LocalApplicationData := GetEnvironmentVariable('LOCALAPPDATA');
  if LocalApplicationData = '' then
    LocalApplicationData := TPath.GetHomePath;
  PreferenceDirectory := TPath.Combine(LocalApplicationData,
    'DelphiAppTranslationStudio');
  FreeAndNil(TranslationRuntimeInstance);
  TranslationRuntimeInstance := TTranslationRuntime.Create(
    'DelphiAppTranslationStudio',
    TPath.Combine(ApplicationDirectory, 'Localization\Languages'),
    TPath.Combine(PreferenceDirectory, 'language.ini'),
    'en-US', 'FireMonkey');
  TranslationRuntimeInstance.LoadPreferredLanguage;
end;

procedure ApplyStudioTranslation(const AForm: TCommonCustomForm);
begin
  if (TranslationRuntimeInstance <> nil) and
    (TranslationRuntimeInstance.ActivePack <> nil) then
    TFMXTranslationApplicator.ApplyToForm(
      AForm, TranslationRuntimeInstance.ActivePack);
end;

function SelectStudioLanguageMenuItem(
  const AMenuItemName: string): Boolean;
var
  LanguageCode: string;
begin
  LanguageCode := Copy(AMenuItemName,
    Length('datLanguage_') + 1, MaxInt);
  LanguageCode := StringReplace(
    LanguageCode, '_', '-', [rfReplaceAll]);
  Result := (TranslationRuntimeInstance <> nil) and
    TranslationRuntimeInstance.LoadLanguage(LanguageCode);
end;

function StudioTranslationRuntime: TTranslationRuntime;
begin
  Result := TranslationRuntimeInstance;
end;

initialization
  TranslationRuntimeInstance := nil;

finalization
  TranslationRuntimeInstance.Free;

end.
