program FoundationSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Generics.Collections,
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
  DAT.Core.Hyphenation in '..\..\source\core\DAT.Core.Hyphenation.pas',
  DAT.Core.RuntimePack in '..\..\source\core\DAT.Core.RuntimePack.pas',
  DAT.Core.Terminology in '..\..\source\core\DAT.Core.Terminology.pas',
  DAT.Core.Glossary in '..\..\source\core\DAT.Core.Glossary.pas',
  DAT.Review.CodeGeometry in '..\..\source\review\DAT.Review.CodeGeometry.pas',
  DAT.Review.Localization in '..\..\source\review\DAT.Review.Localization.pas',
  DAT.Review.TextMeasurement in '..\..\source\review\DAT.Review.TextMeasurement.pas',
  DAT.Review.TextMeasurement.GDI in '..\..\source\review\DAT.Review.TextMeasurement.GDI.pas',
  DAT.Review.TextMeasurement.FMX in '..\..\source\review\DAT.Review.TextMeasurement.FMX.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Runtime.Preference in '..\..\source\runtime\DAT.Runtime.Preference.pas',
  DAT.Runtime.Manager in '..\..\source\runtime\DAT.Runtime.Manager.pas',
  DAT.Integration.Package in '..\..\source\integration\DAT.Integration.Package.pas',
  DAT.Integration.ComponentPackage in '..\..\source\integration\DAT.Integration.ComponentPackage.pas',
  DAT.Integration.MenuResource in '..\..\source\integration\DAT.Integration.MenuResource.pas',
  DAT.Integration.DelphiSource in '..\..\source\integration\DAT.Integration.DelphiSource.pas',
  DAT.Scan.Types in '..\..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Rules in '..\..\source\scan\DAT.Scan.Rules.pas',
  DAT.Scan.DomainProfile in '..\..\source\scan\DAT.Scan.DomainProfile.pas',
  DAT.Scan.Context in '..\..\source\scan\DAT.Scan.Context.pas',
  DAT.Scan.Quality in '..\..\source\scan\DAT.Scan.Quality.pas',
  DAT.Scan.TextCodec in '..\..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Scan.FormText in '..\..\source\scan\DAT.Scan.FormText.pas',
  DAT.Scan.PascalResources in '..\..\source\scan\DAT.Scan.PascalResources.pas',
  DAT.Scan.Project in '..\..\source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in '..\..\source\scan\DAT.Scan.CatalogMerge.pas',
  DAT.Provider.Types in '..\..\source\provider\DAT.Provider.Types.pas',
  DAT.Provider.Placeholders in '..\..\source\provider\DAT.Provider.Placeholders.pas',
  DAT.Provider.Batching in '..\..\source\provider\DAT.Provider.Batching.pas',
  DAT.Provider.LanguageCodes in '..\..\source\provider\DAT.Provider.LanguageCodes.pas',
  DAT.Provider.CalendarTerms in '..\..\source\provider\DAT.Provider.CalendarTerms.pas',
  DAT.Provider.Retry in '..\..\source\provider\DAT.Provider.Retry.pas',
  DAT.Provider.Client in '..\..\source\provider\DAT.Provider.Client.pas',
  DAT.Validation.Catalog in '..\..\source\validation\DAT.Validation.Catalog.pas';

type
  TProviderClientAccess = class(TTranslationProviderClient)
  public
    function PublicBuildRequestBody(const ATexts: TArray<string>;
      const ASourceLanguage, ATargetLanguage: string;
      const AContext: string = ''): string;
    function PublicEndpoint: string;
    function PublicParseResponse(
      const AResponseText: string): TArray<string>;
  end;

function TProviderClientAccess.PublicBuildRequestBody(
  const ATexts: TArray<string>; const ASourceLanguage,
  ATargetLanguage, AContext: string): string;
begin
  Result := BuildRequestBody(ATexts,
    ASourceLanguage, ATargetLanguage, AContext);
end;

procedure Require(const ACondition: Boolean; const AMessage: string); forward;

procedure TestUnicodeTextRepairContract;
var
  CorrectGerman: string;
  MisdecodedGerman: string;
