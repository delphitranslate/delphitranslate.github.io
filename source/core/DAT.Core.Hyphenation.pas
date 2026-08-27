unit DAT.Core.Hyphenation;

{ Where a long word may be broken, one companion dictionary per language.

  German builds one word where English uses three, and a single word cannot be
  wrapped: there is no space in Benachrichtigungseinstellungen to break at. A
  column heading or a caption either gets wider or gets cut off - unless the
  word itself may be broken, which is what a reader of that language expects
  anyway. Every German newspaper does it.

  The break is marked with a soft hyphen, and that is the whole reason this is
  safe to do generously. A soft hyphen is invisible: the text renderer shows
  nothing at all unless the line actually has to break at that point, and then
  it draws a hyphen. Marking every plausible break in a long word therefore
  costs nothing where the word fits and rescues it where it does not.

  Each language gets its own dictionary file, installed beside the shared
  terminology dictionaries and editable by hand:

    C:\Users\Public\Documents\Delphi App Translation\Hyphenation\de-DE.json

  A dictionary says which letters are vowels in that language, which consonant
  pairs must never be split, how much of the word must be left whole at each
  end, and any words whose breaks are known outright. Those are the parts that
  differ between languages; the algorithm below is the same for all of them,
  and is the classical one: break between vowels and following consonants,
  split a run of consonants, and never so near an end that a stray letter is
  left stranded on a line of its own. }

interface

uses
  System.Generics.Collections;

type
  TDATHyphenationDictionary = class
  private
    FLanguageCode: string;
    FVowels: string;
    FInseparable: TList<string>;
    FMinimumPrefix: Integer;
    FMinimumSuffix: Integer;
    FMinimumWordLength: Integer;
    FExceptions: TDictionary<string, string>;
  public
    constructor Create(const ALanguageCode: string);
    destructor Destroy; override;
    { The word with a soft hyphen at every point it may be broken. }
    function Hyphenate(const AWord: string): string;
    { Every word in the text, long enough to be worth marking, marked. }
    function HyphenateText(const AText: string): string;
    property LanguageCode: string read FLanguageCode;
    property Vowels: string read FVowels write FVowels;
    property Inseparable: TList<string> read FInseparable;
    property MinimumPrefix: Integer read FMinimumPrefix write FMinimumPrefix;
    property MinimumSuffix: Integer read FMinimumSuffix write FMinimumSuffix;
    property MinimumWordLength: Integer read FMinimumWordLength
      write FMinimumWordLength;
    property Exceptions: TDictionary<string, string> read FExceptions;
  end;

  TDATHyphenation = class
  public
    { Where the dictionaries live. }
    class function Directory: string; static;
    class function FileName(const ALanguageCode: string): string; static;
    { Writes the companion dictionary for a language if it is not there yet,
      and answers whether one exists afterwards. Called when a language is
      added, so that adding a language installs its hyphenation with it. }
    class function EnsureInstalled(const ALanguageCode: string): Boolean;
      static;
    { The dictionary for a language, loaded from its file, or nil where no
      dictionary is installed and none can be written. }
    class function Load(const ALanguageCode: string):
      TDATHyphenationDictionary; static;
  end;

{ The soft hyphen itself: shown only when a break happens there. }
const
  SoftHyphen = #$00AD;

implementation

uses
  System.Character,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  DAT.Core.AtomicFile;

{ ---------------------------------------------------------------------------
  What differs between languages, and nothing else.

  These are the starting dictionaries written out when a language is first
  added. They are deliberately conservative: a break that is merely allowed is
  invisible unless it is used, but a break in the wrong place is visible and
  wrong, so where the rule is uncertain no break is offered.
  --------------------------------------------------------------------------- }

function BuiltInDictionaryJson(const ALanguageCode: string): string;
var
  BaseCode: string;
