unit DAT.Core.SharedDictionary;

{ One dictionary per language, shared by every application.

  Until this existed, each project kept its own glossary in its own private
  folder, so translating a second application started from nothing even when it
  said the same things as the first. "Close", "Save", "Play Time", "Enable
  logging" had to be approved again for every project, and nothing stopped the
  same English word being rendered two different ways in two applications from
  the same author.

  The dictionaries live where anything can reach them:

    %PUBLIC%\Documents\Delphi App Translation\Dictionaries

  Public Documents is readable and writable by every account on the machine
  without elevation, which is what "shared" has to mean in practice. One file
  per language - es.dictionary.json, fr.dictionary.json - rather than one file
  holding every language, because a single combined file grows slow to load and
  invites two applications to write it at the same moment.

  The rules are deliberately plain:

    - Reading, the shared dictionary is applied first and the project glossary
      second, so a project always has the last word on its own wording.
    - Writing, only approved terms are contributed upward, and a term already
      in the shared dictionary is left alone. Approving something once in one
      project makes it available everywhere afterwards; nothing a later project
      does silently rewrites what an earlier one settled. }

interface

uses
  DAT.Core.Types,
  DAT.Core.Glossary;

type
  TSharedDictionary = class
  private
    class function SafeFilePart(const AValue: string): string; static;
    class function SameTerm(const ALeft, ARight: TProjectGlossaryTerm): Boolean;
      static;
  public
    { Where the shared dictionaries live. Created on demand. }
    class function Directory: string; static;
    class function FileName(const ALanguageCode: string): string; static;
    { The shared dictionary for a language. Never nil: a language nobody has
      contributed to yet returns an empty dictionary rather than failing, so
      first use of a new language behaves like every later use. }
    class function Load(const ALanguageCode: string): TProjectGlossary; static;
    { Approved terms from a project glossary, added to the shared dictionary.
      Returns how many were new. }
    class function Contribute(const ALanguageCode: string;
      const AGlossary: TProjectGlossary): Integer; static;
    { Fills in what the shared dictionary already knows. Call before applying
      the project glossary so the project's own wording wins. }
    class function ApplyToCatalog(const ALanguageCode: string;
      const ACatalog: TTranslationCatalog): Integer; static;
    class function TermCount(const ALanguageCode: string): Integer; static;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils;

class function TSharedDictionary.SafeFilePart(const AValue: string): string;
var
  CharacterIndex: Integer;
begin
  Result := Trim(AValue);
  for CharacterIndex := 1 to Length(Result) do
    if not CharInSet(Result[CharacterIndex],
      ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
      Result[CharacterIndex] := '_';
  if Result = '' then
    Result := 'language';
end;

class function TSharedDictionary.Directory: string;
var
  PublicRoot: string;
begin
  PublicRoot := GetEnvironmentVariable('PUBLIC');
  if PublicRoot = '' then
    PublicRoot := TPath.Combine(TPath.GetHomePath, 'Public');
  Result := TPath.Combine(TPath.Combine(PublicRoot, 'Documents'),
    TPath.Combine('Delphi App Translation', 'Dictionaries'));
end;

class function TSharedDictionary.FileName(
  const ALanguageCode: string): string;
begin
  Result := TPath.Combine(Directory,
    SafeFilePart(ALanguageCode) + '.dictionary.json');
end;

class function TSharedDictionary.Load(
  const ALanguageCode: string): TProjectGlossary;
begin
  Result := TProjectGlossary.LoadFromFile(FileName(ALanguageCode));
  if Result = nil then
    Result := TProjectGlossary.Create;
  { A shared dictionary belongs to a language, not to any one application. }
  Result.ApplicationId := 'Shared';
  Result.TargetLanguage := ALanguageCode;
  Result.OriginNote := 'Applied from the shared language dictionary.';
end;

{ Two terms are the same when they say the same thing in the same setting. The
  context matters: "Close" on a button and "Close" in a menu can legitimately
  differ in languages that inflect them differently. }
class function TSharedDictionary.SameTerm(const ALeft,
  ARight: TProjectGlossaryTerm): Boolean;
begin
  Result := SameText(Trim(ALeft.SourceText), Trim(ARight.SourceText)) and
    SameText(Trim(ALeft.ContextKind), Trim(ARight.ContextKind));
end;

class function TSharedDictionary.Contribute(const ALanguageCode: string;
  const AGlossary: TProjectGlossary): Integer;
var
  Shared: TProjectGlossary;
  Candidate: TProjectGlossaryTerm;
  Existing: TProjectGlossaryTerm;
  Addition: TProjectGlossaryTerm;
  Known: Boolean;
begin
  Result := 0;
  if AGlossary = nil then
    Exit;
  Shared := Load(ALanguageCode);
  try
    for Candidate in AGlossary.Terms do
    begin
      { Only settled wording travels. A draft that happens to be sitting in one
        project's glossary should not become the answer everywhere. }
      if not Candidate.Approved then
        Continue;
      if Trim(Candidate.SourceText) = '' then
        Continue;
      if Trim(Candidate.TargetText) = '' then
        Continue;

      Known := False;
      for Existing in Shared.Terms do
        if SameTerm(Existing, Candidate) then
        begin
          Known := True;
          Break;
        end;
      if Known then
        Continue;

      Addition := TProjectGlossaryTerm.Create;
      Addition.SourceText := Candidate.SourceText;
      Addition.TargetText := Candidate.TargetText;
      Addition.SemanticConcept := Candidate.SemanticConcept;
      Addition.ContextKind := Candidate.ContextKind;
      Addition.DeveloperNote := Candidate.DeveloperNote;
      Addition.CaseSensitive := Candidate.CaseSensitive;
      Addition.Approved := True;
      Shared.Terms.Add(Addition);
      Inc(Result);
    end;

    if Result > 0 then
    begin
      if not TDirectory.Exists(Directory) then
        TDirectory.CreateDirectory(Directory);
      Shared.SaveToFile(FileName(ALanguageCode));
    end;
  finally
    Shared.Free;
  end;
end;

class function TSharedDictionary.ApplyToCatalog(const ALanguageCode: string;
  const ACatalog: TTranslationCatalog): Integer;
var
  Shared: TProjectGlossary;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  Shared := Load(ALanguageCode);
  try
    Result := Shared.ApplyToCatalog(ACatalog);
  finally
    Shared.Free;
  end;
end;

class function TSharedDictionary.TermCount(
  const ALanguageCode: string): Integer;
var
  Shared: TProjectGlossary;
begin
  Shared := Load(ALanguageCode);
  try
    Result := Shared.Terms.Count;
  finally
    Shared.Free;
  end;
end;

end.