begin
  CorrectGerman := #$00DC + 'berpr' + #$00FC +
    'fen Sie das FMX-' + #$00C4 + 'quivalent';
  Require(RepairMisdecodedText(CorrectGerman) = CorrectGerman,
    'Correct non-ASCII text was rejected by the mojibake repair boundary.');

  MisdecodedGerman := 'Zur' + #$00C3 + #$00BC + 'cksetzen';
  Require(RepairMisdecodedText(MisdecodedGerman) =
    'Zur' + #$00FC + 'cksetzen',
    'A genuine UTF-8-as-Windows-1252 sequence was not repaired.');

  Require(RepairMisdecodedText(#$0627 + #$0644 + #$0639 + #$0631 +
    #$0628 + #$064A + #$0629) = #$0627 + #$0644 + #$0639 + #$0631 +
    #$0628 + #$064A + #$0629,
    'Unicode text outside Windows-1252 was changed by text repair.');
end;

procedure TestLocalizationIntelligence;
var
  Catalog: TTranslationCatalog;
  Entry, EnvelopeEntry: TTranslationEntry;
  Glossary, LoadedGlossary: TProjectGlossary;
  Suggestions: TObjectList<TGlossarySuggestion>;
  Term: TProjectGlossaryTerm;
  Review: TLocalizationReview;
  TestDirectory, FormFileName, GlossaryFileName, CatalogFileName: string;
  HtmlFileName, ProposalFileName, EnvelopeFileName: string;
  CatalogFiles: TArray<string>;
begin
  TestDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT-LocalizationIntelligence-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(TestDirectory);
  Catalog := TTranslationCatalog.Create;
  Glossary := TProjectGlossary.Create;
  LoadedGlossary := nil;
  Review := nil;
  Suggestions := nil;
  try
    FormFileName := TPath.Combine(TestDirectory, 'Fixture.fmx');
    TFile.WriteAllText(FormFileName,
      'object frmFixture: TForm' + sLineBreak +
      '  ClientWidth = 400' + sLineBreak +
      '  ClientHeight = 220' + sLineBreak +
      '  object btnClose: TButton' + sLineBreak +
      '    Position.X = 20' + sLineBreak +
      '    Position.Y = 20' + sLineBreak +
      '    Size.Width = 55' + sLineBreak +
      '    Size.Height = 30' + sLineBreak +
      '    Text = ''Close''' + sLineBreak +
      '  end' + sLineBreak +
      'end', TEncoding.UTF8);
    Catalog.ApplicationId := 'LocalizationFixture';
    Catalog.SourceLanguage := 'en-US';
    Catalog.Locale.LanguageCode := 'es-ES';
    Entry := TTranslationEntry.Create;
    Entry.Key := 'frmFixture.btnClose.Text';
    Entry.FormName := 'frmFixture';
    Entry.ComponentName := 'btnClose';
    Entry.ComponentClassName := 'TButton';
    Entry.PropertyName := 'Text';
    Entry.SourceText := 'Close';
    Entry.TranslatedText := 'Una traduccion deliberadamente extensa';
    Entry.SourceFileName := FormFileName;
    Entry.Status := tsMachineTranslated;
    Entry.TranslationOrigin := torGoogle;
    Entry.TranslationConfidence := 'provider-basic';
    Catalog.Entries.Add(Entry);

    Glossary.ApplicationId := Catalog.ApplicationId;
    Glossary.SourceLanguage := Catalog.SourceLanguage;
    Glossary.TargetLanguage := Catalog.Locale.LanguageCode;
    Term := TProjectGlossaryTerm.Create;
    Term.SourceText := 'Close';
    Term.TargetText := 'Cerrar';
    Term.Approved := True;
    Glossary.Terms.Add(Term);
    GlossaryFileName := TPath.Combine(TestDirectory, 'glossary.json');
    Glossary.SaveToFile(GlossaryFileName);
    LoadedGlossary := TProjectGlossary.LoadFromFile(GlossaryFileName);
    Require(LoadedGlossary.ApplyToCatalog(Catalog) = 1,
      'The approved project glossary was not applied.');
    Require((Entry.TranslatedText = 'Cerrar') and
      (Entry.TranslationOrigin = torProjectGlossary),
      'Project glossary provenance was not preserved.');

    Entry.TranslatedText := 'Una traduccion deliberadamente extensa';
    Entry.TranslationOrigin := torGoogle;
    Suggestions := TProjectGlossarySuggester.Build(Catalog, Glossary);
    Require(Suggestions.Count = 0,
      'An already-approved glossary term was suggested again.');
    FreeAndNil(Suggestions);
    Glossary.Terms.Clear;
    Suggestions := TProjectGlossarySuggester.Build(Catalog, Glossary);
    Require((Suggestions.Count = 1) and
      SameText(Suggestions[0].Provenance, 'Google') and
      not Suggestions[0].CanBulkApprove,
      'Provider terminology provenance or approval safety is incorrect.');
    Review := TLocalizationReviewer.Analyze(Catalog);
    Require(Review.Controls.Count >= 2,
      'The read-only layout scanner did not inventory the form.');
    Require(Review.Proposals.Count > 0,
      'The layout audit did not propose a correction for obvious overflow.');
    HtmlFileName := TPath.Combine(TestDirectory, 'review.html');
    ProposalFileName := TPath.Combine(TestDirectory, 'proposal.json');
    TLocalizationReviewer.GenerateReviewPackage(Review, HtmlFileName,
      ProposalFileName);
    Require(TFile.Exists(HtmlFileName) and TFile.Exists(ProposalFileName),
      'The visual review package or proposal file was not created.');
    CatalogFileName := TPath.Combine(TestDirectory, 'catalog.json');
    EnvelopeEntry := TTranslationEntry.Create;
    EnvelopeEntry.Key := 'frmFixture.btnClose.TextPrompt';
    EnvelopeEntry.FormName := 'frmFixture';
    EnvelopeEntry.ComponentName := 'btnClose';
    EnvelopeEntry.PropertyName := 'TextPrompt';
    EnvelopeEntry.SourceText := 'Close the current window';
    { Loading every development catalog while building the multilingual
      envelope invokes the shared text-repair boundary. Correct German text
      with umlauts must survive that reload without a code-page exception. }
    EnvelopeEntry.TranslatedText := #$00DC + 'berpr' + #$00FC +
      'fen Sie das FMX-' + #$00C4 + 'quivalent';
    EnvelopeEntry.Status := tsMachineTranslated;
    Catalog.Entries.Add(EnvelopeEntry);
    TCatalogJson.SaveToFile(Catalog, CatalogFileName);
    SetLength(CatalogFiles, 1);
    CatalogFiles[0] := CatalogFileName;
    EnvelopeFileName := TPath.Combine(TestDirectory, 'envelope.json');
    TLocalizationReviewer.SaveEnvelope(CatalogFiles, EnvelopeFileName);
    Require(TFile.Exists(EnvelopeFileName),
      'The multilingual layout envelope was not created.');
  finally
    Review.Free;
    Suggestions.Free;
    LoadedGlossary.Free;
    Glossary.Free;
    Catalog.Free;
    if TDirectory.Exists(TestDirectory) then
      TDirectory.Delete(TestDirectory, True);
  end;
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
    RequestBody := Client.PublicBuildRequestBody(SourceTexts, 'en-US',
      'it-IT', 'Text used as a user command in a desktop application.');
    Require(ContainsText(RequestBody, '"context":'),
      'The DeepL request does not include approved UI context.');
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
    RequestBody := Client.PublicBuildRequestBody(SourceTexts, 'en-US',
      'it-IT', 'Context must not be sent to Google Basic.');
    Require(not ContainsText(RequestBody, '"context":'),
      'Google Basic was sent an unsupported context field.');
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
    Entry.RuntimeTextRole := rtrRuntimeTemplate;
    Entry.RuntimeWiringConfirmed := True;
    Entry.ContextKind := 'user command';
    Entry.ContextDescription :=
      'Text used as a user command in a desktop application.';
    Entry.SemanticConcept := 'command.save';
    Entry.ContextConfidence := 'inferred';
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
      Require(LoadedCatalog.Entries[0].RuntimeTextRole = rtrRuntimeTemplate,
        'Runtime text role was not preserved.');
      Require(LoadedCatalog.Entries[0].RuntimeWiringConfirmed,
        'Runtime wiring confirmation was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceFileName = 'MainForm.dfm',
        'Source filename was not preserved.');
      Require(LoadedCatalog.Entries[0].SourceLine = 42,
        'Source line was not preserved.');
      Require((LoadedCatalog.Entries[0].ContextKind = 'user command') and
        (LoadedCatalog.Entries[0].SemanticConcept = 'command.save') and
        (LoadedCatalog.Entries[0].ContextConfidence = 'inferred'),
        'Translation context metadata was not preserved.');
    finally
      LoadedCatalog.Free;
    end;

    LoadedCatalog := TCatalogJson.Deserialize(
      '{"schemaVersion":1,"applicationId":"Legacy","framework":"VCL",' +
      '"sourceLanguage":"en-US","entries":[{"key":"Unit1.SMessage",' +
      '"sourceText":"Message","sourceKind":"Resource string",' +
      '"status":"needsTranslation"}]}');
    try
      Require(LoadedCatalog.SchemaVersion = 6,
        'A schema version 1 catalog was not migrated to version 6.');
      Require(LoadedCatalog.Entries[0].RuntimeApplication =
        rakManualTranslateText,
        'Legacy resourcestring runtime mode was not derived.');
      Require(LoadedCatalog.Entries[0].RuntimeTextRole = rtrRuntimeTemplate,
        'Legacy resourcestring runtime role was not derived.');
      Require(not LoadedCatalog.Entries[0].RuntimeWiringConfirmed,
        'Legacy resourcestring wiring should require confirmation.');
    finally
      LoadedCatalog.Free;
    end;
  finally
    SourceCatalog.Free;
  end;
end;

procedure TestContextualTerminology;
var
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  ScanItem: TScanItem;
  Translation: string;
begin
  ScanItem := TScanItem.Create;
  try
    ScanItem.SourceText := 'Play';
    ScanItem.FormName := 'frmCarillon';
    ScanItem.ComponentName := 'btnPlaySong';
    ScanItem.ComponentClassName := 'TButton';
    ScanItem.PropertyName := 'Text';
    TScanContextAnalyzer.Analyze(ScanItem);
    Require(ScanItem.SemanticConcept = 'media.play',
      'Carillon Play was not classified as media playback.');
    Entry := TTranslationEntry.Create;
    try
      Entry.SemanticConcept := ScanItem.SemanticConcept;
      Require(TTerminologyResolver.TryResolve(Entry, 'es-ES', Translation)
        and (Translation = 'Reproducir'),
        'Spanish media Play terminology is incorrect.');
    finally
      Entry.Free;
    end;
  finally
    ScanItem.Free;
  end;

  ScanItem := TScanItem.Create;
  try
    ScanItem.SourceText := 'Schedule';
    ScanItem.ComponentName := 'File2';
    ScanItem.ComponentClassName := 'TMenuItem';
    ScanItem.PropertyName := 'Text';
    TScanContextAnalyzer.Analyze(ScanItem);
    Require(ScanItem.SemanticConcept = 'noun.schedule',
      'A Schedule menu heading was classified as a scheduling command.');
    Entry := TTranslationEntry.Create;
    try
      Entry.SourceText := ScanItem.SourceText;
      Entry.SemanticConcept := ScanItem.SemanticConcept;
      Require(TTerminologyResolver.TryResolve(Entry, 'es-ES', Translation)
        and (Translation = 'Horario'),
        'Spanish Schedule menu terminology is incorrect.');
    finally
      Entry.Free;
    end;
  finally
    ScanItem.Free;
  end;

  ScanItem := TScanItem.Create;
  try
    ScanItem.SourceText := 'Language:';
    ScanItem.ComponentName := 'lblLanguage';
    ScanItem.ComponentClassName := 'TLabel';
    ScanItem.PropertyName := 'Text';
    TScanContextAnalyzer.Analyze(ScanItem);
    Entry := TTranslationEntry.Create;
    try
      Entry.SourceText := ScanItem.SourceText;
      Entry.SemanticConcept := ScanItem.SemanticConcept;
      Require(TTerminologyResolver.TryResolve(Entry, 'es-ES', Translation)
        and (Translation = 'Idioma:'),
        'The Spanish Language label did not preserve its colon.');
    finally
      Entry.Free;
    end;
  finally
    ScanItem.Free;
  end;

  Catalog := TTranslationCatalog.Create;
  try
    Entry := TTranslationEntry.Create;
    Entry.SourceText := 'Close';
    Entry.ContextKind := 'user command';
    Entry.SemanticConcept := 'command.close';
    Entry.TranslatedText := 'Cerrar';
    Entry.Status := tsApproved;
    Catalog.Entries.Add(Entry);
    Entry := TTranslationEntry.Create;
    Entry.SourceText := 'Close';
    Entry.ContextKind := 'user command';
    Entry.SemanticConcept := 'command.close';
    Catalog.Entries.Add(Entry);
    Require(TTerminologyResolver.TryTranslationMemory(Catalog, Entry,
      Translation) and (Translation = 'Cerrar'),
      'Approved contextual translation memory was not reused.');
  finally
    Catalog.Free;
  end;
end;

procedure TestAuthoritativeTerminologyRepair;
var
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
begin
  Catalog := TTranslationCatalog.Create;
  try
    Catalog.Locale.LanguageCode := 'es-ES';
    Entry := TTranslationEntry.Create;
    Entry.SourceText := 'Close';
    Entry.TranslatedText := 'Cerca';
    Entry.SemanticConcept := 'command.close';
    Entry.Status := tsMachineTranslated;
    Entry.TranslationOrigin := torGoogle;
    Catalog.Entries.Add(Entry);
    Entry := TTranslationEntry.Create;
    Entry.SourceText := 'Wed';
    Entry.TranslatedText := 'Casarse';
    Entry.SemanticConcept := 'calendar.wednesday';
    Entry.Status := tsMachineTranslated;
    Entry.TranslationOrigin := torGoogle;
    Catalog.Entries.Add(Entry);
    Entry := TTranslationEntry.Create;
    Entry.SourceText := 'Times to play:';
    Entry.TranslatedText := 'Tiempos para jugar:';
    Entry.SemanticConcept := 'media.timesToPlay';
    Entry.Status := tsMachineTranslated;
    Entry.TranslationOrigin := torGoogle;
    Catalog.Entries.Add(Entry);
    Require(TTerminologyResolver.ApplyAuthoritativeTerms(Catalog) = 3,
      'Authoritative terminology did not repair a provider translation.');
    Require(Catalog.Entries[0].TranslatedText = 'Cerrar',
      'Provider Close was not repaired to Spanish Cerrar.');
    Require(Catalog.Entries[1].TranslatedText = 'Mi' + #$00E9,
      'Provider Wednesday was not repaired to Spanish Mi' + #$00E9 + '.');
    Require(Catalog.Entries[2].TranslatedText = 'Veces:',
      'Provider Times to play was not repaired to Spanish Veces.');
  finally
    Catalog.Free;
  end;
end;

{ The opposite, and just as much worth stating. A scanner that claims too much
  is the harder fault to see: the extra strings look like work rather than like
  a mistake, and they reach the translator and are paid for. }
procedure RequireNoSourceText(const AResult: TProjectScanResult;
  const AUnwantedText: string);
var
  Item: TScanItem;
begin
  for Item in AResult.Items do
    if Item.SourceText = AUnwantedText then
      raise Exception.Create(
        'Scanned source text that should have been left alone: ' +
        AUnwantedText);
end;

procedure RequireSourceText(const AResult: TProjectScanResult;
  const AExpectedText: string; const AExpectedKind: TScannedTextKind);
var
  Item: TScanItem;
begin
  for Item in AResult.Items do
    if (Item.Kind = AExpectedKind) and
      (Item.SourceText = AExpectedText) then
      Exit;
  raise Exception.Create('Expected scanned source text was not found: ' +
    AExpectedText);
end;

procedure TestExtendedTextScanning;
var
  FormFileName: string;
  PascalFileName: string;
  ScanItem: TScanItem;
  ScanResult: TProjectScanResult;
  TempDirectory: string;
begin
  TempDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT-Extended-Scan-' + FormatDateTime('hhnnsszzz', Now));
  TDirectory.CreateDirectory(TempDirectory);
  FormFileName := TPath.Combine(TempDirectory, 'RuntimeForm.fmx');
  PascalFileName := TPath.Combine(TempDirectory, 'RuntimeForm.pas');
  TFile.WriteAllText(FormFileName,
    'object frmRuntime: TForm' + sLineBreak +
    '  object lblInstructions: TLabel' + sLineBreak +
    '    Text =' + sLineBreak +
    '      ''Select a folder for each slot. Dates use month/day format, for e'' +' + sLineBreak +
    '      ''xample 04/27.''' + sLineBreak +
    '  end' + sLineBreak +
    'end', TEncoding.UTF8);
  TFile.WriteAllText(PascalFileName,
    'unit RuntimeForm;' + sLineBreak +
    'interface' + sLineBreak +
    'implementation' + sLineBreak +
    'procedure Build;' + sLineBreak +
    'var DisplayText: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  Column.Header := ''Play Date From'';' + sLineBreak +
    '  RuntimeLabel.Text := ''Play Time'';' + sLineBreak +
    '  DisplayText := Format('' Uptime: %d years %d seconds'', [1, 2]);' + sLineBreak +
    '  Items.Add(''Close window'');' + sLineBreak +
    '  ShowMessage(''Unable to open the selected file.'');' + sLineBreak +
    '  Canvas.FillText(Rect, ''Owner drawn heading'', False, 1, [], Align);' + sLineBreak +
    '  EventColumn.Header := ''Eventoooooooooooooooo'';' + sLineBreak +
    '  Html.Add(''<thead><tr><th>Time</th><th>Type</th><th>Song/Purpose</th></tr></thead>'');' + sLineBreak +
    'end;' + sLineBreak +
    'end.', TEncoding.UTF8);
  ScanResult := TProjectScanResult.Create;
  try
    TTextFormScanner.ScanFile(FormFileName, tfFireMonkey, ScanResult);
    TPascalResourceStringScanner.ScanFile(PascalFileName, ScanResult);
    RequireSourceText(ScanResult,
      'Select a folder for each slot. Dates use month/day format, for example 04/27.',
      stkFormProperty);
    RequireSourceText(ScanResult, 'Play Date From', stkRuntimeAssignment);
    RequireSourceText(ScanResult, 'Play Time', stkRuntimeAssignment);
    RequireSourceText(ScanResult, ' Uptime: %d years %d seconds',
      stkRuntimeAssignment);
    { Deliberately not claimed. Items.Add, Lines.Add and Strings.Add carry data
      rows, log lines, file names and generated markup far more often than they
      carry a caption, and harvesting them produced thousands of false
      translatable strings on this application. Designer-authored items are
      still read from the form file; runtime interface text is expected to go
      through a visible property, a resourcestring or a dialog call.

      This expectation used to require the opposite. The decision changed and
      the test did not, and nothing noticed because this suite had not compiled
      since the units it referenced were deleted. }
    RequireNoSourceText(ScanResult, 'Close window');
    RequireSourceText(ScanResult, 'Unable to open the selected file.',
      stkRuntimeAssignment);
    { Deliberately not claimed either, and for the same reason as the item
      above: what a canvas draws is usually a data row or a runtime value, not
      a caption that holds still. No drawing call is registered for scanning. }
    RequireNoSourceText(ScanResult, 'Owner drawn heading');
    ScanItem := nil;
    for ScanItem in ScanResult.Items do
      if ScanItem.SourceText = 'Eventoooooooooooooooo' then
        Break;
    Require((ScanItem <> nil) and
      (ScanItem.SourceText = 'Eventoooooooooooooooo'),
      'Suspicious runtime source was not scanned.');
    Require(ScanItem.TextOwnership = tokSuspicious,
      'Repeated-character runtime source was not classified as suspicious.');
    RequireSourceText(ScanResult, 'Time', stkRuntimeAssignment);
    RequireSourceText(ScanResult, 'Type', stkRuntimeAssignment);
    RequireSourceText(ScanResult, 'Song/Purpose', stkRuntimeAssignment);
    Require(not TranslationEntryEligibleForAutomaticTranslation(nil),
      'A nil entry was incorrectly eligible for automatic translation.');
  finally
    ScanResult.Free;
    TDirectory.Delete(TempDirectory, True);
  end;
end;

procedure TestNestedProjectExclusion;
var
  NestedDirectory: string;
  Profile: TProjectProfile;
  ScanResult: TProjectScanResult;
  TempDirectory: string;
begin
  TempDirectory := TPath.Combine(TPath.GetTempPath,
    'DAT-Nested-Project-' + FormatDateTime('hhnnsszzz', Now));
  NestedDirectory := TPath.Combine(TempDirectory, 'Conversion Utility');
  TDirectory.CreateDirectory(NestedDirectory);
  TFile.WriteAllText(TPath.Combine(TempDirectory, 'Main.dproj'),
    '<Project><FrameworkType>FMX</FrameworkType></Project>', TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(TempDirectory, 'Main.fmx'),
    'object frmMain: TForm' + sLineBreak +
    '  Caption = ''Main application''' + sLineBreak + 'end', TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(NestedDirectory, 'Utility.dproj'),
    '<Project><FrameworkType>FMX</FrameworkType></Project>', TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(NestedDirectory, 'Utility.fmx'),
    'object frmUtility: TForm' + sLineBreak +
    '  Caption = ''Conversion utility''' + sLineBreak + 'end', TEncoding.UTF8);
  Profile := Default(TProjectProfile);
  Profile.ProjectFileName := TPath.Combine(TempDirectory, 'Main.dproj');
  Profile.ProjectName := 'Main';
  Profile.Framework := tfFireMonkey;
  ScanResult := TProjectScanner.Scan(Profile);
  try
    RequireSourceText(ScanResult, 'Main application', stkFormProperty);
    Require(ScanResult.Items.Count = 1,
      'A nested Delphi utility project was included in the selected app scan.');
  finally
    ScanResult.Free;
    TDirectory.Delete(TempDirectory, True);
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

  Require(TScanRuleSet.IsTranslatableProperty(tfFireMonkey,
    'TStringColumn', 'Header', False),
    'FMX string-grid column headers must be translatable.');

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

procedure TestRuntimeOwnershipClassification;
begin
  Require(TScanRuleSet.ClassifyRuntimeTextRole('lblTitle', 'TLabel',
    'Text', 'Dashboard') = rtrStaticText,
    'A static label was not classified as static text.');
  Require(TScanRuleSet.ClassifyRuntimeTextRole('lblConnectionStatus',
    'TLabel', 'Text', 'Not connected') = rtrDynamicValue,
    'A live status label was not protected as a dynamic value.');
  Require(TScanRuleSet.ClassifyRuntimeTextRole('lblUsersValue', 'TLabel',
    'Text', '--') = rtrExcluded,
    'A runtime placeholder was not excluded.');
  Require(TScanRuleSet.ClassifyRuntimeTextRole('lblUsersValue', 'TLabel',
    'Text', '42') = rtrDataValue,
    'A designer data value was not protected.');
  Require(TScanRuleSet.ClassifyRuntimeTextRole('lblWebsite', 'TLabel',
    'Text', 'https://example.com') = rtrIdentifier,
    'A URL was not protected as an identifier.');
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

  Entry := TTranslationEntry.Create;
  Entry.Key := 'MainForm.StatusMessage';
  Entry.SourceText := 'Updated at %s';
  Entry.TranslatedText := 'Aktualisiert um %s';
  Entry.SourceChecksum := 'source-checksum-3';
  Entry.Status := tsApproved;
  Entry.RuntimeApplication := rakManualTranslateText;
  Entry.RuntimeTextRole := rtrRuntimeTemplate;
  Entry.RuntimeWiringConfirmed := True;
  Result.Entries.Add(Entry);

  Entry := TTranslationEntry.Create;
  Entry.Key := 'MainForm.UsersValue.Text';
  Entry.SourceText := '--';
  Entry.SourceChecksum := 'source-checksum-4';
  Entry.Status := tsExcluded;
  Entry.RuntimeApplication := rakNotApplied;
  Entry.RuntimeTextRole := rtrDataValue;
  Entry.RuntimeWiringConfirmed := True;
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
      Require(LoadedCatalog.Entries.Count = 4,
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
  { The workspace lives beside the user's other application data now, not
    inside the project under a Localization folder, so a project tree is
    never written to merely by opening it. These expectations still
    described the old shape; nothing noticed, because this suite had not
    compiled since the units it referenced were deleted. }
  Require(EndsText(
    'Workspaces\SampleVCLApp\Development\SampleVCLApp.de-DE.translation-project.json',
    CatalogFileName), 'The development catalog path is incorrect.');
  Require(EndsText('Workspaces\SampleVCLApp\Languages\de-DE.json',
    RuntimeFileName), 'The runtime pack path is incorrect.');
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
  TemplatesObject: TJSONObject;
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
      Require(StringsObject.Get('MainForm.StatusMessage') = nil,
        'A runtime template leaked into automatic form strings.');
      Require(StringsObject.Get('MainForm.UsersValue.Text') = nil,
        'A protected data value leaked into automatic form strings.');
      TemplatesObject := Root.GetValue('templates') as TJSONObject;
      Require(TemplatesObject <> nil,
        'The runtime templates object is missing.');
      JsonPair := TemplatesObject.Get('MainForm.StatusMessage');
      Require((JsonPair <> nil) and
        (JsonPair.JsonValue.Value = 'Aktualisiert um %s'),
        'The runtime message template was not exported.');
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
  RuntimeText: string;
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
    Require(Pack.FormatTemplate('MainForm.StatusMessage', 'Updated at %s',
      ['10:30']) = 'Aktualisiert um 10:30',
      'The runtime loader did not format a keyed template.');
    Require(Pack.TryTranslateSource('E&xit', RuntimeText) and
      (RuntimeText = '&Beenden'),
      'The runtime source-text index did not translate a static string.');
    Require(Pack.TryTranslateDynamicText('Updated at 10:30', RuntimeText) and
      (RuntimeText = 'Aktualisiert um 10:30'),
      'The runtime source-template index did not translate formatted text.');
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

function CountTextOccurrences(const AText, ASearchText: string): Integer;
  forward;

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
    TestUnicodeTextRepairContract;
    TestProjectDetection;
    TestProviderProtocolFixtures;
    TestCatalogRoundTrip;
    TestContextualTerminology;
    TestAuthoritativeTerminologyRepair;
    TestExtendedTextScanning;
    TestNestedProjectExclusion;
    TestProjectScanning;
    TestStudioProjectScanning;
    TestIncrementalCatalogMerge;
    TestRuntimeOwnershipClassification;
    TestCatalogFilePersistence;
    TestCatalogCsvRoundTrip;
    TestWorkspacePaths;
    TestCatalogValidation;
    TestRuntimePack;
    TestRuntimeLoadingAndPreference;
    TestProjectUnitInsertionBeforeResourceDirective;
    TestImplementationUsesAfterResourceDirective;
    TestFMXProjectStartupDefersTranslationToForms;
    TestSecondaryFMXFormStartupWiring;
    TestInPlaceAITranslationWorkflow;
    TestLocalizationIntelligence;
    Writeln('Foundation, scanner, catalog, runtime, validation, and export tests passed.');
  except
    on E: Exception do
    begin
      Writeln('Foundation smoke tests failed: ', E.Message);
      Halt(1);
    end;
  end;
end.
