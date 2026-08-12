unit DAT.Core.CatalogJson;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.JSON,
  DAT.Core.Types;

type
  ECatalogJsonError = class(Exception);
  ECatalogCsvError = class(Exception);

  TCatalogCsvImportChange = class
  private
    FEntry: TTranslationEntry;
    FTranslatedText: string;
  public
    property Entry: TTranslationEntry read FEntry write FEntry;
    property TranslatedText: string read FTranslatedText write FTranslatedText;
  end;

  TCatalogCsvImportPlan = class
  private
    FChanges: TObjectList<TCatalogCsvImportChange>;
    FIssues: TStringList;
    FRowsRead: Integer;
    FUnchangedCount: Integer;
    FStaleCount: Integer;
    FUnknownCount: Integer;
    FDuplicateCount: Integer;
    FProtectedCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Apply;
    function Summary: string;
    property Changes: TObjectList<TCatalogCsvImportChange> read FChanges;
    property Issues: TStringList read FIssues;
    property RowsRead: Integer read FRowsRead write FRowsRead;
    property UnchangedCount: Integer read FUnchangedCount
      write FUnchangedCount;
    property StaleCount: Integer read FStaleCount write FStaleCount;
    property UnknownCount: Integer read FUnknownCount write FUnknownCount;
    property DuplicateCount: Integer read FDuplicateCount
      write FDuplicateCount;
    property ProtectedCount: Integer read FProtectedCount
      write FProtectedCount;
  end;

  TCatalogJson = class
  private
    class function JsonValueText(AObject: TJSONObject;
      const AName, ADefault: string): string; static;
  public
    class function Serialize(const ACatalog: TTranslationCatalog): string; static;
    class function Deserialize(const AJson: string): TTranslationCatalog; static;
    class procedure SaveToFile(const ACatalog: TTranslationCatalog;
      const AFileName: string); static;
    class function LoadFromFile(const AFileName: string): TTranslationCatalog; static;
  end;

  TCatalogCsv = class
  private
    class function EscapeField(const AValue: string): string; static;
    class function ParseRows(const AText: string):
      TObjectList<TStringList>; static;
  public
    class procedure ExportToFile(const ACatalog: TTranslationCatalog;
      const AFileName: string); static;
    class function AnalyzeImport(const ACatalog: TTranslationCatalog;
      const AFileName: string): TCatalogCsvImportPlan; static;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils;

constructor TCatalogCsvImportPlan.Create;
begin
  inherited Create;
  FChanges := TObjectList<TCatalogCsvImportChange>.Create(True);
  FIssues := TStringList.Create;
end;

destructor TCatalogCsvImportPlan.Destroy;
begin
  FIssues.Free;
  FChanges.Free;
  inherited Destroy;
end;

procedure TCatalogCsvImportPlan.Apply;
var
  Change: TCatalogCsvImportChange;
begin
  for Change in FChanges do
  begin
    Change.Entry.TranslatedText := Change.TranslatedText;
    Change.Entry.Status := tsImported;
    Change.Entry.TranslationOrigin := torImported;
    Change.Entry.TranslationConfidence := '';
    Change.Entry.TranslationReviewNote := '';
  end;
end;

function TCatalogCsvImportPlan.Summary: string;
begin
  Result := Format(
    '%d data rows read'#13#10 +
    '%d translations ready to import'#13#10 +
    '%d unchanged or empty'#13#10 +
    '%d stale source rows'#13#10 +
    '%d unknown keys'#13#10 +
    '%d duplicate keys'#13#10 +
    '%d reviewed/approved entries protected',
    [FRowsRead, FChanges.Count, FUnchangedCount, FStaleCount,
     FUnknownCount, FDuplicateCount, FProtectedCount]);
end;

class function TCatalogJson.JsonValueText(AObject: TJSONObject;
  const AName, ADefault: string): string;
var
  JsonValue: TJSONValue;
begin
  Result := ADefault;
  if AObject = nil then
    Exit;

  JsonValue := AObject.GetValue(AName);
  if JsonValue <> nil then
    Result := JsonValue.Value;
