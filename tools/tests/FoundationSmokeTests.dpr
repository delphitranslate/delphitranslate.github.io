program FoundationSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Hash,
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in '..\..\source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.AITranslation in '..\..\source\core\DAT.Core.AITranslation.pas',
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
  DAT.Integration.Reset in '..\..\source\integration\DAT.Integration.Reset.pas',
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
    Entry.TranslationOrigin := torCodex;
    Entry.TranslationConfidence := 'high';
    Entry.TranslationReviewNote := 'Second pass complete';
    Entry.RuntimeApplication := rakManualTranslateText;
    Entry.RuntimeWiringConfirmed := True;
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
      Require((LoadedCatalog.Entries[0].TranslationOrigin = torCodex) and
        (LoadedCatalog.Entries[0].TranslationConfidence = 'high') and
        (LoadedCatalog.Entries[0].TranslationReviewNote =
          'Second pass complete'),
        'AI translation provenance was not preserved.');
      Require(LoadedCatalog.Entries[0].RuntimeApplication =
        rakManualTranslateText,
        'Runtime application mode was not preserved.');
      Require(LoadedCatalog.Entries[0].RuntimeWiringConfirmed,
        'Runtime wiring confirmation was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceFileName = 'MainForm.dfm',
        'Source filename was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceLine = 42,
        'Source line was not preserved.');
    finally
      LoadedCatalog.Free;
    end;

    LoadedCatalog := TCatalogJson.Deserialize(
      '{"schemaVersion":1,"applicationId":"Legacy","framework":"VCL",' +
      '"sourceLanguage":"en-US","entries":[{"key":"Unit1.SMessage",' +
      '"sourceText":"Message","sourceKind":"Resource string",' +
      '"status":"needsTranslation"}]}');
    try
      Require(LoadedCatalog.SchemaVersion = 3,
        'A schema version 1 catalog was not migrated to version 3.');
      Require(LoadedCatalog.Entries[0].RuntimeApplication =
        rakManualTranslateText,
        'Legacy resourcestring runtime mode was not derived.');
      Require(not LoadedCatalog.Entries[0].RuntimeWiringConfirmed,
        'Legacy resourcestring wiring should require confirmation.');
    finally
      LoadedCatalog.Free;
    end;
  finally
    SourceCatalog.Free;
  end;
end;

procedure TestCatalogCsvRoundTrip;
var
  Bytes: TBytes;
  Catalog: TTranslationCatalog;
  CsvFileName: string;
  Entry: TTranslationEntry;
  ImportPlan: TCatalogCsvImportPlan;
  ProjectRoot: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  CsvFileName := TPath.Combine(ProjectRoot,
    'export\FoundationSmokeTest.translation.csv');
  Catalog := TTranslationCatalog.Create;
  try
    Entry := TTranslationEntry.Create;
    Entry.Key := 'MainForm.Memo.Lines.Strings.0';
    Entry.SourceText := 'Hello, "developer"' + sLineBreak + 'Second line';
    Entry.TranslatedText := 'Hallo, "Entwickler"' + sLineBreak +
      'Zweite Zeile';
    Entry.SourceChecksum := 'csv-source-checksum';
    Entry.DeveloperNote := 'Comma, quote, and multiline test';
    Entry.Status := tsEdited;
    Entry.RuntimeApplication := rakAutomatic;
    Entry.RuntimeWiringConfirmed := True;
    Catalog.Entries.Add(Entry);

    TCatalogCsv.ExportToFile(Catalog, CsvFileName);
    Require(TFile.Exists(CsvFileName), 'The CSV export was not created.');
    Bytes := TFile.ReadAllBytes(CsvFileName);
    Require((Length(Bytes) >= 3) and (Bytes[0] = $EF) and
      (Bytes[1] = $BB) and (Bytes[2] = $BF),
      'The CSV export is not UTF-8 with a BOM.');

    Entry.TranslatedText := '';
    Entry.Status := tsNeedsTranslation;
    ImportPlan := TCatalogCsv.AnalyzeImport(Catalog, CsvFileName);
    try
      Require(ImportPlan.Changes.Count = 1,
        'The CSV import did not stage one translation.');
      ImportPlan.Apply;
      Require(Entry.TranslatedText =
        'Hallo, "Entwickler"' + sLineBreak + 'Zweite Zeile',
        'CSV quoted or multiline text was not preserved.');
      Require(Entry.Status = tsImported,
        'CSV import did not mark the entry as imported.');
    finally
      ImportPlan.Free;
    end;

    Entry.Status := tsApproved;
    ImportPlan := TCatalogCsv.AnalyzeImport(Catalog, CsvFileName);
    try
      Require((ImportPlan.Changes.Count = 0) and
        (ImportPlan.ProtectedCount = 1),
        'CSV import did not protect an approved entry.');
    finally
      ImportPlan.Free;
    end;

    Entry.Status := tsNeedsTranslation;
    Entry.SourceChecksum := 'changed-after-export';
    ImportPlan := TCatalogCsv.AnalyzeImport(Catalog, CsvFileName);
    try
      Require((ImportPlan.Changes.Count = 0) and
        (ImportPlan.StaleCount = 1),
        'CSV import did not reject a stale source checksum.');
    finally
      ImportPlan.Free;
    end;
  finally
    Catalog.Free;
    if TFile.Exists(CsvFileName) then
      TFile.Delete(CsvFileName);
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
  Require(Format('%2:s|%0:s|%1:s', ['zero', 'one', 'two']) =
    'two|zero|one',
    'RAD Studio Format indexed-argument behavior changed.');
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

    Catalog.Entries[0].SourceText := '%s defeats %s with %s';
    Catalog.Entries[0].TranslatedText := '%1:s verliert gegen %0:s mit %2:s';
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(not ValidationResult.HasErrors,
        'Valid indexed placeholder reordering was rejected.');
    finally
      ValidationResult.Free;
    end;

    Catalog.Entries[0].TranslatedText := '%1:d verliert gegen %0:s mit %2:s';
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(ValidationResult.HasErrors,
        'An incompatible indexed placeholder type was accepted.');
    finally
      ValidationResult.Free;
    end;

    Catalog.Entries[0].TranslatedText := '%s verliert gegen %2:s mit %s';
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(ValidationResult.HasErrors,
        'Mixed placeholders with a missing argument were accepted.');
    finally
      ValidationResult.Free;
    end;

    Catalog.Entries[0].TranslatedText := '%1:s verliert gegen %0:s mit %2:s';
    Catalog.Entries[0].RuntimeApplication := rakManualTranslateText;
    Catalog.Entries[0].RuntimeWiringConfirmed := False;
    ValidationResult := TCatalogValidator.Validate(Catalog);
    try
      Require(not ValidationResult.HasErrors,
        'Unconfirmed manual wiring should warn without blocking export.');
      Require(ValidationResult.CountBySeverity(vsWarning) > 0,
        'Unconfirmed manual wiring did not produce a warning.');
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

