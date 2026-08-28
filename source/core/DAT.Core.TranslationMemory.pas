unit DAT.Core.TranslationMemory;

{ What has already been translated, remembered across applications.

  The shared dictionaries hold approved *terms*: a word or a short phrase with
  an agreed rendering. That is terminology, and it is not the same thing as a
  translation memory. A memory holds whole segments - the actual strings an
  application showed - with what they were translated to, so that the second
  application saying "Are you sure you want to delete this item?" does not pay
  to have it translated again, and does not risk getting a different wording
  than the first one got.

  This is the largest functional gap this product had against the commercial
  tools, and the one that most obstructs a customer bringing existing work in.

  Where it lives, beside the dictionaries, for the same reason:

    %PUBLIC%\Documents\Delphi App Translation\Memory

  One file per language. Every unit is readable and writable by every account
  on the machine without elevation, which is what "shared" has to mean.

  Matching is deliberately conservative, and the distinction matters:

    - An **exact** match is the same string, character for character. It is
      applied automatically.
    - A **normalized** match differs only in leading and trailing space, in
      internal runs of whitespace, or in letter case. That is the same segment
      written slightly differently, so it is also applied automatically, and
      the answer carries the source's own capitalization pattern.
    - A **similar** match is anything else close enough to be worth a human
      look. It is never applied. It is offered as a suggestion, with its
      score, because a memory that quietly substitutes an almost-right
      sentence is worse than one that says nothing: nobody reviews what they
      were not told about.

  Only reviewed or approved translations are remembered. Machine output is not
  contributed, because a memory that fills up with unreviewed guesses stops
  being an asset and becomes a way to spread one bad translation across every
  application a developer owns. }

interface

uses
  System.Generics.Collections,
  DAT.Core.Types;

type
  TMemoryMatchKind = (mmkNone, mmkExact, mmkNormalized, mmkSimilar);

  TTranslationMemoryUnit = class
  private
    FSourceText: string;
    FTranslatedText: string;
    FApplicationId: string;
    FRecordedOn: string;
  public
    property SourceText: string read FSourceText write FSourceText;
    property TranslatedText: string read FTranslatedText
      write FTranslatedText;
    { Which application first contributed it. Kept so that a reviewer can see
      where a remembered wording came from. }
    property ApplicationId: string read FApplicationId write FApplicationId;
    { ISO date, as text, so the file stays readable and diffable. }
    property RecordedOn: string read FRecordedOn write FRecordedOn;
  end;

  TMemoryMatch = record
    Kind: TMemoryMatchKind;
    TranslatedText: string;
    SourceText: string;
    ApplicationId: string;
    { 100 for exact and normalized; below that for a similar match. }
    Score: Integer;
    function Applies: Boolean;
  end;

  TTranslationMemory = class
  private
    FLanguageCode: string;
    FUnits: TObjectList<TTranslationMemoryUnit>;
    FIndex: TDictionary<string, Integer>;
    procedure Reindex;
    function IndexOfSource(const ASourceText: string): Integer;
  public
    constructor Create(const ALanguageCode: string);
    destructor Destroy; override;

    class function Directory: string; static;
    class function FileName(const ALanguageCode: string): string; static;
    { Never nil. A language nobody has contributed to yet loads empty, so the
      first use of a language behaves like every later one. }
    class function Load(const ALanguageCode: string): TTranslationMemory;
      static;
    procedure Save;

    { The best match for this string, or a match of kind mmkNone. Only
      Applies-kind matches may be used without a human looking. }
    function Lookup(const ASourceText: string;
      const AMinimumSimilarity: Integer = 75): TMemoryMatch;

    { Records one segment. A source already present is left alone rather than
      overwritten: what an earlier project settled is not silently rewritten by
      a later one, which is the same rule the shared dictionaries follow. }
    function Remember(const ASourceText, ATranslatedText, AApplicationId,
      ARecordedOn: string): Boolean;

    { Contributes every reviewed or approved entry of a catalog. Answers how
      many were new. Machine output is deliberately skipped. }
    function RememberCatalog(const ACatalog: TTranslationCatalog;
      const ARecordedOn: string): Integer;

    { Fills in every untranslated entry the memory can answer exactly, and
      answers how many. Called before anything is sent, so a segment already
      settled in another application is neither paid for again nor given a
      second, different wording. Only applicable matches are used; a similar
      one is left for a human. }
    function ApplyToCatalog(const ACatalog: TTranslationCatalog): Integer;

    property LanguageCode: string read FLanguageCode write FLanguageCode;
    property Units: TObjectList<TTranslationMemoryUnit> read FUnits;
  end;

