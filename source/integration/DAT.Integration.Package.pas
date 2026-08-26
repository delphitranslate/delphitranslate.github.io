unit DAT.Integration.Package;

interface

uses
  DAT.Core.Types;

type
  TIntegrationPackageGenerator = class
  public
    class function Generate(const AProfile: TProjectProfile;
      const AOutputRoot, ARuntimeSourceDirectory: string): string; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  DAT.Core.RuntimePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Scan.Types,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack;

function PascalIdentifier(const AValue: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in AValue do
    if CharInSet(Character,
      ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Result := Result + Character;
  if (Result = '') or CharInSet(Result[1], ['0'..'9']) then
    Result := 'TranslatedApp' + Result;
end;

procedure CopyRuntimeUnit(const ASourceDirectory, ADestinationDirectory,
  AUnitName: string);
var
  SourceFileName: string;
begin
  SourceFileName := TPath.Combine(ASourceDirectory, AUnitName + '.pas');
  if not TFile.Exists(SourceFileName) then
    raise EFileNotFoundException.CreateFmt(
      'Runtime source unit not found: %s', [SourceFileName]);
  TFile.Copy(SourceFileName,
    TPath.Combine(ADestinationDirectory, AUnitName + '.pas'), True);
end;

procedure GenerateSourceLanguagePack(const AProfile: TProjectProfile;
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

function GeneratedUnitText(const AProfile: TProjectProfile;
  const ASourceLanguageCode: string): string;
var
  AdapterUnit: string;
  FormType: string;
  FormsUnit: string;
  UnitName: string;
begin
  UnitName := PascalIdentifier(AProfile.ProjectName) + '.Translation';
  if AProfile.Framework = tfVCL then
  begin
    AdapterUnit := 'DAT.Runtime.VCL';
    FormsUnit := 'Vcl.Forms';
    FormType := 'TCustomForm';
  end
  else
  begin
    AdapterUnit := 'DAT.Runtime.FMX';
    FormsUnit := 'FMX.Forms';
    FormType := 'TCommonCustomForm';
  end;

  Result :=
    'unit ' + UnitName + ';' + sLineBreak + sLineBreak +
    'interface' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  System.SysUtils,' + sLineBreak +
    '  ' + FormsUnit + ',' + sLineBreak +
    '  DAT.Runtime.Manager,' + sLineBreak +
    '  ' + AdapterUnit + ';' + sLineBreak + sLineBreak +
    'procedure InitializeTranslation;' + sLineBreak +
    'procedure ApplyTranslation(const AForm: ' + FormType + ');' + sLineBreak +
    'procedure ApplyTranslationToOpenForms;' + sLineBreak +
    'function SelectLanguage(const ALanguageCode: string): Boolean;' + sLineBreak +
    'function SelectLanguageMenuItem(const AMenuItemName: string): Boolean;' + sLineBreak +
    'function TranslateText(const AKey, AFallbackText: string): string;' + sLineBreak +
    'function TranslateFormat(const AKey, AFallbackText: string;' + sLineBreak +
    '  const AArgs: array of const): string;' + sLineBreak +
    'function ActiveLanguageCode: string;' + sLineBreak +
    'function ActiveTextDirection: string;' + sLineBreak +
    'function TranslationRuntime: TTranslationRuntime;' + sLineBreak + sLineBreak +
    'implementation' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  System.IOUtils;' + sLineBreak + sLineBreak +
    'var' + sLineBreak +
    '  ApplicationTranslationRuntime: TTranslationRuntime;' + sLineBreak + sLineBreak +
    'procedure InitializeTranslation;' + sLineBreak +
    'var' + sLineBreak +
    '  ApplicationDirectory: string;' + sLineBreak +
    '  LocalApplicationData: string;' + sLineBreak +
    '  PreferenceDirectory: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  ApplicationDirectory := ExtractFilePath(ParamStr(0));' + sLineBreak +
    '  LocalApplicationData := GetEnvironmentVariable(''LOCALAPPDATA'');' + sLineBreak +
    '  if LocalApplicationData = '''' then' + sLineBreak +
    '    LocalApplicationData := TPath.GetHomePath;' + sLineBreak +
    '  PreferenceDirectory := TPath.Combine(LocalApplicationData,' + sLineBreak +
    '    ''' + PascalIdentifier(AProfile.ProjectName) + ''');' + sLineBreak +
    '  ApplicationTranslationRuntime.Free;' + sLineBreak +
    '  ApplicationTranslationRuntime := TTranslationRuntime.Create(' + sLineBreak +
    '    ''' + AProfile.ProjectName + ''',' + sLineBreak +
    '    TPath.Combine(ApplicationDirectory, ''Localization\Languages''),' + sLineBreak +
    '    TPath.Combine(PreferenceDirectory, ''language.ini''),' + sLineBreak +
    '    ''' + ASourceLanguageCode + ''');' + sLineBreak +
    '  ApplicationTranslationRuntime.LoadPreferredLanguage;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure ApplyTranslation(const AForm: ' + FormType + ');' + sLineBreak +
    'begin' + sLineBreak +
    '  if (AForm <> nil) and' + sLineBreak +
    '    (ApplicationTranslationRuntime <> nil) and' + sLineBreak +
    '    (ApplicationTranslationRuntime.ActivePack <> nil) then' + sLineBreak;

  if AProfile.Framework = tfVCL then
    Result := Result +
      '    TVCLTranslationApplicator.ApplyToForm(AForm,' + sLineBreak
  else
    Result := Result +
      '    TFMXTranslationApplicator.ApplyToForm(AForm,' + sLineBreak;

  Result := Result +
    '      ApplicationTranslationRuntime.ActivePack);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure ApplyTranslationToOpenForms;' + sLineBreak +
    'var' + sLineBreak +
    '  FormIndex: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  for FormIndex := 0 to Screen.FormCount - 1 do' + sLineBreak +
    '    ApplyTranslation(Screen.Forms[FormIndex]);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function SelectLanguage(const ALanguageCode: string): Boolean;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := (ApplicationTranslationRuntime <> nil) and' + sLineBreak +
    '    ApplicationTranslationRuntime.LoadLanguage(ALanguageCode);' + sLineBreak +
    '  if Result then' + sLineBreak +
    '    ApplyTranslationToOpenForms;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function SelectLanguageMenuItem(const AMenuItemName: string): Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  LanguageCode: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  LanguageCode := Copy(AMenuItemName, Length(''datLanguage_'') + 1,' +
      ' MaxInt);' + sLineBreak +
    '  LanguageCode := StringReplace(LanguageCode, ''_'', ''-'',' +
      ' [rfReplaceAll]);' + sLineBreak +
    '  Result := SelectLanguage(LanguageCode);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function TranslateText(const AKey, AFallbackText: string): string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if ApplicationTranslationRuntime = nil then' + sLineBreak +
    '    Result := AFallbackText' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := ApplicationTranslationRuntime.Translate(AKey, AFallbackText);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function TranslateFormat(const AKey, AFallbackText: string;' + sLineBreak +
    '  const AArgs: array of const): string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if ApplicationTranslationRuntime = nil then' + sLineBreak +
    '    Result := Format(AFallbackText, AArgs)' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := ApplicationTranslationRuntime.FormatTemplate(AKey,' + sLineBreak +
    '      AFallbackText, AArgs);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function ActiveLanguageCode: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ApplicationTranslationRuntime <> nil) and' + sLineBreak +
    '    (ApplicationTranslationRuntime.ActivePack <> nil) then' + sLineBreak +
    '    Result := ApplicationTranslationRuntime.ActivePack.LanguageCode' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := ''' + ASourceLanguageCode + ''';' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function ActiveTextDirection: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ApplicationTranslationRuntime <> nil) and' + sLineBreak +
    '    (ApplicationTranslationRuntime.ActivePack <> nil) and' + sLineBreak +
    '    SameText(ApplicationTranslationRuntime.ActivePack.TextDirection,' + sLineBreak +
    '      ''rtl'') then' + sLineBreak +
    '    Result := ''rtl''' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := ''ltr'';' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function TranslationRuntime: TTranslationRuntime;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ApplicationTranslationRuntime;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'initialization' + sLineBreak +
    '  ApplicationTranslationRuntime := nil;' + sLineBreak + sLineBreak +
    'finalization' + sLineBreak +
    '  ApplicationTranslationRuntime.Free;' + sLineBreak + sLineBreak +
    'end.' + sLineBreak;
end;

class function TIntegrationPackageGenerator.Generate(
  const AProfile: TProjectProfile; const AOutputRoot,
  ARuntimeSourceDirectory: string): string;
var
  AdapterUnit: string;
  Descriptor: TLanguagePackDescriptor;
  JsonArray: TJSONArray;
  JsonObject: TJSONObject;
  Languages: TObjectList<TLanguagePackDescriptor>;
  LanguagesDirectory: string;
  PackageLanguagesDirectory: string;
  PackageDirectory: string;
  RuntimeDirectory: string;
  SourceLanguageCode: string;
  UnitFileName: string;
  DeploymentScript: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('Open a Delphi project first.');

  PackageDirectory := TPath.Combine(AOutputRoot,
    PascalIdentifier(AProfile.ProjectName));
  RuntimeDirectory := TPath.Combine(PackageDirectory, 'Runtime');
  TDirectory.CreateDirectory(RuntimeDirectory);

  CopyRuntimeUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Runtime.LanguagePack');
  CopyRuntimeUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Runtime.Preference');
  CopyRuntimeUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Runtime.Manager');
  if AProfile.Framework = tfVCL then
    AdapterUnit := 'DAT.Runtime.VCL'
  else
    AdapterUnit := 'DAT.Runtime.FMX';
  CopyRuntimeUnit(ARuntimeSourceDirectory, RuntimeDirectory, AdapterUnit);

  PackageLanguagesDirectory := TPath.Combine(
    PackageDirectory, 'Localization\Languages');
  TDirectory.CreateDirectory(PackageLanguagesDirectory);
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
  GenerateSourceLanguagePack(AProfile,
    TPath.Combine(PackageLanguagesDirectory, 'en-US.json'));

  Languages := TLanguagePackDiscovery.Discover(
    PackageLanguagesDirectory, AProfile.ProjectName);
  try
    SourceLanguageCode := 'en-US';
    if Languages.Count > 0 then
      SourceLanguageCode := Languages[0].SourceLanguage;

    UnitFileName := TPath.Combine(PackageDirectory,
      PascalIdentifier(AProfile.ProjectName) + '.Translation.pas');
    TFile.WriteAllText(UnitFileName,
      GeneratedUnitText(AProfile, SourceLanguageCode), TEncoding.UTF8);

    JsonArray := TJSONArray.Create;
    try
      for Descriptor in Languages do
      begin
        JsonObject := TJSONObject.Create;
        JsonObject.AddPair('code', Descriptor.LanguageCode);
        JsonObject.AddPair('nativeName', Descriptor.NativeLanguageName);
        JsonObject.AddPair('fileName',
          TPath.GetFileName(Descriptor.FileName));
        JsonArray.AddElement(JsonObject);
      end;
      TFile.WriteAllText(TPath.Combine(PackageDirectory,
        'language-menu.json'), JsonArray.ToJSON, TEncoding.UTF8);
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
        'Write-Output ""Language packs deployed to $destination""' +
        sLineBreak;
      TFile.WriteAllText(TPath.Combine(PackageDirectory,
        'Deploy-LanguagePacks.ps1'), DeploymentScript, TEncoding.UTF8);
    finally
      JsonArray.Free;
    end;
  finally
    Languages.Free;
  end;

  Result := PackageDirectory;
end;

end.
