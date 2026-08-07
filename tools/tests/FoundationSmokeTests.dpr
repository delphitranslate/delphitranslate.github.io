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
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in '..\..\source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.FormText in '..\..\source\scan\DAT.Scan.FormText.pas',
  DAT.Scan.PascalResources in '..\..\source\scan\DAT.Scan.PascalResources.pas',
  DAT.Scan.Project in '..\..\source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in '..\..\source\scan\DAT.Scan.CatalogMerge.pas',
  DAT.Validation.Catalog in '..\..\source\validation\DAT.Validation.Catalog.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
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

begin
  try
    TestProjectDetection;
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
    Writeln('Foundation, scanner, catalog, runtime, validation, and export tests passed.');
  except
    on E: Exception do
    begin
      Writeln('Foundation smoke tests failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
