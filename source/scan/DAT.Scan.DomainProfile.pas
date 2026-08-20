unit DAT.Scan.DomainProfile;

{ What an application is about, worked out from the application itself.

  The first attempt at this recognised six subjects - music, scheduling,
  business records, clinical records, email, backups - by looking for keywords.
  It read Carillon correctly and would have failed almost everything else. A
  file utility, a CAD package, a laboratory system, a point of sale, a database
  administration tool: none of them are on that list, and no list anyone writes
  will hold them all. A recogniser can only ever recognise what somebody
  already thought of, which is the opposite of what this was supposed to do.

  So nothing is recognised here. The application is read.

  Two things come out of the reading. The first is the vocabulary the
  application actually uses, once the words every program uses - File, Edit,
  Cancel, Save - are set aside. What remains is what this program is about, in
  its own words, and it works as well for a file renamer (rename, mask,
  extension, prefix) as for Carillon (song, playlist, chime, bell).

  The second matters more. Most mistranslations are not domain mistakes, they
  are word-sense mistakes: one English word that means two things, and the
  translator picking the wrong one. "Play Date From" became Spielverabredungen -
  an afternoon arranged between children - because "play" and "date" were both
  read in their social sense. Spanish "Close" became cerca, meaning nearby,
  rather than cerrar, to shut. And "Volume" is loudness in Carillon but a disk
  in a file utility, so no single answer to it is right.

  A word's sense is settled by the company it keeps. That is the whole idea
  here: a shared list says which English words are ambiguous in a user
  interface and what each sense is, each sense carries the words that would be
  present if it were the one meant, and the application's own vocabulary casts
  the vote. Nothing needs to know what kind of application it is.

  The list lives beside the shared terminology and hyphenation dictionaries and
  is editable by hand:

    C:\Users\Public\Documents\Delphi App Translation\Terms\ambiguous-terms.json

  It is about English, the source language, so there is one of it rather than
  one per target language. }

interface

uses
  System.Generics.Collections,
  DAT.Scan.Types;

type
  { One ambiguous word, the sense this application means, and the word of its
    own that settled it. The evidence is carried so that a decision can be
    explained rather than merely trusted. }
  TResolvedTerm = record
    Term: string;
    Sense: string;
    Evidence: string;
  end;

  TApplicationDomainProfile = class
  private
    FApplicationName: string;
    FVocabulary: TList<string>;
    FTerms: TList<TResolvedTerm>;
  public
    constructor Create;
    destructor Destroy; override;
    { The sense this application means by a word, where the word is one of the
      ambiguous ones and its sense was settled. }
    function SenseOf(const ATerm: string; out ASense: string): Boolean;
    { Any ambiguous word appearing in a given piece of text, with its sense,
      ready to be added to what the translator is told. }
    function SensesWithin(const AText: string): string;
    { The application described by its own commonest words. Empty where there
      were too few strings to be worth saying anything about. }
    function VocabularySentence: string;
    property ApplicationName: string read FApplicationName
      write FApplicationName;
    property Vocabulary: TList<string> read FVocabulary;
    property Terms: TList<TResolvedTerm> read FTerms;
  end;

  TDomainProfiler = class
  public
    { Where the shared ambiguous-term list lives. }
    class function Directory: string; static;
    class function FileName: string; static;
    { Writes the list if it is not there yet, and answers whether one exists
      afterwards. }
    class function EnsureInstalled: Boolean; static;
    { Reads an application and returns its profile. Never nil. }
    class function Profile(const AResult: TProjectScanResult;
      const AApplicationName: string): TApplicationDomainProfile; static;
  end;

implementation

uses
  System.Character,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.SysUtils;

const
  { How many of the application's own words are worth quoting. Enough to place
    the application, few enough to stay a sentence. }
  VocabularySize = 10;
  { Below this there is not enough of an application to describe. }
  MinimumVocabularyWords = 3;