function ItalianPilotTranslation(const ASourceText: string): string;
begin
  if ASourceText = 'Customer Manager' then
    Result := 'Gestione clienti'
  else if ASourceText = 'Customer Account Details' then
    Result := 'Dettagli account cliente'
  else if ASourceText = 'Customer name' then
    Result := 'Nome cliente'
  else if ASourceText = 'Full name' then
    Result := 'Nome completo'
  else if ASourceText = '&Save Customer' then
    Result := '&Salva cliente'
  else if ASourceText = 'E&xit' then
    Result := 'E&sci'
  else if ASourceText = '&Language' then
    Result := '&Lingua'
  else
    Result := '[IT] ' + ASourceText;
end;

procedure ExportItalianFixturePack(const AProfile: TProjectProfile);
var
  Catalog: TTranslationCatalog;
  CatalogFileName: string;
  Entry: TTranslationEntry;
  ExternalCatalog: TTranslationCatalog;
  OriginalCatalog: TTranslationCatalog;
  Review: TAITranslationReview;
  ScanResult: TProjectScanResult;
  ValidationResult: TCatalogValidationResult;
begin
  Catalog := TTranslationCatalog.Create;
  try
    Catalog.ApplicationId := AProfile.ProjectName;
    Catalog.Framework := AProfile.Framework;
    Catalog.SourceLanguage := 'en-US';
    Catalog.Locale.LanguageCode := 'it-IT';
    Catalog.Locale.NativeLanguageName := 'Italiano';
    Catalog.Locale.TextDirection := 'ltr';
    Catalog.Locale.ShortDateFormat := 'dd/MM/yyyy';
    Catalog.Locale.LongDateFormat := 'dddd d MMMM yyyy';
    Catalog.Locale.ShortTimeFormat := 'HH:mm';
    Catalog.Locale.LongTimeFormat := 'HH:mm:ss';
    Catalog.Locale.DecimalSeparator := ',';
    Catalog.Locale.ThousandSeparator := '.';
    Catalog.Locale.CurrencySymbol := #$20AC;
    ScanResult := TProjectScanner.Scan(AProfile);
    try
      TScanCatalogMerger.Merge(ScanResult, Catalog);
    finally
      ScanResult.Free;
    end;
    CatalogFileName :=
      TTranslationWorkspace.DevelopmentCatalogFileName(
        AProfile, 'it-IT');
    TCatalogJson.SaveToFile(Catalog, CatalogFileName);
    TAITranslationWorkflow.PrepareSession(Catalog, CatalogFileName);

    ExternalCatalog := TCatalogJson.LoadFromFile(CatalogFileName);
    try
      for Entry in ExternalCatalog.Entries do
      begin
        Entry.TranslatedText := ItalianPilotTranslation(Entry.SourceText);
        Entry.Status := tsAIDraft;
        Entry.TranslationOrigin := torCodex;
        Entry.TranslationConfidence := 'high';
      end;
      TCatalogJson.SaveToFile(ExternalCatalog, CatalogFileName);
    finally
      ExternalCatalog.Free;
    end;

    OriginalCatalog := TCatalogJson.LoadFromFile(
      TAITranslationWorkflow.SnapshotFileName(CatalogFileName));
    try
      ExternalCatalog := TCatalogJson.LoadFromFile(CatalogFileName);
      try
        Review := TAITranslationWorkflow.AnalyzeExternalCatalog(
          OriginalCatalog, ExternalCatalog);
        try
          Require(not Review.HasBlockingIssues,
            'The in-place AI pilot failed protected-field review: ' +
            Review.Summary);
          Require(Review.ChangedCount = OriginalCatalog.Entries.Count,
            'The in-place AI pilot did not translate every scanned entry.');
          TAITranslationWorkflow.ApplyExternalTranslations(
            OriginalCatalog, ExternalCatalog);
        finally
          Review.Free;
        end;
      finally
        ExternalCatalog.Free;
      end;

      for Entry in OriginalCatalog.Entries do
      begin
        Require(Entry.Status = tsAIDraft,
          'An in-place AI pilot translation did not retain AI Draft status.');
        Require(Entry.TranslationOrigin = torCodex,
          'An in-place AI pilot translation did not retain Codex provenance.');
        Entry.Status := tsReviewed;
        Entry.Status := tsApproved;
      end;
      ValidationResult := TCatalogValidator.Validate(OriginalCatalog);
      try
        Require(not ValidationResult.HasErrors,
          'The in-place AI pilot catalog failed structural validation.');
      finally
        ValidationResult.Free;
      end;
      TCatalogJson.SaveToFile(OriginalCatalog, CatalogFileName);
      TRuntimePackBuilder.ExportToFile(OriginalCatalog,
        TTranslationWorkspace.RuntimePackFileName(AProfile, 'it-IT'));
    finally
      OriginalCatalog.Free;
    end;
    TFile.Delete(TAITranslationWorkflow.SnapshotFileName(CatalogFileName));
  finally
    Catalog.Free;
  end;
