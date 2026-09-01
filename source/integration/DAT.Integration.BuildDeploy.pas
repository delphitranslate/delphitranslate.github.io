unit DAT.Integration.BuildDeploy;

interface

uses
  System.Classes,
  DAT.Core.Types;

type
  TGlossaryPublishResult = class
  private
    FAppliedEntryCount: Integer;
    FUnmatchedTermCount: Integer;
    FDeployedDestinationCount: Integer;
    FFailedDestinationCount: Integer;
    FCatalogFileName: string;
    FRuntimePackFileName: string;
    FMessages: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Summary: string;
    property AppliedEntryCount: Integer read FAppliedEntryCount;
    property UnmatchedTermCount: Integer read FUnmatchedTermCount;
    property DeployedDestinationCount: Integer read FDeployedDestinationCount;
    property FailedDestinationCount: Integer read FFailedDestinationCount;
    property CatalogFileName: string read FCatalogFileName;
    property RuntimePackFileName: string read FRuntimePackFileName;
    property Messages: TStringList read FMessages;
  end;

  TGlossaryPublisher = class
  public
    class function Publish(const AProfile: TProjectProfile;
      const AGlossaryFileName, ALayoutProposalFileName: string):
      TGlossaryPublishResult; static;
  end;

  TTargetBuildDeployer = class
  public
    class function FindBuildOutputDirectory(const AProjectFileName,
      AProjectName, APlatform, AConfiguration: string;
      ARequireExecutable: Boolean = False): string; static;
    class function ExistingBuildOutputDirectories(const AProjectFileName,
      AProjectName: string; ASupportsWin32, ASupportsWin64: Boolean):
      TArray<string>; static;
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
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.RegularExpressions,
  System.StrUtils,
  System.SysUtils,
  System.Win.Registry,
  DAT.Core.CatalogJson,
  DAT.Core.Glossary,
  DAT.Core.RuntimePack,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack,
  DAT.Validation.Catalog,
  Winapi.Windows;

const
  BuildProcessTimeout = 1800000;
  ProcessTerminationWait = 5000;

constructor TGlossaryPublishResult.Create;
begin
  inherited Create;
  FMessages := TStringList.Create;
end;

destructor TGlossaryPublishResult.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

function TGlossaryPublishResult.Summary: string;
begin
  Result := Format(
    '%d catalog entr%s updated; %d unmatched glossary term(s); ' +
    '%d destination(s) deployed',
    [FAppliedEntryCount,
     IfThen(FAppliedEntryCount = 1, 'y', 'ies'),
     FUnmatchedTermCount, FDeployedDestinationCount]);
  if FFailedDestinationCount > 0 then
    Result := Result + Format('; %d destination(s) failed',
      [FFailedDestinationCount])
  else
    Result := Result + '.';
end;

class function TGlossaryPublisher.Publish(const AProfile: TProjectProfile;
  const AGlossaryFileName, ALayoutProposalFileName: string):
  TGlossaryPublishResult;
var
  ApprovedTermCount: Integer;
  ArrayValue: TJSONValue;
  Catalog: TTranslationCatalog;
  DependencyLanguageDirectory: string;
  DependencyPackFileName: string;
  DeploymentFileName: string;
  Destinations: TJSONArray;
  Glossary: TProjectGlossary;
  JsonValue: TJSONValue;
  OutputDirectory: string;
  ProjectDirectory: string;
  RememberedDestinations: TStringList;
  Root: TJSONObject;
  SeenDestinations: TStringList;
  Term: TProjectGlossaryTerm;
  Validation: TCatalogValidationResult;

  procedure DeployToApplicationDirectory(const ADirectory,
    ADescription: string);
  var
    DestinationDirectory: string;
    NormalizedDirectory: string;
  begin
    NormalizedDirectory := Trim(ADirectory);
    if NormalizedDirectory = '' then
      Exit;
    try
      NormalizedDirectory := TPath.GetFullPath(NormalizedDirectory);
      if SeenDestinations.IndexOf(NormalizedDirectory) >= 0 then
        Exit;
      SeenDestinations.Add(NormalizedDirectory);
      if not TDirectory.Exists(NormalizedDirectory) then
      begin
        Result.FMessages.Add(ADescription + ' unavailable; skipped: ' +
          NormalizedDirectory);
        Exit;
      end;
      DestinationDirectory := TPath.Combine(NormalizedDirectory,
        'Localization\Languages');
      TTargetBuildDeployer.DeployLanguagePacks(
        DependencyLanguageDirectory, DestinationDirectory,
        AProfile.ProjectName);
      Inc(Result.FDeployedDestinationCount);
      Result.FMessages.Add(ADescription + ' updated: ' +
        DestinationDirectory);
    except
      on E: Exception do
      begin
        Inc(Result.FFailedDestinationCount);
        Result.FMessages.Add(ADescription + ' failed: ' +
          NormalizedDirectory + ' (' + E.Message + ')');
      end;
    end;
  end;

