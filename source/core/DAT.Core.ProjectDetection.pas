unit DAT.Core.ProjectDetection;

interface

uses
  System.SysUtils,
  DAT.Core.Types;

type
  EProjectDetectionError = class(Exception);

  TProjectDetector = class
  private
    class function ReadProjectText(const AProjectFileName: string): string; static;
    class function DetectFramework(const AProjectText: string): TTargetFramework; static;
    class procedure DetectPlatforms(const AProjectText: string;
      out ASupportsWin32, ASupportsWin64: Boolean); static;
    class function CountFiles(const ADirectory, AMask: string): Integer; static;
  public
    class function Detect(const AProjectFileName: string): TProjectProfile; static;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils;

class function TProjectDetector.ReadProjectText(
  const AProjectFileName: string): string;
begin
  try
    Result := TFile.ReadAllText(AProjectFileName, TEncoding.UTF8);
  except
    on E: EEncodingError do
      Result := TFile.ReadAllText(AProjectFileName);
  end;
end;

class function TProjectDetector.DetectFramework(
  const AProjectText: string): TTargetFramework;
var
  NormalizedText: string;
begin
  NormalizedText := LowerCase(AProjectText);
  if ContainsText(NormalizedText, '<frameworktype>fmx</frameworktype>') or
     ContainsText(NormalizedText, 'fmx.forms') then
    Exit(tfFireMonkey);

  if ContainsText(NormalizedText, '<frameworktype>vcl</frameworktype>') or
     ContainsText(NormalizedText, 'vcl.forms') then
    Exit(tfVCL);

  Result := tfUnknown;
end;

class procedure TProjectDetector.DetectPlatforms(const AProjectText: string;
  out ASupportsWin32, ASupportsWin64: Boolean);
var
  NormalizedText: string;
begin
  NormalizedText := LowerCase(AProjectText);
  ASupportsWin32 :=
    ContainsText(NormalizedText, '<platform value="win32">true</platform>') or
    ContainsText(NormalizedText, '<targetedplatforms>1</targetedplatforms>') or
    ContainsText(NormalizedText, '<targetedplatforms>3</targetedplatforms>');
  ASupportsWin64 :=
    ContainsText(NormalizedText, '<platform value="win64">true</platform>') or
    ContainsText(NormalizedText, '<targetedplatforms>2</targetedplatforms>') or
    ContainsText(NormalizedText, '<targetedplatforms>3</targetedplatforms>');

  if not ASupportsWin32 and not ASupportsWin64 then
    ASupportsWin32 := True;
end;

class function TProjectDetector.CountFiles(const ADirectory,
  AMask: string): Integer;
begin
  try
    Result := Length(TDirectory.GetFiles(ADirectory, AMask,
      TSearchOption.soAllDirectories));
  except
    on E: EInOutError do
      Result := 0;
  end;
end;

class function TProjectDetector.Detect(
  const AProjectFileName: string): TProjectProfile;
var
  ProjectDirectory: string;
  ProjectText: string;
begin
  Result := Default(TProjectProfile);

  if not TFile.Exists(AProjectFileName) then
    raise EProjectDetectionError.CreateFmt('Project file not found: %s',
      [AProjectFileName]);

  if not SameText(TPath.GetExtension(AProjectFileName), '.dproj') and
     not SameText(TPath.GetExtension(AProjectFileName), '.dpr') then
    raise EProjectDetectionError.Create(
      'Select a Delphi .dproj or .dpr project file.');

  ProjectText := ReadProjectText(AProjectFileName);
  ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);

  Result.ProjectFileName := TPath.GetFullPath(AProjectFileName);
  Result.ProjectName := TPath.GetFileNameWithoutExtension(AProjectFileName);
  Result.Framework := DetectFramework(ProjectText);
  DetectPlatforms(ProjectText, Result.SupportsWin32, Result.SupportsWin64);
  Result.FormResourceCount :=
    CountFiles(ProjectDirectory, '*.dfm') +
    CountFiles(ProjectDirectory, '*.fmx');
  Result.SourceFileCount := CountFiles(ProjectDirectory, '*.pas');
end;

end.