end;

procedure RemoveFMXDesignerMenuFixture(const AFixtureDirectory,
  AFormResourceFileName: string);
var
  FormFileName: string;
  FormText: string;
  MenuEndPosition: Integer;
  MenuStartPosition: Integer;
  SourceFileName: string;
  SourceText: string;
begin
  FormFileName := TPath.Combine(AFixtureDirectory,
    AFormResourceFileName);
  FormText := TFile.ReadAllText(FormFileName);
  MenuStartPosition := Pos('  object MainMenuBar: TMenuBar', FormText);
  MenuEndPosition := PosEx('  object ContentLayout: TLayout', FormText,
    MenuStartPosition);
  Require((MenuStartPosition > 0) and
    (MenuEndPosition > MenuStartPosition),
    'The no-menu FMX fixture could not remove its designer menu.');
  Delete(FormText, MenuStartPosition,
    MenuEndPosition - MenuStartPosition);
  TFile.WriteAllText(FormFileName, FormText);

  SourceFileName := TPath.ChangeExtension(FormFileName, '.pas');
  SourceText := TFile.ReadAllText(SourceFileName);
  SourceText := StringReplace(SourceText,
    '    MainMenuBar: TMenuBar;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuFile: TMenuItem;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuExit: TMenuItem;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuLanguage: TMenuItem;', '', []);
  TFile.WriteAllText(SourceFileName, SourceText);
end;

procedure RemoveVCLDesignerMenuFixture(const AFixtureDirectory,
  AFormResourceFileName: string);
var
  Depth: Integer;
  FormFileName: string;
  FormLines: TStringList;
  LineIndex: Integer;
  MenuEndIndex: Integer;
  MenuStartIndex: Integer;
  SourceFileName: string;
  SourceText: string;
begin
  FormFileName := TPath.Combine(AFixtureDirectory,
    AFormResourceFileName);
  FormLines := TStringList.Create;
  try
    FormLines.LoadFromFile(FormFileName);
    MenuStartIndex := -1;
    for LineIndex := 0 to FormLines.Count - 1 do
      if SameText(Trim(FormLines[LineIndex]),
        'object MainMenu: TMainMenu') then
      begin
        MenuStartIndex := LineIndex;
        Break;
      end;
    MenuEndIndex := -1;
    Depth := 0;
    if MenuStartIndex >= 0 then
      for LineIndex := MenuStartIndex to FormLines.Count - 1 do
      begin
        if StartsText('object ', Trim(FormLines[LineIndex])) then
          Inc(Depth)
        else if SameText(Trim(FormLines[LineIndex]), 'end') then
          Dec(Depth);
        if Depth = 0 then
        begin
          MenuEndIndex := LineIndex;
          Break;
        end;
      end;
    Require((MenuStartIndex >= 0) and
      (MenuEndIndex >= MenuStartIndex),
      'The no-menu VCL fixture could not remove its designer menu.');
    for LineIndex := MenuEndIndex downto MenuStartIndex do
      FormLines.Delete(LineIndex);
    FormLines.SaveToFile(FormFileName);
  finally
    FormLines.Free;
  end;

  SourceFileName := TPath.ChangeExtension(FormFileName, '.pas');
  SourceText := TFile.ReadAllText(SourceFileName);
  SourceText := StringReplace(SourceText,
    '    MainMenu: TMainMenu;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuFile: TMenuItem;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuExit: TMenuItem;', '', []);
  SourceText := StringReplace(SourceText,
    '    mnuLanguage: TMenuItem;', '', []);
  TFile.WriteAllText(SourceFileName, SourceText);
