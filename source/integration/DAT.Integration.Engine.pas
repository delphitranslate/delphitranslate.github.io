unit DAT.Integration.Engine;

interface

uses
  DAT.Core.Types,
  DAT.Integration.Types;

type
  TTargetIntegrationEngine = class
  public
    class function BuildChangeSet(const AProfile: TProjectProfile;
      const APackageDirectory, ALanguageMenuName: string):
      TIntegrationChangeSet; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.TranslationWorkspace,
  DAT.Integration.DelphiSource,
  DAT.Integration.MenuResource,
  DAT.Runtime.LanguagePack;

function PascalIdentifier(const AValue: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in AValue do
    if CharInSet(Character,
      ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Result := Result + Character;
  if (Result = '') or CharInSet(Result[1], ['0'..'9']) then
    Result := 'TranslatedApp' + Result;
end;

function FindFormSource(const AProjectDirectory,
  AFormResourceFileName, AFormClassName: string): string;
var
  CandidateFileName: string;
begin
  Result := TPath.ChangeExtension(AFormResourceFileName, '.pas');
  if TFile.Exists(Result) then
    Exit;
  for CandidateFileName in TDirectory.GetFiles(
    AProjectDirectory, '*.pas', TSearchOption.soAllDirectories) do
  begin
    if ContainsText(CandidateFileName, '\Localization\') or
      ContainsText(CandidateFileName, '\bin\') or
      ContainsText(CandidateFileName, '\dcu\') then
      Continue;
    if ContainsText(TFile.ReadAllText(CandidateFileName),
      AFormClassName + ' = class') then
      Exit(CandidateFileName);
  end;
  raise Exception.CreateFmt(
    'The Pascal source for form class %s was not found.',
    [AFormClassName]);
end;

function ProjectSourceFileName(const AProfile: TProjectProfile): string;
begin
  if SameText(TPath.GetExtension(AProfile.ProjectFileName), '.dpr') then
    Result := AProfile.ProjectFileName
  else
    Result := TPath.ChangeExtension(AProfile.ProjectFileName, '.dpr');
  if not TFile.Exists(Result) then
    raise EFileNotFoundException.CreateFmt(
      'The Delphi project source was not found: %s', [Result]);
end;

class function TTargetIntegrationEngine.BuildChangeSet(
  const AProfile: TProjectProfile; const APackageDirectory,
  ALanguageMenuName: string): TIntegrationChangeSet;
var
  DprojFileName: string;
  DprojText: string;
  DprFileName: string;
  FormSourceFileName: string;
  FormSourceText: string;
  IntegrationRelativeFileName: string;
  IntegrationUnitFileName: string;
  IntegrationUnitName: string;
  IsStudioSelfIntegration: Boolean;
  LanguageDirectory: string;
  Languages: TObjectList<TLanguagePackDescriptor>;
  MenuEdit: TMenuResourceEdit;
  PackageRuntimeDirectory: string;
  ProjectDirectory: string;
  ProjectText: string;
  RuntimeFileName: string;
  RuntimeRelativeFileName: string;
  SourceLanguageCode: string;
begin
  if not TDirectory.Exists(APackageDirectory) then
    raise EDirectoryNotFoundException.CreateFmt(
      'The integration package was not found: %s', [APackageDirectory]);

  ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
  IsStudioSelfIntegration :=
    SameText(AProfile.ProjectName, 'DelphiAppTranslationStudio') and
    TFile.Exists(TPath.Combine(ProjectDirectory,
      'source\studio\DAT.Studio.Translation.pas'));
  IntegrationUnitName := PascalIdentifier(AProfile.ProjectName) +
    '.Translation';
  IntegrationUnitFileName := TPath.Combine(APackageDirectory,
    IntegrationUnitName + '.pas');
  if not TFile.Exists(IntegrationUnitFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The generated integration unit was not found: %s',
      [IntegrationUnitFileName]);

  LanguageDirectory := TTranslationWorkspace.LanguagesDirectory(AProfile);
  Languages := TLanguagePackDiscovery.Discover(
    LanguageDirectory, AProfile.ProjectName);
  try
    SourceLanguageCode := 'en-US';
    if Languages.Count > 0 then
      SourceLanguageCode := Languages[0].SourceLanguage;
    MenuEdit := TLanguageMenuResourceEditor.Build(
      AProfile, ALanguageMenuName, SourceLanguageCode, Languages);
    try
      Result := TIntegrationChangeSet.Create;
      try
        Result.ProjectDirectory := ProjectDirectory;
        Result.ProjectName := AProfile.ProjectName;

        if IsStudioSelfIntegration then
        begin
          Result.AddTextChange(ickFormResource, MenuEdit.FileName,
            'Update the Studio designer-persisted language menu',
            MenuEdit.NewText);
          Exit;
        end;

        PackageRuntimeDirectory := TPath.Combine(
          APackageDirectory, 'Runtime');
        for RuntimeFileName in TDirectory.GetFiles(
          PackageRuntimeDirectory, '*.pas') do
        begin
          RuntimeRelativeFileName := TPath.Combine(
            'Localization\Runtime', TPath.GetFileName(RuntimeFileName));
          Result.AddTextChange(ickRuntimeUnit,
            TPath.Combine(ProjectDirectory, RuntimeRelativeFileName),
            'Install offline runtime unit ' +
              TPath.GetFileName(RuntimeFileName),
            TFile.ReadAllText(RuntimeFileName));
        end;

        IntegrationRelativeFileName := TPath.Combine(
          'Localization\Runtime', TPath.GetFileName(
            IntegrationUnitFileName));
        Result.AddTextChange(ickGeneratedUnit,
          TPath.Combine(ProjectDirectory, IntegrationRelativeFileName),
          'Install the project-specific translation integration unit',
          TFile.ReadAllText(IntegrationUnitFileName));

        Result.AddTextChange(ickFormResource, MenuEdit.FileName,
          'Update the designer-persisted language menu',
          MenuEdit.NewText);
        FormSourceFileName := FindFormSource(ProjectDirectory,
          MenuEdit.FileName, MenuEdit.FormClassName);
        FormSourceText := TDelphiIntegrationSourceEditor.AddFormLanguageHandler(
          TFile.ReadAllText(FormSourceFileName), MenuEdit.FormClassName,
          IntegrationUnitName);
        Result.AddTextChange(ickFormSource, FormSourceFileName,
          'Connect persisted language items to the selection handler',
          FormSourceText);

        DprFileName := ProjectSourceFileName(AProfile);
        ProjectText := TFile.ReadAllText(DprFileName);
        for RuntimeFileName in TDirectory.GetFiles(
          PackageRuntimeDirectory, '*.pas') do
        begin
          RuntimeRelativeFileName := TPath.Combine(
            'Localization\Runtime', TPath.GetFileName(RuntimeFileName));
          ProjectText :=
            TDelphiIntegrationSourceEditor.AddProjectUnitReference(
              ProjectText,
              TPath.GetFileNameWithoutExtension(RuntimeFileName),
              RuntimeRelativeFileName);
        end;
        ProjectText := TDelphiIntegrationSourceEditor.AddProjectStartup(
          ProjectText, IntegrationUnitName,
          IntegrationRelativeFileName);
        Result.AddTextChange(ickProjectSource, DprFileName,
          'Initialize offline translation before creating forms',
          ProjectText);

        DprojFileName := TPath.ChangeExtension(DprFileName, '.dproj');
        if TFile.Exists(DprojFileName) then
        begin
          DprojText := TFile.ReadAllText(DprojFileName);
          DprojText := TDelphiIntegrationSourceEditor.AddProjectReference(
            DprojText, IntegrationRelativeFileName);
          for RuntimeFileName in TDirectory.GetFiles(
            PackageRuntimeDirectory, '*.pas') do
          begin
            RuntimeRelativeFileName := TPath.Combine(
              'Localization\Runtime', TPath.GetFileName(RuntimeFileName));
            DprojText := TDelphiIntegrationSourceEditor.AddProjectReference(
              DprojText, RuntimeRelativeFileName);
          end;
          Result.AddTextChange(ickProjectMetadata, DprojFileName,
            'Register generated runtime files with the Delphi project',
            DprojText);
        end;
      except
        Result.Free;
        raise;
      end;
    finally
      MenuEdit.Free;
    end;
  finally
    Languages.Free;
  end;
end;

end.