end;

class function TCatalogJson.Serialize(
  const ACatalog: TTranslationCatalog): string;
var
  Root: TJSONObject;
  LocaleObject: TJSONObject;
  EntriesArray: TJSONArray;
  EntryObject: TJSONObject;
  Entry: TTranslationEntry;
begin
  if ACatalog = nil then
    raise ECatalogJsonError.Create('A catalog is required.');

  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(ACatalog.SchemaVersion));
    Root.AddPair('applicationId', ACatalog.ApplicationId);
    Root.AddPair('applicationVersion', ACatalog.ApplicationVersion);
    Root.AddPair('framework', TargetFrameworkToString(ACatalog.Framework));
    Root.AddPair('sourceLanguage', ACatalog.SourceLanguage);

    LocaleObject := TJSONObject.Create;
    LocaleObject.AddPair('languageCode', ACatalog.Locale.LanguageCode);
    LocaleObject.AddPair('nativeLanguageName', ACatalog.Locale.NativeLanguageName);
    LocaleObject.AddPair('textDirection', ACatalog.Locale.TextDirection);
    LocaleObject.AddPair('shortDateFormat', ACatalog.Locale.ShortDateFormat);
    LocaleObject.AddPair('longDateFormat', ACatalog.Locale.LongDateFormat);
    LocaleObject.AddPair('shortTimeFormat', ACatalog.Locale.ShortTimeFormat);
    LocaleObject.AddPair('longTimeFormat', ACatalog.Locale.LongTimeFormat);
    LocaleObject.AddPair('decimalSeparator', ACatalog.Locale.DecimalSeparator);
    LocaleObject.AddPair('thousandSeparator', ACatalog.Locale.ThousandSeparator);
    LocaleObject.AddPair('currencySymbol', ACatalog.Locale.CurrencySymbol);
    Root.AddPair('locale', LocaleObject);

    EntriesArray := TJSONArray.Create;
    for Entry in ACatalog.Entries do
    begin
      EntryObject := TJSONObject.Create;
      EntryObject.AddPair('key', Entry.Key);
      EntryObject.AddPair('sourceText', Entry.SourceText);
      EntryObject.AddPair('translatedText', Entry.TranslatedText);
      EntryObject.AddPair('formName', Entry.FormName);
      EntryObject.AddPair('componentName', Entry.ComponentName);
      EntryObject.AddPair('componentClassName', Entry.ComponentClassName);
      EntryObject.AddPair('propertyName', Entry.PropertyName);
      EntryObject.AddPair('sourceFileName', Entry.SourceFileName);
      EntryObject.AddPair('sourceLine', TJSONNumber.Create(Entry.SourceLine));
      EntryObject.AddPair('sourceKind', Entry.SourceKind);
      EntryObject.AddPair('sourceChecksum', Entry.SourceChecksum);
      EntryObject.AddPair('developerNote', Entry.DeveloperNote);
      EntryObject.AddPair('contextKind', Entry.ContextKind);
      EntryObject.AddPair('contextDescription', Entry.ContextDescription);
      EntryObject.AddPair('semanticConcept', Entry.SemanticConcept);
      EntryObject.AddPair('contextConfidence', Entry.ContextConfidence);
      EntryObject.AddPair('textOwnership',
        TextOwnershipKindToString(Entry.TextOwnership));
      EntryObject.AddPair('suspiciousReason', Entry.SuspiciousReason);
      EntryObject.AddPair('status', TranslationStatusToString(Entry.Status));
      EntryObject.AddPair('translationOrigin',
        TranslationOriginToString(Entry.TranslationOrigin));
      EntryObject.AddPair('translationConfidence',
        Entry.TranslationConfidence);
      EntryObject.AddPair('translationReviewNote',
        Entry.TranslationReviewNote);
      EntryObject.AddPair('runtimeApplication',
        RuntimeApplicationKindToString(Entry.RuntimeApplication));
      EntryObject.AddPair('runtimeTextRole',
        RuntimeTextRoleToString(Entry.RuntimeTextRole));
      EntryObject.AddPair('runtimeWiringConfirmed',
        TJSONBool.Create(Entry.RuntimeWiringConfirmed));
      EntriesArray.AddElement(EntryObject);
    end;
    Root.AddPair('entries', EntriesArray);

    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