end;

procedure TestTargetIntegration(const AProjectRoot, ASampleDirectory,
  AProjectFileName, AFormResourceFileName: string;
  const AFixtureDirectoryName: string = '';
  const ARemoveDesignerMenu: Boolean = False);
var
  BackupDirectory: string;
  BackupFileName: string;
  BackupFileBytes: TBytes;
  BackupHash: string;
  Change: TIntegrationFileChange;
  ChangeSet: TIntegrationChangeSet;
  FixtureDirectory: string;
  FixtureDirectoryName: string;
  FormText: string;
  IntegrationUnitName: string;
  PackageDirectory: string;
  Profile: TProjectProfile;
  ProjectText: string;
  ResultInfo: TIntegrationApplyResult;
  RestoreRejected: Boolean;
  SourceText: string;
begin
  FixtureDirectoryName := AFixtureDirectoryName;
  if FixtureDirectoryName = '' then
    FixtureDirectoryName := ASampleDirectory;
  FixtureDirectory := TPath.Combine(AProjectRoot,
    'export\TargetIntegrationSmoke\' + FixtureDirectoryName);
  CopyFixtureDirectory(TPath.Combine(
    AProjectRoot, 'samples\' + ASampleDirectory), FixtureDirectory);
  if ARemoveDesignerMenu then
    if SameText(TPath.GetExtension(AFormResourceFileName), '.fmx') then
      RemoveFMXDesignerMenuFixture(FixtureDirectory,
        AFormResourceFileName)
    else
      RemoveVCLDesignerMenuFixture(FixtureDirectory,
        AFormResourceFileName);
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
      'export\TargetIntegrationBackups\' + FixtureDirectoryName + '\First');
    ResultInfo := TIntegrationTransaction.Apply(
      ChangeSet, BackupDirectory);
    try
      Require(ResultInfo.FilesWritten = ChangeSet.Changes.Count,
        'The transaction did not write every planned file.');
    finally
      ResultInfo.Free;
    end;
    SourceText := TFile.ReadAllText(TPath.Combine(
      BackupDirectory, 'integration-backup.json'));
    Require(ContainsText(SourceText, '"schemaVersion":2'),
      'The integration backup does not use the SHA-256 manifest schema.');
    Require(ContainsText(SourceText, '"sha256"'),
      'The integration backup manifest contains no content hashes.');
    BackupFileName := '';
    for Change in ChangeSet.Changes do
      if Change.OriginalExists then
      begin
        BackupFileName := TPath.Combine(
          TPath.Combine(BackupDirectory, 'Files'),
          Copy(Change.TargetFileName,
            Length(IncludeTrailingPathDelimiter(FixtureDirectory)) + 1,
            MaxInt));
        Break;
      end;
    Require(BackupFileName <> '',
      'The integration test found no original file to protect.');
    BackupHash := THashSHA2.GetHashStringFromFile(BackupFileName);
    BackupFileBytes := TFile.ReadAllBytes(BackupFileName);
    TFile.AppendAllText(BackupFileName, 'tamper-test', TEncoding.UTF8);
    RestoreRejected := False;
    try
      TIntegrationTransaction.Restore(
        FixtureDirectory, BackupDirectory);
    except
      on E: EIntegrationTransactionError do
        RestoreRejected := ContainsText(E.Message,
          'SHA-256 verification failed');
    end;
    Require(RestoreRejected,
      'Restore accepted a backup whose contents were changed.');
    TFile.WriteAllBytes(BackupFileName, BackupFileBytes);
    Require(SameText(BackupHash,
      THashSHA2.GetHashStringFromFile(BackupFileName)),
      'The integration test could not restore its backup fixture.');
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
  if ARemoveDesignerMenu then
  begin
    if Profile.Framework = tfFireMonkey then
      Require(ContainsText(FormText,
        'object datTranslationMenuBar: TMenuBar'),
        'The missing FMX designer menu bar was not created.')
    else
    begin
      Require(ContainsText(FormText,
        'object datTranslationMainMenu: TMainMenu'),
        'The missing VCL designer main menu was not created.');
    end;
    Require(ContainsText(FormText,
      'object mnuLanguage: TMenuItem'),
      'The missing Language menu was not created.');
    Require(ContainsText(FormText,
      'object datTranslationFileMenu: TMenuItem'),
      'The generated menu container lacks a File menu.');
    Require(ContainsText(FormText,
      'object datTranslationExitMenuItem: TMenuItem'),
      'The generated File menu lacks an Exit item.');
    Require(ContainsText(FormText,
      'OnClick = datTranslationExitClick'),
      'The generated Exit item is not designer-wired.');
  end;

  SourceText := TFile.ReadAllText(TPath.ChangeExtension(
    TPath.Combine(FixtureDirectory, AFormResourceFileName), '.pas'));
  Require(CountTextOccurrences(SourceText,
    'procedure datLanguageMenuItemClick(Sender: TObject);') = 1,
    'The form language handler declaration is missing or duplicated.');
  if ARemoveDesignerMenu then
  begin
    Require(ContainsText(SourceText,
      'mnuLanguage: TMenuItem;'),
      'The generated Language menu lacks its form-class field.');
    if Profile.Framework = tfFireMonkey then
      Require(ContainsText(SourceText,
        'datTranslationMenuBar: TMenuBar;'),
        'The generated FMX menu bar lacks its form-class field.')
    else
      Require(ContainsText(SourceText,
        'datTranslationMainMenu: TMainMenu;'),
        'The generated VCL main menu lacks its form-class field.');
    Require(ContainsText(SourceText,
      'datTranslationFileMenu: TMenuItem;'),
      'The generated File menu lacks its form-class field.');
    Require(ContainsText(SourceText,
      'datTranslationExitMenuItem: TMenuItem;'),
      'The generated Exit item lacks its form-class field.');
    Require(ContainsText(SourceText,
      'procedure datTranslationExitClick(Sender: TObject);'),
      'The generated Exit handler declaration is missing.');
    Require(ContainsText(SourceText, '  Close;'),
      'The generated Exit handler does not close its form.');
  end;

  ProjectText := TFile.ReadAllText(TPath.Combine(
    FixtureDirectory, TPath.ChangeExtension(
      AProjectFileName, '.dpr')));
  Require(CountTextOccurrences(ProjectText,
    'InitializeTranslation;') = 1,
    'Translation initialization is missing or duplicated.');
  if Profile.Framework = tfVCL then
    Require(CountTextOccurrences(ProjectText,
      'ApplyTranslation(') = 1,
      'VCL startup form translation is missing or duplicated.')
  else
  begin
    Require(CountTextOccurrences(ProjectText,
      'ApplyTranslation(') = 0,
      'Unsafe first-form FMX translation remained in the DPR.');
    Require(ContainsText(FormText,
      'OnCreate = datTranslationFormCreate'),
      'The FMX form resource lacks its designer-persisted startup event.');
    Require(ContainsText(SourceText, 'ApplyTranslation(Self);'),
      'The FMX OnCreate handler does not apply startup translation.');
  end;

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
    if ARemoveDesignerMenu then
      Require(CountTextOccurrences(FormText,
        'object datTranslationFileMenu: TMenuItem') = 1,
        'A repeated integration preview duplicated the generated File menu.');
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
        'export\TargetIntegrationBackups\' + FixtureDirectoryName +
        '\Final'));
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
  TestTargetIntegration(ProjectRoot, 'VCLBasic',
    'SampleVCLApp.dproj', 'SampleVCL.MainForm.dfm',
    'VCLWithoutMenu', True);
  TestTargetIntegration(ProjectRoot, 'FMXBasic',
    'SampleFMXApp.dproj', 'SampleFMX.MainForm.fmx');
  TestTargetIntegration(ProjectRoot, 'FMXBasic',
    'SampleFMXApp.dproj', 'SampleFMX.MainForm.fmx',
    'FMXWithoutMenu', True);
end;

procedure TestCompleteResetWorkflow;
var
  BackupDirectory: string;
  ChangeSet: TIntegrationChangeSet;
  FixtureDirectory: string;
  FormFileName: string;
  FormText: string;
  PackageDirectory: string;
  Plan: TCompleteResetPlan;
  Profile: TProjectProfile;
  ProjectRoot: string;
  ResultInfo: TIntegrationApplyResult;
  SafetyBackupDirectory: string;
begin
  ProjectRoot := TPath.GetFullPath(GetCurrentDir);
  FixtureDirectory := TPath.Combine(ProjectRoot,
    'export\CompleteResetSmoke\FMXBasic');
  CopyFixtureDirectory(TPath.Combine(ProjectRoot,
    'samples\FMXBasic'), FixtureDirectory);
  TFile.WriteAllText(TPath.Combine(FixtureDirectory,
    'developer-owned.txt'), 'preserve me', TEncoding.UTF8);
  Profile := TProjectDetector.Detect(TPath.Combine(
    FixtureDirectory, 'SampleFMXApp.dproj'));
  ExportItalianFixturePack(Profile);
  PackageDirectory := TIntegrationPackageGenerator.Generate(
    Profile, TPath.Combine(ProjectRoot,
      'export\CompleteResetSmoke\Packages'),
    TPath.Combine(ProjectRoot, 'source\runtime'));
  ChangeSet := TTargetIntegrationEngine.BuildChangeSet(
    Profile, PackageDirectory, 'mnuLanguage');
  try
    BackupDirectory := TPath.Combine(FixtureDirectory,
      'Localization\Integration Backups\Translation Integration Test');
    ResultInfo := TIntegrationTransaction.Apply(
      ChangeSet, BackupDirectory);
    ResultInfo.Free;
  finally
    ChangeSet.Free;
  end;

  FormFileName := TPath.Combine(FixtureDirectory,
    'SampleFMX.MainForm.fmx');
  Require(ContainsText(TFile.ReadAllText(FormFileName),
    'datLanguage_it_IT'),
    'The complete-reset fixture was not integrated first.');
  Plan := TCompleteResetEngine.BuildPlan(
    Profile.ProjectName, FixtureDirectory);
  try
    Require(SameText(Plan.BaselineBackupDirectory,
      BackupDirectory),
      'Complete Reset did not select the original integration baseline.');
    SafetyBackupDirectory := TPath.Combine(ProjectRoot,
      'export\CompleteResetSmoke\SafetyBackup');
    TCompleteResetEngine.Execute(Plan, SafetyBackupDirectory);
    Require(TFile.Exists(TPath.Combine(
      SafetyBackupDirectory, 'integration-backup.json')),
      'Complete Reset did not retain its verified safety backup.');
  finally
    Plan.Free;
  end;

  FormText := TFile.ReadAllText(FormFileName);
  Require(not ContainsText(FormText, 'datLanguage_it_IT'),
    'Complete Reset did not restore the original form resource.');
  Require(not TDirectory.Exists(TPath.Combine(
    FixtureDirectory, 'Localization\Development')),
    'Complete Reset retained the development catalogs.');
  Require(not TDirectory.Exists(TPath.Combine(
    FixtureDirectory, 'Localization\Languages')),
    'Complete Reset retained the runtime language packs.');
  Require(not TDirectory.Exists(TPath.Combine(
    FixtureDirectory, 'Localization\Runtime')),
    'Complete Reset retained the generated runtime units.');
  Require(TFile.ReadAllText(TPath.Combine(FixtureDirectory,
    'developer-owned.txt'), TEncoding.UTF8) = 'preserve me',
    'Complete Reset changed an unrelated developer-owned file.');
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

procedure TestExactIntegrationReview;
var
  Change: TIntegrationFileChange;
  ReviewText: string;
begin
  Change := TIntegrationFileChange.Create;
  try
    Change.TargetFileName := 'Example.pas';
    Change.Description := 'Update startup';
    Change.OriginalExists := True;
    Change.OriginalText :=
      'line one' + sLineBreak +
      'old line' + sLineBreak +
      'line three';
    Change.NewText :=
      'line one' + sLineBreak +
      'new line' + sLineBreak +
      'line three';
    ReviewText := Change.ExactReviewText;
    Require(ContainsText(ReviewText, '- O:0002'),
      'Exact review did not identify the removed line.');
    Require(ContainsText(ReviewText, 'N:0002 | new line'),
      'Exact review did not identify the proposed line.');
    Require(ContainsText(ReviewText, 'old line') and
      ContainsText(ReviewText, 'new line'),
      'Exact review omitted changed text.');
  finally
    Change.Free;
  end;
end;

procedure TestProjectUnitInsertionBeforeResourceDirective;
var
  ProjectText: string;
  UpdatedText: string;
begin
  ProjectText :=
    'program WebsiteAnalytics;' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  System.StartUpCopy,' + sLineBreak +
    '  FMX.Forms,' + sLineBreak +
    '  WebsiteAnalytics.GA4DataModule in ' +
      '''WebsiteAnalytics.GA4DataModule.pas'' ' +
      '{dmGA4: TDataModule};' + sLineBreak + sLineBreak +
    '{$R *.res}' + sLineBreak + sLineBreak +
    'begin' + sLineBreak +
    '  Application.Initialize;' + sLineBreak +
    '  Application.Run;' + sLineBreak +
    'end.';
  UpdatedText := TDelphiIntegrationSourceEditor.AddProjectUnitReference(
    ProjectText, 'WebsiteAnalytics.Translation',
    'Localization\Runtime\WebsiteAnalytics.Translation.pas');
  Require(ContainsText(UpdatedText,
    'WebsiteAnalytics.GA4DataModule.pas'' {dmGA4: TDataModule},'),
    'The final DPR unit reference was not changed to a comma.');
  Require(ContainsText(UpdatedText,
    'WebsiteAnalytics.Translation in ' +
      '''Localization\Runtime\WebsiteAnalytics.Translation.pas'';'),
    'The generated DPR unit reference was not inserted.');
  Require(Pos('WebsiteAnalytics.Translation in', UpdatedText) <
    Pos('{$R *.res}', UpdatedText),
    'The generated DPR unit reference was inserted after the resource directive.');
