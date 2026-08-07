program FoundationSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in '..\..\source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.TranslationWorkspace in '..\..\source\core\DAT.Core.TranslationWorkspace.pas',
  DAT.Core.RuntimePack in '..\..\source\core\DAT.Core.RuntimePack.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Integration.Plan in '..\..\source\integration\DAT.Integration.Plan.pas',
  DAT.Integration.Package in '..\..\source\integration\DAT.Integration.Package.pas',
  DAT.Integration.Types in '..\..\source\integration\DAT.Integration.Types.pas',
  DAT.Integration.MenuResource in '..\..\source\integration\DAT.Integration.MenuResource.pas',
  DAT.Integration.DelphiSource in '..\..\source\integration\DAT.Integration.DelphiSource.pas',
  DAT.Integration.Transaction in '..\..\source\integration\DAT.Integration.Transaction.pas',
  DAT.Integration.Engine in '..\..\source\integration\DAT.Integration.Engine.pas',
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in '..\..\source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.FormText in '..\..\source\scan\DAT.Scan.FormText.pas',
  DAT.Scan.PascalResources in '..\..\source\scan\DAT.Scan.PascalResources.pas',
  DAT.Scan.Project in '..\..\source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in '..\..\source\scan\DAT.Scan.CatalogMerge.pas',
  DAT.Provider.Types in '..\..\source\provider\DAT.Provider.Types.pas',
  DAT.Provider.Client in '..\..\source\provider\DAT.Provider.Client.pas',
  DAT.Validation.Catalog in '..\..\source\validation\DAT.Validation.Catalog.pas';

type
  TProviderClientAccess = class(TTranslationProviderClient)
  public
    function PublicBuildRequestBody(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string): string;
    function PublicEndpoint: string;
    function PublicParseResponse(
      const AResponseText: string): TArray<string>;
  end;

function TProviderClientAccess.PublicBuildRequestBody(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage: string): string;
begin
  Result := BuildRequestBody(ATexts,
    ASourceLanguage, ATargetLanguage);
end;

function TProviderClientAccess.PublicEndpoint: string;
begin
  Result := Endpoint;
end;

function TProviderClientAccess.PublicParseResponse(
  const AResponseText: string): TArray<string>;
begin
  Result := ParseResponse(AResponseText);
end;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestProviderProtocolFixtures;
var
  Client: TProviderClientAccess;
  RequestBody: string;
  SourceTexts: TArray<string>;
  Translations: TArray<string>;
begin
  SetLength(SourceTexts, 2);
  SourceTexts[0] := 'Save';
  SourceTexts[1] := 'Cancel';

  Client := TProviderClientAccess.Create(tpDeepL, dpFree,
    'fixture-key-not-sent', 30, 40);
  try
    Require(ContainsText(Client.PublicEndpoint, 'api-free.deepl.com'),
      'The DeepL Free endpoint is incorrect.');
    RequestBody := Client.PublicBuildRequestBody(
      SourceTexts, 'en-US', 'it-IT');
    Require(ContainsText(RequestBody, '"text":["Save","Cancel"]'),
      'The DeepL request text array is incorrect.');
    Require(ContainsText(RequestBody, '"source_lang":"EN"'),
      'The DeepL source language is incorrect.');
    Translations := Client.PublicParseResponse(
      '{"translations":[{"text":"Salva"},{"text":"Annulla"}]}');
    Require((Length(Translations) = 2) and
      (Translations[0] = 'Salva') and
      (Translations[1] = 'Annulla'),
      'The DeepL response fixture was parsed incorrectly.');
  finally
    Client.Free;
  end;

  Client := TProviderClientAccess.Create(tpGoogle, dpFree,
    'fixture-key-not-sent', 30, 40);
  try
    Require(ContainsText(Client.PublicEndpoint,
      'translation.googleapis.com'),
      'The Google endpoint is incorrect.');
    RequestBody := Client.PublicBuildRequestBody(
      SourceTexts, 'en-US', 'it-IT');
    Require(ContainsText(RequestBody, '"q":["Save","Cancel"]'),
      'The Google request text array is incorrect.');
    Require(ContainsText(RequestBody, '"target":"it"'),
      'The Google target language is incorrect.');
    Translations := Client.PublicParseResponse(
      '{"data":{"translations":[' +
      '{"translatedText":"Salva"},' +
      '{"translatedText":"Annulla"}]}}');
    Require((Length(Translations) = 2) and
      (Translations[0] = 'Salva') and
      (Translations[1] = 'Annulla'),
      'The Google response fixture was parsed incorrectly.');
  finally
    Client.Free;
  end;
