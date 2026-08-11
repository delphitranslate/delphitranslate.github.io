unit DAT.Scan.CatalogMerge;

interface

uses
  DAT.Core.Types,
  DAT.Scan.Types;

type
  TCatalogMergeSummary = record
    NewEntries: Integer;
    UnchangedEntries: Integer;
    ChangedEntries: Integer;
    ObsoleteEntries: Integer;
  end;

  TScanCatalogMerger = class
  private
    class function SourceChecksum(const ASourceText: string): string; static;
    class procedure CopyScanMetadata(const AScanItem: TScanItem;
      const AEntry: TTranslationEntry); static;
  public
    class function Merge(const AScanResult: TProjectScanResult;
      const ACatalog: TTranslationCatalog): TCatalogMergeSummary; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.Hash,
  System.SysUtils;

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
  case AEntry.RuntimeTextRole of
    rtrStaticText:
      begin
        AEntry.RuntimeApplication := rakAutomatic;
        AEntry.RuntimeWiringConfirmed := True;
      end;
    rtrDynamicValue, rtrRuntimeTemplate:
      begin
        AEntry.RuntimeApplication := rakManualTranslateText;
        AEntry.RuntimeWiringConfirmed := False;
      end;
  else
    AEntry.RuntimeApplication := rakNotApplied;
    AEntry.RuntimeWiringConfirmed := True;
  end;
end;

class function TScanCatalogMerger.Merge(const AScanResult: TProjectScanResult;
  const ACatalog: TTranslationCatalog): TCatalogMergeSummary;
var
  Entry: TTranslationEntry;
  PreviousRuntimeTextRole: TRuntimeTextRole;
  ScanItem: TScanItem;
  SeenKeys: TDictionary<string, Boolean>;
begin
  Result := Default(TCatalogMergeSummary);
  if AScanResult = nil then
    raise EArgumentNilException.Create('A scan result is required.');
  if ACatalog = nil then
    raise EArgumentNilException.Create('A translation catalog is required.');

  SeenKeys := TDictionary<string, Boolean>.Create;
  try
    for ScanItem in AScanResult.Items do
    begin
      SeenKeys.AddOrSetValue(LowerCase(ScanItem.Key), True);
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
        Inc(Result.NewEntries);
        Continue;
      end;

      PreviousRuntimeTextRole := Entry.RuntimeTextRole;
      CopyScanMetadata(ScanItem, Entry);
      if not RuntimeTextRoleRequiresTranslation(Entry.RuntimeTextRole) then
        Entry.Status := tsExcluded
      else if (Entry.Status = tsExcluded) and
        not RuntimeTextRoleRequiresTranslation(PreviousRuntimeTextRole) then
        Entry.Status := tsNeedsTranslation;
      if Entry.SourceText = ScanItem.SourceText then
        Inc(Result.UnchangedEntries)
      else
      begin
        Entry.SourceText := ScanItem.SourceText;
        Entry.SourceChecksum := SourceChecksum(ScanItem.SourceText);
        if Entry.Status <> tsExcluded then
          Entry.Status := tsSourceChanged;
        Inc(Result.ChangedEntries);
      end;
    end;

    for Entry in ACatalog.Entries do
      if not SeenKeys.ContainsKey(LowerCase(Entry.Key)) and
        (Entry.Status <> tsExcluded) then
      begin
        Entry.Status := tsObsolete;
        Inc(Result.ObsoleteEntries);
      end;
  finally
    SeenKeys.Free;
  end;
end;

end.