end;

procedure TestImplementationUsesAfterResourceDirective;
var
  ImplementationUsesPosition: Integer;
  SourceText: string;
  UpdatedText: string;
begin
  SourceText :=
    'unit WebsiteAnalytics.MainForm;' + sLineBreak + sLineBreak +
    'interface' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  System.Classes;' + sLineBreak + sLineBreak +
    'type' + sLineBreak +
    '  TfrmMainDashboard = class(TObject)' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak +
    'implementation' + sLineBreak + sLineBreak +
    '{$R *.fmx}' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  WebsiteAnalytics.DiagnosticsForm;' + sLineBreak + sLineBreak +
    'end.';
  UpdatedText := TDelphiIntegrationSourceEditor.AddFormLanguageHandler(
    SourceText, 'TfrmMainDashboard', 'WebsiteAnalytics.Translation');
  ImplementationUsesPosition := PosEx('uses', UpdatedText,
    Pos('implementation', UpdatedText) + Length('implementation'));
  Require(ImplementationUsesPosition > Pos('{$R *.fmx}', UpdatedText),
    'The existing implementation uses clause moved ahead of its resource directive.');
  Require(ContainsText(UpdatedText,
    'WebsiteAnalytics.DiagnosticsForm,' + sLineBreak +
    '  WebsiteAnalytics.Translation;'),
    'The translation unit was not merged into the existing implementation uses clause.');
  Require(CountTextOccurrences(UpdatedText,
    'uses' + sLineBreak) = 2,
    'Integration created a duplicate implementation uses clause.');