class function TCatalogJson.Deserialize(
  const AJson: string): TTranslationCatalog;
var
  JsonValue: TJSONValue;
  Root: TJSONObject;
  LocaleObject: TJSONObject;
  EntriesArray: TJSONArray;
  ArrayValue: TJSONValue;
  EntryObject: TJSONObject;
  Entry: TTranslationEntry;
begin
  JsonValue := TJSONObject.ParseJSONValue(AJson);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise ECatalogJsonError.Create('The catalog JSON root must be an object.');
  end;

  Root := TJSONObject(JsonValue);
  try
    Result := TTranslationCatalog.Create;
    try
      Result.SchemaVersion := StrToIntDef(
        JsonValueText(Root, 'schemaVersion', '1'), 1);
      Result.ApplicationId := JsonValueText(Root, 'applicationId', '');
      Result.ApplicationVersion := JsonValueText(Root, 'applicationVersion', '');
      Result.Framework := StringToTargetFramework(
        JsonValueText(Root, 'framework', 'Unknown'));
      Result.SourceLanguage := JsonValueText(Root, 'sourceLanguage', '');

      LocaleObject := Root.GetValue('locale') as TJSONObject;
      if LocaleObject <> nil then
      begin
        Result.Locale.LanguageCode :=
          JsonValueText(LocaleObject, 'languageCode', '');
        Result.Locale.NativeLanguageName :=
          JsonValueText(LocaleObject, 'nativeLanguageName', '');
        Result.Locale.TextDirection :=
          JsonValueText(LocaleObject, 'textDirection', 'ltr');
        Result.Locale.ShortDateFormat :=
          JsonValueText(LocaleObject, 'shortDateFormat', '');
        Result.Locale.LongDateFormat :=
          JsonValueText(LocaleObject, 'longDateFormat', '');
        Result.Locale.ShortTimeFormat :=
          JsonValueText(LocaleObject, 'shortTimeFormat', '');
        Result.Locale.LongTimeFormat :=
          JsonValueText(LocaleObject, 'longTimeFormat', '');
        Result.Locale.DecimalSeparator :=
          JsonValueText(LocaleObject, 'decimalSeparator', '');
        Result.Locale.ThousandSeparator :=
          JsonValueText(LocaleObject, 'thousandSeparator', '');
        Result.Locale.CurrencySymbol :=
          JsonValueText(LocaleObject, 'currencySymbol', '');
      end;

      EntriesArray := Root.GetValue('entries') as TJSONArray;
      if EntriesArray <> nil then
        for ArrayValue in EntriesArray do
          if ArrayValue is TJSONObject then
          begin
            EntryObject := TJSONObject(ArrayValue);
            Entry := TTranslationEntry.Create;
            Entry.Key := JsonValueText(EntryObject, 'key', '');
            Entry.SourceText := JsonValueText(EntryObject, 'sourceText', '');
            Entry.TranslatedText :=
              JsonValueText(EntryObject, 'translatedText', '');
            Entry.FormName := JsonValueText(EntryObject, 'formName', '');
            Entry.ComponentName :=
              JsonValueText(EntryObject, 'componentName', '');
            Entry.ComponentClassName :=
              JsonValueText(EntryObject, 'componentClassName', '');
            Entry.PropertyName :=
              JsonValueText(EntryObject, 'propertyName', '');
            Entry.SourceFileName :=
              JsonValueText(EntryObject, 'sourceFileName', '');
            Entry.SourceLine := StrToIntDef(
              JsonValueText(EntryObject, 'sourceLine', '0'), 0);
            Entry.SourceKind :=
              JsonValueText(EntryObject, 'sourceKind', '');
            Entry.SourceChecksum :=
              JsonValueText(EntryObject, 'sourceChecksum', '');
            Entry.DeveloperNote :=
              JsonValueText(EntryObject, 'developerNote', '');
            Entry.ContextKind := JsonValueText(EntryObject,
              'contextKind', '');
            Entry.ContextDescription := JsonValueText(EntryObject,
              'contextDescription', '');
            Entry.SemanticConcept := JsonValueText(EntryObject,
              'semanticConcept', '');
            Entry.ContextConfidence := JsonValueText(EntryObject,
              'contextConfidence', '');
            Entry.TextOwnership := StringToTextOwnershipKind(JsonValueText(
              EntryObject, 'textOwnership', 'designerAutomatic'));
            Entry.SuspiciousReason := JsonValueText(EntryObject,
              'suspiciousReason', '');
            Entry.Status := StringToTranslationStatus(
              JsonValueText(EntryObject, 'status', 'needsTranslation'));
            Entry.TranslationOrigin := StringToTranslationOrigin(
              JsonValueText(EntryObject, 'translationOrigin', 'unknown'));
            Entry.TranslationConfidence := JsonValueText(EntryObject,
              'translationConfidence', '');
            Entry.TranslationReviewNote := JsonValueText(EntryObject,
              'translationReviewNote', '');
            if EntryObject.GetValue('runtimeApplication') <> nil then
              Entry.RuntimeApplication := StringToRuntimeApplicationKind(
                JsonValueText(EntryObject, 'runtimeApplication',
                  'automatic'))
            else if SameText(Entry.SourceKind, 'Resource string') then
              Entry.RuntimeApplication := rakManualTranslateText
            else
              Entry.RuntimeApplication := rakAutomatic;
            if EntryObject.GetValue('runtimeTextRole') <> nil then
              Entry.RuntimeTextRole := StringToRuntimeTextRole(
                JsonValueText(EntryObject, 'runtimeTextRole', 'staticText'))
            else if SameText(Entry.SourceKind, 'Resource string') then
              Entry.RuntimeTextRole := rtrRuntimeTemplate
            else
              Entry.RuntimeTextRole := rtrStaticText;
            Entry.RuntimeWiringConfirmed := SameText(
              JsonValueText(EntryObject, 'runtimeWiringConfirmed',
                BoolToStr(Entry.RuntimeApplication = rakAutomatic, True)),
              'true');
            Result.Entries.Add(Entry);
          end;
      if Result.SchemaVersion < 6 then
        Result.SchemaVersion := 6;
    except
      Result.Free;
      raise;
    end;
  finally
    Root.Free;
  end;
