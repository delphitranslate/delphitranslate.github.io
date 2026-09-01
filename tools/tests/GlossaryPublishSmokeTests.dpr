program GlossaryPublishSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.AtomicFile in '..\..\source\core\DAT.Core.AtomicFile.pas',
  DAT.Core.Diagnostics in '..\..\source\core\DAT.Core.Diagnostics.pas',
  DAT.Core.CatalogJson in '..\..\source\core\DAT.Core.CatalogJson.pas',
  DAT.Core.Glossary in '..\..\source\core\DAT.Core.Glossary.pas',
  DAT.Core.Hyphenation in '..\..\source\core\DAT.Core.Hyphenation.pas',
  DAT.Core.LocaleFacts in '..\..\source\core\DAT.Core.LocaleFacts.pas',
  DAT.Core.RuntimePack in '..\..\source\core\DAT.Core.RuntimePack.pas',
  DAT.Core.TranslationWorkspace in '..\..\source\core\DAT.Core.TranslationWorkspace.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas',
  DAT.Validation.Catalog in '..\..\source\validation\DAT.Validation.Catalog.pas',
  DAT.Integration.BuildDeploy in '..\..\source\integration\DAT.Integration.BuildDeploy.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

function FrenchOn: string;
begin
  Result := 'Activ' + Char($00E9);
end;

function FrenchOff: string;
begin
  Result := 'D' + Char($00E9) + 'sactiv' + Char($00E9);
end;

procedure AddEntry(const ACatalog: TTranslationCatalog;
  const AKey, ASourceText, ATranslatedText: string);
var
  Entry: TTranslationEntry;
begin
  Entry := TTranslationEntry.Create;
  Entry.Key := AKey;
  Entry.SourceText := ASourceText;
  Entry.TranslatedText := ATranslatedText;
  Entry.FormName := 'frmMain';
  Entry.ComponentName := AKey;
  Entry.ComponentClassName := 'TLabel';
  Entry.PropertyName := 'Text';
  Entry.SourceKind := 'Runtime value';
  Entry.SourceFileName := 'MainForm.pas';
  Entry.SourceChecksum := LowerCase(THashSHA2.GetHashString(ASourceText));
  Entry.Status := tsMachineTranslated;
  Entry.TranslationOrigin := torDeepL;
  Entry.TextOwnership := tokRuntimeWired;
  Entry.RuntimeApplication := rakAutomatic;
  Entry.RuntimeTextRole := rtrStaticText;
  Entry.RuntimeWiringConfirmed := True;
  ACatalog.Entries.Add(Entry);
end;

function CreateCatalog: TTranslationCatalog;
begin
  Result := TTranslationCatalog.Create;
  Result.ApplicationId := 'GlossaryPublishSample';
  Result.ApplicationVersion := '1.0';
  Result.Framework := tfFireMonkey;
  Result.SourceLanguage := 'en-US';
  Result.Locale.LanguageCode := 'fr-FR';
  Result.Locale.NativeLanguageName := 'Fran' + Char($00E7) + 'ais';
  Result.Locale.TextDirection := 'ltr';
  Result.Locale.ShortDateFormat := 'dd/MM/yyyy';
  Result.Locale.LongDateFormat := 'dddd d MMMM yyyy';
  Result.Locale.ShortTimeFormat := 'HH:mm';
  Result.Locale.LongTimeFormat := 'HH:mm:ss';
  Result.Locale.DecimalSeparator := ',';
  Result.Locale.ThousandSeparator := ' ';
  Result.Locale.CurrencySymbol := 'EUR';
  AddEntry(Result, 'State.On', 'On', 'Sur');
  AddEntry(Result, 'State.Off', 'Off', 'Hors');
end;

procedure AddGlossaryTerm(const AGlossary: TProjectGlossary;
  const ASourceText, ATargetText: string);
var
  Term: TProjectGlossaryTerm;
begin
  Term := TProjectGlossaryTerm.Create;
  Term.SourceText := ASourceText;
  Term.TargetText := ATargetText;
  Term.Approved := True;
  AGlossary.Terms.Add(Term);
end;

function PackHas(const AFileName, ASourceText, ATargetText: string): Boolean;
var
  Pack: TRuntimeLanguagePack;
  Value: string;
begin
  Pack := TRuntimeLanguagePack.LoadFromFile(AFileName);
  try
    Result := Pack.SourceStrings.TryGetValue(ASourceText, Value) and
      (Value = ATargetText);
  finally
    Pack.Free;
  end;
end;

var
  Catalog: TTranslationCatalog;
  CatalogFileName: string;
  Configuration: string;
  DependencyLanguageDirectory: string;
  DependencyPackFileName: string;
  ExitCode: Integer;
  Glossary: TProjectGlossary;
  GlossaryFileName: string;
  OriginalLocalAppData: string;
  OutputDirectory: string;
  OutputPackFileName: string;
  Platform: string;
  Profile: TProjectProfile;
  ProjectFileHash: string;
  ProjectRoot: string;
  PublishedCatalog: TTranslationCatalog;
  PublishResult: TGlossaryPublishResult;
  RuntimePackFileName: string;
  TestRoot: string;
