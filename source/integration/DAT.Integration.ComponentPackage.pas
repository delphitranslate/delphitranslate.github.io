unit DAT.Integration.ComponentPackage;

interface

uses
  DAT.Core.Types;

type
  TComponentIntegrationPackageGenerator = class
  public
    class function Generate(const AProfile: TProjectProfile;
      const AOutputRoot, ARuntimeSourceDirectory,
      AComponentSourceDirectory: string): string; static;
    class function ConfigureProject(const AProfile: TProjectProfile;
      const AKitDirectory, ABackupDirectory: string): string; static;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.AtomicFile,
  DAT.Core.RuntimePack,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Scan.Types;

function UniqueSiblingDirectory(const ADirectory, ASuffix: string): string;
var
  Identifier: TGUID;
begin
  CreateGUID(Identifier);
  Result := ADirectory + ASuffix + '-' +
    Copy(GUIDToString(Identifier), 2, 36);
end;

procedure PromoteStagedDirectory(const AStagedDirectory,
  AFinalDirectory: string);
var
  PreviousDirectory: string;
begin
  PreviousDirectory := AFinalDirectory + '.previous';
  if TDirectory.Exists(PreviousDirectory) then
  begin
    if TDirectory.Exists(AFinalDirectory) then
      TDirectory.Delete(PreviousDirectory, True)
    else
      TDirectory.Move(PreviousDirectory, AFinalDirectory);
  end;
  if TDirectory.Exists(AFinalDirectory) then
    TDirectory.Move(AFinalDirectory, PreviousDirectory);
  try
    TDirectory.Move(AStagedDirectory, AFinalDirectory);
  except
    if not TDirectory.Exists(AFinalDirectory) and
      TDirectory.Exists(PreviousDirectory) then
      TDirectory.Move(PreviousDirectory, AFinalDirectory);
    raise;
  end;
end;

procedure WriteIntegrityManifest(const ARootDirectory: string);
var
  FileName: string;
  Files: TStringList;
  JsonRoot: TJSONObject;
  RelativeName: string;
begin
  Files := TStringList.Create;
  JsonRoot := TJSONObject.Create;
  try
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    for FileName in TDirectory.GetFiles(ARootDirectory, '*',
      TSearchOption.soAllDirectories) do
      Files.Add(FileName);
    JsonRoot.AddPair('schemaVersion', TJSONNumber.Create(1));
    for FileName in Files do
    begin
      RelativeName := Copy(FileName,
        Length(IncludeTrailingPathDelimiter(ARootDirectory)) + 1, MaxInt);
      RelativeName := StringReplace(RelativeName, '\', '/', [rfReplaceAll]);
      JsonRoot.AddPair(RelativeName,
        LowerCase(THashSHA2.GetHashStringFromFile(FileName)));
    end;
    TAtomicTextFile.WriteAllText(TPath.Combine(ARootDirectory,
      'integrity-sha256.json'), JsonRoot.Format(2), TEncoding.UTF8);
  finally
    JsonRoot.Free;
    Files.Free;
  end;
end;

procedure ValidateComponentKit(const ARootDirectory,
  AApplicationId: string; AFramework: TTargetFramework);
const
  CommonUnits: array[0..8] of string = (
    'DAT.Runtime.LanguagePack.pas', 'DAT.Core.AtomicFile.pas',
    'DAT.Core.Diagnostics.pas', 'DAT.Runtime.Preference.pas',
    'DAT.Runtime.Manager.pas', 'DAT.Runtime.LayoutOverrides.pas',
    'DAT.Runtime.SplashTranslation.pas',
    'DAT.Runtime.TemplateRewrite.pas', 'DAT.Components.Core.pas');
var
  Descriptor: TLanguagePackDescriptor;
  FrameworkUnit: string;
  JsonRoot: TJSONObject;
  JsonText: string;
  Languages: TObjectList<TLanguagePackDescriptor>;
  LanguagesDirectory: string;
  UnitName: string;
  DesignPackageDirectory: string;
  PackageName: string;
begin
  JsonText := TFile.ReadAllText(TPath.Combine(ARootDirectory,
    'component-integration.json'), TEncoding.UTF8);
  JsonRoot := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  try
    if (JsonRoot = nil) or
      (JsonRoot.GetValue<Integer>('schemaVersion', 0) <> 1) or
      not SameText(JsonRoot.GetValue<string>('applicationId', ''),
        AApplicationId) or
      not SameText(JsonRoot.GetValue<string>('framework', ''),
        TargetFrameworkToString(AFramework)) then
      raise EInvalidOpException.Create(
        'The staged component integration manifest failed validation.');
  finally
    JsonRoot.Free;
  end;

  for UnitName in CommonUnits do
    if not TFile.Exists(TPath.Combine(TPath.Combine(ARootDirectory,
      'ComponentSource'), UnitName)) then
      raise EFileNotFoundException.CreateFmt(
        'The staged component kit is incomplete: %s', [UnitName]);
  if AFramework = tfVCL then
    FrameworkUnit := 'DAT.Components.VCL.pas'
  else
    FrameworkUnit := 'DAT.Components.FMX.pas';
  if not TFile.Exists(TPath.Combine(TPath.Combine(ARootDirectory,
    'ComponentSource'), FrameworkUnit)) then
    raise EFileNotFoundException.CreateFmt(
      'The staged component kit is incomplete: %s', [FrameworkUnit]);

  LanguagesDirectory := TPath.Combine(ARootDirectory,
    'Localization\Languages');
  Languages := TLanguagePackDiscovery.Discover(LanguagesDirectory,
    AApplicationId);
  try
    if (Languages.Count = 0) or
      (Languages.Count <> Length(TDirectory.GetFiles(LanguagesDirectory,
        '*.json', TSearchOption.soTopDirectoryOnly))) then
      raise EInvalidOpException.Create(
        'The staged component kit contains a missing or incompatible language pack.');
    for Descriptor in Languages do
      if not TFile.Exists(Descriptor.FileName) then
        raise EFileNotFoundException.Create(Descriptor.FileName);
  finally
    Languages.Free;
  end;

  DesignPackageDirectory := TPath.Combine(ARootDirectory,
    'DesignPackages\Win32\Release');
  for PackageName in ['DATLanguageManagerCoreRuntime.bpl',
    IfThen(AFramework = tfVCL, 'DATLanguageManagerVCLRuntime.bpl',
      'DATLanguageManagerFMXRuntime.bpl'),
    IfThen(AFramework = tfVCL, 'DATLanguageManagerVCLDesign.bpl',
      'DATLanguageManagerFMXDesign.bpl')] do
    if not TFile.Exists(TPath.Combine(DesignPackageDirectory, PackageName)) then
      raise EFileNotFoundException.CreateFmt(
        'The staged component kit is missing its verified package file: %s',
        [PackageName]);
end;

procedure CopyDirectoryContents(const ASourceDirectory,
  ADestinationDirectory: string);
var
  DestinationFileName: string;
  FileName: string;
  RelativeName: string;
begin
  if not TDirectory.Exists(ASourceDirectory) then
    raise EDirectoryNotFoundException.CreateFmt(
      'Required source directory not found: %s', [ASourceDirectory]);
  TDirectory.CreateDirectory(ADestinationDirectory);
  for FileName in TDirectory.GetFiles(ASourceDirectory, '*',
    TSearchOption.soAllDirectories) do
  begin
    RelativeName := Copy(FileName,
      Length(IncludeTrailingPathDelimiter(ASourceDirectory)) + 1, MaxInt);
    DestinationFileName := TPath.Combine(ADestinationDirectory, RelativeName);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(DestinationFileName));
    TFile.Copy(FileName, DestinationFileName, True);
    if not SameText(THashSHA2.GetHashStringFromFile(FileName),
      THashSHA2.GetHashStringFromFile(DestinationFileName)) then
      raise EInOutError.CreateFmt('Copied file failed verification: %s',
        [DestinationFileName]);
  end;