end;

procedure TestFMXProjectStartupDefersTranslationToForms;
var
  ProjectText: string;
  UpdatedText: string;
begin
  ProjectText :=
    'program MultiFormFMX;' + sLineBreak + sLineBreak +
    'uses' + sLineBreak +
    '  FMX.Forms,' + sLineBreak +
    '  MainForm in ''MainForm.pas'' {frmMain},' + sLineBreak +
    '  ChildForm in ''ChildForm.pas'' {frmChild};' + sLineBreak + sLineBreak +
    '{$R *.res}' + sLineBreak + sLineBreak +
    'begin' + sLineBreak +
    '  Application.Initialize;' + sLineBreak +
    '  Application.CreateForm(TfrmMain, frmMain);' + sLineBreak +
    '  ApplyTranslation(frmMain);' + sLineBreak +
    '  Application.CreateForm(TfrmChild, frmChild);' + sLineBreak +
    '  ApplyTranslation(frmChild);' + sLineBreak +
    '  Application.Run;' + sLineBreak +
    'end.';
  UpdatedText := TDelphiIntegrationSourceEditor.AddProjectStartup(
    ProjectText, 'MultiFormFMX.Translation',
    'Localization\Runtime\MultiFormFMX.Translation.pas', True);
  Require(CountTextOccurrences(UpdatedText,
    'ApplyTranslation(') = 0,
    'FMX DPR translation calls remained before RealCreateForms.');
  Require(CountTextOccurrences(UpdatedText,
    'Application.CreateForm(') = 2,
    'FMX startup correction changed the project form registrations.');
  Require(ContainsText(UpdatedText, 'InitializeTranslation;'),
    'FMX startup correction removed translation initialization.');
