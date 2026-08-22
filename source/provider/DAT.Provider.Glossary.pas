unit DAT.Provider.Glossary;

{ Terminology enforced by the service rather than suggested to it.

  This product already sends terminology two ways: it substitutes approved
  terms itself before a request, and it describes a string's meaning in the
  context field. Both work, and neither binds the service. A glossary held on
  the service's own side does: for the language pairs it supports, DeepL
  applies the glossary during translation, so a term comes back the way it was
  agreed rather than the way the engine would otherwise have rendered it.

  What belongs in one is narrower than what belongs in a project glossary, and
  the filtering here is the substance of this unit:

    - Both sides must be present and neither may be only punctuation.
    - Only approved terms. An unapproved suggestion is a guess, and a guess
      enforced on every future translation is worse than a guess offered once.
    - No format specifiers. A glossary entry is matched as text; a %s inside
      one invites the service to move or duplicate it, which is exactly the
      damage the placeholder protection exists to prevent.
    - No newlines or tabs, because the wire format is tab-separated lines and
      an entry carrying either would break the entry after it rather than
      itself - the worst kind of failure to diagnose.
    - Source terms are unique. DeepL rejects a glossary with a duplicated
      source, and the whole upload fails rather than the one entry.

  A term that fails any of those is not an error. It stays in the project
  glossary and is still applied locally by the terminology resolver, which was
  the only mechanism before this one existed.

  **What is here, and what is not.** This unit decides what may be sent. It
  contains no HTTP at all: nothing here creates, replaces, or deletes a
  glossary on the service, and nothing calls it. TTranslationProviderClient
  has a GlossaryId property and sends glossary_id with a DeepL request when it
  is set - but nothing in the product sets it yet, so today that property is
  always empty and every request goes without a glossary.

  The two ends are therefore built and not joined. Finishing it needs a POST
  to /v2/glossaries carrying the tab-separated form below, somewhere to keep
  the identifier it returns, a DELETE when the terms change, and a caller in
  the Studio that sets GlossaryId from it. That work is deliberately not done
  here rather than half-done: it cannot be exercised without a paid key, and
  network code that has never once run is a liability rather than a feature.

  What this unit does do is the part most likely to be wrong, and it is
  covered by ProviderGlossarySmokeTests. }

interface

uses
  System.Generics.Collections,
  DAT.Core.Glossary;

type
  TGlossaryEntry = record
    SourceTerm: string;
    TargetTerm: string;
  end;

  TProviderGlossary = record
  public
    { The terms from AGlossary that may safely be enforced by a service, in the
      order they appear, with duplicates by source term removed. }
    class function Eligible(const AGlossary: TProjectGlossary)
      : TArray<TGlossaryEntry>; static;

    { The tab-separated form DeepL expects: one entry per line, source, tab,
      target. Answers an empty string when there is nothing eligible, which the
      caller should treat as "do not create a glossary" rather than as an
      empty one. }
    class function ToTabSeparated(const AEntries: TArray<TGlossaryEntry>)
      : string; static;

    { Whether DeepL supports a glossary for this pair at all. The list is
      short, it is theirs rather than ours, and asking for an unsupported pair
      is rejected - so it is worth knowing before the request is made rather
      than after. }
    class function SupportsPair(const ASourceLanguage,
      ATargetLanguage: string): Boolean; static;
  end;

implementation

uses
  System.Character,
  System.Classes,
  System.StrUtils,
  System.SysUtils;

const
  { DeepL's documented glossary language pairs, as two-letter codes. Kept as a
    flat list of "from>to" because that is how it reads and how it is checked. }
  SupportedPairs: array [0 .. 23] of string = (
    'de>en', 'en>de', 'de>fr', 'fr>de', 'en>fr', 'fr>en',
    'en>es', 'es>en', 'de>es', 'es>de', 'es>fr', 'fr>es',
    'en>it', 'it>en', 'en>nl', 'nl>en', 'en>pl', 'pl>en',
    'en>pt', 'pt>en', 'en>ja', 'ja>en', 'en>ru', 'ru>en');

