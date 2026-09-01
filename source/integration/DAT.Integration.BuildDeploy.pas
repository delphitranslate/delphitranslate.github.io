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
    class procedure DeployLanguagePacks(const ASourceDirectory,
      ADestinationDirectory, AApplicationId: string); static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.RegularExpressions,
  System.StrUtils,
  System.SysUtils,
  System.Win.Registry,
  DAT.Runtime.LanguagePack,
  Winapi.Windows;

const
  BuildProcessTimeout = 1800000;
  ProcessTerminationWait = 5000;

function FindDelphiEnvironmentFile: string;
const
  RegistryBaseKey = '\Software\Embarcadero\BDS';
var
  BestVersion: Double;
  Candidate: string;
  ConfiguredRoot: string;
  Index: Integer;
  ParsedVersion: Double;
  Registry: TRegistry;
  RegistryRoot: HKEY;
  RegistryRootIndex: Integer;
  RootDirectory: string;
  VersionName: string;
  VersionNames: TStringList;
begin
  Result := '';

  { A developer may select a specific installation without changing a project
    file or this product. RAD Studio's own BDS environment variable is the
    next choice when the Studio was launched from its configured environment. }
  ConfiguredRoot := Trim(GetEnvironmentVariable('DAT_RAD_STUDIO_ROOT'));
  if ConfiguredRoot = '' then
    ConfiguredRoot := Trim(GetEnvironmentVariable('BDS'));
  if ConfiguredRoot <> '' then
  begin
    Candidate := TPath.Combine(ConfiguredRoot,
      TPath.Combine('bin', 'rsvars.bat'));
    if TFile.Exists(Candidate) then
      Exit(Candidate);
  end;

  { Otherwise use the newest installed RAD Studio registered on this machine.
    No Delphi release number or installation drive is assumed. }
  BestVersion := -1;
  VersionNames := TStringList.Create;
  Registry := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  try
    for RegistryRootIndex := 0 to 1 do
    begin
      if RegistryRootIndex = 0 then
        RegistryRoot := HKEY_CURRENT_USER
      else
        RegistryRoot := HKEY_LOCAL_MACHINE;
      Registry.RootKey := RegistryRoot;
      VersionNames.Clear;
      if not Registry.OpenKeyReadOnly(RegistryBaseKey) then
        Continue;
      try
        Registry.GetKeyNames(VersionNames);
      finally
        Registry.CloseKey;
      end;
      for Index := 0 to VersionNames.Count - 1 do
      begin
        VersionName := VersionNames[Index];
        if not TryStrToFloat(VersionName, ParsedVersion,
          TFormatSettings.Invariant) then
          Continue;
        if not Registry.OpenKeyReadOnly(RegistryBaseKey + '\' +
          VersionName) then
          Continue;
        try
          if not Registry.ValueExists('RootDir') then
            Continue;
          RootDirectory := Trim(Registry.ReadString('RootDir'));
        finally
          Registry.CloseKey;
        end;
        Candidate := TPath.Combine(RootDirectory,
          TPath.Combine('bin', 'rsvars.bat'));
        if TFile.Exists(Candidate) and (ParsedVersion > BestVersion) then
        begin
          BestVersion := ParsedVersion;
          Result := Candidate;
        end;
      end;
    end;
  finally
    Registry.Free;
    VersionNames.Free;
  end;
end;

function UniqueSiblingName(const APath, ASuffix: string): string;
var
  Identifier: TGUID;
begin
  CreateGUID(Identifier);
  Result := APath + ASuffix + '-' + Copy(GUIDToString(Identifier), 2, 36);
end;

function FileHash(const AFileName: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashStringFromFile(AFileName));
end;

procedure CopyFileVerified(const ASourceFileName,
  ADestinationFileName: string);
var
  SourceHash: string;
begin
  SourceHash := FileHash(ASourceFileName);
  TFile.Copy(ASourceFileName, ADestinationFileName, False);
  if not TFile.Exists(ADestinationFileName) or
    not SameText(SourceHash, FileHash(ADestinationFileName)) then
    raise EInOutError.CreateFmt('The staged copy failed hash validation: %s',
      [ADestinationFileName]);
end;

procedure PromoteStagedDirectory(const AStagedDirectory,
  ADestinationDirectory: string);
var
  PreviousDirectory: string;
