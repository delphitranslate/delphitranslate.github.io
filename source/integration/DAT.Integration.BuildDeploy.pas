unit DAT.Integration.BuildDeploy;

interface

type
  TTargetBuildDeployer = class
  public
    class function BuildAndDeploy(const AProjectFileName, AProjectName,
      APlatform, AConfiguration, APackageDirectory: string): string; static;
    class function DeployBuildOutput(const AProjectFileName, AProjectName,
      APlatform, AConfiguration, ADestinationDirectory,
      APackageDirectory: string; AReplaceExecutable: Boolean): string; static;
  end;

implementation

uses
  System.IOUtils,
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
  DestinationDirectory := TPath.Combine(ProjectDirectory,
    TPath.Combine('bin', TPath.Combine(APlatform, AConfiguration)));
  RunElevatedBuild(BuildProjectFileName, APlatform, AConfiguration);
  ExecutableFileName := TPath.Combine(
    DestinationDirectory, AProjectName + '.exe');
  if not TFile.Exists(ExecutableFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The build completed, but the expected executable was not found: %s. ' +
      'Set the target project output directory to bin\%s\%s.',
      [ExecutableFileName, APlatform, AConfiguration]);

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
  SourceExecutable := TPath.Combine(ProjectDirectory,
    TPath.Combine('bin', TPath.Combine(APlatform,
      TPath.Combine(AConfiguration, AProjectName + '.exe'))));
  if not TFile.Exists(SourceExecutable) then
    raise EFileNotFoundException.CreateFmt(
      'The built executable was not found: %s', [SourceExecutable]);
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
