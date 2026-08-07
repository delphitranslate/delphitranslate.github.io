unit DAT.Core.AITranslation;

interface

uses
  System.Classes,
  DAT.Core.Types;

type
  TAITranslationReview = class
  private
    FIssues: TStringList;
    FChangedCount: Integer;
    FMissingCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function HasBlockingIssues: Boolean;
    function Summary: string;
    property Issues: TStringList read FIssues;
    property ChangedCount: Integer read FChangedCount write FChangedCount;
    property MissingCount: Integer read FMissingCount write FMissingCount;
  end;

  TAITranslationWorkflow = class
  private
    class procedure CompareProtectedEntry(
      const AOriginal, AExternal: TTranslationEntry;
      const AIssues: TStrings); static;
  public
    class function FileHash(const AFileName: string): string; static;
    class function ProfileFileName(const ACatalogFileName: string): string; static;
    class function InstructionsFileName(
      const ACatalogFileName: string): string; static;
    class function SnapshotFileName(
      const ACatalogFileName: string): string; static;
    class procedure EnsureProfile(const ACatalogFileName: string); static;
    class function BuildInstructions(const ACatalog: TTranslationCatalog;
      const ACatalogFileName: string): string; static;
    class procedure PrepareSession(const ACatalog: TTranslationCatalog;
      const ACatalogFileName: string); static;
    class function AnalyzeExternalCatalog(
      const AOriginal, AExternal: TTranslationCatalog):
      TAITranslationReview; static;
    class procedure ApplyExternalTranslations(
      const AOriginal, AExternal: TTranslationCatalog); static;
  end;

implementation

uses
  System.Hash,
  System.IOUtils,
  System.SysUtils,
  DAT.Core.CatalogJson;

constructor TAITranslationReview.Create;
begin
  inherited Create;
  FIssues := TStringList.Create;
end;

destructor TAITranslationReview.Destroy;
begin
  FIssues.Free;
  inherited Destroy;
end;

function TAITranslationReview.HasBlockingIssues: Boolean;
begin
  Result := FIssues.Count > 0;
end;

function TAITranslationReview.Summary: string;
begin
  Result := Format(
    '%d translation changes detected; %d eligible entries remain unresolved; ' +
    '%d protected-field issue(s).',
    [FChangedCount, FMissingCount, FIssues.Count]);
end;

class function TAITranslationWorkflow.FileHash(
  const AFileName: string): string;
begin
  if not TFile.Exists(AFileName) then
    Exit('');
  Result := THashSHA2.GetHashStringFromFile(AFileName);
end;

class function TAITranslationWorkflow.ProfileFileName(
  const ACatalogFileName: string): string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(ACatalogFileName),
    'translation-profile.json');
end;

class function TAITranslationWorkflow.InstructionsFileName(
  const ACatalogFileName: string): string;
begin
  Result := TPath.ChangeExtension(ACatalogFileName, '.ai-instructions.md');
end;

class function TAITranslationWorkflow.SnapshotFileName(
  const ACatalogFileName: string): string;
begin
  Result := TPath.ChangeExtension(ACatalogFileName, '.pre-ai.json');
end;

class procedure TAITranslationWorkflow.EnsureProfile(
  const ACatalogFileName: string);
const
  PROFILE_TEMPLATE =
    '{'#13#10 +
    '  "applicationDescription": "",'#13#10 +
    '  "domain": "",'#13#10 +
    '  "audience": "",'#13#10 +
    '  "tone": "clear and professional",'#13#10 +
    '  "formality": "appropriate for the target locale",'#13#10 +
    '  "protectedTerms": [],'#13#10 +
    '  "preferredTerminology": {},'#13#10 +
    '  "additionalInstructions": ""'#13#10 +
    '}';
var
  FileName: string;
begin
  FileName := ProfileFileName(ACatalogFileName);
  if not TFile.Exists(FileName) then
    TFile.WriteAllText(FileName, PROFILE_TEMPLATE, TEncoding.UTF8);
end;