begin
  PreviousDirectory := ADestinationDirectory + '.previous';
  if TDirectory.Exists(PreviousDirectory) then
    TDirectory.Delete(PreviousDirectory, True);
  if TDirectory.Exists(ADestinationDirectory) then
    TDirectory.Move(ADestinationDirectory, PreviousDirectory);
  try
    TDirectory.Move(AStagedDirectory, ADestinationDirectory);
  except
    if not TDirectory.Exists(ADestinationDirectory) and
      TDirectory.Exists(PreviousDirectory) then
      TDirectory.Move(PreviousDirectory, ADestinationDirectory);
    raise;
  end;
end;

procedure DeployLanguagePacksAtomic(const ASourceDirectory,
  ADestinationDirectory, AApplicationId: string);
var
  Descriptor: TLanguagePackDescriptor;
  DestinationFileName: string;
  Languages: TObjectList<TLanguagePackDescriptor>;
  SourceFiles: TArray<string>;
  SourceFileName: string;
  StagedDirectory: string;
  StagedLanguages: TObjectList<TLanguagePackDescriptor>;
begin
  if not TDirectory.Exists(ASourceDirectory) then
    raise EDirectoryNotFoundException.CreateFmt(
      'The language-pack source directory was not found: %s',
      [ASourceDirectory]);
  SourceFiles := TDirectory.GetFiles(ASourceDirectory, '*.json',
    TSearchOption.soTopDirectoryOnly);
  Languages := TLanguagePackDiscovery.Discover(ASourceDirectory,
    AApplicationId);
  try
    if (Languages.Count = 0) or (Languages.Count <> Length(SourceFiles)) then
      raise EInvalidOpException.Create(
        'Deployment stopped because a language pack is missing or incompatible.');
    for Descriptor in Languages do
      if not TFile.Exists(Descriptor.FileName) then
        raise EFileNotFoundException.Create(Descriptor.FileName);
  finally
    Languages.Free;
  end;

  StagedDirectory := UniqueSiblingName(ADestinationDirectory, '.staging');
  try
    TDirectory.CreateDirectory(StagedDirectory);
    for SourceFileName in SourceFiles do
    begin
      DestinationFileName := TPath.Combine(StagedDirectory,
        TPath.GetFileName(SourceFileName));
      CopyFileVerified(SourceFileName, DestinationFileName);
    end;
    StagedLanguages := TLanguagePackDiscovery.Discover(StagedDirectory,
      AApplicationId);
    try
      if StagedLanguages.Count <> Length(SourceFiles) then
        raise EInvalidOpException.Create(
          'The staged language packs failed compatibility validation.');
    finally
      StagedLanguages.Free;
    end;
    TDirectory.CreateDirectory(TPath.GetDirectoryName(
      ADestinationDirectory));
    PromoteStagedDirectory(StagedDirectory, ADestinationDirectory);
  except
    if TDirectory.Exists(StagedDirectory) then
      TDirectory.Delete(StagedDirectory, True);
    raise;
  end;
end;

procedure ReplaceFileAtomic(const ASourceFileName,
  ADestinationFileName: string);
var
  PreviousFileName: string;
  StagedFileName: string;
begin
  StagedFileName := UniqueSiblingName(ADestinationFileName, '.staging');
  PreviousFileName := ADestinationFileName + '.previous';
  try
    CopyFileVerified(ASourceFileName, StagedFileName);
    if TFile.Exists(ADestinationFileName) then
    begin
      if TFile.Exists(PreviousFileName) then
        TFile.Delete(PreviousFileName);
      TFile.Replace(StagedFileName, ADestinationFileName, PreviousFileName);
    end
    else
      TFile.Move(StagedFileName, ADestinationFileName);
    if not SameText(FileHash(ASourceFileName),
      FileHash(ADestinationFileName)) then
      raise EInOutError.CreateFmt(
        'The promoted file failed hash validation: %s',
        [ADestinationFileName]);
  finally
    if TFile.Exists(StagedFileName) then
      TFile.Delete(StagedFileName);
  end;
end;

{ The lines of a build log that say what went wrong.

  An MSBuild log for a failed Delphi build is mostly noise: the interesting
  part is the handful of lines carrying 'error' or a Delphi diagnostic code,
  and the first of those is almost always the real cause. Everything after
  the first few is usually the same fault repeated per unit. }