begin
  Result := TGlossaryPublishResult.Create;
  Catalog := nil;
  Glossary := nil;
  RememberedDestinations := TStringList.Create;
  SeenDestinations := TStringList.Create;
  try
    try
      SeenDestinations.CaseSensitive := False;
      SeenDestinations.Sorted := True;
      SeenDestinations.Duplicates := dupIgnore;
      if not TFile.Exists(AProfile.ProjectFileName) then
        raise EFileNotFoundException.Create(
          'The selected Delphi project is no longer available.');
    if Trim(AProfile.ProjectName) = '' then
      raise EArgumentException.Create('The application identity is missing.');
    if not TFile.Exists(AGlossaryFileName) then
      raise EFileNotFoundException.CreateFmt(
        'The saved project glossary was not found: %s',
        [AGlossaryFileName]);

    Glossary := TProjectGlossary.LoadFromFile(AGlossaryFileName);
    if (Trim(Glossary.ApplicationId) <> '') and
      not SameText(Glossary.ApplicationId, AProfile.ProjectName) then
      raise EInvalidOpException.Create(
        'The glossary belongs to a different application.');
    if Trim(Glossary.TargetLanguage) = '' then
      raise EInvalidOpException.Create(
        'The glossary does not identify its target language.');
    ApprovedTermCount := 0;
    for Term in Glossary.Terms do
      if Term.Approved and (Trim(Term.SourceText) <> '') and
        (Trim(Term.TargetText) <> '') then
        Inc(ApprovedTermCount);
    if ApprovedTermCount = 0 then
      raise EInvalidOpException.Create(
        'The glossary contains no approved terms to publish.');

    Result.FCatalogFileName :=
      TTranslationWorkspace.DevelopmentCatalogFileName(AProfile,
        Glossary.TargetLanguage);
    if not TFile.Exists(Result.FCatalogFileName) then
      raise EFileNotFoundException.CreateFmt(
        'The matching development catalog was not found. Complete the Setup ' +
        'Wizard once before publishing glossary changes: %s',
        [Result.FCatalogFileName]);
    Catalog := TCatalogJson.LoadFromFile(Result.FCatalogFileName);
    if not SameText(Catalog.ApplicationId, AProfile.ProjectName) then
      raise EInvalidOpException.Create(
        'The development catalog belongs to a different application.');
    if not SameText(Catalog.Locale.LanguageCode,
      Glossary.TargetLanguage) then
      raise EInvalidOpException.Create(
        'The development catalog belongs to a different language.');
    if (Catalog.Framework <> tfUnknown) and
      (Catalog.Framework <> AProfile.Framework) then
      raise EInvalidOpException.Create(
        'The development catalog framework does not match the open project.');

    ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
    DependencyLanguageDirectory := TPath.Combine(ProjectDirectory,
      'dependencies\DelphiAppTranslation\deployment\Languages');
    if not TDirectory.Exists(DependencyLanguageDirectory) then
      raise EDirectoryNotFoundException.CreateFmt(
        'The project dependency language-pack folder was not found. Complete ' +
        'the Setup Wizard once before publishing glossary changes: %s',
        [DependencyLanguageDirectory]);

    { Validate and retain remembered destinations before any catalog or pack
      is replaced. A damaged preference file therefore cannot leave a publish
      operation in a partially reported state. }
    DeploymentFileName :=
      TTranslationWorkspace.DeploymentDestinationsFileName(AProfile);
    if TFile.Exists(DeploymentFileName) then
    begin
      JsonValue := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(DeploymentFileName, TEncoding.UTF8));
      try
        if not (JsonValue is TJSONObject) then
          raise EConvertError.Create(
            'The saved deployment destinations file is invalid.');
        Root := TJSONObject(JsonValue);
        Destinations := Root.GetValue('destinations') as TJSONArray;
        if Destinations <> nil then
          for ArrayValue in Destinations do
          begin
            if not (ArrayValue is TJSONString) then
              raise EConvertError.Create(
                'The saved deployment destinations file contains an invalid path.');
            RememberedDestinations.Add(ArrayValue.Value);
          end;
      finally
        JsonValue.Free;
      end;
    end;

    Result.FAppliedEntryCount := Glossary.ApplyToCatalog(Catalog);
    Result.FUnmatchedTermCount :=
      Glossary.CountTermsMatchingNothing(Catalog);
    Validation := TCatalogValidator.Validate(Catalog);
    try
      if Validation.HasErrors then
        raise EInvalidOpException.CreateFmt(
          'Glossary publishing stopped because validation found %d blocking ' +
          'error(s). The existing catalog and deployed packs were left intact.',
          [Validation.CountBySeverity(vsError)]);
    finally
      Validation.Free;
    end;

    { Serialize before replacing any file. This validates the complete runtime
      structure, including an accepted layout proposal when one exists. }
    TRuntimePackBuilder.Serialize(Catalog, ALayoutProposalFileName);
    TCatalogJson.SaveToFile(Catalog, Result.FCatalogFileName);
    Result.FRuntimePackFileName := TTranslationWorkspace.RuntimePackFileName(
      AProfile, Glossary.TargetLanguage);
    TRuntimePackBuilder.ExportToFile(Catalog, Result.FRuntimePackFileName,
      ALayoutProposalFileName);
    DependencyPackFileName := TPath.Combine(DependencyLanguageDirectory,
      TPath.GetFileName(Result.FRuntimePackFileName));
    TRuntimePackBuilder.ExportToFile(Catalog, DependencyPackFileName,
      ALayoutProposalFileName);
    if not SameText(
      THashSHA2.GetHashStringFromFile(Result.FRuntimePackFileName),
      THashSHA2.GetHashStringFromFile(DependencyPackFileName)) then
      raise EInvalidOpException.Create(
        'The canonical and dependency runtime packs did not verify as identical.');
    Result.FMessages.Add('Glossary saved: ' + AGlossaryFileName);
    Result.FMessages.Add('Development catalog updated: ' +
      Result.FCatalogFileName);
    Result.FMessages.Add('Canonical runtime pack updated: ' +
      Result.FRuntimePackFileName);
    Result.FMessages.Add('Dependency runtime pack updated: ' +
      DependencyPackFileName);

    for OutputDirectory in
      TTargetBuildDeployer.ExistingBuildOutputDirectories(
        AProfile.ProjectFileName, AProfile.ProjectName,
        AProfile.SupportsWin32, AProfile.SupportsWin64) do
      DeployToApplicationDirectory(OutputDirectory, 'Existing build output');

    for OutputDirectory in RememberedDestinations do
      DeployToApplicationDirectory(OutputDirectory,
        'Remembered application destination');
    if Result.FDeployedDestinationCount = 0 then
      Result.FMessages.Add(
        'No existing build or remembered application destination was available; canonical and dependency packs are current.');
    except
      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Catalog.Free;
    Glossary.Free;
    RememberedDestinations.Free;
    SeenDestinations.Free;
  end;