class function TAITranslationWorkflow.BuildInstructions(
  const ACatalog: TTranslationCatalog;
  const ACatalogFileName: string): string;
var
  Builder: TStringBuilder;
begin
  if ACatalog = nil then
    raise Exception.Create('A translation catalog is required.');
  Builder := TStringBuilder.Create;
  try
    Builder.AppendLine('# In-place Delphi catalog translation');
    Builder.AppendLine;
    Builder.AppendLine('Translate the development catalog directly in place.');
    Builder.AppendLine('Catalog: ' + ACatalogFileName);
    Builder.AppendLine('Profile: ' + ProfileFileName(ACatalogFileName));
    Builder.AppendLine('Source language: ' + ACatalog.SourceLanguage);
    Builder.AppendLine('Target language: ' +
      ACatalog.Locale.LanguageCode + ' (' +
      ACatalog.Locale.NativeLanguageName + ')');
    Builder.AppendLine;
    Builder.AppendLine('## Required editing contract');
    Builder.AppendLine;
    Builder.AppendLine(
      '1. Read the entire translation profile and catalog before editing.');
    Builder.AppendLine(
      '2. Modify only translatedText, status, translationOrigin, ' +
      'translationConfidence, and translationReviewNote.');
    Builder.AppendLine(
      '3. Never modify stable keys, source text, checksums, source locations, ' +
      'component metadata, runtime metadata, locale metadata, or entry order.');
    Builder.AppendLine(
      '4. Translate only blank, needsTranslation, sourceChanged, error, or ' +
      'existing aiDraft entries. Preserve Reviewed and Approved work.');
    Builder.AppendLine(
      '5. Set status to aiDraft. Set translationOrigin to codex or claude, ' +
      'matching the agent performing the work.');
    Builder.AppendLine(
      '6. Set translationConfidence to high, medium, or low. Put ambiguity, ' +
      'context questions, or terminology concerns in translationReviewNote.');
    Builder.AppendLine(
      '7. Preserve Delphi Format argument identity, percent escapes, ' +
      'accelerators, line breaks, quoting, and protected product names.');
    Builder.AppendLine(
      '8. Use form, component, class, property, source unit, neighboring ' +
      'entries, and the project profile as translation context.');
    Builder.AppendLine(
      '9. Maintain consistent terminology across the complete catalog. Do a ' +
      'second linguistic QA pass after translating.');
    Builder.AppendLine(
      '10. Validate the final JSON, confirm every protected field is unchanged, ' +
      'and report translated, skipped, uncertain, and unresolved counts.');
    Builder.AppendLine;
    Builder.AppendLine(
      'For a large catalog, work in checkpoints in the same file. Save valid ' +
      'JSON after each checkpoint so the operation can be resumed safely.');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

class procedure TAITranslationWorkflow.PrepareSession(
  const ACatalog: TTranslationCatalog;
  const ACatalogFileName: string);
begin
  if ACatalogFileName = '' then
    raise Exception.Create('Save the development catalog before translation.');
  EnsureProfile(ACatalogFileName);
  TFile.WriteAllText(SnapshotFileName(ACatalogFileName),
    TCatalogJson.Serialize(ACatalog), TEncoding.UTF8);
  TFile.WriteAllText(InstructionsFileName(ACatalogFileName),
    BuildInstructions(ACatalog, ACatalogFileName), TEncoding.UTF8);
end;

class procedure TAITranslationWorkflow.CompareProtectedEntry(
  const AOriginal, AExternal: TTranslationEntry;
  const AIssues: TStrings);
