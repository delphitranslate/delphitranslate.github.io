unit DAT.Integration.BuildDeploy;

interface

type
  TTargetBuildDeployer = class
  public
    class function FindBuildOutputDirectory(const AProjectFileName,
      AProjectName, APlatform, AConfiguration: string;
      ARequireExecutable: Boolean = False): string; static;
    class function BuildAndDeploy(const AProjectFileName, AProjectName,
      APlatform, AConfiguration, APackageDirectory: string): string; static;
    class function DeployBuildOutput(const AProjectFileName, AProjectName,
      APlatform, AConfiguration, ADestinationDirectory,
      APackageDirectory: string; AReplaceExecutable: Boolean): string; static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils,
  Winapi.ShellAPI,
  Winapi.Windows;

const
  DelphiEnvironmentFile =
    'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat';
  BuildProcessTimeout = 1800000;
  ProcessTerminationWait = 5000;

procedure RunElevatedBuild(const AProjectFileName, APlatform,
  AConfiguration: string);
var
  CommandParameters: string;
  ExitCode: Cardinal;
  ExecuteInfo: TShellExecuteInfo;
  WaitResult: Cardinal;
begin
  CommandParameters := Format(
    '/d /s /c ""%s" && msbuild "%s" /t:Build /p:Platform=%s /p:Config=%s"',
    [DelphiEnvironmentFile, AProjectFileName, APlatform, AConfiguration]);
  ZeroMemory(@ExecuteInfo, SizeOf(ExecuteInfo));
  ExecuteInfo.cbSize := SizeOf(ExecuteInfo);
  ExecuteInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ExecuteInfo.Wnd := 0;
  ExecuteInfo.lpVerb := 'runas';
  ExecuteInfo.lpFile := 'cmd.exe';
  ExecuteInfo.lpParameters := PChar(CommandParameters);
  ExecuteInfo.nShow := SW_HIDE;
  if not ShellExecuteEx(@ExecuteInfo) then
    RaiseLastOSError;
  try
    WaitResult := WaitForSingleObject(ExecuteInfo.hProcess,
      BuildProcessTimeout);
    if WaitResult = WAIT_TIMEOUT then
    begin
      TerminateProcess(ExecuteInfo.hProcess, ERROR_TIMEOUT);
      WaitForSingleObject(ExecuteInfo.hProcess, ProcessTerminationWait);
      raise Exception.CreateFmt(
        'The %s %s build timed out and its command process was stopped.',
        [APlatform, AConfiguration]);
    end;
    if WaitResult = WAIT_FAILED then
      RaiseLastOSError;
    if WaitResult <> WAIT_OBJECT_0 then
      raise Exception.CreateFmt('Unexpected build wait result: %d.',
        [WaitResult]);
    if not GetExitCodeProcess(ExecuteInfo.hProcess, ExitCode) then
      RaiseLastOSError;
    if ExitCode <> 0 then
      raise Exception.CreateFmt(
        'The %s %s build failed with exit code %d.',
        [APlatform, AConfiguration, ExitCode]);
  finally
    CloseHandle(ExecuteInfo.hProcess);
  end;
end;

class function TTargetBuildDeployer.FindBuildOutputDirectory(
  const AProjectFileName, AProjectName, APlatform, AConfiguration: string;
  ARequireExecutable: Boolean): string;
