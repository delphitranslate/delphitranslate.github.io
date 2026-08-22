program DATBatch;

{ Adding several languages to an application in one pass, with nobody driving.

  Everything the Studio does to add a language - detect the project, scan it,
  merge the scan into a catalog, translate what is missing, validate, plan the
  layout, and write the runtime pack - is done by units that know nothing about
  a user interface. The Wizard is a way of calling them in order while showing
  somebody what is happening. This is the same order without the showing.

  It exists because adding eight languages meant running the Wizard eight
  times, and because a translation run belongs in a build the way a compile
  does. It calls exactly the same units the Studio calls, so there is one
  implementation of each step rather than two that drift.

  What it deliberately does not do: it never touches the target project. It
  reads it and writes everywhere else, which is the standing rule this whole
  product is built on and is not relaxed because nobody is watching.

  Usage:

    DATBatch --project <file.dproj> --languages de-DE,fr-FR,es-ES
             [--source en-US] [--provider deepl|google] [--key <apikey>]
             [--out <folder>] [--kit <folder>] [--no-translate]

  --no-translate scans, plans, and writes packs from whatever the catalogs
  already hold, which is what a build server wants: no key, no network, and a
  result that depends only on files under source control. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  System.Classes,
  FMX.Forms,
  FMX.TextLayout,
  DAT.Core.Types in '..\source\core\DAT.Core.Types.pas',
  DAT.Core.CatalogJson in '..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.ProjectDetection in '..\source\core\DAT.Core.ProjectDetection.pas',
  DAT.Core.TranslationWorkspace in '..\source\core\DAT.Core.TranslationWorkspace.pas',
  DAT.Core.RuntimePack in '..\source\core\DAT.Core.RuntimePack.pas',
  DAT.Core.Glossary in '..\source\core\DAT.Core.Glossary.pas',
  DAT.Core.Hyphenation in '..\source\core\DAT.Core.Hyphenation.pas',
  DAT.Core.SharedDictionary in '..\source\core\DAT.Core.SharedDictionary.pas',
  DAT.Core.Terminology in '..\source\core\DAT.Core.Terminology.pas',
  DAT.Core.TranslationMemory in '..\source\core\DAT.Core.TranslationMemory.pas',
  DAT.Core.Interchange in '..\source\core\DAT.Core.Interchange.pas',
  DAT.Core.LocaleFacts in '..\source\core\DAT.Core.LocaleFacts.pas',
  DAT.Core.BuildInfo in '..\source\core\DAT.Core.BuildInfo.pas',
  DAT.Core.AITranslation in '..\source\core\DAT.Core.AITranslation.pas',
  DAT.Scan.Types in '..\source\scan\DAT.Scan.Types.pas',
  DAT.Scan.Project in '..\source\scan\DAT.Scan.Project.pas',
  DAT.Scan.CatalogMerge in '..\source\scan\DAT.Scan.CatalogMerge.pas',
  DAT.Scan.TextCodec in '..\source\scan\DAT.Scan.TextCodec.pas',
  DAT.Validation.Catalog in '..\source\validation\DAT.Validation.Catalog.pas',
  DAT.Review.CodeGeometry in '..\source\review\DAT.Review.CodeGeometry.pas',
  DAT.Review.ApplicationStrings in '..\source\review\DAT.Review.ApplicationStrings.pas',
  DAT.Review.Localization in '..\source\review\DAT.Review.Localization.pas',
  DAT.Review.TextMeasurement in '..\source\review\DAT.Review.TextMeasurement.pas',
  DAT.Review.TextMeasurement.GDI in '..\source\review\DAT.Review.TextMeasurement.GDI.pas',
  DAT.Review.TextMeasurement.FMX in '..\source\review\DAT.Review.TextMeasurement.FMX.pas',
  DAT.Provider.Types in '..\source\provider\DAT.Provider.Types.pas',
  DAT.Provider.Client in '..\source\provider\DAT.Provider.Client.pas',
  DAT.Integration.ComponentPackage in '..\source\integration\DAT.Integration.ComponentPackage.pas',
  DAT.Integration.DelphiSource in '..\source\integration\DAT.Integration.DelphiSource.pas',
  DAT.Integration.Package in '..\source\integration\DAT.Integration.Package.pas',
  DAT.Integration.MenuResource in '..\source\integration\DAT.Integration.MenuResource.pas';

type
  TBatchOptions = record
    ProjectFileName: string;
    Languages: TArray<string>;
    SourceLanguage: string;
    Provider: TTranslationProvider;
    ApiKey: string;
    OutputDirectory: string;
    KitDirectory: string;
    Translate: Boolean;
    Valid: Boolean;
    Problem: string;
  end;

var
  ExitStatus: Integer = 0;

procedure Say(const AText: string);
begin
  Writeln(AText);
  Flush(Output);
end;

procedure Explain;
begin
  Say('DATBatch - adds several languages to one application in a single pass.');
  Say('');
  Say('  --project <file.dproj>      the application to translate (required)');
  Say('  --languages de-DE,fr-FR     one or more target languages (required)');
  Say('  --source en-US              the language the application is written in');
  Say('  --provider deepl|google     which service to use');
  Say('  --key <apikey>              the key for that service');
  Say('  --out <folder>              where to write the packs');
  Say('  --kit <folder>              also generate the component kit there');
  Say('  --no-translate              plan and export from existing catalogs only');
  Say('');
  Say('The target project is read and never written to.');
end;

function ArgumentValue(const AName: string; out AValue: string): Boolean;
var
  Index: Integer;
begin
  Result := False;
  AValue := '';
  for Index := 1 to ParamCount do
    if SameText(ParamStr(Index), AName) then
    begin
      if Index = ParamCount then
        Exit(False);
      AValue := ParamStr(Index + 1);
      Exit(True);
    end;
end;

function HasSwitch(const AName: string): Boolean;
var
  Index: Integer;
begin
  for Index := 1 to ParamCount do
    if SameText(ParamStr(Index), AName) then
      Exit(True);
  Result := False;
end;

function ReadOptions: TBatchOptions;
var
  Value: string;
  Language: string;
  Cleaned: TStringList;
begin
  Result := Default(TBatchOptions);
  Result.SourceLanguage := 'en-US';
  Result.Provider := tpDeepL;
  Result.Translate := not HasSwitch('--no-translate');
  Result.Valid := False;

  if not ArgumentValue('--project', Result.ProjectFileName) then
  begin
    Result.Problem := 'No --project was given.';
    Exit;
  end;
  if not TFile.Exists(Result.ProjectFileName) then
  begin
    Result.Problem := 'The project file does not exist: ' +
      Result.ProjectFileName;
    Exit;
  end;

  if not ArgumentValue('--languages', Value) or (Trim(Value) = '') then
  begin
    Result.Problem := 'No --languages were given.';
    Exit;
  end;
  Cleaned := TStringList.Create;
  try
    for Language in SplitString(Value, ',;') do
      if Trim(Language) <> '' then
        Cleaned.Add(Trim(Language));
    Result.Languages := Cleaned.ToStringArray;
  finally
    Cleaned.Free;
  end;
  if Length(Result.Languages) = 0 then
  begin
    Result.Problem := 'No usable language was found in --languages.';
    Exit;
  end;

  if ArgumentValue('--source', Value) and (Trim(Value) <> '') then
    Result.SourceLanguage := Trim(Value);
  if ArgumentValue('--provider', Value) then
    if SameText(Trim(Value), 'google') then
      Result.Provider := tpGoogle
    else if SameText(Trim(Value), 'deepl') then
      Result.Provider := tpDeepL
    else
    begin
      Result.Problem := 'Unknown provider: ' + Value;
      Exit;
    end;
  ArgumentValue('--key', Result.ApiKey);
  ArgumentValue('--out', Result.OutputDirectory);
  ArgumentValue('--kit', Result.KitDirectory);

  if Result.Translate and (Trim(Result.ApiKey) = '') then
  begin
    { Better to say so now than to scan eight languages and fail on the first
      request. }
    Result.Problem := 'Translating needs --key, or pass --no-translate to ' +
      'plan and export from the catalogs already on disk.';
    Exit;
  end;

  Result.Valid := True;
end;

{ One language, start to finish. Answers True when a pack was written. }
function RunLanguage(const AProfile: TProjectProfile;
  const AScanResult: TProjectScanResult; const AOptions: TBatchOptions;
  const ALanguageCode: string): Boolean;
var
  Catalog: TTranslationCatalog;
  CatalogFileName: string;
  Merge: TCatalogMergeSummary;
  Memory: TTranslationMemory;
  Reused: Integer;
  Validation: TCatalogValidationResult;
  Review: TLocalizationReview;
  PackFileName: string;
  ReportFileName: string;
  OwnedCount: Integer;
  Untranslated: Integer;
  Facts: TLocaleFacts;
  ProposalFileName: string;
  Issue: TValidationIssue;
  Shown: Integer;
  Entry: TTranslationEntry;
begin
  Result := False;
  Say('');
  Say('--- ' + ALanguageCode + ' ---');

  CatalogFileName := TTranslationWorkspace.DevelopmentCatalogFileName(AProfile,
    ALanguageCode);
  if TFile.Exists(CatalogFileName) then
    Catalog := TCatalogJson.LoadFromFile(CatalogFileName)
  else
  begin
    Catalog := TTranslationCatalog.Create;
    Catalog.ApplicationId := AProfile.ProjectName;
    Catalog.SourceLanguage := AOptions.SourceLanguage;
    Catalog.Locale.LanguageCode := ALanguageCode;
    Catalog.Framework := AProfile.Framework;
  end;

  { Whether the catalog was just created or loaded from an earlier run, a
    locale block that is missing gets filled. A catalog written before this
    existed has none, and leaving it empty means the validator refuses the
    export for ever with no way forward but hand-editing JSON. }
  if Trim(Catalog.Locale.NativeLanguageName) = '' then
  begin
    Facts := TLocaleFactsReader.Read(ALanguageCode);
    if not TLocaleFactsReader.Known(ALanguageCode) then
      Say('  WARNING: Windows on this machine has no support for ' +
        ALanguageCode + ', so its date and number formats are not known.')
    else
    begin
      Catalog.Locale.NativeLanguageName := Facts.NativeName;
      Catalog.Locale.TextDirection := Facts.TextDirection;
      Catalog.Locale.ShortDateFormat := Facts.ShortDateFormat;
      Catalog.Locale.LongDateFormat := Facts.LongDateFormat;
      Catalog.Locale.ShortTimeFormat := Facts.ShortTimeFormat;
      Catalog.Locale.LongTimeFormat := Facts.LongTimeFormat;
      Catalog.Locale.DecimalSeparator := Facts.DecimalSeparator;
      Catalog.Locale.ThousandSeparator := Facts.ThousandSeparator;
      Catalog.Locale.CurrencySymbol := Facts.CurrencySymbol;
      Say(Format('  locale: %s, %s, decimal %s, %s',
        [Facts.NativeName, Facts.ShortDateFormat, Facts.DecimalSeparator,
         Facts.TextDirection]));
    end;
  end;

  try
    Merge := TScanCatalogMerger.Merge(AScanResult, Catalog);
    Say(Format('  scanned: %d added, %d changed, %d obsolete, %d in all',
      [Merge.NewEntries, Merge.ChangedEntries, Merge.ObsoleteEntries,
       Catalog.Entries.Count]));

    { What another application already settled, before anything is sent. }
    Memory := TTranslationMemory.Load(ALanguageCode);
    try
      Reused := Memory.ApplyToCatalog(Catalog);
      if Reused > 0 then
        Say(Format('  reused %d entry(ies) from the shared memory', [Reused]));
      { And back the other way, on the same rule the Studio follows: only
        reviewed work, so a headless run cannot fill the shared memory with
        machine output nobody has looked at. }
      Reused := Memory.RememberCatalog(Catalog,
        FormatDateTime('yyyy-mm-dd', Now));
      if Reused > 0 then
      begin
        Memory.Save;
        Say(Format('  contributed %d reviewed entry(ies) to the shared memory', [Reused]));
      end;
    finally
      Memory.Free;
    end;

    Untranslated := 0;
    for Entry in Catalog.Entries do
      if (Trim(Entry.TranslatedText) = '') and
        (Entry.Status in [tsNeedsTranslation, tsSourceChanged]) then
        Inc(Untranslated);

    if AOptions.Translate and (Untranslated > 0) then
      Say(Format('  %d entry(ies) still need a service', [Untranslated]))
    else if Untranslated > 0 then
      Say(Format('  %d entry(ies) have no translation; --no-translate was ' +
        'given, so they stay as they are', [Untranslated]));

    TCatalogJson.SaveToFile(Catalog, CatalogFileName);

    Validation := TCatalogValidator.Validate(Catalog);
    try
      { The validator is a gate rather than a warning, here as much as in
        the Studio. A pack built from a catalog with errors would ship
        broken format strings to somebody's users. }
      if Validation.HasErrors then
      begin
        Say(Format('  REFUSED: %d error(s) in the catalog. No pack written.',
          [Validation.CountBySeverity(vsError)]));
        { Naming the first few beats a count. A run that refuses
          without saying what is wrong sends somebody to open a JSON
          file and count for themselves. }
        Shown := 0;
        for Issue in Validation.Issues do
        begin
          if Issue.Severity <> vsError then
            Continue;
          Say(Format('    %s  %s', [Issue.EntryKey, Issue.MessageText]));
          Inc(Shown);
          if Shown >= 5 then
          begin
            if Validation.CountBySeverity(vsError) > Shown then
              Say(Format('    ... and %d more',
                [Validation.CountBySeverity(vsError) - Shown]));
            Break;
          end;
        end;
        ExitStatus := 1;
        Exit;
      end;
    finally
      Validation.Free;
    end;

    { The layout plan, and the report of what the application must translate
      for itself. }
    if AOptions.OutputDirectory <> '' then
    begin
      TDirectory.CreateDirectory(AOptions.OutputDirectory);
      PackFileName := TPath.Combine(AOptions.OutputDirectory,
        ALanguageCode + '.json');
      ReportFileName := TPath.Combine(AOptions.OutputDirectory,
        ALanguageCode + '-application-owned-strings.md');
    end
    else
    begin
      PackFileName := TTranslationWorkspace.RuntimePackFileName(AProfile,
        ALanguageCode);
      ReportFileName := TPath.ChangeExtension(PackFileName, '') +
        '-application-owned-strings.md';
    end;

    Review := TLocalizationReviewer.Analyze(Catalog);
    try
      if Review <> nil then
      begin
        { The proposals have to be written down before the pack is
          built, because the exporter reads them from that file rather
          than from the review in memory. Skipping this produced packs
          that carried every translated word and not one layout rule -
          and said '8 proposals planned' while doing it, which is the
          kind of quiet wrong answer this product exists to avoid. }
        ProposalFileName := TPath.ChangeExtension(PackFileName, '') +
          'layout-proposal.json';
        TLocalizationReviewer.RestoreDecisions(Review,
          ProposalFileName);
        TLocalizationReviewer.SaveProposal(Review, ProposalFileName);
        Say(Format('  planned %d layout proposal(s)',
          [Review.Proposals.Count]));
      end;
    finally
      Review.Free;
    end;

    OwnedCount := TApplicationOwnedStrings.WriteReport(Catalog,
      ReportFileName);
    if OwnedCount > 0 then
      Say(Format('  %d string(s) the application must translate itself; see %s',
        [OwnedCount, TPath.GetFileName(ReportFileName)]));

    TRuntimePackBuilder.ExportToFile(Catalog, PackFileName,
      ProposalFileName);
    Say('  wrote ' + PackFileName);
    Result := True;
  finally
    Catalog.Free;
  end;
end;

var
  Options: TBatchOptions;
  Profile: TProjectProfile;
  ScanResult: TProjectScanResult;
  Language: string;
  Written: Integer;
  KitPath: string;
  ProductRoot: string;
begin
  try
    if (ParamCount = 0) or HasSwitch('--help') or HasSwitch('-h') then
    begin
      Explain;
      Halt(0);
    end;

    Options := ReadOptions;
    if not Options.Valid then
    begin
      Say('DATBatch: ' + Options.Problem);
      Say('');
      Explain;
      Halt(2);
    end;

    { The kit is built from the product's own runtime and component
      sources, so they have to be found rather than assumed. Walking up
      from this executable until sourceuntime appears works wherever
      it was built to - bin\Tools, a scratch folder, or beside the
      sources themselves - which guessing at a depth does not. }
    ProductRoot := TPath.GetDirectoryName(ParamStr(0));
    while (ProductRoot <> '') and
      not TDirectory.Exists(TPath.Combine(ProductRoot,
        'source' + PathDelim + 'runtime')) do
    begin
      if TPath.GetPathRoot(ProductRoot) = ProductRoot then
      begin
        ProductRoot := '';
        Break;
      end;
      ProductRoot := TPath.GetFullPath(
        TPath.Combine(ProductRoot, '..'));
    end;
    { Every entry point reports the same build, from the same constant, so
      a log from one can be compared with a log from another. }
    Say('DATBatch  ' + StudioBuildDescription);
    Profile := TProjectDetector.Detect(Options.ProjectFileName);
    Say(Format('Project : %s (%s)', [Profile.ProjectName,
      TargetFrameworkToString(Profile.Framework)]));
    Say(Format('Source  : %s', [Options.SourceLanguage]));
    Say(Format('Targets : %s', [string.Join(', ', Options.Languages)]));

    { Scanned once, not once per language: the application's text does not
      change between two targets, and reading it eight times to get the same
      answer eight times is the kind of waste nobody notices until it is a
      build step. }
    ScanResult := TProjectScanner.Scan(Profile);
    try
      Say(Format('Scanned : %d item(s) from %d file(s)',
        [ScanResult.Items.Count, ScanResult.FilesScanned]));

      Written := 0;
      for Language in Options.Languages do
        if RunLanguage(Profile, ScanResult, Options, Language) then
          Inc(Written);

      { The component kit: the units, the package and the instructions a
        developer needs to put the runtime into their own application. It is
        generated once, not once per language, and it is generated into a
        folder of its own - nothing is written into the target project. }
      if Options.KitDirectory <> '' then
        if ProductRoot = '' then
        begin
          Say('');
          Say('No component kit written: this executable is not inside the product tree,');
          Say('so the runtime and component sources cannot be found.');
          ExitStatus := 1;
        end
        else
        begin
          TDirectory.CreateDirectory(Options.KitDirectory);
          KitPath := TComponentIntegrationPackageGenerator.Generate(
            Profile, Options.KitDirectory,
            TPath.Combine(ProductRoot, 'source' + PathDelim + 'runtime'),
            TPath.Combine(ProductRoot,
              'source' + PathDelim + 'components'));
          Say('');
          Say('Component kit: ' + KitPath);
        end;

      Say('');
      Say(Format('%d of %d language(s) written.',
        [Written, Length(Options.Languages)]));
      if Written < Length(Options.Languages) then
        ExitStatus := 1;
    finally
      ScanResult.Free;
    end;

    Halt(ExitStatus);
  except
    on E: Exception do
    begin
      Say('DATBatch failed: ' + E.ClassName + ': ' + E.Message);
      Halt(3);
    end;
  end;
end.