begin
  if AOriginal.SourceText <> AExternal.SourceText then
    AIssues.Add(AOriginal.Key + ': sourceText was modified.');
  if AOriginal.SourceChecksum <> AExternal.SourceChecksum then
    AIssues.Add(AOriginal.Key + ': sourceChecksum was modified.');
  if AOriginal.FormName <> AExternal.FormName then
    AIssues.Add(AOriginal.Key + ': formName was modified.');
  if AOriginal.ComponentName <> AExternal.ComponentName then
    AIssues.Add(AOriginal.Key + ': componentName was modified.');
  if AOriginal.ComponentClassName <> AExternal.ComponentClassName then
    AIssues.Add(AOriginal.Key + ': componentClassName was modified.');
  if AOriginal.PropertyName <> AExternal.PropertyName then
    AIssues.Add(AOriginal.Key + ': propertyName was modified.');
  if AOriginal.SourceFileName <> AExternal.SourceFileName then
    AIssues.Add(AOriginal.Key + ': sourceFileName was modified.');
  if AOriginal.SourceLine <> AExternal.SourceLine then
    AIssues.Add(AOriginal.Key + ': sourceLine was modified.');
  if AOriginal.SourceKind <> AExternal.SourceKind then
    AIssues.Add(AOriginal.Key + ': sourceKind was modified.');
  if AOriginal.DeveloperNote <> AExternal.DeveloperNote then
    AIssues.Add(AOriginal.Key + ': developerNote was modified.');
  if AOriginal.RuntimeApplication <> AExternal.RuntimeApplication then
    AIssues.Add(AOriginal.Key + ': runtimeApplication was modified.');
  if AOriginal.RuntimeWiringConfirmed <>
     AExternal.RuntimeWiringConfirmed then
    AIssues.Add(AOriginal.Key + ': runtimeWiringConfirmed was modified.');
end;

class function TAITranslationWorkflow.AnalyzeExternalCatalog(
  const AOriginal, AExternal: TTranslationCatalog): TAITranslationReview;
var
  AllowedDataChanged: Boolean;
  EntryEligible: Boolean;
  Index: Integer;
  OriginalEntry: TTranslationEntry;
  ExternalEntry: TTranslationEntry;
begin
  Result := TAITranslationReview.Create;
  if (AOriginal = nil) or (AExternal = nil) then
  begin
    Result.Issues.Add('Both the original and external catalogs are required.');
    Exit;
  end;
  if AOriginal.SchemaVersion <> AExternal.SchemaVersion then
    Result.Issues.Add('schemaVersion was modified.');
  if AOriginal.ApplicationId <> AExternal.ApplicationId then
    Result.Issues.Add('applicationId was modified.');
  if AOriginal.ApplicationVersion <> AExternal.ApplicationVersion then
    Result.Issues.Add('applicationVersion was modified.');
  if AOriginal.Framework <> AExternal.Framework then
    Result.Issues.Add('framework was modified.');
  if AOriginal.SourceLanguage <> AExternal.SourceLanguage then
    Result.Issues.Add('sourceLanguage was modified.');
  if AOriginal.Locale.LanguageCode <> AExternal.Locale.LanguageCode then
    Result.Issues.Add('target languageCode was modified.');
  if AOriginal.Locale.NativeLanguageName <>
     AExternal.Locale.NativeLanguageName then
    Result.Issues.Add('nativeLanguageName was modified.');
  if AOriginal.Locale.TextDirection <> AExternal.Locale.TextDirection then
    Result.Issues.Add('textDirection was modified.');
  if AOriginal.Locale.ShortDateFormat <>
     AExternal.Locale.ShortDateFormat then
    Result.Issues.Add('shortDateFormat was modified.');
  if AOriginal.Locale.LongDateFormat <>
     AExternal.Locale.LongDateFormat then
    Result.Issues.Add('longDateFormat was modified.');
  if AOriginal.Locale.ShortTimeFormat <>
     AExternal.Locale.ShortTimeFormat then
    Result.Issues.Add('shortTimeFormat was modified.');
  if AOriginal.Locale.LongTimeFormat <>
     AExternal.Locale.LongTimeFormat then
    Result.Issues.Add('longTimeFormat was modified.');
  if AOriginal.Locale.DecimalSeparator <>
     AExternal.Locale.DecimalSeparator then
    Result.Issues.Add('decimalSeparator was modified.');
  if AOriginal.Locale.ThousandSeparator <>
     AExternal.Locale.ThousandSeparator then
    Result.Issues.Add('thousandSeparator was modified.');
  if AOriginal.Locale.CurrencySymbol <>
     AExternal.Locale.CurrencySymbol then
    Result.Issues.Add('currencySymbol was modified.');
  if AOriginal.Entries.Count <> AExternal.Entries.Count then
  begin
    Result.Issues.Add('The catalog entry count was modified.');
    Exit;
  end;

  for Index := 0 to AOriginal.Entries.Count - 1 do
  begin
    OriginalEntry := AOriginal.Entries[Index];
    ExternalEntry := AExternal.Entries[Index];
    if OriginalEntry.Key <> ExternalEntry.Key then
    begin
      Result.Issues.Add(Format(
        'Entry %d key/order was modified (%s versus %s).',
        [Index + 1, OriginalEntry.Key, ExternalEntry.Key]));
      Continue;
    end;
    CompareProtectedEntry(OriginalEntry, ExternalEntry, Result.Issues);
    EntryEligible := OriginalEntry.Status in [
      tsNeedsTranslation, tsAIDraft, tsSourceChanged, tsError];
    AllowedDataChanged :=
      (OriginalEntry.TranslatedText <> ExternalEntry.TranslatedText) or
      (OriginalEntry.Status <> ExternalEntry.Status) or
      (OriginalEntry.TranslationOrigin <>
       ExternalEntry.TranslationOrigin) or
      (OriginalEntry.TranslationConfidence <>
       ExternalEntry.TranslationConfidence) or
      (OriginalEntry.TranslationReviewNote <>
       ExternalEntry.TranslationReviewNote);
    if AllowedDataChanged then
    begin
      if not EntryEligible then
        Result.Issues.Add(OriginalEntry.Key +
          ': translation data is protected by its current status.')
      else
      begin
        Inc(Result.FChangedCount);
        if not (ExternalEntry.TranslationOrigin in
           [torCodex, torClaude]) then
          Result.Issues.Add(OriginalEntry.Key +
            ': AI origin must be codex or claude.');
        if not SameText(ExternalEntry.TranslationConfidence, 'high') and
           not SameText(ExternalEntry.TranslationConfidence, 'medium') and
           not SameText(ExternalEntry.TranslationConfidence, 'low') then
          Result.Issues.Add(OriginalEntry.Key +
            ': AI confidence must be high, medium, or low.');
      end;
    end;
    if EntryEligible and
       (Trim(ExternalEntry.TranslatedText) = '') then
      Inc(Result.FMissingCount);
  end;