begin
  BaseCode := LowerCase(Copy(ALanguageCode, 1, 2));

  if BaseCode = 'de' then
    { German splits a run of consonants and keeps its digraphs whole. ch, sch,
      ck, ph, th and st are single sounds and a break inside one is wrong. }
    Exit('{' +
      '"languageCode": "' + ALanguageCode + '",' +
      '"vowels": "aeiouy\u00E4\u00F6\u00FCAEIOUY\u00C4\u00D6\u00DC",' +
      '"inseparable": ["sch", "ch", "ck", "ph", "th", "sh", "st", "qu",' +
        ' "bl", "br", "dr", "fl", "fr", "gl", "gr", "kl", "kr", "pl", "pr",' +
        ' "tr", "zw"],' +
      '"minimumPrefix": 2,' +
      '"minimumSuffix": 3,' +
      '"minimumWordLength": 10,' +
      '"exceptions": {}' +
      '}');

  if BaseCode = 'es' then
    { Spanish syllables are regular, which is why its rules are shorter: a
      single consonant between vowels begins the next syllable, a pair is
      split unless it is one of the inseparable pairs, and ch, ll and rr are
      single letters in the language's own reckoning. }
    Exit('{' +
      '"languageCode": "' + ALanguageCode + '",' +
      '"vowels": "aeiou\u00E1\u00E9\u00ED\u00F3\u00FA\u00FCAEIOU\u00C1\u00C9\u00CD\u00D3\u00DA\u00DC",' +
      '"inseparable": ["ch", "ll", "rr", "bl", "br", "cl", "cr", "dr",' +
        ' "fl", "fr", "gl", "gr", "pl", "pr", "tr", "qu"],' +
      '"minimumPrefix": 2,' +
      '"minimumSuffix": 2,' +
      '"minimumWordLength": 9,' +
      '"exceptions": {}' +
      '}');

  if BaseCode = 'fr' then
    Exit('{' +
      '"languageCode": "' + ALanguageCode + '",' +
      '"vowels": "aeiouy\u00E0\u00E2\u00E9\u00E8\u00EA\u00EB\u00EE\u00EF\u00F4\u00F9\u00FB\u00FCAEIOUY",' +
      '"inseparable": ["ch", "ph", "th", "gn", "bl", "br", "cl", "cr",' +
        ' "dr", "fl", "fr", "gl", "gr", "pl", "pr", "tr", "vr", "qu"],' +
      '"minimumPrefix": 2,' +
      '"minimumSuffix": 3,' +
      '"minimumWordLength": 10,' +
      '"exceptions": {}' +
      '}');

  { Everything else starts from the same shape and can be tuned by hand. The
    file is written so that a translator or developer can correct it without
    touching the program. }
  Result := '{' +
    '"languageCode": "' + ALanguageCode + '",' +
    '"vowels": "aeiouyAEIOUY",' +
    '"inseparable": ["ch", "sh", "th", "ph", "bl", "br", "cl", "cr", "dr",' +
      ' "fl", "fr", "gl", "gr", "pl", "pr", "tr", "qu"],' +
    '"minimumPrefix": 3,' +
    '"minimumSuffix": 3,' +
    '"minimumWordLength": 12,' +
    '"exceptions": {}' +
    '}';
end;

{ --------------------------------------------------------------- dictionary }

constructor TDATHyphenationDictionary.Create(const ALanguageCode: string);
begin
  inherited Create;
  FLanguageCode := ALanguageCode;
  FVowels := 'aeiouyAEIOUY';
  FInseparable := TList<string>.Create;
  FMinimumPrefix := 3;
  FMinimumSuffix := 3;
  FMinimumWordLength := 12;
  FExceptions := TDictionary<string, string>.Create;
end;

destructor TDATHyphenationDictionary.Destroy;
begin
  FExceptions.Free;
  FInseparable.Free;
  inherited Destroy;
end;

function TDATHyphenationDictionary.Hyphenate(const AWord: string): string;
var
  Bare: string;
  Index: Integer;
  Known: string;
  Marks: TArray<Boolean>;

  function IsVowel(const APosition: Integer): Boolean;
  begin
    Result := (APosition >= 1) and (APosition <= Length(Bare)) and
      (Pos(Bare[APosition], FVowels) > 0);
  end;

  { True when breaking before this position would cut a pair that the language
    treats as one sound. }
  function CutsAPair(const APosition: Integer): Boolean;
  var
    Pair: string;
  begin
    Result := False;
    for Pair in FInseparable do
    begin
      if Length(Pair) < 2 then
        Continue;
      if (APosition - 1 >= 1) and (APosition - 1 + Length(Pair) - 1 <=
        Length(Bare)) then
        if SameText(Copy(Bare, APosition - 1, Length(Pair)), Pair) then
          Exit(True);
      { A break immediately before the pair is fine; one inside it is not, so
        every position the pair covers except its first is refused. }
      if (APosition - 2 >= 1) and (Length(Pair) >= 3) and
        (APosition - 2 + Length(Pair) - 1 <= Length(Bare)) then
        if SameText(Copy(Bare, APosition - 2, Length(Pair)), Pair) then
          Exit(True);
    end;
  end;

begin
  Result := AWord;
  Bare := AWord;
  if Length(Bare) < FMinimumWordLength then
    Exit;
  { A word already carrying its own hyphen, or a soft one, is left alone. }
  if (Pos('-', Bare) > 0) or (Pos(SoftHyphen, Bare) > 0) then
    Exit;

  if FExceptions.TryGetValue(LowerCase(Bare), Known) then
    Exit(Known);

  SetLength(Marks, Length(Bare) + 1);

  { The classical rule. A break may fall before a consonant that is followed
    by a vowel, when a vowel stands before it: that is the boundary between
    one syllable and the next. Two consonants between vowels are split
    between them. }
  for Index := FMinimumPrefix + 1 to Length(Bare) - FMinimumSuffix do
  begin
    if IsVowel(Index) then
      Continue;                       { a break before a vowel reads badly }
    if not IsVowel(Index - 1) and not IsVowel(Index + 1) then
      Continue;                       { middle of a consonant run }
    if IsVowel(Index - 1) and not IsVowel(Index + 1) then
    begin
      { Vowel, then two consonants: break between the consonants instead. }
      if IsVowel(Index + 2) and not CutsAPair(Index + 1) then
        Marks[Index + 1] := True;
      Continue;
    end;
    if CutsAPair(Index) then
      Continue;
    Marks[Index] := True;
  end;

  Result := '';
  for Index := 1 to Length(Bare) do
  begin
    if Marks[Index] then
      Result := Result + SoftHyphen;
    Result := Result + Bare[Index];
  end;
end;

function TDATHyphenationDictionary.HyphenateText(const AText: string): string;
var
  Builder: TStringBuilder;
  Index: Integer;
  Word: string;

  function IsWordCharacter(const ACharacter: Char): Boolean;
  begin
    Result := ACharacter.IsLetter;
  end;

begin
  if Trim(AText) = '' then
    Exit(AText);
  Builder := TStringBuilder.Create;
  try
    Word := '';
    for Index := 1 to Length(AText) do
    begin
      if IsWordCharacter(AText[Index]) then
        Word := Word + AText[Index]
      else
      begin
        if Word <> '' then
        begin
          Builder.Append(Hyphenate(Word));
          Word := '';
        end;
        Builder.Append(AText[Index]);
      end;
    end;
    if Word <> '' then
      Builder.Append(Hyphenate(Word));
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

{ ------------------------------------------------------------------ storage }

class function TDATHyphenation.Directory: string;
var
  PublicRoot: string;
begin
  PublicRoot := GetEnvironmentVariable('PUBLIC');
  if PublicRoot = '' then
    PublicRoot := TPath.Combine(TPath.GetHomePath, 'Public');
  Result := TPath.Combine(TPath.Combine(PublicRoot, 'Documents'),
    TPath.Combine('Delphi App Translation', 'Hyphenation'));
end;

class function TDATHyphenation.FileName(const ALanguageCode: string): string;
var
  SafeName: string;
  Index: Integer;
begin
  SafeName := Trim(ALanguageCode);
  for Index := 1 to Length(SafeName) do
    if not CharInSet(SafeName[Index],
      ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      SafeName[Index] := '_';
  if SafeName = '' then
    SafeName := 'language';
  Result := TPath.Combine(Directory, SafeName + '.json');
end;

class function TDATHyphenation.EnsureInstalled(
  const ALanguageCode: string): Boolean;
var
  Target: string;
begin
  Target := FileName(ALanguageCode);
  Result := TFile.Exists(Target);
  if Result then
    Exit;
  try
    if not TDirectory.Exists(Directory) then
      TDirectory.CreateDirectory(Directory);
    TAtomicTextFile.WriteAllText(Target, BuiltInDictionaryJson(ALanguageCode),
      TEncoding.UTF8);
    Result := True;
  except
    { A dictionary that cannot be written is not a reason to fail a
      translation: the words simply do not get their breaks. }
    Result := False;
  end;
end;

class function TDATHyphenation.Load(
  const ALanguageCode: string): TDATHyphenationDictionary;
var
  ArrayValue: TJSONValue;
  ExceptionPair: TJSONPair;
  ExceptionsObject: TJSONObject;
  InseparableArray: TJSONArray;
  JsonValue: TJSONValue;
  Root: TJSONObject;
  Target: string;
begin
  Result := nil;
  Target := FileName(ALanguageCode);
  if not TFile.Exists(Target) then
    if not EnsureInstalled(ALanguageCode) then
      Exit;
  if not TFile.Exists(Target) then
    Exit;

  JsonValue := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(Target, TEncoding.UTF8));
  if not (JsonValue is TJSONObject) then
  begin
    JsonValue.Free;
    Exit;
  end;
  Root := TJSONObject(JsonValue);
  try
    Result := TDATHyphenationDictionary.Create(ALanguageCode);
    Result.Vowels := Root.GetValue<string>('vowels', Result.Vowels);
    Result.MinimumPrefix := Root.GetValue<Integer>('minimumPrefix',
      Result.MinimumPrefix);
    Result.MinimumSuffix := Root.GetValue<Integer>('minimumSuffix',
      Result.MinimumSuffix);
    Result.MinimumWordLength := Root.GetValue<Integer>('minimumWordLength',
      Result.MinimumWordLength);

    InseparableArray := Root.GetValue('inseparable') as TJSONArray;
    if InseparableArray <> nil then
      for ArrayValue in InseparableArray do
        if Trim(ArrayValue.Value) <> '' then
          Result.Inseparable.Add(LowerCase(Trim(ArrayValue.Value)));

    ExceptionsObject := Root.GetValue('exceptions') as TJSONObject;
    if ExceptionsObject <> nil then
      for ExceptionPair in ExceptionsObject do
        Result.Exceptions.AddOrSetValue(
          LowerCase(ExceptionPair.JsonString.Value),
          ExceptionPair.JsonValue.Value);
  finally
    Root.Free;
  end;
end;

end.
