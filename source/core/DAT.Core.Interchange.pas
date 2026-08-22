unit DAT.Core.Interchange;

{ Getting translation work in and out in the formats the industry already uses.

  A customer with existing localization work has it in TMX, and a customer with
  agreed terminology has it in TBX. Until this unit existed there was no way in
  and no way out: everything this product knew was locked in its own JSON, which
  is a fine format for reading and a poor argument for adopting a tool.

  Two standards, two different things, and they are routinely confused:

    - **TMX** carries a translation *memory*: whole segments, source paired with
      target. It maps onto DAT.Core.TranslationMemory.
    - **TBX** carries *terminology*: a concept with its term in each language.
      It maps onto the shared dictionaries and the project glossary.

  Both are XML. Both are written here by hand rather than through a document
  object model, because what is produced is a flat, regular structure and the
  escaping rules are the only subtle part. Reading is done with a small
  tag-scanning parser for the same reason: the shape being read is known, the
  files can be very large, and pulling a hundred thousand segments through a
  DOM to reach two attributes and two text nodes is a poor trade.

  What is deliberately not attempted: neither reader validates against the
  full standard, and neither preserves markup inside a segment. An element a
  segment carries inside it - a bold run, an inline placeholder tag - is
  flattened to its text. That is honest for this product, whose segments are
  control captions rather than documents, and it is written down here so the
  limit is known rather than discovered. }

interface

uses
  DAT.Core.Glossary,
  DAT.Core.TranslationMemory;

type
  TTmxInterchange = record
  public
    { Writes the whole memory as TMX 1.4b. Answers how many segments were
      written. }
    class function Export_(const AMemory: TTranslationMemory;
      const AFileName, ASourceLanguage: string): Integer; static;

    { Reads a TMX file into the memory, taking the variant whose language
      matches the memory's own. Answers how many segments were new; existing
      ones are left alone, following the same rule as everything else here. }
    class function Import_(const AMemory: TTranslationMemory;
      const AFileName, ASourceLanguage, AApplicationId,
      ARecordedOn: string): Integer; static;
  end;

  TTbxInterchange = record
  public
    { Writes a glossary as TBX-Basic. Answers how many terms were written. }
    class function Export_(const AGlossary: TProjectGlossary;
      const AFileName: string): Integer; static;

    { Reads TBX into a glossary, pairing the source-language term with the
      target-language term of the same concept. Answers how many were added. }
    class function Import_(const AGlossary: TProjectGlossary;
      const AFileName: string): Integer; static;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils;

{ ---------------------------------------------------------------------------
  Escaping, and the small scanner both readers share.
  --------------------------------------------------------------------------- }

function XmlEscape(const AText: string): string;
begin
  Result := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function XmlUnescape(const AText: string): string;
