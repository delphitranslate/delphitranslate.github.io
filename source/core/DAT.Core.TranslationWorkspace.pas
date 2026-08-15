unit DAT.Core.TranslationWorkspace;

interface

uses
  DAT.Core.Types;

type
  TTranslationWorkspace = class
  private
    class function SafeFilePart(const AValue: string): string; static;
  public
    class function RootDirectory(const AProfile: TProjectProfile): string; static;
    class function DevelopmentDirectory(
      const AProfile: TProjectProfile): string; static;
    class function LanguagesDirectory(
      const AProfile: TProjectProfile): string; static;
    class function DevelopmentCatalogFileName(const AProfile: TProjectProfile;
      const ALanguageCode: string): string; static;
    class function RuntimePackFileName(const AProfile: TProjectProfile;
      const ALanguageCode: string): string; static;
    class function GlossariesDirectory(
      const AProfile: TProjectProfile): string; static;
    class function GlossaryFileName(const AProfile: TProjectProfile;
      const ALanguageCode: string): string; static;
    class function DeploymentDirectory(
      const AProfile: TProjectProfile): string; static;
    class function DeploymentDestinationsFileName(
      const AProfile: TProjectProfile): string; static;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils;

class function TTranslationWorkspace.SafeFilePart(
  const AValue: string): string;
var
  CharacterIndex: Integer;
begin
  Result := Trim(AValue);
  for CharacterIndex := 1 to Length(Result) do
    if not CharInSet(Result[CharacterIndex],
      ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
      Result[CharacterIndex] := '_';
  if Result = '' then
    Result := 'language';
end;

class function TTranslationWorkspace.RootDirectory(
  const AProfile: TProjectProfile): string;
var
  LocalAppData: string;
  WorkspaceRoot: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('A Delphi project must be open.');
  LocalAppData := GetEnvironmentVariable('LOCALAPPDATA');
  if LocalAppData = '' then
    LocalAppData := TPath.GetHomePath;
  WorkspaceRoot := TPath.Combine(LocalAppData,
    'DelphiAppTranslationStudio\Workspaces');
  Result := TPath.Combine(WorkspaceRoot,
    SafeFilePart(AProfile.ProjectName));
end;

class function TTranslationWorkspace.DevelopmentDirectory(
  const AProfile: TProjectProfile): string;
begin
  Result := TPath.Combine(RootDirectory(AProfile), 'Development');
end;

class function TTranslationWorkspace.LanguagesDirectory(
  const AProfile: TProjectProfile): string;
begin
  Result := TPath.Combine(RootDirectory(AProfile), 'Languages');
end;

class function TTranslationWorkspace.GlossariesDirectory(
  const AProfile: TProjectProfile): string;
begin
  Result := TPath.Combine(RootDirectory(AProfile), 'Glossaries');
end;

class function TTranslationWorkspace.GlossaryFileName(
  const AProfile: TProjectProfile; const ALanguageCode: string): string;
begin
  Result := TPath.Combine(GlossariesDirectory(AProfile),
    SafeFilePart(AProfile.ProjectName) + '.' +
    SafeFilePart(ALanguageCode) + '.glossary.json');
end;

class function TTranslationWorkspace.DeploymentDirectory(
  const AProfile: TProjectProfile): string;
begin
  Result := TPath.Combine(RootDirectory(AProfile), 'Deployment');
end;

class function TTranslationWorkspace.DeploymentDestinationsFileName(
  const AProfile: TProjectProfile): string;
begin
  Result := TPath.Combine(DeploymentDirectory(AProfile),
    'deployment-destinations.json');
end;

class function TTranslationWorkspace.DevelopmentCatalogFileName(
  const AProfile: TProjectProfile; const ALanguageCode: string): string;
begin
  Result := TPath.Combine(DevelopmentDirectory(AProfile),
    SafeFilePart(AProfile.ProjectName) + '.' +
    SafeFilePart(ALanguageCode) + '.translation-project.json');
end;

class function TTranslationWorkspace.RuntimePackFileName(
  const AProfile: TProjectProfile; const ALanguageCode: string): string;
begin
  Result := TPath.Combine(LanguagesDirectory(AProfile),
    SafeFilePart(ALanguageCode) + '.json');
end;

end.