end;

procedure TestProjectDetection;
var
  ProjectRoot: string;
  Profile: TProjectProfile;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);

  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\VCLBasic\SampleVCLApp.dproj'));
  Require(Profile.Framework = tfVCL, 'The VCL sample was not detected as VCL.');
  Require(Profile.SupportsWin32 and Profile.SupportsWin64,
    'The VCL sample target platforms were not detected.');

  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\FMXBasic\SampleFMXApp.dproj'));
  Require(Profile.Framework = tfFireMonkey,
    'The FMX sample was not detected as FireMonkey.');
  Require(Profile.SupportsWin32 and Profile.SupportsWin64,
    'The FMX sample target platforms were not detected.');
end;

procedure TestCatalogRoundTrip;
var
  SourceCatalog: TTranslationCatalog;
  LoadedCatalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  JsonText: string;
begin
  SourceCatalog := TTranslationCatalog.Create;
  try
    SourceCatalog.ApplicationId := 'FoundationSmokeTest';
    SourceCatalog.ApplicationVersion := '1.0';
    SourceCatalog.Framework := tfVCL;
    SourceCatalog.SourceLanguage := 'en-US';
    SourceCatalog.Locale.LanguageCode := 'de-DE';
    SourceCatalog.Locale.NativeLanguageName := 'Deutsch';
    SourceCatalog.Locale.TextDirection := 'ltr';

    Entry := TTranslationEntry.Create;
    Entry.Key := 'MainForm.SaveButton.Caption';
    Entry.SourceText := 'Save';
    Entry.TranslatedText := 'Speichern';
    Entry.SourceFileName := 'MainForm.dfm';
    Entry.SourceLine := 42;
    Entry.SourceKind := 'Form property';
    Entry.Status := tsApproved;
    SourceCatalog.Entries.Add(Entry);

    JsonText := TCatalogJson.Serialize(SourceCatalog);
    LoadedCatalog := TCatalogJson.Deserialize(JsonText);
    try
      Require(LoadedCatalog.ApplicationId = SourceCatalog.ApplicationId,
        'Application id was not preserved.');
      Require(LoadedCatalog.Framework = tfVCL,
        'Framework was not preserved.');
      Require(LoadedCatalog.Entries.Count = 1,
        'Translation entry count was not preserved.');
      Require(LoadedCatalog.Entries[0].TranslatedText = 'Speichern',
        'Translated text was not preserved.');
      Require(LoadedCatalog.Entries[0].Status = tsApproved,
        'Translation status was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceFileName = 'MainForm.dfm',
        'Source filename was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceLine = 42,
        'Source line was not preserved.');
    finally
      LoadedCatalog.Free;
    end;
  finally
    SourceCatalog.Free;
  end;
end;

procedure RequireItem(const AResult: TProjectScanResult;
  const AKey, AExpectedText: string);
var
  ScanItem: TScanItem;
begin
  ScanItem := AResult.FindItem(AKey);
  Require(ScanItem <> nil, 'Expected scan key was not found: ' + AKey);
  Require(ScanItem.SourceText = AExpectedText,
    'Unexpected source text for scan key: ' + AKey);
  Require(ScanItem.SourceLine > 0,
    'The scan item did not retain its source line: ' + AKey);
end;