{ ---------------------------------------------------------------------------
  Words that say nothing about what an application does.

  Every program has a File menu, a Cancel button and an OK button. Those words
  are the furniture of a user interface, present whatever the program is for,
  and leaving them in would describe every application ever written as being
  about files, options and closing things. Taking them out is what makes the
  remainder characteristic.
  --------------------------------------------------------------------------- }

function IsCommonWord(const AWord: string): Boolean;
const
  Ordinary: array[0..117] of string = (
    { grammar }
    'the', 'and', 'for', 'with', 'from', 'this', 'that', 'these', 'those',
    'you', 'your', 'not', 'are', 'was', 'were', 'has', 'have', 'had', 'will',
    'can', 'may', 'must', 'should', 'would', 'been', 'into', 'onto', 'out',
    'off', 'all', 'any', 'each', 'per', 'its', 'their', 'them', 'they', 'but',
    'nor', 'yet', 'via', 'here', 'there', 'when', 'then', 'than', 'only',
    'also', 'such', 'both', 'more', 'most', 'some', 'none', 'one', 'two',
    { the furniture of every user interface }
    'file', 'edit', 'view', 'help', 'tools', 'window', 'menu', 'options',
    'settings', 'preferences', 'about', 'exit', 'quit', 'close', 'open',
    'save', 'cancel', 'apply', 'reset', 'default', 'defaults', 'new', 'add',
    'remove', 'delete', 'clear', 'copy', 'paste', 'cut', 'undo', 'redo',
    'find', 'search', 'select', 'browse', 'refresh', 'update', 'print',
    'preview', 'back', 'next', 'previous', 'finish', 'done', 'yes', 'error',
    'warning', 'information', 'message', 'name', 'value', 'list', 'item',
    'items', 'show', 'hide', 'enable', 'disable', 'enabled', 'disabled',
    'start', 'stop');
var
  Ordinary_: string;
begin
  if Length(AWord) < 3 then
    Exit(True);
  for Ordinary_ in Ordinary do
    if SameText(AWord, Ordinary_) then
      Exit(True);
  Result := False;
end;

{ ---------------------------------------------------------------------------
  The shared list of words that are ambiguous in a user interface.

  Each sense carries the words that would be present in an application that
  meant it. They are deliberately words a program would show, not words a
  dictionary would use: an application that means loudness by "volume" says
  mute and speaker somewhere, and one that means a disk says partition and
  format.

  Where a word has one sense only, it is here because getting it wrong is
  common - "close" read as an adjective is a mistake in every language that
  distinguishes them, and no amount of context in the application will hint
  at it.
  --------------------------------------------------------------------------- }

