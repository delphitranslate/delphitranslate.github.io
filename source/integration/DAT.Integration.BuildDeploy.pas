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
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows;

const
  DelphiEnvironmentFile =
    'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat';
  BuildProcessTimeout = 1800000;
  ProcessTerminationWait = 5000;

procedure RunHiddenBuild(const AProjectFileName, APlatform,
  AConfiguration, APackageDirectory: string);
var
  CommandLine: string;
  ComponentSourceDirectory: string;
  ExitCode: Cardinal;
  SearchPathProperty: string;
  ProcessInfo: TProcessInformation;
  StartupInfo: TStartupInfo;
  WaitResult: Cardinal;
  WorkDirectory: string;
begin
  ComponentSourceDirectory := TPath.Combine(APackageDirectory,
    'ComponentSource');
  SearchPathProperty := '';
  if TDirectory.Exists(ComponentSourceDirectory) then
    SearchPathProperty := Format(
      ' /p:DCC_UnitSearchPath="%s;$(DCC_UnitSearchPath)"',
      [ComponentSourceDirectory]);
  CommandLine := Format(
    'cmd.exe /d /s /c ""%s" && msbuild "%s" /t:Build /p:Platform=%s /p:Config=%s%s"',
    [DelphiEnvironmentFile, AProjectFileName, APlatform, AConfiguration,
     SearchPathProperty]);
  WorkDirectory := TPath.GetDirectoryName(AProjectFileName);
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  if not CreateProcess(nil, PChar(CommandLine), nil, nil, False,
    CREATE_NO_WINDOW, nil, PChar(WorkDirectory), StartupInfo, ProcessInfo) then
    RaiseLastOSError;
  try
    CloseHandle(ProcessInfo.hThread);
    ProcessInfo.hThread := 0;
    WaitResult := WaitForSingleObject(ProcessInfo.hProcess,
      BuildProcessTimeout);
    if WaitResult = WAIT_TIMEOUT then
    begin
      TerminateProcess(ProcessInfo.hProcess, ERROR_TIMEOUT);
      WaitForSingleObject(ProcessInfo.hProcess, ProcessTerminationWait);
      raise Exception.CreateFmt(
        'The %s %s build timed out and its command process was stopped.',
        [APlatform, AConfiguration]);
    end;
    if WaitResult = WAIT_FAILED then
      RaiseLastOSError;
    if WaitResult <> WAIT_OBJECT_0 then
      raise Exception.CreateFmt('Unexpected build wait result: %d.',
        [WaitResult]);
    if not GetExitCodeProcess(ProcessInfo.hProcess, ExitCode) then
      RaiseLastOSError;
    if ExitCode <> 0 then
      raise Exception.CreateFmt(
        'The %s %s build failed with exit code %d.',
        [APlatform, AConfiguration, ExitCode]);
  finally
    if ProcessInfo.hThread <> 0 then
      CloseHandle(ProcessInfo.hThread);
    if ProcessInfo.hProcess <> 0 then
      CloseHandle(ProcessInfo.hProcess);
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
  var
    FullDirectory: string;
  begin
    FullDirectory := IncludeTrailingPathDelimiter(TPath.GetFullPath(ADirectory));
    Result := StartsText(IncludeTrailingPathDelimiter(ProjectDirectory),
      FullDirectory) and TDirectory.Exists(ADirectory) and
      ((not ARequireExecutable) or TFile.Exists(
        TPath.Combine(ADirectory, ExecutableName)));
  end;

begin
  ProjectDirectory := IncludeTrailingPathDelimiter(
    TPath.GetFullPath(TPath.GetDirectoryName(AProjectFileName)));
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
      begin
        { Candidate order is intentional: Delphi's DCC_ExeOutput comes first,
          followed by the common bin\Platform\Config and Platform\Config
          folders. Do not choose by newest timestamp; a stale executable in a
          different candidate folder can be newer than the real configured
          build output and would deploy the wrong EXE. }
        Exit(Candidate);
      end;
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
  RunHiddenBuild(BuildProjectFileName, APlatform, AConfiguration,
    APackageDirectory);
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
  SourceExecutable: string;
  SourceLanguageDirectory: string;
  ExecutableStatus: string;
  Attempt: Integer;
  CopySucceeded: Boolean;
  DestinationExisted: Boolean;
  DestinationSize: Int64;
  SourceSize: Int64;
begin
  if not TFile.Exists(AProjectFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The target project was not found: %s', [AProjectFileName]);
  for Attempt := 1 to 12 do
  begin
    try
      if not TDirectory.Exists(ADestinationDirectory) then
        TDirectory.CreateDirectory(ADestinationDirectory);
      if TDirectory.Exists(ADestinationDirectory) then
        Break;
    except
      if Attempt = 12 then
        raise;
    end;
    Sleep(500);
  end;
  SourceExecutable := FindBuildOutputDirectory(AProjectFileName, AProjectName,
    APlatform, AConfiguration, True);
  if SourceExecutable = '' then
    raise EFileNotFoundException.CreateFmt(
      'The built executable %s was not found in the configured output folder, ' +
      'bin\%s\%s, or %s\%s.', [AProjectName + '.exe', APlatform,
      AConfiguration, APlatform, AConfiguration]);
  SourceExecutable := TPath.Combine(SourceExecutable, AProjectName + '.exe');
  SourceSize := TFile.GetSize(SourceExecutable);
  DestinationExecutable := TPath.Combine(ADestinationDirectory,
    AProjectName + '.exe');
  DestinationExisted := TFile.Exists(DestinationExecutable);
  if DestinationExisted and not AReplaceExecutable then
  begin
    DestinationSize := TFile.GetSize(DestinationExecutable);
    ExecutableStatus := Format(
      'Executable left unchanged at %s (replace authorization was not selected). ' +
      'Source was %s (%d bytes); existing destination is %d bytes.',
      [DestinationExecutable, SourceExecutable, SourceSize, DestinationSize]);
  end
  else
  begin
    CopySucceeded := False;
    for Attempt := 1 to 8 do
    begin
      try
        TFile.Copy(SourceExecutable, DestinationExecutable, True);
        CopySucceeded := TFile.Exists(DestinationExecutable) and
          (TFile.GetSize(DestinationExecutable) =
           TFile.GetSize(SourceExecutable));
        if CopySucceeded then
          Break;
      except
        on E: EInOutError do
          if Attempt = 8 then
            raise;
      end;
      Sleep(500);
    end;
    if not CopySucceeded then
      raise EInOutError.CreateFmt(
        'The executable copy did not verify at %s. Source was %s (%d bytes).',
        [DestinationExecutable, SourceExecutable, SourceSize]);
    DestinationSize := TFile.GetSize(DestinationExecutable);
    if DestinationExisted then
      ExecutableStatus := Format(
        'Executable replaced at %s from %s (%d bytes verified).',
        [DestinationExecutable, SourceExecutable, DestinationSize])
    else
      ExecutableStatus := Format(
        'Executable created at %s from %s (%d bytes verified).',
        [DestinationExecutable, SourceExecutable, DestinationSize]);
  end;
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
  Result := Format('%s %s Language packs deployed to %s.',
    [ExecutableStatus, APlatform + ' ' + AConfiguration,
     DestinationLanguageDirectory]);
end;

end.
