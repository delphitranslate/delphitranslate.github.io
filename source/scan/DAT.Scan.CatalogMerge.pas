unit DAT.Scan.CatalogMerge;

interface

uses
  System.SysUtils,
  DAT.Core.Types,
  DAT.Scan.Types;

type
  EScanKeyCollision = class(Exception);

  TCatalogMergeSummary = record
    NewEntries: Integer;
    UnchangedEntries: Integer;
    ChangedEntries: Integer;
    ObsoleteEntries: Integer;
    MigratedEntries: Integer;
    DuplicateScanKeys: Integer;
    ConflictingScanKeys: Integer;
  end;

  TScanCatalogMerger = class
  private
    class function SourceChecksum(const ASourceText: string): string; static;
    class procedure CopyScanMetadata(const AScanItem: TScanItem;
      const AEntry: TTranslationEntry); static;
  public
    class function RecoverStableSemanticContracts(
      const ACatalog: TTranslationCatalog;
      const AScanResult: TProjectScanResult): Integer; static;
    class function RecoverWorkspaceSemanticContracts(
      const ADevelopmentDirectory, AApplicationId, ASourceLanguage: string;
      const AFramework: TTargetFramework;
      const AScanResult: TProjectScanResult): Integer; static;
    class function Merge(const AScanResult: TProjectScanResult;
      const ACatalog: TTranslationCatalog): TCatalogMergeSummary; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.StrUtils,
  DAT.Core.CatalogJson;

class function TScanCatalogMerger.SourceChecksum(
  const ASourceText: string): string;
begin
  Result := LowerCase(THashSHA2.GetHashString(ASourceText));
end;

class procedure TScanCatalogMerger.CopyScanMetadata(
  const AScanItem: TScanItem; const AEntry: TTranslationEntry);
begin
  AEntry.FormName := AScanItem.FormName;
  AEntry.ComponentName := AScanItem.ComponentName;
  AEntry.ComponentClassName := AScanItem.ComponentClassName;
  AEntry.PropertyName := AScanItem.PropertyName;
  AEntry.SourceFileName := AScanItem.SourceFileName;
  AEntry.SourceLine := AScanItem.SourceLine;
  AEntry.SourceKind := ScannedTextKindDisplayName(AScanItem.Kind);
  AEntry.RuntimeTextRole := AScanItem.RuntimeTextRole;
  AEntry.ContextKind := AScanItem.ContextKind;
  AEntry.ContextDescription := AScanItem.ContextDescription;
  AEntry.SemanticConcept := AScanItem.SemanticConcept;
  AEntry.ContextConfidence := AScanItem.ContextConfidence;
  AEntry.FontColor := AScanItem.FontColor;
  AEntry.TextOwnership := AScanItem.TextOwnership;
  AEntry.SuspiciousReason := AScanItem.SuspiciousReason;
  case AEntry.RuntimeTextRole of
    rtrStaticText:
      begin
        AEntry.RuntimeApplication := rakAutomatic;
        AEntry.RuntimeWiringConfirmed := True;
      end;
    rtrRuntimeTemplate:
      begin
        AEntry.RuntimeApplication := rakAutomatic;
        AEntry.RuntimeWiringConfirmed := True;
      end;
    rtrDynamicValue:
      begin
        AEntry.RuntimeApplication := rakManualTranslateText;
        AEntry.RuntimeWiringConfirmed := False;
      end;
  else
    AEntry.RuntimeApplication := rakNotApplied;
    AEntry.RuntimeWiringConfirmed := True;
  end;
  if AScanItem.SuspiciousReason <> '' then
    AEntry.TextOwnership := tokSuspicious
  else if AScanItem.Kind <> stkFormProperty then
  begin
    if AEntry.RuntimeWiringConfirmed then
      AEntry.TextOwnership := tokRuntimeWired
    else
      AEntry.TextOwnership := tokRuntimeUnwired;
  end
  else if AEntry.RuntimeTextRole in [rtrDataValue, rtrIdentifier] then
    AEntry.TextOwnership := tokApplicationData
  else if AEntry.RuntimeTextRole = rtrExcluded then
    AEntry.TextOwnership := tokExcluded
  else
    AEntry.TextOwnership := tokDesignerAutomatic;
end;

class function TScanCatalogMerger.Merge(const AScanResult: TProjectScanResult;
  const ACatalog: TTranslationCatalog): TCatalogMergeSummary;
