unit DAT.Scan.Project;

interface

uses
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TProjectScanner = class
  private
    class function IsExcludedPath(const AProjectDirectory,
      AFileName: string): Boolean; static;
  public
    class function Scan(const AProfile: TProjectProfile): TProjectScanResult; static;
  end;

implementation

uses
  System.Diagnostics,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Scan.FormText,
  DAT.Scan.PascalResources;

class function TProjectScanner.IsExcludedPath(const AProjectDirectory,
  AFileName: string): Boolean;
var
  CandidateDirectory: string;
  DirectoryPrefix: string;
  NestedProjects: TArray<string>;
  RelativePath: string;
begin
  DirectoryPrefix := IncludeTrailingPathDelimiter(
    LowerCase(TPath.GetFullPath(AProjectDirectory)));
  RelativePath := LowerCase(TPath.GetFullPath(AFileName));
  if StartsText(DirectoryPrefix, RelativePath) then
    Delete(RelativePath, 1, Length(DirectoryPrefix));
  Result := StartsText('.git' + PathDelim, RelativePath) or
    StartsText('.agents' + PathDelim, RelativePath) or
    StartsText('__history' + PathDelim, RelativePath) or
    StartsText('__recovery' + PathDelim, RelativePath) or
    StartsText('bin' + PathDelim, RelativePath) or
    StartsText('dcu' + PathDelim, RelativePath) or
    StartsText('docs' + PathDelim, RelativePath) or
    StartsText('export' + PathDelim, RelativePath) or
    StartsText('localization' + PathDelim, RelativePath) or
    StartsText('samples' + PathDelim, RelativePath) or
    StartsText('source distributions' + PathDelim, RelativePath);
  if Result then
    Exit;

  { A source tree may contain a separate utility or conversion project. Such
    a nested project is not part of the application selected by the user. }
  CandidateDirectory := TPath.GetDirectoryName(TPath.GetFullPath(AFileName));
  while not SameText(CandidateDirectory,
    TPath.GetFullPath(AProjectDirectory)) do
  begin
    NestedProjects := TDirectory.GetFiles(CandidateDirectory, '*.dproj',
      TSearchOption.soTopDirectoryOnly);
    if Length(NestedProjects) = 0 then
      NestedProjects := TDirectory.GetFiles(CandidateDirectory, '*.dpr',
        TSearchOption.soTopDirectoryOnly);
    if Length(NestedProjects) > 0 then
      Exit(True);
    if SameText(TPath.GetDirectoryName(CandidateDirectory),
      CandidateDirectory) then
      Break;
    CandidateDirectory := TPath.GetDirectoryName(CandidateDirectory);
  end;
end;

class function TProjectScanner.Scan(
  const AProfile: TProjectProfile): TProjectScanResult;
var
  FileName: string;
  FileNames: TArray<string>;
  ProjectDirectory: string;
  Stopwatch: TStopwatch;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('A detected Delphi project is required.');
  if AProfile.Framework = tfUnknown then
    raise EArgumentException.Create(
      'The project framework must be identified before scanning.');

  Result := TProjectScanResult.Create;
  try
    ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
    Stopwatch := TStopwatch.StartNew;

    if AProfile.Framework = tfVCL then
      FileNames := TDirectory.GetFiles(ProjectDirectory, '*.dfm',
        TSearchOption.soAllDirectories)
    else
      FileNames := TDirectory.GetFiles(ProjectDirectory, '*.fmx',
        TSearchOption.soAllDirectories);

    for FileName in FileNames do
      if not IsExcludedPath(ProjectDirectory, FileName) then
      begin
        TTextFormScanner.ScanFile(FileName, AProfile.Framework, Result);
        Result.FormFilesScanned := Result.FormFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
      end;

    FileNames := TDirectory.GetFiles(ProjectDirectory, '*.pas',
      TSearchOption.soAllDirectories);
    for FileName in FileNames do
      if not IsExcludedPath(ProjectDirectory, FileName) then
      begin
        TPascalResourceStringScanner.ScanFile(FileName, Result);
        Result.SourceFilesScanned := Result.SourceFilesScanned + 1;
        Result.FilesScanned := Result.FilesScanned + 1;
      end;

    Stopwatch.Stop;
    Result.ElapsedMilliseconds := Stopwatch.ElapsedMilliseconds;
  except
    Result.Free;
    raise;
  end;
end;

end.