{ Exposed for the interchange unit and for testing. Collapses whitespace runs
  to one space and trims the ends; case is handled separately so that the
  answer can be given the source's own capitalization. }
function NormalizeSegment(const AText: string): string;

{ How alike two segments are, 0 to 100. Token-based rather than
  character-based, because a translator cares that the same words are present
  far more than that the same letters are. }
function SegmentSimilarity(const ALeft, ARight: string): Integer;

implementation

uses
  System.Character,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.AtomicFile,
  DAT.Core.Diagnostics;

procedure ValidateMemoryText(const AText: string);
var
  Item: TJSONValue;
  JsonValue: TJSONValue;
  Root: TJSONObject;
  Units: TJSONArray;
begin
  JsonValue := TJSONObject.ParseJSONValue(AText);
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    raise EConvertError.Create('The translation memory is not valid JSON.');
  end;
  Root := TJSONObject(JsonValue);
  try
    Units := Root.GetValue('units') as TJSONArray;
    if Units = nil then
      raise EConvertError.Create(
        'The translation memory is missing its units array.');
    for Item in Units do
      if not (Item is TJSONObject) then
        raise EConvertError.Create(
          'The translation memory contains an invalid unit.');
  finally
    Root.Free;
  end;
end;

function TMemoryMatch.Applies: Boolean;
begin
  Result := Kind in [mmkExact, mmkNormalized];
end;

function NormalizeSegment(const AText: string): string;
var
  Builder: TStringBuilder;
  Character: Char;
  PendingSpace: Boolean;
begin
  Builder := TStringBuilder.Create;
  try
    PendingSpace := False;
    for Character in AText do
    begin
      if Character.IsWhiteSpace then
      begin
        PendingSpace := Builder.Length > 0;
        Continue;
      end;
      if PendingSpace then
      begin
        Builder.Append(' ');
        PendingSpace := False;
      end;
      Builder.Append(Character);
    end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

{ The words of a segment, lower case, punctuation set aside. }
function SegmentTokens(const AText: string): TArray<string>;
var
  Builder: TStringBuilder;
  Character: Char;
  Tokens: TStringList;
begin
  Tokens := TStringList.Create;
  Builder := TStringBuilder.Create;
  try
    for Character in AText.ToLower do
    begin
      if Character.IsLetterOrDigit then
        Builder.Append(Character)
      else if Builder.Length > 0 then
      begin
        Tokens.Add(Builder.ToString);
        Builder.Clear;
      end;
    end;
    if Builder.Length > 0 then
      Tokens.Add(Builder.ToString);
    Result := Tokens.ToStringArray;
  finally
    Builder.Free;
    Tokens.Free;
  end;
end;

function SegmentSimilarity(const ALeft, ARight: string): Integer;
var
  LeftTokens, RightTokens: TArray<string>;
  Used: TArray<Boolean>;
  Shared: Integer;
  Total: Integer;
  I, J: Integer;
begin
  LeftTokens := SegmentTokens(ALeft);
  RightTokens := SegmentTokens(ARight);
  if (Length(LeftTokens) = 0) or (Length(RightTokens) = 0) then
    Exit(0);

  SetLength(Used, Length(RightTokens));
  Shared := 0;
  for I := 0 to High(LeftTokens) do
    for J := 0 to High(RightTokens) do
      if not Used[J] and SameText(LeftTokens[I], RightTokens[J]) then
      begin
        Used[J] := True;
        Inc(Shared);
        Break;
      end;

  { Measured against the longer of the two, so that a short segment matching
    part of a long one does not score as a near-perfect match. }
  Total := Length(LeftTokens);
  if Length(RightTokens) > Total then
    Total := Length(RightTokens);
  Result := Round(Shared * 100 / Total);
end;

{ Carries the source's capitalization onto a remembered answer, for the case
  where the two differ only in case. Whole-word decisions only: anything more
  clever would be guessing at a language's own rules. }
function LikeSourceCase(const ASource, AAnswer: string): string;
var
  Character: Char;
  HasLetter, AllUpper, AllLower: Boolean;
begin
  Result := AAnswer;
  HasLetter := False;
  AllUpper := True;
  AllLower := True;
  for Character in ASource do
    if Character.IsLetter then
    begin
      HasLetter := True;
      if Character.IsUpper then
        AllLower := False
      else
        AllUpper := False;
    end;
  if not HasLetter then
    Exit;
  if AllUpper then
    Result := AAnswer.ToUpper
  else if AllLower then
    Result := AAnswer.ToLower;
end;

constructor TTranslationMemory.Create(const ALanguageCode: string);
begin
  inherited Create;
  FLanguageCode := ALanguageCode;
  FUnits := TObjectList<TTranslationMemoryUnit>.Create(True);
  FIndex := TDictionary<string, Integer>.Create;
end;

destructor TTranslationMemory.Destroy;
begin
  FIndex.Free;
  FUnits.Free;
  inherited Destroy;
end;

class function TTranslationMemory.Directory: string;
var
  PublicRoot: string;
begin
  PublicRoot := GetEnvironmentVariable('PUBLIC');
  if PublicRoot = '' then
    PublicRoot := TPath.Combine(TPath.GetHomePath, 'Public');
  Result := TPath.Combine(TPath.Combine(PublicRoot, 'Documents'),
    TPath.Combine('Delphi App Translation', 'Memory'));
end;

class function TTranslationMemory.FileName(
  const ALanguageCode: string): string;
var
  Safe: string;
  Character: Char;
begin
  Safe := '';
  for Character in ALanguageCode do
    if Character.IsLetterOrDigit or (Character = '-') or (Character = '_') then
      Safe := Safe + Character;
  if Safe = '' then
    Safe := 'unknown';
  Result := TPath.Combine(Directory, Safe + '.memory.json');
end;

procedure TTranslationMemory.Reindex;
var
  Index: Integer;
  Key: string;
begin
  FIndex.Clear;
  for Index := 0 to FUnits.Count - 1 do
  begin
    Key := NormalizeSegment(FUnits[Index].SourceText).ToLower;
    if not FIndex.ContainsKey(Key) then
      FIndex.Add(Key, Index);
  end;
end;

function TTranslationMemory.IndexOfSource(const ASourceText: string): Integer;
begin
  if not FIndex.TryGetValue(NormalizeSegment(ASourceText).ToLower, Result) then
    Result := -1;
end;

class function TTranslationMemory.Load(
  const ALanguageCode: string): TTranslationMemory;
var
  Memory: TTranslationMemory;
  Path: string;
  Root: TJSONObject;
  Items: TJSONArray;
  Item: TJSONValue;
  Entry: TTranslationMemoryUnit;
  JsonText: string;
  Recovered: Boolean;
begin
  Memory := TTranslationMemory.Create(ALanguageCode);
  try
    Path := FileName(ALanguageCode);
    if not TFile.Exists(Path) then
      Exit(Memory);
    JsonText := TAtomicTextFile.ReadAllText(Path, TEncoding.UTF8,
      ValidateMemoryText, Recovered);
    if Recovered then
      TDATDiagnostics.Log('DAT-MEMORY-RECOVERY-001', 'Load',
        'Recovered the prior valid translation memory and quarantined the invalid file: ' +
        Path, dsWarning);
    Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
    if Root = nil then
      Exit(Memory);
    try
      Memory.LanguageCode := Root.GetValue<string>('languageCode',
        ALanguageCode);
      Items := Root.GetValue('units') as TJSONArray;
      if Items <> nil then
        for Item in Items do
        begin
          Entry := TTranslationMemoryUnit.Create;
          Entry.SourceText := (Item as TJSONObject).GetValue<string>(
            'sourceText', '');
          Entry.TranslatedText := (Item as TJSONObject).GetValue<string>(
            'translatedText', '');
          Entry.ApplicationId := (Item as TJSONObject).GetValue<string>(
            'applicationId', '');
          Entry.RecordedOn := (Item as TJSONObject).GetValue<string>(
            'recordedOn', '');
          if (Entry.SourceText <> '') and (Entry.TranslatedText <> '') then
            Memory.Units.Add(Entry)
          else
            Entry.Free;
        end;
    finally
      Root.Free;
    end;
    Memory.Reindex;
    Result := Memory;
  except
    on E: Exception do
    begin
      TDATDiagnostics.LogException('DAT-MEMORY-READ-001',
        'Load(' + Path + ')', E);
    { A memory that cannot be read is an empty memory, not a failed run. The
      worst it costs is translating something again. }
      Result := Memory;
    end;
  end;
end;

procedure TTranslationMemory.Save;
var
  Root: TJSONObject;
  Items: TJSONArray;
  Item: TJSONObject;
  Entry: TTranslationMemoryUnit;
begin
  TDirectory.CreateDirectory(Directory);
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', TJSONNumber.Create(1));
    Root.AddPair('languageCode', FLanguageCode);
    Items := TJSONArray.Create;
    for Entry in FUnits do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('sourceText', Entry.SourceText);
      Item.AddPair('translatedText', Entry.TranslatedText);
      Item.AddPair('applicationId', Entry.ApplicationId);
      Item.AddPair('recordedOn', Entry.RecordedOn);
      Items.AddElement(Item);
    end;
    Root.AddPair('units', Items);
    TAtomicTextFile.WriteAllText(FileName(FLanguageCode), Root.Format(2),
      TEncoding.UTF8, ValidateMemoryText);
  finally
    Root.Free;
  end;
end;

function TTranslationMemory.Lookup(const ASourceText: string;
  const AMinimumSimilarity: Integer): TMemoryMatch;
var
  Entry: TTranslationMemoryUnit;
  At: Integer;
  Score: Integer;
  Best: Integer;
begin
  Result := Default(TMemoryMatch);
  Result.Kind := mmkNone;
  Result.Score := 0;
  if Trim(ASourceText) = '' then
    Exit;

  At := IndexOfSource(ASourceText);
  if At >= 0 then
  begin
    Entry := FUnits[At];
    Result.SourceText := Entry.SourceText;
    Result.ApplicationId := Entry.ApplicationId;
    Result.Score := 100;
    if Entry.SourceText = ASourceText then
    begin
      Result.Kind := mmkExact;
      Result.TranslatedText := Entry.TranslatedText;
    end
    else
    begin
      Result.Kind := mmkNormalized;
      Result.TranslatedText := LikeSourceCase(ASourceText,
        Entry.TranslatedText);
    end;
    Exit;
  end;

  { Nothing identical. Offer the closest thing worth a human look, and never
    more than that. }
  Best := 0;
  for Entry in FUnits do
  begin
    Score := SegmentSimilarity(ASourceText, Entry.SourceText);
    if Score > Best then
    begin
      Best := Score;
      Result.SourceText := Entry.SourceText;
      Result.TranslatedText := Entry.TranslatedText;
      Result.ApplicationId := Entry.ApplicationId;
    end;
  end;
  if (Best >= AMinimumSimilarity) and (Best < 100) then
  begin
    Result.Kind := mmkSimilar;
    Result.Score := Best;
  end
  else
  begin
    Result := Default(TMemoryMatch);
    Result.Kind := mmkNone;
  end;
end;

function TTranslationMemory.Remember(const ASourceText, ATranslatedText,
  AApplicationId, ARecordedOn: string): Boolean;
var
  Entry: TTranslationMemoryUnit;
begin
  Result := False;
  if (Trim(ASourceText) = '') or (Trim(ATranslatedText) = '') then
    Exit;
  if IndexOfSource(ASourceText) >= 0 then
    Exit;
  Entry := TTranslationMemoryUnit.Create;
  Entry.SourceText := ASourceText;
  Entry.TranslatedText := ATranslatedText;
  Entry.ApplicationId := AApplicationId;
  Entry.RecordedOn := ARecordedOn;
  FUnits.Add(Entry);
  FIndex.AddOrSetValue(NormalizeSegment(ASourceText).ToLower, FUnits.Count - 1);
  Result := True;
end;

function TTranslationMemory.ApplyToCatalog(
  const ACatalog: TTranslationCatalog): Integer;
var
  Entry: TTranslationEntry;
  Match: TMemoryMatch;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  for Entry in ACatalog.Entries do
  begin
    { Anything a person has already dealt with is left alone. The memory
      fills gaps; it does not overrule a decision made in this project. }
    if Trim(Entry.TranslatedText) <> '' then
      Continue;
    if not (Entry.Status in [tsNeedsTranslation, tsSourceChanged]) then
      Continue;
    Match := Lookup(Entry.SourceText);
    if not Match.Applies then
      Continue;
    Entry.TranslatedText := Match.TranslatedText;
    { Imported, not machine translated: it came from work somebody already
      reviewed, and the status should say where it came from. }
    Entry.Status := tsImported;
    Inc(Result);
  end;
end;

function TTranslationMemory.RememberCatalog(
  const ACatalog: TTranslationCatalog; const ARecordedOn: string): Integer;
var
  Entry: TTranslationEntry;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  for Entry in ACatalog.Entries do
  begin
    { Machine output is not contributed. A memory full of unreviewed guesses
      spreads one bad translation across every application its owner writes. }
    if not (Entry.Status in [tsReviewed, tsApproved, tsEdited]) then
      Continue;
    if Remember(Entry.SourceText, Entry.TranslatedText,
      ACatalog.ApplicationId, ARecordedOn) then
      Inc(Result);
  end;
end;

end.