var
  Entry: TTranslationEntry;
  PreviousRuntimeTextRole: TRuntimeTextRole;
  ScanItem: TScanItem;
  FirstScanItem: TScanItem;
  SourceFileCache: TDictionary<string, string>;
  SeenKeys: TDictionary<string, TScanItem>;
  NormalizedKey: string;

  function StableSemanticSourceStillExists(
    const ACatalogEntry: TTranslationEntry): Boolean;
  var
    FileText: string;
    QuotedLiteral: string;
  begin
    Result := False;
    if (ACatalogEntry = nil) or
      ContainsText(ACatalogEntry.Key, '.Runtime.') or
      (ACatalogEntry.RuntimeApplication <> rakAutomatic) or
      not ACatalogEntry.RuntimeWiringConfirmed or
      not RuntimeTextRoleRequiresTranslation(
        ACatalogEntry.RuntimeTextRole) or
      (Trim(ACatalogEntry.SourceText) = '') or
      not SameText(ExtractFileExt(ACatalogEntry.SourceFileName), '.pas') or
      not TFile.Exists(ACatalogEntry.SourceFileName) then
      Exit;
    if not SourceFileCache.TryGetValue(ACatalogEntry.SourceFileName,
      FileText) then
    begin
      FileText := TFile.ReadAllText(ACatalogEntry.SourceFileName,
        TEncoding.UTF8);
      SourceFileCache.Add(ACatalogEntry.SourceFileName, FileText);
    end;
    QuotedLiteral := '''' + StringReplace(ACatalogEntry.SourceText, '''',
      '''''', [rfReplaceAll]) + '''';
    Result := Pos(QuotedLiteral, FileText) > 0;
  end;

  function ReuseStableSourceTranslation(const AScanItem: TScanItem;
    const AEntry: TTranslationEntry): Boolean;
  var
    Candidate: TTranslationEntry;
    Chosen: TTranslationEntry;
    ChosenText: string;
  begin
    Result := False;
    Chosen := nil;
    ChosenText := '';
    for Candidate in ACatalog.Entries do
    begin
      if (Candidate = AEntry) or (Trim(Candidate.TranslatedText) = '') or
        (Candidate.Status in [tsExcluded, tsError]) or
        (Candidate.SourceText <> AScanItem.SourceText) or
        (Candidate.RuntimeTextRole <> AScanItem.RuntimeTextRole) then
        Continue;
      if Chosen = nil then
      begin
        Chosen := Candidate;
        ChosenText := Candidate.TranslatedText;
      end
      else if Candidate.TranslatedText <> ChosenText then
        { Context-identical prior entries disagree.  Guessing between them
          would silently assign the wrong wording, so leave the new entry for
          review rather than calling either translation authoritative. }
        Exit(False)
      else if Candidate.Status in [tsReviewed, tsApproved] then
        Chosen := Candidate;
    end;
    if Chosen = nil then
      Exit;
    AEntry.TranslatedText := Chosen.TranslatedText;
    AEntry.TranslationOrigin := Chosen.TranslationOrigin;
    AEntry.TranslationConfidence := Chosen.TranslationConfidence;
    AEntry.TranslationReviewNote := Chosen.TranslationReviewNote;
    if Chosen.Status in [tsObsolete, tsNeedsTranslation, tsSourceChanged] then
      AEntry.Status := tsImported
    else
      AEntry.Status := Chosen.Status;
    Result := True;
  end;
begin
  Result := Default(TCatalogMergeSummary);
  if AScanResult = nil then
    raise EArgumentNilException.Create('A scan result is required.');
  if ACatalog = nil then
    raise EArgumentNilException.Create('A translation catalog is required.');

  SeenKeys := TDictionary<string, TScanItem>.Create;
  SourceFileCache := TDictionary<string, string>.Create;
  try
    for ScanItem in AScanResult.Items do
    begin
      NormalizedKey := LowerCase(ScanItem.Key);
      if SeenKeys.TryGetValue(NormalizedKey, FirstScanItem) then
      begin
        if FirstScanItem.SourceText <> ScanItem.SourceText then
        begin
          Inc(Result.ConflictingScanKeys);
          raise EScanKeyCollision.CreateFmt(
            'Scan key collision for "%s". "%s" at %s:%d conflicts with "%s" at %s:%d.',
            [ScanItem.Key, FirstScanItem.SourceText,
             FirstScanItem.SourceFileName, FirstScanItem.SourceLine,
             ScanItem.SourceText, ScanItem.SourceFileName,
             ScanItem.SourceLine]);
        end;
        Inc(Result.DuplicateScanKeys);
        Continue;
      end;
      SeenKeys.Add(NormalizedKey, ScanItem);
      Entry := ACatalog.FindEntry(ScanItem.Key);
      if Entry = nil then
      begin
        Entry := TTranslationEntry.Create;
        Entry.Key := ScanItem.Key;
        Entry.SourceText := ScanItem.SourceText;
        Entry.SourceChecksum := SourceChecksum(ScanItem.SourceText);
        Entry.Status := tsNeedsTranslation;
        CopyScanMetadata(ScanItem, Entry);
        if not RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) then
          Entry.Status := tsExcluded;
        ACatalog.Entries.Add(Entry);
        if (Entry.Status <> tsExcluded) and
          ReuseStableSourceTranslation(ScanItem, Entry) then
          Inc(Result.MigratedEntries);
        Inc(Result.NewEntries);
        Continue;
      end;

      PreviousRuntimeTextRole := Entry.RuntimeTextRole;
      CopyScanMetadata(ScanItem, Entry);
      if not RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) then
        Entry.Status := tsExcluded
      else if Entry.Status = tsObsolete then
      begin
        { Obsolete means absent from the preceding scan, not forbidden for
          life.  When a manifest or source file returns, revive its exact
          entry and preserve the translation already attached to that key. }
        if Trim(Entry.TranslatedText) = '' then
          Entry.Status := tsNeedsTranslation
        else
          Entry.Status := tsImported;
      end
      else if (Entry.Status = tsExcluded) and
        not RuntimeTextRoleRequiresTranslation(PreviousRuntimeTextRole) then
        Entry.Status := tsNeedsTranslation;
      if Entry.SourceText = ScanItem.SourceText then
      begin
        if RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) and
          (Trim(Entry.TranslatedText) = '') and
          ReuseStableSourceTranslation(ScanItem, Entry) then
          Inc(Result.MigratedEntries);
        Inc(Result.UnchangedEntries)
      end
      else
      begin
        Entry.SourceText := ScanItem.SourceText;
        Entry.SourceChecksum := SourceChecksum(ScanItem.SourceText);
        if (Entry.Status <> tsExcluded) and
          ReuseStableSourceTranslation(ScanItem, Entry) then
          Inc(Result.MigratedEntries)
        else if Entry.Status <> tsExcluded then
          Entry.Status := tsSourceChanged;
        Inc(Result.ChangedEntries);
      end;
    end;

    for Entry in ACatalog.Entries do
      if not SeenKeys.ContainsKey(LowerCase(Entry.Key)) and
        (Entry.Status <> tsExcluded) then
      begin
        { A catalog may contain explicit stable semantic contracts for text
          passed through application helper methods. A conservative scanner
          cannot infer every helper's UI semantics. Preserve such a contract
          when its exact Delphi literal still exists in the same source file;
          line-derived Runtime keys remain governed solely by the scan. }
        if StableSemanticSourceStillExists(Entry) then
        begin
          if Trim(Entry.TranslatedText) = '' then
            Entry.Status := tsNeedsTranslation
          else if Entry.Status = tsObsolete then
            Entry.Status := tsImported;
          Inc(Result.MigratedEntries);
        end
        else
        begin
          Entry.Status := tsObsolete;
          Inc(Result.ObsoleteEntries);
        end;
      end;

    { The canonical source pack is identity translation by definition.  It
      must never be sent to a provider as en|en (or any other same-language
      pair), and a newly discovered source string must be immediately valid. }
    if SameText(ACatalog.SourceLanguage,
      ACatalog.Locale.LanguageCode) then
      for Entry in ACatalog.Entries do
        if (Entry.Status <> tsExcluded) and (Entry.Status <> tsObsolete) then
        begin
          Entry.TranslatedText := Entry.SourceText;
          Entry.Status := tsApproved;
        end;
  finally
    SourceFileCache.Free;
    SeenKeys.Free;
  end;
end;

class function TScanCatalogMerger.RecoverStableSemanticContracts(
  const ACatalog: TTranslationCatalog;
  const AScanResult: TProjectScanResult): Integer;
var
  Entry: TTranslationEntry;
  Existing: TScanItem;
  FileText: string;
  NewItem: TScanItem;
  QuotedLiteral: string;
  SourceFileCache: TDictionary<string, string>;
begin
  Result := 0;
  if ACatalog = nil then
    raise EArgumentNilException.Create('A translation catalog is required.');
  if AScanResult = nil then
    raise EArgumentNilException.Create('A scan result is required.');

  SourceFileCache := TDictionary<string, string>.Create;
  try
    for Entry in ACatalog.Entries do
    begin
      { Explicit semantic contracts are the durable bridge for text passed
        through application helper methods. Line-derived Runtime keys are
        deliberately excluded: only the ordinary scanner owns those. }
      if ContainsText(Entry.Key, '.Runtime.') or
        (Entry.RuntimeApplication <> rakAutomatic) or
        not Entry.RuntimeWiringConfirmed or
        not RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) or
        (Trim(Entry.SourceText) = '') or
        not SameText(ExtractFileExt(Entry.SourceFileName), '.pas') or
        not TFile.Exists(Entry.SourceFileName) then
        Continue;

      if not SourceFileCache.TryGetValue(Entry.SourceFileName, FileText) then
      begin
        FileText := TFile.ReadAllText(Entry.SourceFileName, TEncoding.UTF8);
        SourceFileCache.Add(Entry.SourceFileName, FileText);
      end;
      QuotedLiteral := '''' + StringReplace(Entry.SourceText, '''', '''''',
        [rfReplaceAll]) + '''';
      if Pos(QuotedLiteral, FileText) = 0 then
        Continue;

      Existing := AScanResult.FindItem(Entry.Key);
      if Existing <> nil then
      begin
        if Existing.SourceText <> Entry.SourceText then
          raise EScanKeyCollision.CreateFmt(
            'Stable semantic key collision for "%s": "%s" conflicts with "%s".',
            [Entry.Key, Existing.SourceText, Entry.SourceText]);
        Continue;
      end;

      NewItem := TScanItem.Create;
      NewItem.Key := Entry.Key;
      NewItem.SourceText := Entry.SourceText;
      NewItem.FormName := Entry.FormName;
      NewItem.ComponentName := Entry.ComponentName;
      NewItem.ComponentClassName := Entry.ComponentClassName;
      NewItem.PropertyName := Entry.PropertyName;
      NewItem.SourceFileName := Entry.SourceFileName;
      NewItem.SourceLine := Entry.SourceLine;
      NewItem.Framework := ACatalog.Framework;
      NewItem.Kind := stkRuntimeAssignment;
      NewItem.RuntimeTextRole := Entry.RuntimeTextRole;
      NewItem.ContextKind := Entry.ContextKind;
      NewItem.ContextDescription := Entry.ContextDescription;
      NewItem.SemanticConcept := Entry.SemanticConcept;
      NewItem.ContextConfidence := Entry.ContextConfidence;
      NewItem.FontColor := Entry.FontColor;
      NewItem.TextOwnership := Entry.TextOwnership;
      NewItem.SuspiciousReason := Entry.SuspiciousReason;
      AScanResult.Items.Add(NewItem);
      Inc(Result);
    end;
  finally
    SourceFileCache.Free;
  end;