begin
  Result := StringReplace(AText, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  { Ampersand last, or an escaped ampersand in the file would be turned into
    a character that then re-reads as the start of another entity. }
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

{ The closing tag for this element and not for one whose name merely starts
  the same way. Searching for '</tu' finds '</tuv>' first, which truncates
  every translation unit at its first variant and imports nothing at all -
  the whole file reads as empty and no error is raised anywhere. }
function FindCloseTag(const AText, AName: string;
  const AFrom: Integer): Integer;
var
  At, After: Integer;
begin
  At := AFrom;
  repeat
    At := PosEx('</' + AName, AText, At);
    if At = 0 then
      Exit(0);
    After := At + Length(AName) + 2;
    if (After > Length(AText)) or
      CharInSet(AText[After], ['>', ' ', #9, #10, #13]) then
      Exit(At);
    Inc(At);
  until False;
end;

{ Everything between the first '>' of the opening tag and the matching closing
  tag, with any nested markup removed. AFrom is advanced past the element.
  Returns False when there is no further element of this name. }
function NextElement(const AText, AName: string; var AFrom: Integer;
  out ABody, AAttributes: string): Boolean;
var
  OpenAt, OpenEnd, CloseAt: Integer;
  Raw: string;
  Scan: Integer;
  InTag: Boolean;
begin
  Result := False;
  ABody := '';
  AAttributes := '';
  OpenAt := PosEx('<' + AName, AText, AFrom);
  if OpenAt = 0 then
    Exit;
  { Guard against matching a longer name that starts the same way. }
  Scan := OpenAt + Length(AName) + 1;
  if (Scan <= Length(AText)) and
    not CharInSet(AText[Scan], [' ', '>', '/', #9, #10, #13]) then
  begin
    AFrom := OpenAt + 1;
    Exit(NextElement(AText, AName, AFrom, ABody, AAttributes));
  end;

  OpenEnd := PosEx('>', AText, OpenAt);
  if OpenEnd = 0 then
    Exit;
  AAttributes := Copy(AText, OpenAt, OpenEnd - OpenAt + 1);

  { A self-closing element has no body. }
  if AText[OpenEnd - 1] = '/' then
  begin
    AFrom := OpenEnd + 1;
    Exit(True);
  end;

  CloseAt := FindCloseTag(AText, AName, OpenEnd);
  if CloseAt = 0 then
    Exit;
  Raw := Copy(AText, OpenEnd + 1, CloseAt - OpenEnd - 1);
  AFrom := PosEx('>', AText, CloseAt) + 1;

  { Flatten any markup the segment carries. Documented as a limit. }
  ABody := '';
  InTag := False;
  for Scan := 1 to Length(Raw) do
  begin
    if Raw[Scan] = '<' then
      InTag := True
    else if Raw[Scan] = '>' then
      InTag := False
    else if not InTag then
      ABody := ABody + Raw[Scan];
  end;
  ABody := XmlUnescape(ABody);
  Result := True;
end;

{ The same scan, answering the element's body untouched. A <tu> holds <tuv>
  elements that still have to be found inside it, and a flattened body has
  had exactly the markup that identifies them removed. }
function NextElementRaw(const AText, AName: string; var AFrom: Integer;
  out ABody, AAttributes: string): Boolean;
var
  OpenAt, OpenEnd, CloseAt, Scan: Integer;
begin
  Result := False;
  ABody := '';
  AAttributes := '';
  OpenAt := PosEx('<' + AName, AText, AFrom);
  if OpenAt = 0 then
    Exit;
  Scan := OpenAt + Length(AName) + 1;
  if (Scan <= Length(AText)) and
    not CharInSet(AText[Scan], [' ', '>', '/', #9, #10, #13]) then
  begin
    AFrom := OpenAt + 1;
    Exit(NextElementRaw(AText, AName, AFrom, ABody, AAttributes));
  end;
  OpenEnd := PosEx('>', AText, OpenAt);
  if OpenEnd = 0 then
    Exit;
  AAttributes := Copy(AText, OpenAt, OpenEnd - OpenAt + 1);
  if AText[OpenEnd - 1] = '/' then
  begin
    AFrom := OpenEnd + 1;
    Exit(True);
  end;
  CloseAt := FindCloseTag(AText, AName, OpenEnd);
  if CloseAt = 0 then
    Exit;
  ABody := Copy(AText, OpenEnd + 1, CloseAt - OpenEnd - 1);
  AFrom := PosEx('>', AText, CloseAt) + 1;
  Result := True;
end;

function AttributeValue(const AAttributes, AName: string): string;
var
  At, Quote, Stop: Integer;
begin
  Result := '';
  At := Pos(AName + '=', AAttributes);
  if At = 0 then
    Exit;
  Quote := At + Length(AName) + 1;
  if (Quote > Length(AAttributes)) or
    not CharInSet(AAttributes[Quote], ['"', '''']) then
    Exit;
  Stop := PosEx(AAttributes[Quote], AAttributes, Quote + 1);
  if Stop = 0 then
    Exit;
  Result := XmlUnescape(Copy(AAttributes, Quote + 1, Stop - Quote - 1));
end;

{ TMX and TBX both write a language on an attribute, and which attribute
  depends on the version that produced the file. Both spellings are accepted
  reading, and the current one is written. }
function LanguageOf(const AAttributes: string): string;
begin
  Result := AttributeValue(AAttributes, 'xml:lang');
  if Result = '' then
    Result := AttributeValue(AAttributes, 'lang');
end;

{ Whether two language tags name the same language. A file written for de-DE
  should still be usable by a catalog that says de, and the other way round. }
function SameLanguage(const ALeft, ARight: string): Boolean;
var
  Left, Right: string;
begin
  Left := Trim(ALeft);
  Right := Trim(ARight);
  if SameText(Left, Right) then
    Exit(True);
  if (Left = '') or (Right = '') then
    Exit(False);
  if Pos('-', Left) > 0 then
    Left := Copy(Left, 1, Pos('-', Left) - 1);
  if Pos('-', Right) > 0 then
    Right := Copy(Right, 1, Pos('-', Right) - 1);
  Result := SameText(Left, Right);
end;

{ ---------------------------------------------------------------------------
  TMX
  --------------------------------------------------------------------------- }

class function TTmxInterchange.Export_(const AMemory: TTranslationMemory;
  const AFileName, ASourceLanguage: string): Integer;
var
  Output: TStringList;
  Entry: TTranslationMemoryUnit;
begin
  Result := 0;
  if AMemory = nil then
    Exit;
  Output := TStringList.Create;
  try
    Output.Add('<?xml version="1.0" encoding="UTF-8"?>');
    Output.Add('<tmx version="1.4">');
    Output.Add('  <header creationtool="Delphi App Translation Studio"');
    Output.Add('          creationtoolversion="1.0" segtype="sentence"');
    Output.Add('          o-tmf="DAT" adminlang="en" datatype="plaintext"');
    Output.Add(Format('          srclang="%s">', [XmlEscape(ASourceLanguage)]));
    Output.Add('  </header>');
    Output.Add('  <body>');
    for Entry in AMemory.Units do
    begin
      Output.Add('    <tu>');
      if Entry.ApplicationId <> '' then
        Output.Add(Format('      <prop type="x-application">%s</prop>',
          [XmlEscape(Entry.ApplicationId)]));
      Output.Add(Format('      <tuv xml:lang="%s"><seg>%s</seg></tuv>',
        [XmlEscape(ASourceLanguage), XmlEscape(Entry.SourceText)]));
      Output.Add(Format('      <tuv xml:lang="%s"><seg>%s</seg></tuv>',
        [XmlEscape(AMemory.LanguageCode), XmlEscape(Entry.TranslatedText)]));
      Output.Add('    </tu>');
      Inc(Result);
    end;
    Output.Add('  </body>');
    Output.Add('</tmx>');
    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
    Output.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

class function TTmxInterchange.Import_(const AMemory: TTranslationMemory;
  const AFileName, ASourceLanguage, AApplicationId,
  ARecordedOn: string): Integer;
var
  Text_: string;
  UnitFrom: Integer;
  UnitRaw, UnitAttributes: string;
  VariantFrom: Integer;
  VariantBody, VariantAttributes: string;
  Language: string;
  SourceText, TargetText: string;
begin
  Result := 0;
  if (AMemory = nil) or not TFile.Exists(AFileName) then
    Exit;
  Text_ := TFile.ReadAllText(AFileName, TEncoding.UTF8);

  { One translation unit at a time, so that a variant can only ever pair with
    a variant of its own unit. Walking every <tuv> in the file instead would
    pair across a unit boundary the moment one unit lacked the target
    language, and silently attach the wrong translation to a source. }
  UnitFrom := 1;
  while NextElementRaw(Text_, 'tu', UnitFrom, UnitRaw, UnitAttributes) do
  begin
    SourceText := '';
    TargetText := '';
    VariantFrom := 1;
    while NextElement(UnitRaw, 'tuv', VariantFrom, VariantBody,
      VariantAttributes) do
    begin
      Language := LanguageOf(VariantAttributes);
      { The body arrives with its markup already flattened, so the <seg> that
        holds the words has become the words. }
      if SameLanguage(Language, ASourceLanguage) then
        SourceText := Trim(VariantBody)
      else if SameLanguage(Language, AMemory.LanguageCode) then
        TargetText := Trim(VariantBody);
    end;
    if (SourceText <> '') and (TargetText <> '') then
      if AMemory.Remember(SourceText, TargetText, AApplicationId,
        ARecordedOn) then
        Inc(Result);
  end;
end;

{ ---------------------------------------------------------------------------
  TBX
  --------------------------------------------------------------------------- }

function HasTerm(const AGlossary: TProjectGlossary;
  const ASourceText: string): Boolean;
var
  Term: TProjectGlossaryTerm;
begin
  for Term in AGlossary.Terms do
    if SameText(Trim(Term.SourceText), Trim(ASourceText)) then
      Exit(True);
  Result := False;
end;

class function TTbxInterchange.Export_(const AGlossary: TProjectGlossary;
  const AFileName: string): Integer;
var
  Output: TStringList;
  Term: TProjectGlossaryTerm;
  Index: Integer;
begin
  Result := 0;
  if AGlossary = nil then
    Exit;
  Output := TStringList.Create;
  try
    Output.Add('<?xml version="1.0" encoding="UTF-8"?>');
    Output.Add('<martif type="TBX-Basic" xml:lang="' +
      XmlEscape(AGlossary.SourceLanguage) + '">');
    Output.Add('  <martifHeader>');
    Output.Add('    <fileDesc>');
    Output.Add('      <titleStmt><title>' +
      XmlEscape(AGlossary.ApplicationId) + '</title></titleStmt>');
    Output.Add('    </fileDesc>');
    Output.Add('  </martifHeader>');
    Output.Add('  <text>');
    Output.Add('    <body>');
    Index := 0;
    for Term in AGlossary.Terms do
    begin
      Inc(Index);
      Output.Add(Format('      <termEntry id="c%d">', [Index]));
      Output.Add(Format('        <langSet xml:lang="%s">',
        [XmlEscape(AGlossary.SourceLanguage)]));
      Output.Add(Format('          <tig><term>%s</term></tig>',
        [XmlEscape(Term.SourceText)]));
      Output.Add('        </langSet>');
      Output.Add(Format('        <langSet xml:lang="%s">',
        [XmlEscape(AGlossary.TargetLanguage)]));
      Output.Add(Format('          <tig><term>%s</term></tig>',
        [XmlEscape(Term.TargetText)]));
      Output.Add('        </langSet>');
      Output.Add('      </termEntry>');
      Inc(Result);
    end;
    Output.Add('    </body>');
    Output.Add('  </text>');
    Output.Add('</martif>');
    TDirectory.CreateDirectory(TPath.GetDirectoryName(AFileName));
    Output.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

class function TTbxInterchange.Import_(const AGlossary: TProjectGlossary;
  const AFileName: string): Integer;
var
  Text_: string;
  SetFrom: Integer;
  SetBody, SetAttributes: string;
  Language: string;
  SourceTerm, TargetTerm: string;
  Term: TProjectGlossaryTerm;
begin
  Result := 0;
  if (AGlossary = nil) or not TFile.Exists(AFileName) then
    Exit;
  Text_ := TFile.ReadAllText(AFileName, TEncoding.UTF8);

  SourceTerm := '';
  TargetTerm := '';
  SetFrom := 1;
  while NextElement(Text_, 'langSet', SetFrom, SetBody, SetAttributes) do
  begin
    Language := LanguageOf(SetAttributes);
    SetBody := Trim(SetBody);
    if SameLanguage(Language, AGlossary.SourceLanguage) then
    begin
      SourceTerm := SetBody;
      TargetTerm := '';
    end
    else if SameLanguage(Language, AGlossary.TargetLanguage) then
      TargetTerm := SetBody;

    if (SourceTerm <> '') and (TargetTerm <> '') then
    begin
      { A term already known is left as it is. What one project settled
        is not silently rewritten by a file somebody imported later. }
      if not HasTerm(AGlossary, SourceTerm) then
      begin
        Term := TProjectGlossaryTerm.Create;
        Term.SourceText := SourceTerm;
        Term.TargetText := TargetTerm;
        Term.Approved := True;
        Term.DeveloperNote := 'Imported from TBX';
        AGlossary.Terms.Add(Term);
        Inc(Result);
      end;
      SourceTerm := '';
      TargetTerm := '';
    end;
  end;
end;

end.