end;

class function TCatalogJson.LoadFromFile(
  const AFileName: string): TTranslationCatalog;
begin
  if not TFile.Exists(AFileName) then
    raise ECatalogJsonError.CreateFmt('Catalog file not found: %s',
      [AFileName]);
  Result := Deserialize(TFile.ReadAllText(AFileName, TEncoding.UTF8));
end;

class procedure TCatalogJson.SaveToFile(const ACatalog: TTranslationCatalog;
  const AFileName: string);
var
  DirectoryName: string;
begin
  DirectoryName := TPath.GetDirectoryName(AFileName);
  if DirectoryName <> '' then
    TDirectory.CreateDirectory(DirectoryName);
  TFile.WriteAllText(AFileName, Serialize(ACatalog), TEncoding.UTF8);
end;

class function TCatalogCsv.EscapeField(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""',
    [rfReplaceAll]) + '"';
end;

class function TCatalogCsv.ParseRows(const AText: string):
  TObjectList<TStringList>;
var
  CharacterIndex: Integer;
  CurrentCharacter: Char;
  Field: TStringBuilder;
  InQuotes: Boolean;
  Row: TStringList;

  procedure FinishField;
  begin
    Row.Add(Field.ToString);
    Field.Clear;
  end;

  procedure FinishRow;
  begin
    FinishField;
    Result.Add(Row);
    Row := TStringList.Create;
  end;

