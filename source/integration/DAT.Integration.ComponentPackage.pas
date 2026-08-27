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
    TDirectory.Delete(PreviousDirectory, True);
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
end;

class function TComponentIntegrationPackageGenerator.ConfigureProject(
  const AProfile: TProjectProfile; const AKitDirectory,
  ABackupDirectory: string): string;
begin
  raise EInvalidOpException.Create(
    'Automatic target project configuration is disabled. The translator treats target project files as read-only.');
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
    'Generating this kit does not modify the target project. The Setup Wizard ' +
      'writes catalogs, runtime packs, and this external component kit only. ' +
      'Pascal source, form resources, the DPR, and the DPROJ remain unchanged. ' +
      'Delphi performs package registration through its own Install Packages ' +
      'dialog. Never use the Install Component wizard and never select a .dpk.' +
      sLineBreak + sLineBreak +
    '1. In Delphi App Translation Studio, build the Integration plan and ' +
      'choose Show Design BPL. The Studio selects the stable verified ' +
      APackageName + ' under bin\packages\Win32\Release.' + sLineBreak +
    '2. Keep the target project closed while the Setup Wizard performs final processing. Then start RAD Studio without opening the target form.' + sLineBreak +
    '3. Choose Component > Install Packages, then choose Add.' + sLineBreak +
    '4. Select the exact design BPL shown by the Studio and choose Open.' +
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
    '11. For manual RAD Studio builds, add this kit''s ComponentSource folder ' +
      'to the project Search Path or install/use a common approved source ' +
      'location. The Wizard build button passes this path to MSBuild without ' +
      'editing the target project file.' + sLineBreak +
    '12. The Wizard deploys Localization\Languages during final processing ' +
      'and after Wizard-initiated builds. The included Deploy-LanguagePacks.ps1 ' +
      'script remains the manual fallback.' + sLineBreak +
    '13. Build and test Win32 and Win64. Changing the selector applies the ' +
      'language immediately and saves the preference.' + sLineBreak +
    '14. For a portable, network, or USB installation, enter its full ' +
      'application folder on the Wizard Deployment page. Final processing and ' +
      'Wizard-initiated builds deploy it whenever the destination is available. ' +
      'The component property stays relative as ' +
      'Localization\Languages.' + sLineBreak + sLineBreak +
    'Ordinary forms need no component. For inherited or unusually renamed ' +
      'forms, configure FormIdentityMappings on the manager using ' +
      'FormClass=ScannerFormRoot entries.' + sLineBreak + sLineBreak +
    'Automatic source integration remains an advanced Studio fallback. It is ' +
      'not used by this kit.' + sLineBreak;
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
  DesignPackageFileName: string;
  ScanItem: TScanItem;
  ScanResult: TProjectScanResult;
  SelectorClass: string;
  StagedDirectory: string;
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
  try
    TDirectory.CreateDirectory(ComponentDirectory);
    TDirectory.CreateDirectory(PackageLanguagesDirectory);

  if AProfile.Framework = tfVCL then
    DesignPackageFileName := 'DATLanguageManagerVCLDesign.bpl'
  else
    DesignPackageFileName := 'DATLanguageManagerFMXDesign.bpl';

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