end;

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

class function TTargetBuildDeployer.ExistingBuildOutputDirectories(
  const AProjectFileName, AProjectName: string; ASupportsWin32,
  ASupportsWin64: Boolean): TArray<string>;
const
  Configurations: array[0..1] of string = ('Debug', 'Release');
  Platforms: array[0..1] of string = ('Win32', 'Win64');
var
  Configuration: string;
  Match: TMatch;
  OutputDirectory: string;
  OutputPattern: string;
  Platform: string;
  ProjectDirectory: string;
  ProjectText: string;
  UniqueDirectories: TStringList;

  function PlatformSupported(const APlatform: string): Boolean;
  begin
    if SameText(APlatform, 'Win32') then
      Result := ASupportsWin32
    else
      Result := ASupportsWin64;
  end;

  procedure AddDirectory(const ADirectory: string);
  var
    NormalizedDirectory: string;
  begin
    if Trim(ADirectory) = '' then
      Exit;
    NormalizedDirectory := TPath.GetFullPath(ADirectory);
    if TDirectory.Exists(NormalizedDirectory) then
      UniqueDirectories.Add(NormalizedDirectory);
  end;

  procedure AddPattern(const APattern: string);
  var
    Candidate: string;
    LocalConfiguration: string;
    LocalPlatform: string;
  begin
    for LocalPlatform in Platforms do
    begin
      if not PlatformSupported(LocalPlatform) then
        Continue;
      for LocalConfiguration in Configurations do
      begin
        Candidate := Trim(APattern);
        Candidate := StringReplace(Candidate, '&amp;', '&',
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(Platform)', LocalPlatform,
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(Config)', LocalConfiguration,
          [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate, '$(PROJECTDIR)',
          ProjectDirectory, [rfReplaceAll, rfIgnoreCase]);
        Candidate := StringReplace(Candidate,
          '$(MSBuildProjectDirectory)', ProjectDirectory,
          [rfReplaceAll, rfIgnoreCase]);
        if Pos('$(', Candidate) > 0 then
          Continue;
        if not TPath.IsPathRooted(Candidate) then
          Candidate := TPath.Combine(ProjectDirectory, Candidate);
        AddDirectory(Candidate);
      end;
    end;
  end;

begin
  UniqueDirectories := TStringList.Create;
  try
    UniqueDirectories.CaseSensitive := False;
    UniqueDirectories.Sorted := True;
    UniqueDirectories.Duplicates := dupIgnore;
    ProjectDirectory := TPath.GetDirectoryName(AProjectFileName);
    if TFile.Exists(AProjectFileName) then
    begin
      ProjectText := TFile.ReadAllText(AProjectFileName, TEncoding.UTF8);
      for Match in TRegEx.Matches(ProjectText,
        '<DCC_ExeOutput>(.*?)</DCC_ExeOutput>',
        [roIgnoreCase, roSingleLine]) do
      begin
        OutputPattern := Match.Groups[1].Value;
        AddPattern(OutputPattern);
      end;
    end;
    for Platform in Platforms do
    begin
      if not PlatformSupported(Platform) then
        Continue;
      for Configuration in Configurations do
      begin
        OutputDirectory := FindBuildOutputDirectory(AProjectFileName,
          AProjectName, Platform, Configuration, False);
        AddDirectory(OutputDirectory);
      end;
    end;
    Result := UniqueDirectories.ToStringArray;
  finally
    UniqueDirectories.Free;
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