end;

procedure TestSecondaryFMXFormStartupWiring;
var
  Edit: TMenuResourceEdit;
  FormText: string;
  SourceText: string;
  UpdatedSource: string;
begin
  FormText :=
    'object frmChild: TfrmChild' + sLineBreak +
    '  Caption = ''Child''' + sLineBreak +
    'end.';
  Edit := TLanguageMenuResourceEditor.EnsureFMXTranslationStartup(
    'ChildForm.fmx', FormText);
  try
    Require(ContainsText(Edit.NewText,
      'OnCreate = datTranslationFormCreate'),
      'A secondary FMX form did not receive designer startup wiring.');
    SourceText :=
      'unit ChildForm;' + sLineBreak + sLineBreak +
      'interface' + sLineBreak + sLineBreak +
      'uses System.Classes, FMX.Forms;' + sLineBreak + sLineBreak +
      'type' + sLineBreak +
      '  TfrmChild = class(TForm)' + sLineBreak +
      '  end;' + sLineBreak + sLineBreak +
      'implementation' + sLineBreak + sLineBreak +
      '{$R *.fmx}' + sLineBreak + sLineBreak +
      'end.';
    UpdatedSource :=
      TDelphiIntegrationSourceEditor.AddFMXFormCreateTranslation(
        SourceText, Edit.FormClassName,
        Edit.FormCreateHandlerName, 'MultiFormFMX.Translation');
    Require(ContainsText(UpdatedSource,
      'procedure datTranslationFormCreate(Sender: TObject);'),
      'A secondary FMX form lacks its startup-handler declaration.');
    Require(ContainsText(UpdatedSource,
      'ApplyTranslation(Self);'),
      'A secondary FMX form does not apply its selected language.');
  finally
    Edit.Free;
  end;
end;

procedure TestInPlaceAITranslationWorkflow;
var
  Catalog: TTranslationCatalog;
  CatalogFile: string;
  Entry: TTranslationEntry;
  ExternalCatalog: TTranslationCatalog;
  Review: TAITranslationReview;
  TestDirectory: string;