function BuiltInTermsJson: string;
begin
  Result :=
    '{' +
    '"terms": [' +

    '{"term": "play", "senses": [' +
      '{"sense": "to play a sound recording, never a game and never a ' +
        'theatre play", "evidence": ["song", "music", "audio", "sound", ' +
        '"track", "chime", "bell", "playlist", "mp3", "wav", "recording", ' +
        '"speaker", "tune"]},' +
      '{"sense": "to play a game", "evidence": ["game", "player", "score", ' +
        '"level", "board", "dice", "card"]},' +
      '{"sense": "to play back a video", "evidence": ["video", "movie", ' +
        '"frame", "clip", "camera"]}]},' +

    '{"term": "date", "senses": [' +
      '{"sense": "a calendar date", "evidence": ["calendar", "schedule", ' +
        '"month", "year", "day", "week", "time", "expiry", "due", ' +
        '"start", "end"]}]},' +

    '{"term": "volume", "senses": [' +
      '{"sense": "the loudness of sound", "evidence": ["sound", "audio", ' +
        '"mute", "speaker", "song", "music", "decibel", "playback"]},' +
      '{"sense": "a disk or storage volume", "evidence": ["disk", "drive", ' +
        '"partition", "mount", "format", "sector", "filesystem", ' +
        '"capacity"]}]},' +

    '{"term": "record", "senses": [' +
      '{"sense": "a stored row of data", "evidence": ["database", "table", ' +
        '"field", "row", "query", "index", "customer", "invoice"]},' +
      '{"sense": "to capture sound or video", "evidence": ["microphone", ' +
        '"audio", "camera", "capture", "input", "level"]}]},' +

    '{"term": "close", "senses": [' +
      '{"sense": "the action of shutting a window, not the adjective ' +
        'meaning nearby", "evidence": []}]},' +

    '{"term": "monitor", "senses": [' +
      '{"sense": "a display screen", "evidence": ["display", "screen", ' +
        '"resolution", "pixel", "graphics"]},' +
      '{"sense": "to watch something continuously", "evidence": ["alert", ' +
        '"threshold", "sensor", "alarm", "status", "temperature", ' +
        '"log"]}]},' +

    '{"term": "key", "senses": [' +
      '{"sense": "a key on the keyboard", "evidence": ["keyboard", ' +
        '"shortcut", "press", "hotkey"]},' +
      '{"sense": "the key that identifies a row of data", "evidence": ' +
        '["database", "table", "index", "primary", "foreign", "field"]},' +
      '{"sense": "a licence or access key", "evidence": ["licence", ' +
        '"license", "registration", "activation", "serial", "api"]}]},' +

    '{"term": "mask", "senses": [' +
      '{"sense": "a pattern that filenames are matched against", ' +
        '"evidence": ["filename", "wildcard", "extension", "folder", ' +
        '"directory", "pattern", "rename"]},' +
      '{"sense": "a pattern that limits what may be typed", "evidence": ' +
        '["input", "edit", "format", "digits"]}]},' +

    '{"term": "port", "senses": [' +
      '{"sense": "a network port number", "evidence": ["network", "host", ' +
        '"server", "tcp", "socket", "address", "connection"]},' +
      '{"sense": "a serial or hardware port", "evidence": ["serial", ' +
        '"baud", "device", "usb", "modem", "printer"]}]},' +

    '{"term": "host", "senses": [' +
      '{"sense": "a computer on a network", "evidence": ["network", ' +
        '"server", "port", "address", "connection", "ping", "domain"]}]},' +

    '{"term": "address", "senses": [' +
      '{"sense": "a network address", "evidence": ["network", "server", ' +
        '"port", "host", "protocol", "gateway"]},' +
      '{"sense": "a postal address", "evidence": ["street", "city", ' +
        '"postcode", "customer", "delivery", "country"]}]},' +

    '{"term": "field", "senses": [' +
      '{"sense": "a data field on a form or in a table", "evidence": ' +
        '["database", "table", "record", "form", "column", "query"]}]},' +

    '{"term": "table", "senses": [' +
      '{"sense": "a table of data", "evidence": ["database", "record", ' +
        '"field", "query", "index", "column", "row"]}]},' +

    '{"term": "scale", "senses": [' +
      '{"sense": "to change the size of something", "evidence": ["zoom", ' +
        '"resize", "image", "width", "height", "resolution"]},' +
      '{"sense": "a weighing scale", "evidence": ["weight", "mass", ' +
        '"gram", "kilogram", "pound", "tare"]}]},' +

    '{"term": "current", "senses": [' +
      '{"sense": "the one in use at the moment", "evidence": ["selected", ' +
        '"active", "position", "page", "user", "session"]},' +
      '{"sense": "electrical current", "evidence": ["voltage", "amp", ' +
        '"circuit", "power", "resistance", "meter"]}]},' +

    '{"term": "run", "senses": [' +
      '{"sense": "to execute something", "evidence": ["execute", ' +
        '"command", "script", "process", "batch", "job", "report"]}]},' +

    '{"term": "load", "senses": [' +
      '{"sense": "to read something in", "evidence": ["file", "import", ' +
        '"read", "open", "data"]},' +
      '{"sense": "how heavily something is being used", "evidence": ' +
        '["cpu", "memory", "server", "performance", "capacity"]}]},' +

    '{"term": "free", "senses": [' +
      '{"sense": "unused space or capacity", "evidence": ["disk", ' +
        '"space", "memory", "drive", "capacity", "used"]},' +
      '{"sense": "at no cost", "evidence": ["price", "trial", ' +
        '"licence", "purchase", "upgrade"]}]},' +

    '{"term": "left", "senses": [' +
      '{"sense": "the direction, not the past tense of leave", ' +
        '"evidence": ["right", "align", "margin", "position", ' +
        '"top"]}]},' +

    '{"term": "second", "senses": [' +
      '{"sense": "the unit of time", "evidence": ["minute", "hour", ' +
        '"delay", "interval", "timeout", "elapsed"]},' +
      '{"sense": "the one after the first", "evidence": ["first", ' +
        '"third", "step", "page"]}]},' +

    '{"term": "share", "senses": [' +
      '{"sense": "a shared folder on a network", "evidence": ["network", ' +
        '"folder", "server", "path", "mapped", "drive"]}]},' +

    '{"term": "driver", "senses": [' +
      '{"sense": "a piece of software that operates a device", ' +
        '"evidence": ["device", "printer", "install", "hardware", ' +
        '"version", "odbc"]},' +
      '{"sense": "a person who drives", "evidence": ["vehicle", ' +
        '"route", "delivery", "fleet", "licence"]}]},' +

    '{"term": "case", "senses": [' +
      '{"sense": "whether letters are capital or small", "evidence": ' +
        '["upper", "lower", "letter", "sensitive", "text", "rename"]},' +
      '{"sense": "a matter being handled", "evidence": ["client", ' +
        '"matter", "court", "patient", "claim", "file"]}]},' +

    '{"term": "match", "senses": [' +
      '{"sense": "to correspond to a pattern", "evidence": ["pattern", ' +
        '"search", "filter", "wildcard", "expression", "found"]}]},' +

    '{"term": "state", "senses": [' +
      '{"sense": "the condition something is in", "evidence": ["status", ' +
        '"active", "idle", "running", "changed", "saved"]},' +
      '{"sense": "a region of a country", "evidence": ["city", ' +
        '"postcode", "country", "province", "address"]}]}' +

    ']}';