function BuildErrorSummary(const ALogFileName: string): string;
const
  MaximumLines = 12;
var
  Lines: TStringList;
  Line: string;
  Trimmed: string;
  Shown: Integer;
begin
  Result := '';
  if not TFile.Exists(ALogFileName) then
    Exit('The build wrote no log.');
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(ALogFileName);
    except
      Exit('The build log could not be read.');
    end;
    Shown := 0;
    for Line in Lines do
    begin
      Trimmed := Trim(Line);
      if Trimmed = '' then
        Continue;
      if (Pos('error', LowerCase(Trimmed)) = 0) and
        not TRegEx.IsMatch(Trimmed, '[EFH]\d{4}') then
        Continue;
      Result := Result + Trimmed + sLineBreak;
      Inc(Shown);
      if Shown >= MaximumLines then
      begin
        Result := Result + '... more in the log.' + sLineBreak;
        Break;
      end;
    end;
    if Shown = 0 then
      Result := 'The log names no error; the last lines of it are worth ' +
        'reading.' + sLineBreak;
  finally
    Lines.Free;
  end;
end;

procedure RunHiddenBuild(const AProjectFileName, APlatform,
  AConfiguration, APackageDirectory, AEnvironmentFile: string);
var
  CommandLine: string;
  ComponentSourceDirectory: string;
  ExitCode: Cardinal;
  SearchPathProperty: string;
  ProcessInfo: TProcessInformation;
  StartupInfo: TStartupInfo;
  WaitResult: Cardinal;
  WorkDirectory: string;
  LogFileName: string;
begin
  WorkDirectory := TPath.GetDirectoryName(AProjectFileName);
  ComponentSourceDirectory := TPath.Combine(WorkDirectory,
    'dependencies\DelphiAppTranslation\source');
  if not TDirectory.Exists(ComponentSourceDirectory) then
    ComponentSourceDirectory := TPath.Combine(APackageDirectory,
      'ComponentSource');
  if not TDirectory.Exists(ComponentSourceDirectory) then
    raise EDirectoryNotFoundException.CreateFmt(
      'The DAT dependency source folder was not found: %s',
      [TPath.Combine(WorkDirectory,
        'dependencies\DelphiAppTranslation\source')]);
  SearchPathProperty := Format(
    ' /p:DCC_UnitSearchPath="%s;$(DCC_UnitSearchPath)"',
    [ComponentSourceDirectory]);
  { The output goes to a file rather than nowhere.

    This used to run with the output discarded and report only the exit
    code, so a failed build said 'exit code 1' and stopped - leaving a
    developer with a broken run, no error text, and no way to find out
    what MSBuild had objected to. The compiler already says exactly what
    is wrong; it was simply being thrown away. }
  LogFileName := TPath.Combine(TPath.GetTempPath,
    Format('dat-build-%s-%s.log', [APlatform, AConfiguration]));
  CommandLine := Format(
    'cmd.exe /d /s /c ""%s" && msbuild "%s" /t:Build /p:Platform=%s /p:Config=%s%s > "%s" 2>&1"',
    [AEnvironmentFile, AProjectFileName, APlatform, AConfiguration,
     SearchPathProperty, LogFileName]);
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
        'The %s %s build failed with exit code %d.%s%s%sFull log: %s',
        [APlatform, AConfiguration, ExitCode, sLineBreak,
         BuildErrorSummary(LogFileName), sLineBreak, LogFileName]);
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
  CandidateIndex: Integer;
  ExecutableName: string;
  Match: TMatch;
  ProjectDirectory: string;
  ProjectText: string;
  OutputPattern: string;

  { ADeclared marks a folder the project file itself names, as opposed to one
    of the conventional folders we guess at below. }
  procedure AddCandidate(const APattern: string; const ADeclared: Boolean);
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
      CandidateList.AddObject(Expanded, TObject(Ord(ADeclared)));
  end;

  function IsUsable(const ADirectory: string;
    const ADeclared: Boolean): Boolean;
  var
    FullDirectory: string;
  begin
    FullDirectory := IncludeTrailingPathDelimiter(TPath.GetFullPath(ADirectory));
    { A folder the project file names is the project's own answer to where it
      builds, and a project may legitimately build to another drive. The
      containment test belongs to the folders we guess at, where straying
      outside the project tree would mean picking up an executable nobody
      asked for; applied to a declared path it rejects the real output and
      falls back silently to whatever stale copy sits in the tree, which is
      the worse failure by far because it looks like success. }
    Result := (ADeclared or
      StartsText(IncludeTrailingPathDelimiter(ProjectDirectory),
        FullDirectory)) and TDirectory.Exists(ADirectory) and
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
        AddCandidate(OutputPattern, True);
      end;
    end;
    { Some Delphi projects use the conventional bin tree; others use the
      project-root Platform\Configuration tree. Keep both supported. }
    AddCandidate(TPath.Combine('bin', TPath.Combine(APlatform,
      AConfiguration)), False);
    AddCandidate(TPath.Combine(APlatform, AConfiguration), False);

    for CandidateIndex := 0 to CandidateList.Count - 1 do
      if IsUsable(CandidateList[CandidateIndex],
        CandidateList.Objects[CandidateIndex] <> nil) then
      begin
        { Candidate order is intentional: Delphi's DCC_ExeOutput comes first,
          followed by the common bin\Platform\Config and Platform\Config
          folders. Do not choose by newest timestamp; a stale executable in a
          different candidate folder can be newer than the real configured
          build output and would deploy the wrong EXE. }
        Exit(CandidateList[CandidateIndex]);
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
  DelphiEnvironmentFileName: string;
  SourceLanguageDirectory: string;