begin
  TestDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT-AI-' + TPath.GetRandomFileName);
  TDirectory.CreateDirectory(TestDirectory);
  Catalog := TTranslationCatalog.Create;
  ExternalCatalog := nil;
  Review := nil;
  try
    Catalog.ApplicationId := 'AIWorkflowFixture';
    Catalog.Framework := tfFireMonkey;
    Catalog.SourceLanguage := 'en-US';
    Catalog.Locale.LanguageCode := 'it-IT';
    Catalog.Locale.NativeLanguageName := 'Italiano';
    Entry := TTranslationEntry.Create;
    Entry.Key := 'frmMain.btnSave.Text';
    Entry.SourceText := 'Save';
    Entry.SourceChecksum := 'fixture-checksum';
    Entry.FormName := 'frmMain';
    Entry.ComponentName := 'btnSave';
    Entry.ComponentClassName := 'TButton';
    Entry.PropertyName := 'Text';
    Entry.SourceKind := 'Form property';
    Entry.RuntimeApplication := rakAutomatic;
    Entry.RuntimeWiringConfirmed := True;
    Entry.Status := tsNeedsTranslation;
    Catalog.Entries.Add(Entry);
    CatalogFile := TPath.Combine(TestDirectory,
      'AIWorkflowFixture.it-IT.translation-project.json');
    TCatalogJson.SaveToFile(Catalog, CatalogFile);
    TAITranslationWorkflow.PrepareSession(Catalog, CatalogFile);
    Require(TFile.Exists(
      TAITranslationWorkflow.ProfileFileName(CatalogFile)),
      'AI translation profile was not created.');
    Require(TFile.Exists(
      TAITranslationWorkflow.InstructionsFileName(CatalogFile)),
      'AI translation instructions were not created.');
    Require(TFile.Exists(
      TAITranslationWorkflow.SnapshotFileName(CatalogFile)),
      'AI recovery snapshot was not created.');

    ExternalCatalog := TCatalogJson.Deserialize(
      TCatalogJson.Serialize(Catalog));
    ExternalCatalog.Entries[0].TranslatedText := 'Salva';
    ExternalCatalog.Entries[0].Status := tsAIDraft;
    ExternalCatalog.Entries[0].TranslationOrigin := torCodex;
    ExternalCatalog.Entries[0].TranslationConfidence := 'high';
    Review := TAITranslationWorkflow.AnalyzeExternalCatalog(
      Catalog, ExternalCatalog);
    Require(not Review.HasBlockingIssues,
      'A valid in-place AI translation was rejected.');
    Require(Review.ChangedCount = 1,
      'The AI translation change was not counted.');
    TAITranslationWorkflow.ApplyExternalTranslations(
      Catalog, ExternalCatalog);
    Require((Catalog.Entries[0].TranslatedText = 'Salva') and
      (Catalog.Entries[0].Status = tsAIDraft) and
      (Catalog.Entries[0].TranslationOrigin = torCodex),
      'The valid AI translation was not adopted safely.');
    FreeAndNil(Review);
    ExternalCatalog.SourceLanguage := 'de-DE';
    Review := TAITranslationWorkflow.AnalyzeExternalCatalog(
      Catalog, ExternalCatalog);
    Require(Review.HasBlockingIssues,
      'A protected catalog mutation was not rejected.');
    FreeAndNil(Review);

    ExternalCatalog.SourceLanguage := Catalog.SourceLanguage;
    Catalog.Entries[0].Status := tsSourceChanged;
    ExternalCatalog.Entries[0].Status := tsAIDraft;
    ExternalCatalog.Entries[0].TranslationOrigin := torClaude;
    ExternalCatalog.Entries[0].TranslationConfidence := 'medium';
    ExternalCatalog.Entries[0].TranslationReviewNote :=
      'Existing wording remains correct after the source edit.';
    Review := TAITranslationWorkflow.AnalyzeExternalCatalog(
      Catalog, ExternalCatalog);
    Require(not Review.HasBlockingIssues,
      'A valid metadata-only AI confirmation was rejected.');
    Require(Review.ChangedCount = 1,
      'A metadata-only AI confirmation was not counted.');
    TAITranslationWorkflow.ApplyExternalTranslations(
      Catalog, ExternalCatalog);
    Require((Catalog.Entries[0].Status = tsAIDraft) and
      (Catalog.Entries[0].TranslationOrigin = torClaude) and
      (Catalog.Entries[0].TranslationConfidence = 'medium'),
      'A metadata-only AI confirmation was not adopted.');
    FreeAndNil(Review);

    Catalog.Entries[0].Status := tsExcluded;
    ExternalCatalog.Entries[0].TranslatedText := 'Non applicare';
    Review := TAITranslationWorkflow.AnalyzeExternalCatalog(
      Catalog, ExternalCatalog);
    Require(Review.HasBlockingIssues,
      'A change to an excluded entry was not rejected.');
  finally
    Review.Free;
    ExternalCatalog.Free;
    Catalog.Free;
    if TDirectory.Exists(TestDirectory) then
      TDirectory.Delete(TestDirectory, True);
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
    TestCatalogCsvRoundTrip;
    TestWorkspacePaths;
    TestCatalogValidation;
    TestRuntimePack;
    TestRuntimeLoadingAndPreference;
    TestIntegrationPlanningAndPackage;
    TestTransactionalTargetIntegration;
    TestCompleteResetWorkflow;
    TestStudioSelfIntegrationChangeSet;
    TestExactIntegrationReview;
    TestProjectUnitInsertionBeforeResourceDirective;
    TestImplementationUsesAfterResourceDirective;
    TestFMXProjectStartupDefersTranslationToForms;
    TestSecondaryFMXFormStartupWiring;
    TestInPlaceAITranslationWorkflow;
    Writeln('Foundation, scanner, catalog, runtime, validation, and export tests passed.');
  except
    on E: Exception do
    begin
      Writeln('Foundation smoke tests failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