procedure TestProjectScanning;
var
  Profile: TProjectProfile;
  ProjectRoot: string;
  ScanResult: TProjectScanResult;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);

  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\VCLBasic\SampleVCLApp.dproj'));
  ScanResult := TProjectScanner.Scan(Profile);
  try
    RequireItem(ScanResult, 'frmVCLSample.lblHeading.Caption',
      'Customer Account Details');
    RequireItem(ScanResult, 'frmVCLSample.edtCustomerName.Hint',
      'Enter the customer''s full name');
    RequireItem(ScanResult, 'frmVCLSample.memInstructions.Lines.Strings.1',
      'Fields marked as required must be completed.');
    RequireItem(ScanResult, 'SampleVCL.MainForm.SWelcomeMessage',
      'Welcome to the VCL translation sample.');
    Require(ScanResult.CountByKind(stkFormProperty) > 0,
      'The VCL form properties were not scanned.');
    Require(ScanResult.CountByKind(stkResourceString) = 2,
      'The VCL resourcestring count is incorrect.');
  finally
    ScanResult.Free;
  end;

  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\FMXBasic\SampleFMXApp.dproj'));
  ScanResult := TProjectScanner.Scan(Profile);
  try
    RequireItem(ScanResult, 'frmFMXSample.lblHeading.Text',
      'Customer Account Details');
    RequireItem(ScanResult, 'frmFMXSample.edtCustomerName.TextPrompt',
      'Full name');
    RequireItem(ScanResult, 'frmFMXSample.mnuLanguage.Text', '&Language');
    RequireItem(ScanResult, 'SampleFMX.MainForm.SNameRequired',
      'Please enter a customer name.');
    Require(ScanResult.CountByKind(stkResourceString) = 2,
      'The FMX resourcestring count is incorrect.');
  finally
    ScanResult.Free;
  end;
end;

procedure TestStudioProjectScanning;
var
  Diagnostic: TScanDiagnostic;
  Profile: TProjectProfile;
  ProjectRoot: string;
  ScanResult: TProjectScanResult;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'DelphiAppTranslationStudio.dproj'));
  ScanResult := TProjectScanner.Scan(Profile);
  try
    RequireItem(ScanResult,
      'frmTranslationStudio.lblApplicationTitle.Text',
      'Delphi App Translation Studio');
    Require(ScanResult.Items.Count >= 25,
      'The Studio project scan found too few translatable entries.');
    for Diagnostic in ScanResult.Diagnostics do
      Require(Diagnostic.Severity <> sdsError,
        'The Studio project scan reported an error: ' +
        Diagnostic.MessageText);
  finally
    ScanResult.Free;
  end;
end;

procedure TestIncrementalCatalogMerge;
var
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  MergeSummary: TCatalogMergeSummary;
  ScanItem: TScanItem;
  ScanResult: TProjectScanResult;
begin
  Catalog := TTranslationCatalog.Create;
  ScanResult := TProjectScanResult.Create;
  try
    Entry := TTranslationEntry.Create;
    Entry.Key := 'MainForm.SaveButton.Caption';
    Entry.SourceText := 'Save';
    Entry.TranslatedText := 'Speichern';
    Entry.Status := tsApproved;
    Catalog.Entries.Add(Entry);

    Entry := TTranslationEntry.Create;
    Entry.Key := 'MainForm.OldLabel.Caption';
    Entry.SourceText := 'Old';
    Entry.Status := tsReviewed;
    Catalog.Entries.Add(Entry);

    ScanItem := TScanItem.Create;
    ScanItem.Key := 'MainForm.SaveButton.Caption';
    ScanItem.SourceText := 'Save now';
    ScanItem.SourceLine := 10;
    ScanResult.Items.Add(ScanItem);

    ScanItem := TScanItem.Create;
    ScanItem.Key := 'MainForm.NewLabel.Caption';
    ScanItem.SourceText := 'New';
    ScanItem.SourceLine := 20;
    ScanResult.Items.Add(ScanItem);

    MergeSummary := TScanCatalogMerger.Merge(ScanResult, Catalog);
    Require(MergeSummary.NewEntries = 1, 'New merge entries were not counted.');
    Require(MergeSummary.ChangedEntries = 1,
      'Changed merge entries were not counted.');
    Require(MergeSummary.ObsoleteEntries = 1,
      'Obsolete merge entries were not counted.');
    Require(Catalog.FindEntry('MainForm.SaveButton.Caption').Status =
      tsSourceChanged, 'Changed source text was not marked for review.');
    Require(Catalog.FindEntry('MainForm.SaveButton.Caption').TranslatedText =
      'Speichern', 'The existing translation was not preserved.');
    Require(Catalog.FindEntry('MainForm.OldLabel.Caption').Status = tsObsolete,
      'Removed source text was not marked obsolete.');
  finally
    ScanResult.Free;
    Catalog.Free;
  end;