begin
  if not TFile.Exists(AProjectFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The target project was not found: %s', [AProjectFileName]);
  DelphiEnvironmentFileName := FindDelphiEnvironmentFile;
  if DelphiEnvironmentFileName = '' then
    raise EFileNotFoundException.Create(
      'No RAD Studio environment was found. Set DAT_RAD_STUDIO_ROOT to the ' +
      'installed RAD Studio root directory and try again.');
  BuildProjectFileName := AProjectFileName;
  if SameText(TPath.GetExtension(BuildProjectFileName), '.dpr') and
    TFile.Exists(TPath.ChangeExtension(BuildProjectFileName, '.dproj')) then
    BuildProjectFileName := TPath.ChangeExtension(
      BuildProjectFileName, '.dproj');
  RunHiddenBuild(BuildProjectFileName, APlatform, AConfiguration,
    APackageDirectory, DelphiEnvironmentFileName);
  DestinationDirectory := FindBuildOutputDirectory(BuildProjectFileName,
    AProjectName, APlatform, AConfiguration, True);
  if DestinationDirectory = '' then
    raise EFileNotFoundException.CreateFmt(
      'The %s %s build completed, but %s.exe was not found in the configured ' +
      'output folder. Checked the project output setting, bin\%s\%s, and ' +
      '%s\%s.', [APlatform, AConfiguration, AProjectName, APlatform,
      AConfiguration, APlatform, AConfiguration]);
  SourceLanguageDirectory := TPath.Combine(
    APackageDirectory, 'Localization\Languages');
  DestinationLanguageDirectory := TPath.Combine(
    DestinationDirectory, 'Localization\Languages');
  DeployLanguagePacksAtomic(SourceLanguageDirectory,
    DestinationLanguageDirectory, AProjectName);
  Result := Format(
    '%s %s built with a temporary DAT dependency Search Path. Language packs deployed to %s.',
    [APlatform, AConfiguration, DestinationLanguageDirectory]);
end;

class procedure TTargetBuildDeployer.DeployLanguagePacks(
  const ASourceDirectory, ADestinationDirectory,
  AApplicationId: string);
begin
  DeployLanguagePacksAtomic(ASourceDirectory, ADestinationDirectory,
    AApplicationId);
end;

class function TTargetBuildDeployer.DeployBuildOutput(
  const AProjectFileName, AProjectName, APlatform, AConfiguration,
  ADestinationDirectory, APackageDirectory: string;
  AReplaceExecutable: Boolean): string;
var
  DestinationExecutable: string;
  DestinationLanguageDirectory: string;
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
        ReplaceFileAtomic(SourceExecutable, DestinationExecutable);
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
  DeployLanguagePacksAtomic(SourceLanguageDirectory,
    DestinationLanguageDirectory, AProjectName);
  Result := Format('%s %s Language packs deployed to %s.',
    [ExecutableStatus, APlatform + ' ' + AConfiguration,
     DestinationLanguageDirectory]);
end;

end.