end;

function ManagedProjectBlock: string;
begin
  Result :=
    '    <!-- Delphi App Translation Studio managed integration: begin -->' +
      sLineBreak +
    '    <PropertyGroup>' + sLineBreak +
    '        <DCC_UnitSearchPath>$(MSBuildProjectDirectory)\dependencies\DelphiAppTranslation\source;$(DCC_UnitSearchPath)</DCC_UnitSearchPath>' +
      sLineBreak +
    '    </PropertyGroup>' + sLineBreak +
    '    <Import Project="dependencies\DelphiAppTranslation\deployment\DelphiAppTranslation.targets" Condition="Exists(''dependencies\DelphiAppTranslation\deployment\DelphiAppTranslation.targets'')"/>' +
      sLineBreak +
    '    <!-- Delphi App Translation Studio managed integration: end -->' +
      sLineBreak;
end;

function ProjectDeploymentTargets: string;
begin
  Result :=
    '<?xml version="1.0" encoding="utf-8"?>' + sLineBreak +
    '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
      sLineBreak +
    '  <PropertyGroup>' + sLineBreak +
    '    <DATExecutableOutput Condition="$([System.IO.Path]::IsPathRooted(''$(DCC_ExeOutput)''))">$(DCC_ExeOutput)</DATExecutableOutput>' +
      sLineBreak +
    '    <DATExecutableOutput Condition="!$([System.IO.Path]::IsPathRooted(''$(DCC_ExeOutput)''))">$(MSBuildProjectDirectory)\$(DCC_ExeOutput)</DATExecutableOutput>' +
      sLineBreak +
    '    <DATLanguagePackOutput>$(DATExecutableOutput)\Localization\Languages</DATLanguagePackOutput>' +
      sLineBreak +
    '  </PropertyGroup>' + sLineBreak +
    '  <ItemGroup>' + sLineBreak +
    '    <DATLanguagePack Include="$(MSBuildThisFileDirectory)Languages\*.json" />' +
      sLineBreak +
    '  </ItemGroup>' + sLineBreak +
    '  <Target Name="DATDeployLanguagePacks" AfterTargets="Build" Condition="''@(DATLanguagePack)'' != ''''">' +
      sLineBreak +
    '    <RemoveDir Directories="$(DATLanguagePackOutput)" Condition="Exists(''$(DATLanguagePackOutput)'')" />' +
      sLineBreak +
    '    <MakeDir Directories="$(DATLanguagePackOutput)" />' + sLineBreak +
    '    <Copy SourceFiles="@(DATLanguagePack)" DestinationFolder="$(DATLanguagePackOutput)" SkipUnchangedFiles="true" />' +
      sLineBreak +
    '    <Message Text="Delphi App Translation language packs deployed to $(DATLanguagePackOutput)" Importance="high" />' +
      sLineBreak +
    '  </Target>' + sLineBreak +
    '</Project>' + sLineBreak;
end;

class function TComponentIntegrationPackageGenerator.ConfigureProject(
  const AProfile: TProjectProfile; const AKitDirectory,
  ABackupDirectory: string): string;
const
  ManagedStart = '<!-- Delphi App Translation Studio managed integration: begin -->';
  ManagedEnd = '<!-- Delphi App Translation Studio managed integration: end -->';
var
  BackupRoot: string;
  BackupProjectFileName: string;
  DependencyDirectory: string;
  DependencyPreviousDirectory: string;
  DependencyStagedDirectory: string;
  DeploymentDirectory: string;
  EndAt: Integer;
  InsertAt: Integer;
  JsonRoot: TJSONObject;
  ProjectDirectory: string;
  ProjectFileName: string;
  ProjectText: string;
  SourceDirectory: string;
  StartAt: Integer;
  TransactionDirectory: string;
begin
  if not TDirectory.Exists(AKitDirectory) then
    raise EDirectoryNotFoundException.CreateFmt(
      'The component integration kit was not found: %s', [AKitDirectory]);
  ValidateComponentKit(AKitDirectory, AProfile.ProjectName,
    AProfile.Framework);

  ProjectFileName := AProfile.ProjectFileName;
  if SameText(TPath.GetExtension(ProjectFileName), '.dpr') then
    ProjectFileName := TPath.ChangeExtension(ProjectFileName, '.dproj');
  if not TFile.Exists(ProjectFileName) then
    raise EFileNotFoundException.CreateFmt(
      'The Delphi project options file was not found: %s', [ProjectFileName]);
  ProjectDirectory := TPath.GetDirectoryName(ProjectFileName);
  BackupRoot := Trim(ABackupDirectory);
  if BackupRoot = '' then
    BackupRoot := TPath.Combine(TPath.GetDocumentsPath,
      TPath.Combine('Delphi App Translation Backups', AProfile.ProjectName));
  TransactionDirectory := UniqueSiblingDirectory(TPath.Combine(BackupRoot,
    'Integration-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now)), '');
  TDirectory.CreateDirectory(TransactionDirectory);

  BackupProjectFileName := TPath.Combine(TransactionDirectory,
    TPath.GetFileName(ProjectFileName));
  TFile.Copy(ProjectFileName, BackupProjectFileName, True);
  if not SameText(THashSHA2.GetHashStringFromFile(ProjectFileName),
    THashSHA2.GetHashStringFromFile(BackupProjectFileName)) then
    raise EInOutError.Create('The DPROJ safety copy failed verification.');

  DependencyDirectory := TPath.Combine(ProjectDirectory,
    'dependencies\DelphiAppTranslation');
  DependencyPreviousDirectory := DependencyDirectory + '.previous';
  DependencyStagedDirectory := UniqueSiblingDirectory(DependencyDirectory,
    '.staging');
  if TDirectory.Exists(DependencyDirectory) then
    CopyDirectoryContents(DependencyDirectory,
      TPath.Combine(TransactionDirectory,
        'dependencies\DelphiAppTranslation'));

  try
    SourceDirectory := TPath.Combine(DependencyStagedDirectory, 'source');
    DeploymentDirectory := TPath.Combine(DependencyStagedDirectory,
      'deployment');
    CopyDirectoryContents(TPath.Combine(AKitDirectory, 'ComponentSource'),
      SourceDirectory);
    CopyDirectoryContents(TPath.Combine(AKitDirectory,
      'Localization\Languages'), TPath.Combine(DeploymentDirectory,
      'Languages'));
    TDirectory.CreateDirectory(DeploymentDirectory);
    TAtomicTextFile.WriteAllText(TPath.Combine(DeploymentDirectory,
      'DelphiAppTranslation.targets'), ProjectDeploymentTargets,
      TEncoding.UTF8);
    for SourceDirectory in ['LICENSE', 'component-integration.json',
      'README.txt'] do
      if TFile.Exists(TPath.Combine(AKitDirectory, SourceDirectory)) then
        TFile.Copy(TPath.Combine(AKitDirectory, SourceDirectory),
          TPath.Combine(DependencyStagedDirectory, SourceDirectory), True);

    JsonRoot := TJSONObject.Create;
    try
      JsonRoot.AddPair('schemaVersion', TJSONNumber.Create(1));
      JsonRoot.AddPair('managedBy', 'Delphi App Translation Studio');
      JsonRoot.AddPair('applicationId', AProfile.ProjectName);
      JsonRoot.AddPair('framework',
        TargetFrameworkToString(AProfile.Framework));
      JsonRoot.AddPair('projectFile', TPath.GetFileName(ProjectFileName));
      JsonRoot.AddPair('searchPath',
        'dependencies\DelphiAppTranslation\source');
      JsonRoot.AddPair('languagePackSource',
        'dependencies\DelphiAppTranslation\deployment\Languages');
      JsonRoot.AddPair('configuredAt', DateToISO8601(Now, False));
      TAtomicTextFile.WriteAllText(TPath.Combine(DependencyStagedDirectory,
        'integration-manifest.json'), JsonRoot.Format(2), TEncoding.UTF8);
    finally
      JsonRoot.Free;
    end;
    WriteIntegrityManifest(DependencyStagedDirectory);

    PromoteStagedDirectory(DependencyStagedDirectory, DependencyDirectory);
    ProjectText := TFile.ReadAllText(ProjectFileName, TEncoding.UTF8);
    StartAt := Pos(ManagedStart, ProjectText);
    if StartAt > 0 then
    begin
      EndAt := Pos(ManagedEnd, ProjectText);
      if EndAt < StartAt then
        raise EInvalidOpException.Create(
          'The existing managed DPROJ block is incomplete. Restore the project backup before retrying.');
      while (StartAt > 1) and
        not CharInSet(ProjectText[StartAt - 1], [#10, #13]) do
        Dec(StartAt);
      Delete(ProjectText, StartAt,
        EndAt + Length(ManagedEnd) - StartAt);
      Insert(ManagedProjectBlock, ProjectText, StartAt);
    end
    else
    begin
      InsertAt := Pos('</Project>', ProjectText);
      if InsertAt = 0 then
        raise EInvalidOpException.Create(
          'The DPROJ file has no closing Project element. No project change was retained.');
      Insert(ManagedProjectBlock, ProjectText, InsertAt);
    end;
    TAtomicTextFile.WriteAllText(ProjectFileName, ProjectText, TEncoding.UTF8);
    ProjectText := TFile.ReadAllText(ProjectFileName, TEncoding.UTF8);
    if (Pos(ManagedStart, ProjectText) = 0) or
      (Pos('dependencies\DelphiAppTranslation\source', ProjectText) = 0) or
      (Pos('DelphiAppTranslation.targets', ProjectText) = 0) then
      raise EInvalidOpException.Create(
        'The project automation block failed post-write validation.');
    if TDirectory.Exists(DependencyPreviousDirectory) then
      TDirectory.Delete(DependencyPreviousDirectory, True);
    Result := TransactionDirectory;
  except
    if TDirectory.Exists(DependencyStagedDirectory) then
      TDirectory.Delete(DependencyStagedDirectory, True);
    if TFile.Exists(BackupProjectFileName) then
      TAtomicTextFile.WriteAllText(ProjectFileName,
        TFile.ReadAllText(BackupProjectFileName, TEncoding.UTF8),
        TEncoding.UTF8);
    if TDirectory.Exists(DependencyDirectory) then
      TDirectory.Delete(DependencyDirectory, True);
    if TDirectory.Exists(DependencyPreviousDirectory) then
      TDirectory.Move(DependencyPreviousDirectory, DependencyDirectory);
    raise;
  end;
end;

function SafeDirectoryName(const AValue: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in AValue do
    if CharInSet(Character,
      ['A'..'Z', 'a'..'z', '0'..'9', '_', '-']) then
      Result := Result + Character;
  if Result = '' then
    Result := 'TranslatedApplication';
end;

procedure CopyUnit(const ASourceDirectory, ADestinationDirectory,
  AUnitName: string);
var
  SourceFileName: string;
begin
  SourceFileName := TPath.Combine(ASourceDirectory, AUnitName + '.pas');
  if not TFile.Exists(SourceFileName) then
    raise EFileNotFoundException.CreateFmt(
      'Component integration source unit not found: %s', [SourceFileName]);
  TFile.Copy(SourceFileName,
    TPath.Combine(ADestinationDirectory, AUnitName + '.pas'), True);
end;

procedure CopyCoreUnit(const ARuntimeSourceDirectory,
  ADestinationDirectory, AUnitName: string);
begin
  CopyUnit(TPath.Combine(TPath.GetDirectoryName(ARuntimeSourceDirectory),
    'core'), ADestinationDirectory, AUnitName);
end;

procedure GenerateSourcePack(const AProfile: TProjectProfile;
  const AFileName: string);
var
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  ScanResult: TProjectScanResult;
begin
  ScanResult := TProjectScanner.Scan(AProfile);
  Catalog := TTranslationCatalog.Create;
  try
    Catalog.ApplicationId := AProfile.ProjectName;
    Catalog.Framework := AProfile.Framework;
    Catalog.SourceLanguage := 'en-US';
    Catalog.Locale.LanguageCode := 'en-US';
    Catalog.Locale.NativeLanguageName := 'English';
    Catalog.Locale.TextDirection := 'ltr';
    Catalog.Locale.ShortDateFormat := 'M/d/yyyy';
    Catalog.Locale.LongDateFormat := 'dddd, MMMM d, yyyy';
    Catalog.Locale.ShortTimeFormat := 'h:mm tt';
    Catalog.Locale.LongTimeFormat := 'h:mm:ss tt';
    Catalog.Locale.DecimalSeparator := '.';
    Catalog.Locale.ThousandSeparator := ',';
    Catalog.Locale.CurrencySymbol := '$';
    TScanCatalogMerger.Merge(ScanResult, Catalog);
    for Entry in Catalog.Entries do
      if Entry.RuntimeApplication = rakAutomatic then
      begin
        Entry.TranslatedText := Entry.SourceText;
        Entry.Status := tsApproved;
        Entry.TranslationOrigin := torHuman;
      end
      else
        Entry.Status := tsExcluded;
    TRuntimePackBuilder.ExportToFile(Catalog, AFileName);
  finally
    Catalog.Free;
    ScanResult.Free;
  end;
end;

function FrameworkManagerClass(const AFramework: TTargetFramework): string;
begin
  if AFramework = tfVCL then
    Result := 'TDATVCLLanguageManager'
  else
    Result := 'TDATFMXLanguageManager';
end;

function FrameworkSelectorClass(const AFramework: TTargetFramework): string;
begin
  if AFramework = tfVCL then
    Result := 'TDATVCLLanguageComboBox'
  else
    Result := 'TDATFMXLanguageComboBox';
end;

function FrameworkPackageName(const AFramework: TTargetFramework): string;
begin
  if AFramework = tfVCL then
    Result := 'DATLanguageManagerVCLDesign.bpl'
  else
    Result := 'DATLanguageManagerFMXDesign.bpl';
end;

function SetupInstructions(const AProfile: TProjectProfile;
  const AManagerClass, ASelectorClass, APackageName: string): string;
begin
  Result :=
    'DELPHI APP TRANSLATION - COMPONENT INTEGRATION KIT' + sLineBreak +
    '==================================================' + sLineBreak + sLineBreak +
    'Target: ' + AProfile.ProjectName + sLineBreak +
    'Framework: ' + TargetFrameworkToString(AProfile.Framework) +
      sLineBreak + sLineBreak +
    'The Studio prepares the target project automatically from this kit. It ' +
      'installs the complete DAT source set under ' +
      'dependencies\DelphiAppTranslation\source, adds one marked Search Path ' +
      'and deployment block to the DPROJ, rebuilds the selected target, and ' +
      'deploys the language packs. Target Pascal, DPR, DFM, and FMX source ' +
      'remain developer-owned and are not rewritten.' +
      sLineBreak + sLineBreak +
    '1. Keep the target project closed while the Studio prepares it.' +
      sLineBreak +
    '2. After preparation, choose Show Design BPL. The Studio selects ' +
      'DesignPackages\Win32\Release\' + APackageName + ' inside this kit. ' +
      'The matching core and framework runtime BPLs are beside it.' + sLineBreak +
    '3. In RAD Studio choose Component > Install Packages, then choose Add.' +
      sLineBreak +
    '4. Select that exact design BPL and choose Open. Never use Install ' +
      'Component and never select a DPK.' +
      sLineBreak +
    '5. Confirm the DAT Language Manager package is checked, then choose OK.' +
      sLineBreak +
    '6. Open the target application and its primary form in the Form Designer.' +
      sLineBreak +
    '7. Place one ' + AManagerClass + ' from the DAT Localization palette page.' +
      sLineBreak +
    '8. Set ApplicationId to "' + AProfile.ProjectName + '".' + sLineBreak +
    '9. Leave LanguagesFolder as "Localization\Languages" and ' +
      'SourceLanguage as "en-US".' + sLineBreak +
    '10. Place one ' + ASelectorClass + '. In Object Inspector, set its ' +
      'LanguageManager property to the manager component. Do not leave this ' +
      'property blank. A visible selector is required unless the ' +
      'application provides an equivalent connected Language menu.' + sLineBreak +
    '11. No manual Search Path or language-pack copy is required. The marked ' +
      'DPROJ block points to the project-local dependency folder and its ' +
      'post-build target replaces the output pack set after every build.' +
      sLineBreak +
    '12. Build and test every platform and configuration you distribute. ' +
      'Changing the selector applies the ' +
      'language immediately and saves the preference.' + sLineBreak +
    '13. For a portable, network, or USB installation, enter its full ' +
      'application folder on the Wizard Deployment page. Final processing and ' +
      'Wizard-initiated builds deploy it whenever the destination is available. ' +
      'The component property stays relative as ' +
      'Localization\Languages.' + sLineBreak + sLineBreak +
    'Ordinary forms need no component. For inherited or unusually renamed ' +
      'forms, configure FormIdentityMappings on the manager using ' +
      'FormClass=ScannerFormRoot entries.' + sLineBreak + sLineBreak +
    'The only package-registration action left to the developer is adding the ' +
      'verified design BPL through RAD Studio. The Studio deliberately does ' +
      'not register IDE packages on the developer''s behalf.' + sLineBreak;
end;

class function TComponentIntegrationPackageGenerator.Generate(
  const AProfile: TProjectProfile; const AOutputRoot,
  ARuntimeSourceDirectory, AComponentSourceDirectory: string): string;
var
  ComponentDirectory: string;
  Descriptor: TLanguagePackDescriptor;
  DeploymentScript: string;
  FormRoots: TDictionary<string, Boolean>;
  JsonLanguages: TJSONArray;
  JsonObject: TJSONObject;
  JsonRoot: TJSONObject;
  JsonForms: TJSONArray;
  DeploymentDestinationsFileName: string;
  Languages: TObjectList<TLanguagePackDescriptor>;
  LanguagesDirectory: string;
  ManagerClass: string;
  PackageLanguagesDirectory: string;
  DesignPackageDirectory: string;
  DesignPackageFileName: string;
  PackageFileName: string;
  PackageSourceDirectory: string;
  ScanItem: TScanItem;
  ScanResult: TProjectScanResult;
  SelectorClass: string;
  StagedDirectory: string;
  StudioProjectRoot: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('Open a Delphi project first.');
  if AProfile.Framework = tfUnknown then
    raise EArgumentException.Create('The project framework is unknown.');

  Result := TPath.Combine(AOutputRoot,
    SafeDirectoryName(AProfile.ProjectName));
  StagedDirectory := UniqueSiblingDirectory(Result, '.staging');
  ComponentDirectory := TPath.Combine(StagedDirectory, 'ComponentSource');
  PackageLanguagesDirectory := TPath.Combine(StagedDirectory,
    'Localization\Languages');
  DesignPackageDirectory := TPath.Combine(StagedDirectory,
    'DesignPackages\Win32\Release');
  try
    TDirectory.CreateDirectory(ComponentDirectory);
    TDirectory.CreateDirectory(PackageLanguagesDirectory);
    TDirectory.CreateDirectory(DesignPackageDirectory);

  if AProfile.Framework = tfVCL then
    DesignPackageFileName := 'DATLanguageManagerVCLDesign.bpl'
  else
    DesignPackageFileName := 'DATLanguageManagerFMXDesign.bpl';

  StudioProjectRoot := TPath.GetDirectoryName(
    TPath.GetDirectoryName(ARuntimeSourceDirectory));
  PackageSourceDirectory := TPath.Combine(StudioProjectRoot,
    'bin\packages\Win32\Release');
  for PackageFileName in ['DATLanguageManagerCoreRuntime.bpl',
    IfThen(AProfile.Framework = tfVCL, 'DATLanguageManagerVCLRuntime.bpl',
      'DATLanguageManagerFMXRuntime.bpl'), DesignPackageFileName] do
  begin
    if not TFile.Exists(TPath.Combine(PackageSourceDirectory,
      PackageFileName)) then
      raise EFileNotFoundException.CreateFmt(
        'The verified RAD Studio package is missing: %s. Build the Studio release packages before generating the kit.',
        [TPath.Combine(PackageSourceDirectory, PackageFileName)]);
    TFile.Copy(TPath.Combine(PackageSourceDirectory, PackageFileName),
      TPath.Combine(DesignPackageDirectory, PackageFileName), True);
    if not SameText(THashSHA2.GetHashStringFromFile(TPath.Combine(
      PackageSourceDirectory, PackageFileName)),
      THashSHA2.GetHashStringFromFile(TPath.Combine(DesignPackageDirectory,
        PackageFileName))) then
      raise EInOutError.CreateFmt(
        'The copied RAD Studio package failed verification: %s',
        [PackageFileName]);
  end;
  if not TFile.Exists(TPath.Combine(StudioProjectRoot, 'LICENSE')) then
    raise EFileNotFoundException.Create(
      'The Apache 2.0 LICENSE file is missing from the Studio project root.');
  TFile.Copy(TPath.Combine(StudioProjectRoot, 'LICENSE'),
    TPath.Combine(StagedDirectory, 'LICENSE'), True);
  if not SameText(THashSHA2.GetHashStringFromFile(TPath.Combine(
    StudioProjectRoot, 'LICENSE')),
    THashSHA2.GetHashStringFromFile(TPath.Combine(StagedDirectory,
      'LICENSE'))) then
    raise EInOutError.Create(
      'The Apache 2.0 LICENSE copy failed verification.');

  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.LanguagePack');
  CopyCoreUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Core.AtomicFile');
  CopyCoreUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Core.Diagnostics');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.Preference');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.Manager');
  { Both applicators use it, so it ships whatever the framework is.
    Leaving it out compiles here and fails in the customer's project,
    which is the worst place to find out. }
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.LayoutOverrides');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.SplashTranslation');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.TemplateRewrite');
  CopyUnit(AComponentSourceDirectory, ComponentDirectory,
    'DAT.Components.Core');
  if AProfile.Framework = tfVCL then
  begin
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory, 'DAT.Runtime.VCL');
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
      'DAT.Runtime.SplashTranslation.VCL');
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
      'DAT.Runtime.TemplateRewrite.VCL');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.VCL');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.VCL.LanguageSelector');
  end
  else
  begin
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory, 'DAT.Runtime.FMX');
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
      'DAT.Runtime.SplashTranslation.FMX');
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
      'DAT.Runtime.TemplateRewrite.FMX');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.FMX');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.FMX.LanguageSelector');
  end;

  LanguagesDirectory := TTranslationWorkspace.LanguagesDirectory(AProfile);
  Languages := TLanguagePackDiscovery.Discover(
    LanguagesDirectory, AProfile.ProjectName);
  try
    for Descriptor in Languages do
      TFile.Copy(Descriptor.FileName,
        TPath.Combine(PackageLanguagesDirectory,
          TPath.GetFileName(Descriptor.FileName)), True);
  finally
    Languages.Free;
  end;
  GenerateSourcePack(AProfile, TPath.Combine(
    PackageLanguagesDirectory, 'en-US.json'));

  ManagerClass := FrameworkManagerClass(AProfile.Framework);
  SelectorClass := FrameworkSelectorClass(AProfile.Framework);
  TAtomicTextFile.WriteAllText(TPath.Combine(StagedDirectory, 'README.txt'),
    SetupInstructions(AProfile, ManagerClass, SelectorClass,
      FrameworkPackageName(AProfile.Framework)),
      TEncoding.UTF8);

  JsonRoot := TJSONObject.Create;
  JsonLanguages := TJSONArray.Create;
  JsonForms := TJSONArray.Create;
  try
    JsonRoot.AddPair('schemaVersion', TJSONNumber.Create(1));
    JsonRoot.AddPair('mode', 'component');
    JsonRoot.AddPair('applicationId', AProfile.ProjectName);
    JsonRoot.AddPair('framework', TargetFrameworkToString(AProfile.Framework));
    JsonRoot.AddPair('managerClass', ManagerClass);
    JsonRoot.AddPair('selectorClass', SelectorClass);
    JsonRoot.AddPair('designPackageName', DesignPackageFileName);
    JsonRoot.AddPair('designPackageRelativePath',
      'DesignPackages/Win32/Release/' + DesignPackageFileName);
    JsonRoot.AddPair('packageInstallationMethod',
      'Delphi Component > Install Packages > Add');
    JsonRoot.AddPair('languagesFolder', 'Localization\Languages');
    JsonRoot.AddPair('sourceLanguage', 'en-US');

    Languages := TLanguagePackDiscovery.Discover(
      PackageLanguagesDirectory, AProfile.ProjectName);
    try
      for Descriptor in Languages do
      begin
        JsonObject := TJSONObject.Create;
        JsonObject.AddPair('code', Descriptor.LanguageCode);
        JsonObject.AddPair('nativeName', Descriptor.NativeLanguageName);
        JsonObject.AddPair('fileName', TPath.GetFileName(
          Descriptor.FileName));
        JsonLanguages.AddElement(JsonObject);
      end;
    finally
      Languages.Free;
    end;
    JsonRoot.AddPair('languages', JsonLanguages);

    FormRoots := TDictionary<string, Boolean>.Create;
    ScanResult := TProjectScanner.Scan(AProfile);
    try
      for ScanItem in ScanResult.Items do
        if (ScanItem.Kind = stkFormProperty) and
          not FormRoots.ContainsKey(ScanItem.FormName) then
        begin
          FormRoots.Add(ScanItem.FormName, True);
          JsonForms.Add(ScanItem.FormName);
        end;
    finally
      ScanResult.Free;
      FormRoots.Free;
    end;
    JsonRoot.AddPair('scannerFormRoots', JsonForms);
    TAtomicTextFile.WriteAllText(TPath.Combine(StagedDirectory,
      'component-integration.json'), JsonRoot.Format(2), TEncoding.UTF8);
  finally
    JsonRoot.Free;
  end;

  DeploymentDestinationsFileName :=
    TTranslationWorkspace.DeploymentDestinationsFileName(AProfile);
  if TFile.Exists(DeploymentDestinationsFileName) then
    TFile.Copy(DeploymentDestinationsFileName,
      TPath.Combine(StagedDirectory, 'deployment-destinations.json'), True);

  DeploymentScript :=
    'param(' + sLineBreak +
    '  [Parameter(Mandatory=$true)][string]$ApplicationDirectory,' + sLineBreak +
    '  [string]$ProjectDirectory = '''',' + sLineBreak +
    '  [switch]$SkipConfiguredDestinations)' +
    sLineBreak + '$ErrorActionPreference = ''Stop''' + sLineBreak +
    'if (-not [System.IO.Path]::IsPathRooted($ApplicationDirectory)) {' +
      sLineBreak +
    '  if ([string]::IsNullOrWhiteSpace($ProjectDirectory)) {' + sLineBreak +
    '    $ProjectDirectory = (Get-Location).Path' + sLineBreak +
    '  }' + sLineBreak +
    '  $ApplicationDirectory = Join-Path $ProjectDirectory $ApplicationDirectory' +
      sLineBreak +
    '}' + sLineBreak +
    '$ApplicationDirectory = [System.IO.Path]::GetFullPath($ApplicationDirectory)' +
      sLineBreak +
    '$source = Join-Path $PSScriptRoot ''Localization\Languages''' +
      sLineBreak +
    '$manifestFile = Join-Path $PSScriptRoot ''integrity-sha256.json''' +
      sLineBreak +
    'if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) { throw ''Integrity manifest is missing.'' }' +
      sLineBreak +
    '$integrity = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json' +
      sLineBreak +
    'if ([int]$integrity.schemaVersion -ne 1) { throw ''Unsupported integrity manifest schema.'' }' +
      sLineBreak +
    'function Deploy-LanguagePacks([string]$TargetDirectory) {' +
      sLineBreak +
    '  $resolvedTarget = [System.IO.Path]::GetFullPath($TargetDirectory)' +
      sLineBreak +
    '  $localization = Join-Path $resolvedTarget ''Localization''' +
      sLineBreak +
    '  $destination = Join-Path $resolvedTarget ''Localization\Languages''' +
      sLineBreak +
    '  $staging = Join-Path $localization (''Languages.staging-'' + [guid]::NewGuid().ToString(''N''))' +
      sLineBreak +
    '  $previous = Join-Path $localization ''Languages.previous''' +
      sLineBreak +
    '  New-Item -ItemType Directory -Path $localization -Force | Out-Null' +
      sLineBreak +
    '  New-Item -ItemType Directory -Path $staging -Force | Out-Null' +
      sLineBreak +
    '  try {' + sLineBreak +
    '    $sourceFiles = @(Get-ChildItem -LiteralPath $source -Filter ''*.json'' -File)' +
      sLineBreak +
    '    if ($sourceFiles.Count -eq 0) { throw ''No language packs were found.'' }' +
      sLineBreak +
    '    foreach ($file in $sourceFiles) {' + sLineBreak +
    '      $relative = ''Localization/Languages/'' + $file.Name' + sLineBreak +
    '      $property = $integrity.PSObject.Properties[$relative]' + sLineBreak +
    '      if ($null -eq $property) { throw "No integrity entry for $relative" }' +
      sLineBreak +
    '      $expected = ([string]$property.Value).ToLowerInvariant()' + sLineBreak +
    '      $actual = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()' +
      sLineBreak +
    '      if ($actual -ne $expected) { throw "Source hash mismatch: $relative" }' +
      sLineBreak +
    '      $stagedFile = Join-Path $staging $file.Name' + sLineBreak +
    '      Copy-Item -LiteralPath $file.FullName -Destination $stagedFile' + sLineBreak +
    '      $copied = (Get-FileHash -LiteralPath $stagedFile -Algorithm SHA256).Hash.ToLowerInvariant()' +
      sLineBreak +
    '      if ($copied -ne $expected) { throw "Staged hash mismatch: $relative" }' +
      sLineBreak +
    '    }' + sLineBreak +
    '    if (Test-Path -LiteralPath $previous) { Remove-Item -LiteralPath $previous -Recurse -Force }' +
      sLineBreak +
    '    if (Test-Path -LiteralPath $destination) { Move-Item -LiteralPath $destination -Destination $previous }' +
      sLineBreak +
    '    try { Move-Item -LiteralPath $staging -Destination $destination }' +
      sLineBreak +
    '    catch {' + sLineBreak +
    '      if ((-not (Test-Path -LiteralPath $destination)) -and (Test-Path -LiteralPath $previous)) { Move-Item -LiteralPath $previous -Destination $destination }' +
      sLineBreak +
    '      throw' + sLineBreak +
    '    }' + sLineBreak +
    '    Write-Output "Language packs deployed and verified at $destination"' +
      sLineBreak +
    '  } finally {' + sLineBreak +
    '    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }' +
      sLineBreak +
    '  }' + sLineBreak +
    '}' + sLineBreak +
    'Deploy-LanguagePacks $ApplicationDirectory' + sLineBreak +
    'if (-not $SkipConfiguredDestinations) {' + sLineBreak +
    '  $settingsFile = Join-Path $PSScriptRoot ''deployment-destinations.json''' +
      sLineBreak +
    '  if (Test-Path -LiteralPath $settingsFile -PathType Leaf) {' +
      sLineBreak +
    '    $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json' +
      sLineBreak +
    '    foreach ($configuredDestination in @($settings.destinations)) {' +
      sLineBreak +
    '      if ([string]::IsNullOrWhiteSpace([string]$configuredDestination)) { continue }' +
      sLineBreak +
    '      if (Test-Path -LiteralPath $configuredDestination -PathType Container) {' +
      sLineBreak +
    '        if ([System.IO.Path]::GetFullPath($configuredDestination) -ne $ApplicationDirectory) {' +
      sLineBreak +
    '          Deploy-LanguagePacks $configuredDestination' + sLineBreak +
    '        }' + sLineBreak +
    '      } else {' + sLineBreak +
    '        Write-Warning "Configured application folder is unavailable; deployment skipped: $configuredDestination"' +
      sLineBreak +
    '      }' + sLineBreak +
    '    }' + sLineBreak +
    '  }' + sLineBreak +
    '}' + sLineBreak;
  TAtomicTextFile.WriteAllText(TPath.Combine(StagedDirectory,
    'Deploy-LanguagePacks.ps1'), DeploymentScript, TEncoding.UTF8);
    ValidateComponentKit(StagedDirectory, AProfile.ProjectName,
      AProfile.Framework);
    WriteIntegrityManifest(StagedDirectory);
    PromoteStagedDirectory(StagedDirectory, Result);
  except
    if TDirectory.Exists(StagedDirectory) then
      TDirectory.Delete(StagedDirectory, True);
    raise;
  end;
end;

end.