end;

function CreateCompleteCatalog: TTranslationCatalog;
var
  Entry: TTranslationEntry;
begin
  Result := TTranslationCatalog.Create;
  Result.ApplicationId := 'OfflineWorkflowTest';
  Result.ApplicationVersion := '1.0';
  Result.Framework := tfFireMonkey;
  Result.SourceLanguage := 'en-US';
  Result.Locale.LanguageCode := 'de-DE';
  Result.Locale.NativeLanguageName := 'Deutsch';
  Result.Locale.TextDirection := 'ltr';
  Result.Locale.ShortDateFormat := 'dd.MM.yyyy';
  Result.Locale.LongDateFormat := 'dddd, d. MMMM yyyy';
  Result.Locale.ShortTimeFormat := 'HH:mm';
  Result.Locale.LongTimeFormat := 'HH:mm:ss';
  Result.Locale.DecimalSeparator := ',';
  Result.Locale.ThousandSeparator := '.';
  Result.Locale.CurrencySymbol := '€';

  Entry := TTranslationEntry.Create;
  Entry.Key := 'MainForm.Greeting.Text';
  Entry.SourceText := 'Hello %s';
  Entry.TranslatedText := 'Hallo %s';
  Entry.SourceChecksum := 'source-checksum-1';
  Entry.Status := tsReviewed;
  Result.Entries.Add(Entry);

  Entry := TTranslationEntry.Create;
  Entry.Key := 'MainForm.Exit.Text';
  Entry.SourceText := 'E&xit';
  Entry.TranslatedText := '&Beenden';
  Entry.SourceChecksum := 'source-checksum-2';
  Entry.Status := tsApproved;
  Result.Entries.Add(Entry);
end;

procedure TestCatalogFilePersistence;
var
  Catalog: TTranslationCatalog;
  CatalogFileName: string;
  LoadedCatalog: TTranslationCatalog;
  ProjectRoot: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  CatalogFileName := TPath.Combine(ProjectRoot,
    'export\FoundationSmokeTest.translation-project.json');
  Catalog := CreateCompleteCatalog;
  try
    TCatalogJson.SaveToFile(Catalog, CatalogFileName);
    Require(TFile.Exists(CatalogFileName),
      'The development catalog file was not created.');
    LoadedCatalog := TCatalogJson.LoadFromFile(CatalogFileName);
    try
      Require(LoadedCatalog.Locale.LanguageCode = 'de-DE',
        'The target language was not loaded from disk.');
      Require(LoadedCatalog.Entries.Count = 2,
        'The persisted catalog entry count is incorrect.');
    finally
      LoadedCatalog.Free;
    end;
  finally
    Catalog.Free;
    if TFile.Exists(CatalogFileName) then
      TFile.Delete(CatalogFileName);
  end;
end;