begin
  Result := TObjectList<TStringList>.Create(True);
  Field := TStringBuilder.Create;
  Row := TStringList.Create;
  try
    InQuotes := False;
    CharacterIndex := 1;
    while CharacterIndex <= Length(AText) do
    begin
      CurrentCharacter := AText[CharacterIndex];
      if InQuotes then
      begin
        if CurrentCharacter = '"' then
        begin
          if (CharacterIndex < Length(AText)) and
             (AText[CharacterIndex + 1] = '"') then
          begin
            Field.Append('"');
            Inc(CharacterIndex);
          end
          else
            InQuotes := False;
        end
        else
          Field.Append(CurrentCharacter);
      end
      else
      begin
        case CurrentCharacter of
          '"':
            if Field.Length = 0 then
              InQuotes := True
            else
              raise ECatalogCsvError.CreateFmt(
                'Unexpected quote at character %d.', [CharacterIndex]);
          ',':
            FinishField;
          #13, #10:
            begin
              FinishRow;
              if (CurrentCharacter = #13) and
                 (CharacterIndex < Length(AText)) and
                 (AText[CharacterIndex + 1] = #10) then
                Inc(CharacterIndex);
            end;
        else
          Field.Append(CurrentCharacter);
        end;
      end;
      Inc(CharacterIndex);
    end;
    if InQuotes then
      raise ECatalogCsvError.Create('The CSV ends inside a quoted field.');
    if (Field.Length > 0) or (Row.Count > 0) then
      FinishRow;
    Row.Free;
    Row := nil;
  except
    Row.Free;
    Result.Free;
    Field.Free;
    raise;
  end;
  Field.Free;
end;

class procedure TCatalogCsv.ExportToFile(
  const ACatalog: TTranslationCatalog; const AFileName: string);
const
  Header: array[0..7] of string = (
    'Key', 'SourceText', 'Translation', 'Status', 'Context',
    'SourceChecksum', 'RuntimeApplication', 'RuntimeTextRole');
var
  ColumnIndex: Integer;
  DirectoryName: string;
  Entry: TTranslationEntry;
  Output: TStringBuilder;

  procedure AddRow(const AValues: array of string);
  var
    ValueIndex: Integer;
  begin
    for ValueIndex := 0 to High(AValues) do
    begin
      if ValueIndex > 0 then
        Output.Append(',');
      Output.Append(EscapeField(AValues[ValueIndex]));
    end;
    Output.AppendLine;
  end;

begin
  if ACatalog = nil then
    raise ECatalogCsvError.Create('A catalog is required.');
  Output := TStringBuilder.Create;
  try
    for ColumnIndex := Low(Header) to High(Header) do
    begin
      if ColumnIndex > 0 then
        Output.Append(',');
      Output.Append(EscapeField(Header[ColumnIndex]));
    end;
    Output.AppendLine;
    for Entry in ACatalog.Entries do
      AddRow([Entry.Key, Entry.SourceText, Entry.TranslatedText,
        TranslationStatusToString(Entry.Status), Entry.DeveloperNote,
        Entry.SourceChecksum,
        RuntimeApplicationKindToString(Entry.RuntimeApplication),
        RuntimeTextRoleToString(Entry.RuntimeTextRole)]);
    DirectoryName := TPath.GetDirectoryName(AFileName);
    if DirectoryName <> '' then
      TDirectory.CreateDirectory(DirectoryName);
    TFile.WriteAllText(AFileName, Output.ToString, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

class function TCatalogCsv.AnalyzeImport(
  const ACatalog: TTranslationCatalog;
  const AFileName: string): TCatalogCsvImportPlan;
const
  ExpectedHeader: array[0..7] of string = (
    'Key', 'SourceText', 'Translation', 'Status', 'Context',
    'SourceChecksum', 'RuntimeApplication', 'RuntimeTextRole');
var
  Change: TCatalogCsvImportChange;
  ColumnIndex: Integer;
  Entry: TTranslationEntry;
  ImportedKeys: TStringList;
  Row: TStringList;
  RowIndex: Integer;
  Rows: TObjectList<TStringList>;
  SourceText: string;
  SourceChecksum: string;
  TranslatedText: string;
begin
  if ACatalog = nil then
    raise ECatalogCsvError.Create('A catalog is required.');
  if not TFile.Exists(AFileName) then
    raise ECatalogCsvError.CreateFmt('CSV file not found: %s',
      [AFileName]);

  Rows := ParseRows(TFile.ReadAllText(AFileName, TEncoding.UTF8));
  ImportedKeys := TStringList.Create;
  Result := TCatalogCsvImportPlan.Create;
  try
    try
      ImportedKeys.CaseSensitive := False;
      ImportedKeys.Sorted := True;
      if Rows.Count = 0 then
        raise ECatalogCsvError.Create('The CSV file is empty.');
      if Rows[0].Count <> Length(ExpectedHeader) then
        raise ECatalogCsvError.CreateFmt(
          'The CSV header must contain %d columns.',
          [Length(ExpectedHeader)]);
      for ColumnIndex := Low(ExpectedHeader) to High(ExpectedHeader) do
        if not SameText(Rows[0][ColumnIndex],
          ExpectedHeader[ColumnIndex]) then
          raise ECatalogCsvError.CreateFmt(
            'Unexpected CSV column %d. Expected "%s".',
            [ColumnIndex + 1, ExpectedHeader[ColumnIndex]]);

      for RowIndex := 1 to Rows.Count - 1 do
      begin
        Row := Rows[RowIndex];
        if (Row.Count = 1) and (Row[0] = '') then
          Continue;
        Inc(Result.FRowsRead);
        if Row.Count <> Length(ExpectedHeader) then
          raise ECatalogCsvError.CreateFmt(
            'CSV row %d contains %d columns; expected %d.',
            [RowIndex + 1, Row.Count, Length(ExpectedHeader)]);
        if ImportedKeys.IndexOf(Row[0]) >= 0 then
        begin
          Inc(Result.FDuplicateCount);
          Result.Issues.Add(Format('Row %d: duplicate key %s',
            [RowIndex + 1, Row[0]]));
          Continue;
        end;
        ImportedKeys.Add(Row[0]);
        Entry := ACatalog.FindEntry(Row[0]);
        if Entry = nil then
        begin
          Inc(Result.FUnknownCount);
          Result.Issues.Add(Format('Row %d: unknown key %s',
            [RowIndex + 1, Row[0]]));
          Continue;
        end;
        SourceText := Row[1];
        TranslatedText := Row[2];
        SourceChecksum := Row[5];
        if (SourceText <> Entry.SourceText) or
           not SameText(SourceChecksum, Entry.SourceChecksum) or
           not SameText(Row[6], RuntimeApplicationKindToString(
             Entry.RuntimeApplication)) or
           not SameText(Row[7], RuntimeTextRoleToString(
             Entry.RuntimeTextRole)) then
        begin
          Inc(Result.FStaleCount);
          Result.Issues.Add(Format(
            'Row %d: protected source or runtime metadata is stale for %s',
            [RowIndex + 1, Row[0]]));
          Continue;
        end;
        if Entry.Status in [tsReviewed, tsApproved] then
        begin
          Inc(Result.FProtectedCount);
          Result.Issues.Add(Format(
            'Row %d: reviewed/approved entry protected for %s',
            [RowIndex + 1, Row[0]]));
          Continue;
        end;
        if (TranslatedText = '') or
           (TranslatedText = Entry.TranslatedText) then
        begin
          Inc(Result.FUnchangedCount);
          Continue;
        end;
        Change := TCatalogCsvImportChange.Create;
        Change.Entry := Entry;
        Change.TranslatedText := TranslatedText;
        Result.Changes.Add(Change);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    ImportedKeys.Free;
    Rows.Free;
  end;
end;

end.