var
  Candidate: string;
  CandidateList: TStringList;
  ExecutableName: string;
  Match: TMatch;
  ProjectDirectory: string;
  ProjectText: string;
  OutputPattern: string;

  procedure AddCandidate(const APattern: string);
  var
    Expanded: string;
  begin
    Expanded := Trim(APattern);
    if Expanded = '' then
      Exit;
    Expanded := StringReplace(Expanded, '&amp;', '&',
      [rfReplaceAll, rfIgnoreCase]);
    Expanded := StringReplace(Expanded, '$(Platform)', APlatform,
      [rfReplaceAll, rfIgnoreCase]);
    Expanded := StringReplace(Expanded, '$(Config)', AConfiguration,
      [rfReplaceAll, rfIgnoreCase]);
    Expanded := StringReplace(Expanded, '$(PROJECTDIR)', ProjectDirectory,
      [rfReplaceAll, rfIgnoreCase]);
    Expanded := StringReplace(Expanded, '$(MSBuildProjectDirectory)',
      ProjectDirectory, [rfReplaceAll, rfIgnoreCase]);
    if Pos('$(', Expanded) > 0 then
      Exit;
    if not TPath.IsPathRooted(Expanded) then
      Expanded := TPath.Combine(ProjectDirectory, Expanded);
    Expanded := TPath.GetFullPath(Expanded);
    while (Length(Expanded) > 0) and
      CharInSet(Expanded[Length(Expanded)], ['\', '/']) do
      Delete(Expanded, Length(Expanded), 1);
    if (Expanded <> '') and (CandidateList.IndexOf(Expanded) < 0) then
      CandidateList.Add(Expanded);
  end;

  function IsUsable(const ADirectory: string): Boolean;
  begin
    Result := TDirectory.Exists(ADirectory) and
      ((not ARequireExecutable) or TFile.Exists(
        TPath.Combine(ADirectory, ExecutableName)));
  end;

begin
  ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);
  ExecutableName := AProjectName + '.exe';
  CandidateList := TStringList.Create;
  try
    if TFile.Exists(AProjectFileName) then
    begin
      ProjectText := TFile.ReadAllText(AProjectFileName, TEncoding.UTF8);
      for Match in TRegEx.Matches(ProjectText,
        '<DCC_ExeOutput>(.*?)</DCC_ExeOutput>',
        [roIgnoreCase, roSingleLine]) do
      begin
        OutputPattern := Match.Groups[1].Value;
        AddCandidate(OutputPattern);
      end;
    end;
    { Some Delphi projects use the conventional bin tree; others use the
      project-root Platform\Configuration tree. Keep both supported. }
    AddCandidate(TPath.Combine('bin', TPath.Combine(APlatform,
      AConfiguration)));
    AddCandidate(TPath.Combine(APlatform, AConfiguration));

    for Candidate in CandidateList do
      if IsUsable(Candidate) then
        Exit(Candidate);
    if not ARequireExecutable then
      for Candidate in CandidateList do
        if TDirectory.Exists(Candidate) then
          Exit(Candidate);
    Result := '';
  finally
    CandidateList.Free;
  end;
end;

class function TTargetBuildDeployer.BuildAndDeploy(
  const AProjectFileName, AProjectName, APlatform, AConfiguration,
  APackageDirectory: string): string;
var
  BuildProjectFileName: string;
  DestinationDirectory: string;
  DestinationLanguageDirectory: string;
  ExecutableFileName: string;
  LanguagePackFileName: string;
  ProjectDirectory: string;
  SourceLanguageDirectory: string;
begin
  if not TFile.Exists(AProjectFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The target project was not found: %s', [AProjectFileName]);
  if not TFile.Exists(DelphiEnvironmentFile) then
    raise EFileNotFoundException.CreateFmt(
      'The Delphi environment file was not found: %s',
      [DelphiEnvironmentFile]);
  ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);
  BuildProjectFileName := AProjectFileName;
  if SameText(TPath.GetExtension(BuildProjectFileName), '.dpr') and
    TFile.Exists(TPath.ChangeExtension(BuildProjectFileName, '.dproj')) then
    BuildProjectFileName := TPath.ChangeExtension(
      BuildProjectFileName, '.dproj');
  RunElevatedBuild(BuildProjectFileName, APlatform, AConfiguration);
  DestinationDirectory := FindBuildOutputDirectory(BuildProjectFileName,
    AProjectName, APlatform, AConfiguration, True);
  if DestinationDirectory = '' then
    raise EFileNotFoundException.CreateFmt(
      'The %s %s build completed, but %s.exe was not found in the configured ' +
      'output folder. Checked the project output setting, bin\%s\%s, and ' +
      '%s\%s.', [APlatform, AConfiguration, AProjectName, APlatform,
      AConfiguration, APlatform, AConfiguration]);
  ExecutableFileName := TPath.Combine(DestinationDirectory,
    AProjectName + '.exe');

  SourceLanguageDirectory := TPath.Combine(
    APackageDirectory, 'Localization\Languages');
  DestinationLanguageDirectory := TPath.Combine(
    DestinationDirectory, 'Localization\Languages');
  TDirectory.CreateDirectory(DestinationLanguageDirectory);
  for LanguagePackFileName in TDirectory.GetFiles(
    SourceLanguageDirectory, '*.json') do
    TFile.Copy(LanguagePackFileName,
      TPath.Combine(DestinationLanguageDirectory,
        TPath.GetFileName(LanguagePackFileName)), True);
  Result := Format('%s %s built. Language packs deployed to %s.',
    [APlatform, AConfiguration, DestinationLanguageDirectory]);
end;

class function TTargetBuildDeployer.DeployBuildOutput(
  const AProjectFileName, AProjectName, APlatform, AConfiguration,
  ADestinationDirectory, APackageDirectory: string;
  AReplaceExecutable: Boolean): string;
var
  DestinationExecutable: string;
  DestinationLanguageDirectory: string;
  LanguagePackFileName: string;
  ProjectDirectory: string;
  SourceExecutable: string;
  SourceLanguageDirectory: string;
begin
  if not TFile.Exists(AProjectFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The target project was not found: %s', [AProjectFileName]);
  if not TDirectory.Exists(ADestinationDirectory) then
    TDirectory.CreateDirectory(ADestinationDirectory);
  ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);
  SourceExecutable := FindBuildOutputDirectory(AProjectFileName, AProjectName,
    APlatform, AConfiguration, True);
  if SourceExecutable = '' then
    raise EFileNotFoundException.CreateFmt(
      'The built executable %s was not found in the configured output folder, ' +
      'bin\%s\%s, or %s\%s.', [AProjectName + '.exe', APlatform,
      AConfiguration, APlatform, AConfiguration]);
  SourceExecutable := TPath.Combine(SourceExecutable, AProjectName + '.exe');
  DestinationExecutable := TPath.Combine(ADestinationDirectory,
    AProjectName + '.exe');
  if TFile.Exists(DestinationExecutable) and not AReplaceExecutable then
    raise EInOutError.CreateFmt(
      'The destination already contains %s. Enable the explicit replace/create authorization before deploying the executable.',
      [DestinationExecutable]);
  TFile.Copy(SourceExecutable, DestinationExecutable, True);
  SourceLanguageDirectory := TPath.Combine(APackageDirectory,
    'Localization\Languages');
  DestinationLanguageDirectory := TPath.Combine(ADestinationDirectory,
    'Localization\Languages');
  TDirectory.CreateDirectory(DestinationLanguageDirectory);
  for LanguagePackFileName in TDirectory.GetFiles(
    SourceLanguageDirectory, '*.json') do
    TFile.Copy(LanguagePackFileName,
      TPath.Combine(DestinationLanguageDirectory,
        TPath.GetFileName(LanguagePackFileName)), True);
  Result := Format('%s copied to %s. Language packs deployed to %s.',
    [AProjectName + '.exe', DestinationExecutable,
     DestinationLanguageDirectory]);
end;

end.