procedure TestWorkspacePaths;
var
  CatalogFileName: string;
  Profile: TProjectProfile;
  ProjectRoot: string;
  RuntimeFileName: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\VCLBasic\SampleVCLApp.dproj'));
  CatalogFileName := TTranslationWorkspace.DevelopmentCatalogFileName(
    Profile, 'de-DE');
  RuntimeFileName := TTranslationWorkspace.RuntimePackFileName(
    Profile, 'de-DE');
  Require(EndsText(
    'Localization\Development\SampleVCLApp.de-DE.translation-project.json',
    CatalogFileName), 'The development catalog path is incorrect.');
  Require(EndsText('Localization\Languages\de-DE.json', RuntimeFileName),
    'The runtime pack path is incorrect.');
end;

procedure TestCatalogValidation;
var
  Catalog: TTranslationCatalog;
  ValidationResult: TCatalogValidationResult;
begin
  Catalog := CreateCompleteCatalog;
  try
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(not ValidationResult.HasErrors,
        'A complete catalog did not pass validation.');
    finally
      ValidationResult.Free;
    end;

    Catalog.Entries[0].TranslatedText := 'Hallo';
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(ValidationResult.HasErrors,
        'A placeholder mismatch did not block export.');
    finally
      ValidationResult.Free;
    end;
  finally
    Catalog.Free;
  end;
end;

procedure TestRuntimePack;
var
  Catalog: TTranslationCatalog;
  JsonText: string;
  JsonPair: TJSONPair;
  JsonValue: TJSONValue;
  Root: TJSONObject;
  StringsObject: TJSONObject;
begin
  Catalog := CreateCompleteCatalog;
  try
    JsonText := TRuntimePackBuilder.Serialize(Catalog);
    JsonValue := TJSONObject.ParseJSONValue(JsonText);
    try
      Require(JsonValue is TJSONObject,
        'The runtime pack root is not a JSON object.');
      Root := TJSONObject(JsonValue);
      Require(Root.GetValue<string>('sourceLanguage') = 'en-US',
        'The runtime pack source language is missing.');
      Require(Root.GetValue<string>('sourceCatalogChecksum') <> '',
        'The runtime pack checksum is missing.');
      StringsObject := Root.GetValue('strings') as TJSONObject;
      Require(StringsObject <> nil, 'The runtime strings object is missing.');
      JsonPair := StringsObject.Get('MainForm.Exit.Text');
      Require((JsonPair <> nil) and (JsonPair.JsonValue.Value = '&Beenden'),
        'The runtime translation was not exported.');
    finally
      JsonValue.Free;
    end;
  finally
    Catalog.Free;
  end;
end;

procedure TestRuntimeLoadingAndPreference;
var
  Catalog: TTranslationCatalog;
  LanguageDirectory: string;
  Pack: TRuntimeLanguagePack;
  PackFileName: string;
  PreferenceFileName: string;
  Runtime: TTranslationRuntime;
begin
  LanguageDirectory := TPath.Combine(TPath.GetFullPath(GetCurrentDir),
    'export\RuntimeLoaderTest\Languages');
  PackFileName := TPath.Combine(LanguageDirectory, 'de-DE.json');
  PreferenceFileName := TPath.Combine(
    TPath.GetDirectoryName(LanguageDirectory), 'language.ini');
  Catalog := CreateCompleteCatalog;
  try
    TRuntimePackBuilder.ExportToFile(Catalog, PackFileName);
  finally
    Catalog.Free;
  end;

  Pack := TRuntimeLanguagePack.LoadFromFile(PackFileName);
  try
    Require(Pack.LanguageCode = 'de-DE',
      'The runtime loader did not read the language code.');
    Require(Pack.GetText('MainForm.Exit.Text', 'Exit') = '&Beenden',
      'The runtime loader did not return translated text.');
    Require(Pack.GetText('Missing.Key', 'Fallback') = 'Fallback',
      'The runtime loader did not preserve fallback text.');
  finally
    Pack.Free;
  end;

  Runtime := TTranslationRuntime.Create('OfflineWorkflowTest',
    LanguageDirectory, PreferenceFileName, 'en-US');
  try
    Require(Runtime.LoadLanguage('de-DE'),
      'The runtime manager did not load the exported pack.');
    Require(Runtime.Translate('MainForm.Greeting.Text', 'Hello') = 'Hallo %s',
      'The runtime manager did not translate a key.');
    Require(Runtime.FormatSettings.DecimalSeparator = ',',
      'The locale decimal separator was not applied.');
  finally
    Runtime.Free;
  end;

  Runtime := TTranslationRuntime.Create('OfflineWorkflowTest',
    LanguageDirectory, PreferenceFileName, 'en-US');
  try
    Require(Runtime.LoadPreferredLanguage,
      'The saved language preference was not loaded.');
    Require((Runtime.ActivePack <> nil) and
      (Runtime.ActivePack.LanguageCode = 'de-DE'),
      'The preferred runtime pack was not activated.');
  finally
    Runtime.Free;
  end;

  if TDirectory.Exists(TPath.GetDirectoryName(LanguageDirectory)) then
    TDirectory.Delete(TPath.GetDirectoryName(LanguageDirectory), True);
