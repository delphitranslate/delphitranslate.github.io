unit DAT.Integration.Plan;

interface

uses
  System.Classes,
  DAT.Core.Types;

type
  TIntegrationPlan = class
  private
    FLines: TStringList;
    FLanguageCount: Integer;
    FMenuFound: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property Lines: TStringList read FLines;
    property LanguageCount: Integer read FLanguageCount write FLanguageCount;
    property MenuFound: Boolean read FMenuFound write FMenuFound;
  end;

  TIntegrationPlanner = class
  public
    class function Build(const AProfile: TProjectProfile;
      const ALanguageMenuName: string): TIntegrationPlan; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack;

constructor TIntegrationPlan.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TIntegrationPlan.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function FormContainsMenu(const AProjectDirectory, AMenuName: string): Boolean;
var
  Extension: string;
  FileName: string;
  FormText: string;
begin
  Result := False;
  for Extension in TArray<string>.Create('*.dfm', '*.fmx') do
    for FileName in TDirectory.GetFiles(
      AProjectDirectory, Extension, TSearchOption.soAllDirectories) do
    begin
      FormText := TFile.ReadAllText(FileName);
      if ContainsText(FormText, 'object ' + AMenuName + ':') or
        ContainsText(FormText, 'inherited ' + AMenuName + ':') then
        Exit(True);
    end;
end;

class function TIntegrationPlanner.Build(const AProfile: TProjectProfile;
  const ALanguageMenuName: string): TIntegrationPlan;
var
  Descriptor: TLanguagePackDescriptor;
  Languages: TObjectList<TLanguagePackDescriptor>;
  LanguagesDirectory: string;
  ProjectDirectory: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('Open a Delphi project first.');
  if Trim(ALanguageMenuName) = '' then
    raise EArgumentException.Create('Enter the existing Language menu name.');

  Result := TIntegrationPlan.Create;
  try
    ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
    LanguagesDirectory := TTranslationWorkspace.LanguagesDirectory(
      AProfile);
    Languages := TLanguagePackDiscovery.Discover(
      LanguagesDirectory, AProfile.ProjectName);
    try
      Result.LanguageCount := Languages.Count;
      Result.MenuFound := FormContainsMenu(
        ProjectDirectory, ALanguageMenuName);

      Result.Lines.Add('1. Add the framework-neutral runtime loader, manager, and preference units.');
      if AProfile.Framework = tfVCL then
        Result.Lines.Add('2. Add DAT.Runtime.VCL and apply it after each VCL form is created.')
      else
        Result.Lines.Add('2. Add DAT.Runtime.FMX and apply it after each FMX form is created.');
      Result.Lines.Add('3. Deploy Localization\Languages beside the application.');
      if Result.MenuFound then
        Result.Lines.Add(Format(
          '4. Populate existing designer menu "%s" with these language choices:',
          [ALanguageMenuName]))
      else
        Result.Lines.Add(Format(
          '4. Add designer menu "%s", then populate it with these language choices:',
          [ALanguageMenuName]));

      if Languages.Count = 0 then
        Result.Lines.Add('   No exported runtime language packs were found.')
      else
        for Descriptor in Languages do
          Result.Lines.Add(Format('   %s (%s)',
            [Descriptor.NativeLanguageName, Descriptor.LanguageCode]));
      Result.Lines.Add('5. Connect each menu item to SelectLanguage and restart or reapply open forms.');
      Result.Lines.Add('6. Review the generated integration unit before changing target source.');
    finally
      Languages.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