end;

{ ------------------------------------------------------------------ profile }

constructor TApplicationDomainProfile.Create;
begin
  inherited Create;
  FVocabulary := TList<string>.Create;
  FTerms := TList<TResolvedTerm>.Create;
end;

destructor TApplicationDomainProfile.Destroy;
begin
  FTerms.Free;
  FVocabulary.Free;
  inherited Destroy;
end;

function TApplicationDomainProfile.SenseOf(const ATerm: string;
  out ASense: string): Boolean;
var
  Resolved: TResolvedTerm;
begin
  ASense := '';
  for Resolved in FTerms do
    if SameText(Resolved.Term, ATerm) then
    begin
      ASense := Resolved.Sense;
      Exit(True);
    end;
  Result := False;
end;

function TApplicationDomainProfile.SensesWithin(const AText: string): string;
var
  Resolved: TResolvedTerm;
  Lowered: string;
begin
  Result := '';
  Lowered := ' ' + LowerCase(AText) + ' ';
  for Resolved in FTerms do
    if ContainsText(Lowered, ' ' + LowerCase(Resolved.Term)) then
      Result := Result + Format(' Here "%s" means %s.',
        [Resolved.Term, Resolved.Sense]);
  Result := Trim(Result);
end;

function TApplicationDomainProfile.VocabularySentence: string;
var
  Index: Integer;
  Words: string;