end;

procedure TestIntegrationPlanningAndPackage;
var
  OutputDirectory: string;
  Plan: TIntegrationPlan;
  Profile: TProjectProfile;
  ProjectRoot: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\VCLBasic\SampleVCLApp.dproj'));
  Plan := TIntegrationPlanner.Build(Profile, 'mnuLanguage');
  try
    Require(Plan.MenuFound,
      'The VCL sample language menu was not found.');
    Require(Plan.Lines.Count >= 6,
      'The integration plan is incomplete.');
  finally
    Plan.Free;
  end;

  OutputDirectory := TIntegrationPackageGenerator.Generate(
    Profile, TPath.Combine(ProjectRoot, 'export\IntegrationSmoke'),
    TPath.Combine(ProjectRoot, 'source\runtime'));
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'SampleVCLApp.Translation.pas')),
    'The generated VCL integration unit is missing.');
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'Runtime\DAT.Runtime.VCL.pas')),
    'The VCL runtime adapter was not packaged.');
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'language-menu.json')),
    'The language menu manifest was not packaged.');
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'Deploy-LanguagePacks.ps1')),
    'The language-pack deployment script was not packaged.');
  Require(ContainsText(TFile.ReadAllText(TPath.Combine(OutputDirectory,
    'SampleVCLApp.Translation.pas')), 'LOCALAPPDATA'),
    'The generated runtime preference is not stored per user.');

  Profile := TProjectDetector.Detect(TPath.Combine(ProjectRoot,
    'samples\FMXBasic\SampleFMXApp.dproj'));
  OutputDirectory := TIntegrationPackageGenerator.Generate(
    Profile, TPath.Combine(ProjectRoot, 'export\IntegrationSmoke'),
    TPath.Combine(ProjectRoot, 'source\runtime'));
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'SampleFMXApp.Translation.pas')),
    'The generated FMX integration unit is missing.');
  Require(TFile.Exists(TPath.Combine(OutputDirectory,
    'Runtime\DAT.Runtime.FMX.pas')),
    'The FMX runtime adapter was not packaged.');
end;

function CountTextOccurrences(const AText, ASearchText: string): Integer;
var
  SearchPosition: Integer;
begin
  Result := 0;
  SearchPosition := 1;
  while True do
  begin
    SearchPosition := PosEx(ASearchText, AText, SearchPosition);
    if SearchPosition = 0 then
      Exit;
    Inc(Result);
    Inc(SearchPosition, Length(ASearchText));
  end;
end;

procedure CopyFixtureDirectory(const ASourceDirectory,
  ADestinationDirectory: string);
var
  DestinationFileName: string;
  FileName: string;
  RelativeName: string;