{ The language without its region: a catalog says de-DE and a glossary pair is
  named de. }
function PrimaryLanguage(const ACode: string): string;
var
  Code: string;
begin
  Code := Trim(ACode).ToLower;
  if Pos('-', Code) > 0 then
    Code := Copy(Code, 1, Pos('-', Code) - 1);
  if Pos('_', Code) > 0 then
    Code := Copy(Code, 1, Pos('_', Code) - 1);
  Result := Code;
end;

class function TProviderGlossary.SupportsPair(const ASourceLanguage,
  ATargetLanguage: string): Boolean;
var
  Pair: string;
  Candidate: string;
begin
  Pair := PrimaryLanguage(ASourceLanguage) + '>' +
    PrimaryLanguage(ATargetLanguage);
  for Candidate in SupportedPairs do
    if SameText(Pair, Candidate) then
      Exit(True);
  Result := False;
end;

{ Whether a term can be sent. The reasons are in the unit comment; each test
  here answers one of them. }
function IsSendable(const ASourceTerm, ATargetTerm: string): Boolean;
var
  Character: Char;
  HasLetterOrDigit: Boolean;
begin
  Result := False;
  if (Trim(ASourceTerm) = '') or (Trim(ATargetTerm) = '') then
    Exit;

  { A tab or a newline would break the entry after this one rather than this
    one, which is the worst kind of failure to find. }
  for Character in ASourceTerm + ATargetTerm do
    if (Character = #9) or (Character = #10) or (Character = #13) then
      Exit;

  { A format specifier matched as glossary text invites the engine to move or
    duplicate it. }
  if (Pos('%', ASourceTerm) > 0) or (Pos('%', ATargetTerm) > 0) then
    Exit;

  { Something with no letters and no digits is punctuation, and enforcing
    punctuation as terminology is meaningless. }
  HasLetterOrDigit := False;
  for Character in ASourceTerm do
    if Character.IsLetterOrDigit then
    begin
      HasLetterOrDigit := True;
      Break;
    end;
  if not HasLetterOrDigit then
    Exit;

  Result := True;
end;

class function TProviderGlossary.Eligible(const AGlossary: TProjectGlossary)
  : TArray<TGlossaryEntry>;
var
  Term: TProjectGlossaryTerm;
  Seen: TDictionary<string, Boolean>;
  Entries: TList<TGlossaryEntry>;
  Entry: TGlossaryEntry;
  Key: string;
begin
  SetLength(Result, 0);
  if AGlossary = nil then
    Exit;

  Entries := TList<TGlossaryEntry>.Create;
  Seen := TDictionary<string, Boolean>.Create;
  try
    for Term in AGlossary.Terms do
    begin
      { An unapproved suggestion is a guess. A guess offered once is useful; a
        guess enforced on every future translation is not. }
      if not Term.Approved then
        Continue;
      if not IsSendable(Term.SourceText, Term.TargetText) then
        Continue;
      { DeepL rejects the whole upload for one duplicated source term, so the
        first wins and the rest are dropped here rather than there. }
      Key := Trim(Term.SourceText).ToLower;
      if Seen.ContainsKey(Key) then
        Continue;
      Seen.Add(Key, True);
      Entry.SourceTerm := Trim(Term.SourceText);
      Entry.TargetTerm := Trim(Term.TargetText);
      Entries.Add(Entry);
    end;
    Result := Entries.ToArray;
  finally
    Seen.Free;
    Entries.Free;
  end;
end;

class function TProviderGlossary.ToTabSeparated(
  const AEntries: TArray<TGlossaryEntry>): string;
var
  Lines: TStringBuilder;
  Entry: TGlossaryEntry;
begin
  Result := '';
  if Length(AEntries) = 0 then
    Exit;
  Lines := TStringBuilder.Create;
  try
    for Entry in AEntries do
    begin
      if Lines.Length > 0 then
        Lines.Append(#10);
      Lines.Append(Entry.SourceTerm);
      Lines.Append(#9);
      Lines.Append(Entry.TargetTerm);
    end;
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;

end.