begin
  Result := '';
  if FVocabulary.Count < MinimumVocabularyWords then
    Exit;
  Words := '';
  for Index := 0 to FVocabulary.Count - 1 do
  begin
    if Words <> '' then
      Words := Words + ', ';
    Words := Words + FVocabulary[Index];
  end;
  Result := Format('The words this application uses most are: %s.', [Words]);
end;

{ ----------------------------------------------------------------- profiler }

class function TDomainProfiler.Directory: string;
var
  PublicRoot: string;
begin
  PublicRoot := GetEnvironmentVariable('PUBLIC');
  if PublicRoot = '' then
    PublicRoot := TPath.Combine(TPath.GetHomePath, 'Public');
  Result := TPath.Combine(TPath.Combine(PublicRoot, 'Documents'),
    TPath.Combine('Delphi App Translation', 'Terms'));
end;

class function TDomainProfiler.FileName: string;
begin
  Result := TPath.Combine(Directory, 'ambiguous-terms.json');
end;

class function TDomainProfiler.EnsureInstalled: Boolean;
var
  Target: string;
begin
  Target := FileName;
  try
    if not TDirectory.Exists(Directory) then
      TDirectory.CreateDirectory(Directory);
    if not TFile.Exists(Target) then
      TFile.WriteAllText(Target, BuiltInTermsJson, TEncoding.UTF8);
    Result := TFile.Exists(Target);
  except
    Result := False;
  end;
end;