begin
  if TDirectory.Exists(ADestinationDirectory) then
    TDirectory.Delete(ADestinationDirectory, True);
  TDirectory.CreateDirectory(ADestinationDirectory);
  for FileName in TDirectory.GetFiles(
    ASourceDirectory, '*', TSearchOption.soAllDirectories) do
  begin
    RelativeName := Copy(FileName,
      Length(IncludeTrailingPathDelimiter(ASourceDirectory)) + 1, MaxInt);
    DestinationFileName := TPath.Combine(
      ADestinationDirectory, RelativeName);
    TDirectory.CreateDirectory(
      TPath.GetDirectoryName(DestinationFileName));
    TFile.Copy(FileName, DestinationFileName, True);
  end;
end;

procedure ExportItalianFixturePack(const AProfile: TProjectProfile);
var
  Catalog: TTranslationCatalog;
begin
  Catalog := CreateCompleteCatalog;
  try
    Catalog.ApplicationId := AProfile.ProjectName;
    Catalog.Framework := AProfile.Framework;
    Catalog.Locale.LanguageCode := 'it-IT';
    Catalog.Locale.NativeLanguageName := 'Italiano';
    TRuntimePackBuilder.ExportToFile(Catalog,
      TTranslationWorkspace.RuntimePackFileName(AProfile, 'it-IT'));
  finally
    Catalog.Free;
  end;
end;

procedure TestTargetIntegration(const AProjectRoot, ASampleDirectory,
  AProjectFileName, AFormResourceFileName: string);
var
  BackupDirectory: string;
  ChangeSet: TIntegrationChangeSet;
  FixtureDirectory: string;
  FormText: string;
  IntegrationUnitName: string;
  PackageDirectory: string;
  Profile: TProjectProfile;
  ProjectText: string;
  ResultInfo: TIntegrationApplyResult;
  SourceText: string;