end;

class procedure TAITranslationWorkflow.ApplyExternalTranslations(
  const AOriginal, AExternal: TTranslationCatalog);
var
  Index: Integer;
  OriginalEntry: TTranslationEntry;
  ExternalEntry: TTranslationEntry;
begin
  for Index := 0 to AOriginal.Entries.Count - 1 do
  begin
    OriginalEntry := AOriginal.Entries[Index];
    ExternalEntry := AExternal.Entries[Index];
    if (OriginalEntry.Status in [
         tsNeedsTranslation, tsAIDraft, tsSourceChanged, tsError]) and
       ((OriginalEntry.TranslatedText <> ExternalEntry.TranslatedText) or
        (OriginalEntry.Status <> ExternalEntry.Status) or
        (OriginalEntry.TranslationOrigin <>
         ExternalEntry.TranslationOrigin) or
        (OriginalEntry.TranslationConfidence <>
         ExternalEntry.TranslationConfidence) or
        (OriginalEntry.TranslationReviewNote <>
         ExternalEntry.TranslationReviewNote)) then
    begin
      OriginalEntry.TranslatedText := ExternalEntry.TranslatedText;
      OriginalEntry.Status := tsAIDraft;
      if ExternalEntry.TranslationOrigin in [torCodex, torClaude] then
        OriginalEntry.TranslationOrigin := ExternalEntry.TranslationOrigin
      else
        OriginalEntry.TranslationOrigin := torUnknown;
      OriginalEntry.TranslationConfidence :=
        ExternalEntry.TranslationConfidence;
      OriginalEntry.TranslationReviewNote :=
        ExternalEntry.TranslationReviewNote;
    end;
  end;
end;

end.