{ The application's own words, commonest first. }
function ReadVocabulary(const AResult: TProjectScanResult;
  out ACorpus: string): TList<string>;
var
  Counts: TDictionary<string, Integer>;
  Item: TScanItem;
  Pair: TPair<string, Integer>;
  Best: string;
  BestCount: Integer;
  Taken: TStringList;
  Word: string;
  Cleaned: string;
  Character: Char;
  Index: Integer;
begin
  Result := TList<string>.Create;
  ACorpus := '';
  Counts := TDictionary<string, Integer>.Create;
  Taken := TStringList.Create;
  try
    for Item in AResult.Items do
    begin
      { Punctuation and accelerator markers are not part of a word. }
      Cleaned := '';
      for Character in LowerCase(Item.SourceText) do
        if Character.IsLetter then
          Cleaned := Cleaned + Character
        else
          Cleaned := Cleaned + ' ';
      ACorpus := ACorpus + ' ' + Cleaned;
      for Word in Cleaned.Split([' '], TStringSplitOptions.ExcludeEmpty) do
      begin
        if IsCommonWord(Word) then
          Continue;
        if Counts.ContainsKey(Word) then
          Counts[Word] := Counts[Word] + 1
        else
          Counts.Add(Word, 1);
      end;
    end;

    { Commonest first. A word the application repeats is more characteristic
      than one it says once, and taking only the top handful keeps a stray out
      of the sentence without having to exclude single words outright - which
      would leave a small application described as nothing at all. }
    for Index := 1 to VocabularySize do
    begin
      Best := '';
      BestCount := 0;
      for Pair in Counts do
        if (Taken.IndexOf(Pair.Key) < 0) and
          ((Pair.Value > BestCount) or
           ((Pair.Value = BestCount) and
            ((Best = '') or (Pair.Key < Best)))) then
        begin
          Best := Pair.Key;
          BestCount := Pair.Value;
        end;
      if Best = '' then
        Break;
      Taken.Add(Best);
      Result.Add(Best);
    end;
  finally
    Taken.Free;
    Counts.Free;
  end;
end;

{ Which sense of an ambiguous word this application means, decided by how much
  of each sense's evidence the application actually says. }
function ResolveTerms(const ACorpus: string;
  const ATermsJson: string): TList<TResolvedTerm>;
var
  Root: TJSONObject;
  TermsArray: TJSONArray;
  TermValue: TJSONValue;
  TermObject: TJSONObject;
  SensesArray: TJSONArray;
  SenseValue: TJSONValue;
  SenseObject: TJSONObject;
  EvidenceArray: TJSONArray;
  EvidenceValue: TJSONValue;
  Term: string;
  Padded: string;
  BestSense: string;
  BestEvidence: string;
  BestScore: Integer;
  Score: Integer;
  FirstEvidence: string;
  Resolved: TResolvedTerm;
  Only: Boolean;
begin
  Result := TList<TResolvedTerm>.Create;
  Padded := ' ' + ACorpus + ' ';
  Root := TJSONObject.ParseJSONValue(ATermsJson) as TJSONObject;
  if Root = nil then
    Exit;
  try
    TermsArray := Root.GetValue('terms') as TJSONArray;
    if TermsArray = nil then
      Exit;
    for TermValue in TermsArray do
    begin
      TermObject := TermValue as TJSONObject;
      Term := TermObject.GetValue('term').Value;
      { A word the application never says needs no explaining. }
      if not ContainsText(Padded, ' ' + LowerCase(Term)) then
        Continue;
      SensesArray := TermObject.GetValue('senses') as TJSONArray;
      if (SensesArray = nil) or (SensesArray.Count = 0) then
        Continue;

      Only := SensesArray.Count = 1;
      BestSense := '';
      BestEvidence := '';
      BestScore := 0;
      for SenseValue in SensesArray do
      begin
        SenseObject := SenseValue as TJSONObject;
        Score := 0;
        FirstEvidence := '';
        EvidenceArray := SenseObject.GetValue('evidence') as TJSONArray;
        if EvidenceArray <> nil then
          for EvidenceValue in EvidenceArray do
            if ContainsText(Padded, ' ' + LowerCase(EvidenceValue.Value)) then
            begin
              Inc(Score);
              if FirstEvidence = '' then
                FirstEvidence := EvidenceValue.Value;
            end;
        if Score > BestScore then
        begin
          BestScore := Score;
          BestSense := SenseObject.GetValue('sense').Value;
          BestEvidence := FirstEvidence;
        end;
      end;

      { A word with one sense is stated whatever the application says, because
        it is here for being got wrong rather than for being ambiguous. A word
        with several is stated only where the application settles it: a guess
        between two senses is worse than saying nothing. }
      if Only and (BestSense = '') then
      begin
        BestSense := (SensesArray.Items[0] as TJSONObject)
          .GetValue('sense').Value;
        BestEvidence := '';
      end;
      if BestSense = '' then
        Continue;

      Resolved.Term := Term;
      Resolved.Sense := BestSense;
      Resolved.Evidence := BestEvidence;
      Result.Add(Resolved);
    end;
  finally
    Root.Free;
  end;
end;

class function TDomainProfiler.Profile(const AResult: TProjectScanResult;
  const AApplicationName: string): TApplicationDomainProfile;
var
  Corpus: string;
  Vocabulary: TList<string>;
  Resolved: TList<TResolvedTerm>;
  Term: TResolvedTerm;
  Word: string;
  TermsJson: string;
begin
  Result := TApplicationDomainProfile.Create;
  Result.ApplicationName := Trim(AApplicationName);
  if AResult = nil then
    Exit;

  Vocabulary := ReadVocabulary(AResult, Corpus);
  try
    for Word in Vocabulary do
      Result.Vocabulary.Add(Word);
  finally
    Vocabulary.Free;
  end;

  { The shared list if one is installed, the built-in one otherwise, so that a
    hand-edited list is honoured and a missing one is never fatal. }
  TermsJson := '';
  if EnsureInstalled then
    try
      TermsJson := TFile.ReadAllText(FileName, TEncoding.UTF8);
    except
      TermsJson := '';
    end;
  if Trim(TermsJson) = '' then
    TermsJson := BuiltInTermsJson;

  Resolved := ResolveTerms(Corpus, TermsJson);
  try
    for Term in Resolved do
      Result.Terms.Add(Term);
  finally
    Resolved.Free;
  end;
end;

end.