begin
  FixtureDirectory := TPath.Combine(AProjectRoot,
    'export\TargetIntegrationSmoke\' + ASampleDirectory);
  CopyFixtureDirectory(TPath.Combine(
    AProjectRoot, 'samples\' + ASampleDirectory), FixtureDirectory);
  Profile := TProjectDetector.Detect(TPath.Combine(
    FixtureDirectory, AProjectFileName));
  ExportItalianFixturePack(Profile);
  PackageDirectory := TIntegrationPackageGenerator.Generate(
    Profile, TPath.Combine(AProjectRoot,
      'export\TargetIntegrationPackages'),
    TPath.Combine(AProjectRoot, 'source\runtime'));
  ChangeSet := TTargetIntegrationEngine.BuildChangeSet(
    Profile, PackageDirectory, 'mnuLanguage');
  try
    Require(ChangeSet.Changes.Count >= 9,
      'The target integration change set is incomplete.');
    BackupDirectory := TPath.Combine(AProjectRoot,
      'export\TargetIntegrationBackups\' + ASampleDirectory + '\First');
    ResultInfo := TIntegrationTransaction.Apply(
      ChangeSet, BackupDirectory);
    try
      Require(ResultInfo.FilesWritten = ChangeSet.Changes.Count,
        'The transaction did not write every planned file.');
    finally
      ResultInfo.Free;
    end;
  finally
    ChangeSet.Free;
  end;

  FormText := TFile.ReadAllText(TPath.Combine(
    FixtureDirectory, AFormResourceFileName));
  Require(CountTextOccurrences(FormText,
    'object datLanguage_en_US: TMenuItem') = 1,
    'The source-language menu item is missing or duplicated.');
  Require(CountTextOccurrences(FormText,
    'object datLanguage_it_IT: TMenuItem') = 1,
    'The Italian menu item is missing or duplicated.');
  Require(ContainsText(FormText, 'Italiano'),
    'The native Italian language name was not persisted.');

  SourceText := TFile.ReadAllText(TPath.ChangeExtension(
    TPath.Combine(FixtureDirectory, AFormResourceFileName), '.pas'));
  Require(CountTextOccurrences(SourceText,
    'procedure datLanguageMenuItemClick(Sender: TObject);') = 1,
    'The form language handler declaration is missing or duplicated.');

  ProjectText := TFile.ReadAllText(TPath.Combine(
    FixtureDirectory, TPath.ChangeExtension(
      AProjectFileName, '.dpr')));
  Require(CountTextOccurrences(ProjectText,
    'InitializeTranslation;') = 1,
    'Translation initialization is missing or duplicated.');
  Require(CountTextOccurrences(ProjectText,
    'ApplyTranslation(') = 1,
    'Startup form translation is missing or duplicated.');

  IntegrationUnitName := Profile.ProjectName + '.Translation.pas';
  Require(TFile.Exists(TPath.Combine(FixtureDirectory,
    'Localization\Runtime\' + IntegrationUnitName)),
    'The generated target integration unit is missing.');

  ChangeSet := TTargetIntegrationEngine.BuildChangeSet(
    Profile, PackageDirectory, 'mnuLanguage');
  try
    FormText := ChangeSet.FindChange(TPath.Combine(
      FixtureDirectory, AFormResourceFileName)).NewText;
    Require(CountTextOccurrences(FormText,
      'object datLanguage_it_IT: TMenuItem') = 1,
      'A repeated integration preview duplicated the Italian menu item.');
  finally
    ChangeSet.Free;
  end;

  TIntegrationTransaction.Restore(
    FixtureDirectory, BackupDirectory);
  FormText := TFile.ReadAllText(TPath.Combine(
    FixtureDirectory, AFormResourceFileName));
  Require(not ContainsText(FormText, 'datLanguage_it_IT'),
    'Restore did not remove generated language items.');

  ChangeSet := TTargetIntegrationEngine.BuildChangeSet(
    Profile, PackageDirectory, 'mnuLanguage');
  try
    ResultInfo := TIntegrationTransaction.Apply(ChangeSet,
      TPath.Combine(AProjectRoot,
        'export\TargetIntegrationBackups\' + ASampleDirectory + '\Final'));
    ResultInfo.Free;
  finally
    ChangeSet.Free;
  end;
end;

procedure TestTransactionalTargetIntegration;
var
  ProjectRoot: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  TestTargetIntegration(ProjectRoot, 'VCLBasic',
    'SampleVCLApp.dproj', 'SampleVCL.MainForm.dfm');
  TestTargetIntegration(ProjectRoot, 'FMXBasic',
    'SampleFMXApp.dproj', 'SampleFMX.MainForm.fmx');
end;

procedure TestStudioSelfIntegrationChangeSet;
var
  ChangeSet: TIntegrationChangeSet;
  PackageDirectory: string;
  Profile: TProjectProfile;
  ProjectRoot: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  Profile := TProjectDetector.Detect(TPath.Combine(
    ProjectRoot, 'DelphiAppTranslationStudio.dproj'));
  PackageDirectory := TIntegrationPackageGenerator.Generate(
    Profile, TPath.Combine(ProjectRoot, 'export\IntegrationSmoke'),
    TPath.Combine(ProjectRoot, 'source\runtime'));
  ChangeSet := TTargetIntegrationEngine.BuildChangeSet(
    Profile, PackageDirectory, 'mnuLanguage');
  try
    Require(ChangeSet.Changes.Count = 1,
      'Studio self-integration should update only its persisted menu.');
    Require(ChangeSet.Changes[0].Kind = ickFormResource,
      'Studio self-integration planned an unexpected source change.');
  finally
    ChangeSet.Free;
  end;
end;

begin
  try
    TestProjectDetection;
    TestProviderProtocolFixtures;
    TestCatalogRoundTrip;
    TestProjectScanning;
    TestStudioProjectScanning;
    TestIncrementalCatalogMerge;
    TestCatalogFilePersistence;
    TestWorkspacePaths;
    TestCatalogValidation;
    TestRuntimePack;
    TestRuntimeLoadingAndPreference;
    TestIntegrationPlanningAndPackage;
    TestTransactionalTargetIntegration;
    TestStudioSelfIntegrationChangeSet;
    Writeln('Foundation, scanner, catalog, runtime, validation, and export tests passed.');
  except
    on E: Exception do
    begin
      Writeln('Foundation smoke tests failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
