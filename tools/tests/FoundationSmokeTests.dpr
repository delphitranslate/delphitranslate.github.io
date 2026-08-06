program FoundationSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.ProjectDetection in '..\..\source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in '..\..\source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.FormText in '..\..\source\scan\DAT.Scan.FormText.pas',
  DAT.Scan.PascalResources in '..\..\source\scan\DAT.Scan.PascalResources.pas',
  DAT.Scan.Project in '..\..\source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in '..\..\source\scan\DAT.Scan.CatalogMerge.pas';

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

begin
  try
    TestProjectDetection;
    TestCatalogRoundTrip;
    TestProjectScanning;
    TestIncrementalCatalogMerge;
    Writeln('Foundation and scanner smoke tests passed.');
  except
    on E: Exception do
    begin
      Writeln('Foundation smoke tests failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
