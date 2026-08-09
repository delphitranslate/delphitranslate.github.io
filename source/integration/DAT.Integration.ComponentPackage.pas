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
  end;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  DAT.Core.RuntimePack,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Scan.Types;

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
    'This kit does not modify the target project. Delphi performs package ' +
      'registration through its own Install Packages dialog. Never use the ' +
      'Install Component wizard and never select a .dpk.' +
      sLineBreak + sLineBreak +
    '1. In Delphi App Translation Studio, build the Integration plan and ' +
      'choose Show Design BPL. The Studio selects the stable verified ' +
      APackageName + ' under bin\packages\Win32\Release.' + sLineBreak +
    '2. Start RAD Studio without opening the target form.' + sLineBreak +
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
    '10. Optionally place one ' + ASelectorClass + ' and set its ' +
      'LanguageManager property to the manager.' + sLineBreak +
    '11. Add this kit''s ComponentSource folder to the project Search Path, ' +
      'or reference the installed component source location.' + sLineBreak +
    '12. Copy Localization beside every built executable. The included ' +
      'Deploy-LanguagePacks.ps1 script can do this.' + sLineBreak +
    '13. Build and test Win32 and Win64. Changing the selector applies the ' +
      'language immediately and saves the preference.' + sLineBreak + sLineBreak +
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
  Languages: TObjectList<TLanguagePackDescriptor>;
  LanguagesDirectory: string;
  ManagerClass: string;
  PackageLanguagesDirectory: string;
  DesignPackageFileName: string;
  ScanItem: TScanItem;
  ScanResult: TProjectScanResult;
  SelectorClass: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('Open a Delphi project first.');
  if AProfile.Framework = tfUnknown then
    raise EArgumentException.Create('The project framework is unknown.');

  Result := TPath.Combine(AOutputRoot,
    SafeDirectoryName(AProfile.ProjectName));
  if TDirectory.Exists(Result) then
    TDirectory.Delete(Result, True);
  ComponentDirectory := TPath.Combine(Result, 'ComponentSource');
  PackageLanguagesDirectory := TPath.Combine(Result,
    'Localization\Languages');
  TDirectory.CreateDirectory(ComponentDirectory);
  TDirectory.CreateDirectory(PackageLanguagesDirectory);

  if AProfile.Framework = tfVCL then
    DesignPackageFileName := 'DATLanguageManagerVCLDesign.bpl'
  else
    DesignPackageFileName := 'DATLanguageManagerFMXDesign.bpl';

  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.LanguagePack');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.Preference');
  CopyUnit(ARuntimeSourceDirectory, ComponentDirectory,
    'DAT.Runtime.Manager');
  CopyUnit(AComponentSourceDirectory, ComponentDirectory,
    'DAT.Components.Core');
  if AProfile.Framework = tfVCL then
  begin
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory, 'DAT.Runtime.VCL');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.VCL');
    CopyUnit(AComponentSourceDirectory, ComponentDirectory,
      'DAT.Components.VCL.LanguageSelector');
  end
  else
  begin
    CopyUnit(ARuntimeSourceDirectory, ComponentDirectory, 'DAT.Runtime.FMX');
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
  TFile.WriteAllText(TPath.Combine(Result, 'README.txt'),
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
    TFile.WriteAllText(TPath.Combine(Result,
      'component-integration.json'), JsonRoot.Format(2), TEncoding.UTF8);
  finally
    JsonRoot.Free;
  end;

  DeploymentScript :=
    'param([Parameter(Mandatory=$true)][string]$ApplicationDirectory)' +
    sLineBreak + '$ErrorActionPreference = ''Stop''' + sLineBreak +
    '$source = Join-Path $PSScriptRoot ''Localization\Languages''' +
    sLineBreak +
    '$destination = Join-Path $ApplicationDirectory ''Localization\Languages''' +
    sLineBreak +
    'New-Item -ItemType Directory -Path $destination -Force | Out-Null' +
    sLineBreak +
    'Copy-Item -Path (Join-Path $source ''*.json'') -Destination $destination -Force' +
    sLineBreak +
    'Write-Output "Language packs deployed to $destination"' + sLineBreak;
  TFile.WriteAllText(TPath.Combine(Result, 'Deploy-LanguagePacks.ps1'),
    DeploymentScript, TEncoding.UTF8);
end;

end.
