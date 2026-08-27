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
  System.Classes,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  DAT.Core.AtomicFile,
  DAT.Core.RuntimePack,
  DAT.Scan.CatalogMerge,
  DAT.Scan.Project,
  DAT.Scan.Types,
  DAT.Core.TranslationWorkspace,
  DAT.Runtime.LanguagePack;

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

procedure CopyCoreUnit(const ARuntimeSourceDirectory,
  ADestinationDirectory, AUnitName: string);
begin
  CopyRuntimeUnit(TPath.Combine(
    TPath.GetDirectoryName(ARuntimeSourceDirectory), 'core'),
    ADestinationDirectory, AUnitName);
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
    '    ''' + ASourceLanguageCode + ''',' + sLineBreak +
    '    ''' + TargetFrameworkToString(AProfile.Framework) + ''');' + sLineBreak +
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
  StagedDirectory: string;
  UnitFileName: string;
  DeploymentScript: string;
begin
  if AProfile.ProjectFileName = '' then
    raise EArgumentException.Create('Open a Delphi project first.');

  PackageDirectory := TPath.Combine(AOutputRoot,
    PascalIdentifier(AProfile.ProjectName));
  StagedDirectory := UniqueSiblingDirectory(PackageDirectory, '.staging');
  RuntimeDirectory := TPath.Combine(StagedDirectory, 'Runtime');
  try
    TDirectory.CreateDirectory(RuntimeDirectory);

  CopyRuntimeUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Runtime.LanguagePack');
  CopyCoreUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Core.AtomicFile');
  CopyCoreUnit(ARuntimeSourceDirectory, RuntimeDirectory,
    'DAT.Core.Diagnostics');
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
    StagedDirectory, 'Localization\Languages');
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

    UnitFileName := TPath.Combine(StagedDirectory,
      PascalIdentifier(AProfile.ProjectName) + '.Translation.pas');
    TAtomicTextFile.WriteAllText(UnitFileName,
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
      TAtomicTextFile.WriteAllText(TPath.Combine(StagedDirectory,
        'language-menu.json'), JsonArray.ToJSON, TEncoding.UTF8);
      DeploymentScript :=
        'param([Parameter(Mandatory=$true)][string]$ApplicationDirectory)' +
        sLineBreak + '$ErrorActionPreference = ''Stop''' + sLineBreak +
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
        '$target = [System.IO.Path]::GetFullPath($ApplicationDirectory)' +
        sLineBreak +
        '$localization = Join-Path $target ''Localization''' + sLineBreak +
        '$destination = Join-Path $localization ''Languages''' + sLineBreak +
        '$staging = Join-Path $localization (''Languages.staging-'' + [guid]::NewGuid().ToString(''N''))' +
        sLineBreak +
        '$previous = Join-Path $localization ''Languages.previous''' +
        sLineBreak +
        'New-Item -ItemType Directory -Path $staging -Force | Out-Null' +
        sLineBreak +
        'try {' + sLineBreak +
        '  $files = @(Get-ChildItem -LiteralPath $source -Filter ''*.json'' -File)' +
        sLineBreak +
        '  if ($files.Count -eq 0) { throw ''No language packs were found.'' }' +
        sLineBreak +
        '  foreach ($file in $files) {' + sLineBreak +
        '    $relative = ''Localization/Languages/'' + $file.Name' + sLineBreak +
        '    $property = $integrity.PSObject.Properties[$relative]' + sLineBreak +
        '    if ($null -eq $property) { throw "No integrity entry for $relative" }' +
        sLineBreak +
        '    $expected = ([string]$property.Value).ToLowerInvariant()' + sLineBreak +
        '    $actual = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()' +
        sLineBreak +
        '    if ($actual -ne $expected) { throw "Source hash mismatch: $relative" }' +
        sLineBreak +
        '    $stagedFile = Join-Path $staging $file.Name' + sLineBreak +
        '    Copy-Item -LiteralPath $file.FullName -Destination $stagedFile' +
        sLineBreak +
        '    $copied = (Get-FileHash -LiteralPath $stagedFile -Algorithm SHA256).Hash.ToLowerInvariant()' +
        sLineBreak +
        '    if ($copied -ne $expected) { throw "Staged hash mismatch: $relative" }' +
        sLineBreak +
        '  }' + sLineBreak +
        '  if (Test-Path -LiteralPath $previous) { Remove-Item -LiteralPath $previous -Recurse -Force }' +
        sLineBreak +
        '  if (Test-Path -LiteralPath $destination) { Move-Item -LiteralPath $destination -Destination $previous }' +
        sLineBreak +
        '  try { Move-Item -LiteralPath $staging -Destination $destination }' +
        sLineBreak +
        '  catch {' + sLineBreak +
        '    if ((-not (Test-Path -LiteralPath $destination)) -and (Test-Path -LiteralPath $previous)) { Move-Item -LiteralPath $previous -Destination $destination }' +
        sLineBreak +
        '    throw' + sLineBreak +
        '  }' + sLineBreak +
        '  Write-Output "Language packs deployed and verified at $destination"' +
        sLineBreak +
        '} finally {' + sLineBreak +
        '  if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }' +
        sLineBreak +
        '}' +
        sLineBreak;
      TAtomicTextFile.WriteAllText(TPath.Combine(StagedDirectory,
        'Deploy-LanguagePacks.ps1'), DeploymentScript, TEncoding.UTF8);
    finally
      JsonArray.Free;
    end;
    if Languages.Count <> Length(TDirectory.GetFiles(
      PackageLanguagesDirectory, '*.json', TSearchOption.soTopDirectoryOnly)) then
      raise EInvalidOpException.Create(
        'The staged integration package contains an incompatible language pack.');
  finally
    Languages.Free;
  end;

    WriteIntegrityManifest(StagedDirectory);
    PromoteStagedDirectory(StagedDirectory, PackageDirectory);
    Result := PackageDirectory;
  except
    if TDirectory.Exists(StagedDirectory) then
      TDirectory.Delete(StagedDirectory, True);
    raise;
  end;
end;

end.