begin
  TestRoot := TPath.Combine(TPath.GetTempPath,
    'DAT-GlossaryPublish-' + FormatDateTime('yyyymmdd-hhnnss-zzz', Now));
  OriginalLocalAppData := GetEnvironmentVariable('LOCALAPPDATA');
  ExitCode := 0;
  try
    try
      TDirectory.CreateDirectory(TestRoot);
      Winapi.Windows.SetEnvironmentVariable('LOCALAPPDATA', PChar(TestRoot));
    ProjectRoot := TPath.Combine(TestRoot, 'TargetProject');
    TDirectory.CreateDirectory(ProjectRoot);
    Profile := Default(TProjectProfile);
    Profile.ProjectName := 'GlossaryPublishSample';
    Profile.ProjectFileName := TPath.Combine(ProjectRoot,
      'GlossaryPublishSample.dproj');
    Profile.Framework := tfFireMonkey;
    Profile.SupportsWin32 := True;
    Profile.SupportsWin64 := True;
    TFile.WriteAllText(Profile.ProjectFileName,
      '<Project><PropertyGroup></PropertyGroup></Project>', TEncoding.UTF8);
    ProjectFileHash := THashSHA2.GetHashStringFromFile(Profile.ProjectFileName);

    DependencyLanguageDirectory := TPath.Combine(ProjectRoot,
      'dependencies\DelphiAppTranslation\deployment\Languages');
    TDirectory.CreateDirectory(DependencyLanguageDirectory);
    for Platform in ['Win32', 'Win64'] do
      for Configuration in ['Debug', 'Release'] do
      begin
        OutputDirectory := TPath.Combine(ProjectRoot,
          TPath.Combine(Platform, Configuration));
        TDirectory.CreateDirectory(OutputDirectory);
      end;

    Catalog := CreateCatalog;
    try
      CatalogFileName := TTranslationWorkspace.DevelopmentCatalogFileName(
        Profile, 'fr-FR');
      TCatalogJson.SaveToFile(Catalog, CatalogFileName);
    finally
      Catalog.Free;
    end;

    Glossary := TProjectGlossary.Create;
    try
      Glossary.ApplicationId := Profile.ProjectName;
      Glossary.SourceLanguage := 'en-US';
      Glossary.TargetLanguage := 'fr-FR';
      AddGlossaryTerm(Glossary, 'On', FrenchOn);
      AddGlossaryTerm(Glossary, 'Off', FrenchOff);
      GlossaryFileName := TTranslationWorkspace.GlossaryFileName(
        Profile, 'fr-FR');
      Glossary.SaveToFile(GlossaryFileName);
    finally
      Glossary.Free;
    end;

    PublishResult := TGlossaryPublisher.Publish(Profile, GlossaryFileName, '');
    try
      Check(PublishResult.AppliedEntryCount = 2,
        'Both approved French terms are applied.');
      Check(PublishResult.FailedDestinationCount = 0,
        'No deployment destination fails.');
      Check(PublishResult.DeployedDestinationCount = 4,
        'All four existing Win32/Win64 Debug/Release outputs are updated.');
      RuntimePackFileName := PublishResult.RuntimePackFileName;
    finally
      PublishResult.Free;
    end;

    PublishedCatalog := TCatalogJson.LoadFromFile(CatalogFileName);
    try
      Check(PublishedCatalog.Entries[0].TranslatedText = FrenchOn,
        'The development catalog contains the corrected On term.');
      Check(PublishedCatalog.Entries[1].TranslatedText = FrenchOff,
        'The development catalog contains the corrected Off term.');
    finally
      PublishedCatalog.Free;
    end;
    Check(PackHas(RuntimePackFileName, 'On', FrenchOn) and
      PackHas(RuntimePackFileName, 'Off', FrenchOff),
      'The canonical runtime pack contains both corrections.');
    DependencyPackFileName := TPath.Combine(DependencyLanguageDirectory,
      'fr-FR.json');
    Check(SameText(THashSHA2.GetHashStringFromFile(RuntimePackFileName),
      THashSHA2.GetHashStringFromFile(DependencyPackFileName)),
      'The dependency pack is identical to the canonical pack.');

    for Platform in ['Win32', 'Win64'] do
      for Configuration in ['Debug', 'Release'] do
      begin
        OutputPackFileName := TPath.Combine(ProjectRoot,
          TPath.Combine(Platform, TPath.Combine(Configuration,
            'Localization\Languages\fr-FR.json')));
        Check(TFile.Exists(OutputPackFileName) and SameText(
          THashSHA2.GetHashStringFromFile(RuntimePackFileName),
          THashSHA2.GetHashStringFromFile(OutputPackFileName)),
          Platform + ' ' + Configuration + ' receives the identical pack.');
      end;
    Check(ProjectFileHash =
      THashSHA2.GetHashStringFromFile(Profile.ProjectFileName),
      'Publishing does not alter the target DPROJ file.');
    Check(not TFile.Exists(TPath.Combine(ProjectRoot,
      'GlossaryPublishSample.exe')),
      'Publishing does not build or replace an executable.');

      if Failures = 0 then
        Writeln('Glossary publish smoke tests passed.')
      else
      begin
        Writeln(Format('Glossary publish smoke tests failed: %d', [Failures]));
        ExitCode := 1;
      end;
    except
      on E: Exception do
      begin
        Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
        ExitCode := 3;
      end;
    end;
  finally
    Winapi.Windows.SetEnvironmentVariable('LOCALAPPDATA',
      PChar(OriginalLocalAppData));
    if StartsText(IncludeTrailingPathDelimiter(TPath.GetTempPath),
      IncludeTrailingPathDelimiter(TPath.GetFullPath(TestRoot))) and
      TDirectory.Exists(TestRoot) then
      TDirectory.Delete(TestRoot, True);
  end;
  Halt(ExitCode);
end.