end;

class function TScanCatalogMerger.RecoverWorkspaceSemanticContracts(
  const ADevelopmentDirectory, AApplicationId, ASourceLanguage: string;
  const AFramework: TTargetFramework;
  const AScanResult: TProjectScanResult): Integer;
var
  Catalog: TTranslationCatalog;
  CatalogFileName: string;
begin
  Result := 0;
  if AScanResult = nil then
    raise EArgumentNilException.Create('A project scan result is required.');
  if not TDirectory.Exists(ADevelopmentDirectory) then
    Exit;

  { Every language is generated from one canonical source contract. A helper
    call can be understood by an earlier reviewed catalog even when the
    conservative source scanner cannot infer that call's UI meaning. Recover
    the verified union before any one target catalog is merged, so processing
    a single language cannot silently discard contracts retained by the other
    languages in the same application workspace. }
  for CatalogFileName in TDirectory.GetFiles(ADevelopmentDirectory,
    '*.translation-project.json', TSearchOption.soTopDirectoryOnly) do
  begin
    Catalog := nil;
    try
      try
        Catalog := TCatalogJson.LoadFromFile(CatalogFileName);
        if SameText(Catalog.ApplicationId, AApplicationId) and
          SameText(Catalog.SourceLanguage, ASourceLanguage) and
          (Catalog.Framework = AFramework) then
          Inc(Result, RecoverStableSemanticContracts(Catalog, AScanResult));
      except
        { A stale or interrupted catalog must not prevent a clean rescan.
          Validation will still report that file when it is opened directly. }
      end;
    finally
      Catalog.Free;
    end;
  end;
end;

end.
