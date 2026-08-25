unit DAT.Runtime.TemplateRewrite;

{ Translating text the application built for itself.

  Some text never passes through a property this product can set. It is
  assembled in code and assigned, often on a timer:

    DisplayText := Format('     Uptime:  %d years  %d months ...', [...]);
    Self.Caption := 'Westminster Chimes ... Portable Edition   ' + DisplayText;

  The format string is scanned and translated - it ships in the pack as a
  template - but a template only helps when the application asks for one, and
  an application that calls Format asks for nothing. The translation is
  delivered and never consulted.

  So this works the other way round: instead of the application looking up a
  translation, the translation recognises the application's own output.

  How the match is made. A format string is a run of literal text with holes
  in it. '  Uptime: %d years' is 'Uptime: ' then a hole then ' years'. The
  literal parts are fixed; the holes hold whatever the application computed.
  Finding the literals in order, in the candidate text, both proves the text
  came from this template and reveals what went into the holes - each hole is
  simply what lies between two literals.

  The translated template is then filled with those same pieces. They are
  moved across as text, never re-parsed: an argument that arrived as '0' is
  written back as '0'. Nothing is converted, so nothing can fail to convert,
  and a translation that reorders its placeholders gets the right piece in
  each because Delphi's index specifiers are honoured.

  What stops it mangling innocent text. A template of nothing but '%s' would
  match every string in the application, so a template must contain enough
  fixed text to be recognisable - see MinimumLiteralLength below. Matching is
  also all-or-nothing: every literal must appear, in order, or the text is
  left exactly as it was. Refusing to translate is a blemish; corrupting a
  string somebody is reading is a defect. }

interface

uses
  DAT.Runtime.LanguagePack;

type
  TDATTemplateRewriter = class
  public
    { Rewrites AText if any of the pack's templates recognises it. False - and
      ARewritten untouched - when nothing matches, which is the common case
      and must stay cheap. }
    class function Rewrite(const AText: string;
      const APack: TRuntimeLanguagePack;
      out ARewritten: string): Boolean; static;
    { One template, exposed for the harness so a failure names the template
      that failed rather than "nothing matched". }
    class function RewriteWith(const AText, ASourceTemplate,
      ATranslatedTemplate: string; out ARewritten: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections;

const
  { A template with less fixed text than this is not distinctive enough to be
    recognised safely, and is skipped. Four characters is short enough to keep
    ' years' and similar useful, long enough that '%s' and ': %d' - which
    would match half the application - cannot qualify. }
  MinimumLiteralLength = 4;

type
  TTemplatePart = record
    Literal: string;
    { -1 for the trailing literal, which no placeholder follows. }
    PlaceholderIndex: Integer;
  end;

{ Splits a format string into its literal runs.

  Returns False for a string with no placeholders at all: that is ordinary
  text, already handled by the ordinary string path, and running it through
  here would only risk a wrong match. }
function SplitTemplate(const ATemplate: string;
  out AParts: TArray<TTemplatePart>;
  out APlaceholderCount: Integer): Boolean;
var
  Index: Integer;
  Current: string;
  Parts: TList<TTemplatePart>;
  Part: TTemplatePart;
  Explicit: Integer;
  Digits: string;
  Scan: Integer;
begin
  Result := False;
  APlaceholderCount := 0;
  Parts := TList<TTemplatePart>.Create;
  try
    Current := '';
    Index := 1;
    while Index <= Length(ATemplate) do
    begin
      if ATemplate[Index] <> '%' then
      begin
        Current := Current + ATemplate[Index];
        Inc(Index);
        Continue;
      end;
      { '%%' is a literal per cent, not a hole. }
      if (Index < Length(ATemplate)) and (ATemplate[Index + 1] = '%') then
      begin
        Current := Current + '%';
        Inc(Index, 2);
        Continue;
      end;

      { A placeholder: % [index:] [-] [width] [.precision] conversion }
      Scan := Index + 1;
      Explicit := -1;
      Digits := '';
      while (Scan <= Length(ATemplate)) and
        CharInSet(ATemplate[Scan], ['0'..'9']) do
      begin
        Digits := Digits + ATemplate[Scan];
        Inc(Scan);
      end;
      if (Digits <> '') and (Scan <= Length(ATemplate)) and
        (ATemplate[Scan] = ':') then
      begin
        Explicit := StrToIntDef(Digits, -1);
        Inc(Scan);
      end;
      if (Scan <= Length(ATemplate)) and (ATemplate[Scan] = '-') then
        Inc(Scan);
      while (Scan <= Length(ATemplate)) and
        CharInSet(ATemplate[Scan], ['0'..'9', '*']) do
        Inc(Scan);
      if (Scan <= Length(ATemplate)) and (ATemplate[Scan] = '.') then
      begin
        Inc(Scan);
        while (Scan <= Length(ATemplate)) and
          CharInSet(ATemplate[Scan], ['0'..'9', '*']) do
          Inc(Scan);
      end;
      if (Scan > Length(ATemplate)) or
        not CharInSet(ATemplate[Scan],
          ['d', 'u', 'e', 'f', 'g', 'n', 'm', 's', 'x', 'p',
           'D', 'U', 'E', 'F', 'G', 'N', 'M', 'S', 'X', 'P']) then
      begin
        { Not a placeholder after all - a stray per cent. }
        Current := Current + ATemplate[Index];
        Inc(Index);
        Continue;
      end;

      Part.Literal := Current;
      if Explicit >= 0 then
        Part.PlaceholderIndex := Explicit
      else
        Part.PlaceholderIndex := APlaceholderCount;
      Parts.Add(Part);
      Inc(APlaceholderCount);
      Current := '';
      Index := Scan + 1;
    end;

    if APlaceholderCount = 0 then
      Exit;
    Part.Literal := Current;
    Part.PlaceholderIndex := -1;
    Parts.Add(Part);
    AParts := Parts.ToArray;
    Result := True;
  finally
    Parts.Free;
  end;
end;

{ How much fixed text a template offers for recognition. }
function TotalLiteralLength(const AParts: TArray<TTemplatePart>): Integer;
var
  Part: TTemplatePart;
begin
  Result := 0;
  for Part in AParts do
    Inc(Result, Length(Trim(Part.Literal)));
end;

class function TDATTemplateRewriter.RewriteWith(const AText, ASourceTemplate,
  ATranslatedTemplate: string; out ARewritten: string): Boolean;
var
  SourceParts, TargetParts: TArray<TTemplatePart>;
  SourceCount, TargetCount: Integer;
  Arguments: TArray<string>;
  Index: Integer;
  Position: Integer;
  Found: Integer;
  MatchStart, MatchEnd: Integer;
  Part: TTemplatePart;
  Builder: string;
  Sequential: Integer;
  Argument: string;
begin
  Result := False;
  if (Trim(AText) = '') or (Trim(ASourceTemplate) = '') or
    (Trim(ATranslatedTemplate) = '') then
    Exit;
  if not SplitTemplate(ASourceTemplate, SourceParts, SourceCount) then
    Exit;
  if not SplitTemplate(ATranslatedTemplate, TargetParts, TargetCount) then
    Exit;
  if TotalLiteralLength(SourceParts) < MinimumLiteralLength then
    Exit;

  SetLength(Arguments, SourceCount);
  Position := 1;
  MatchStart := 0;
  MatchEnd := 0;

  for Index := 0 to High(SourceParts) do
  begin
    Part := SourceParts[Index];
    if Part.Literal <> '' then
    begin
      Found := PosEx(Part.Literal, AText, Position);
      if Found = 0 then
        Exit;
      if Index = 0 then
        MatchStart := Found
      else
        { What lay between the previous literal and this one is what the
          application put in the hole. }
        Arguments[SourceParts[Index - 1].PlaceholderIndex] :=
          Copy(AText, Position, Found - Position);
      Position := Found + Length(Part.Literal);
      MatchEnd := Position;
    end
    else if Index = 0 then
      { A template opening with a placeholder has no anchor to start from, so
        the match begins wherever the text does. }
      MatchStart := 1
    else if Index = High(SourceParts) then
    begin
      { A template ending with a placeholder takes the rest of the text. }
      Arguments[SourceParts[Index - 1].PlaceholderIndex] :=
        Copy(AText, Position, Length(AText) - Position + 1);
      MatchEnd := Length(AText) + 1;
    end;
  end;

  if (MatchStart <= 0) or (MatchEnd <= MatchStart) then
    Exit;

  { Fill the translation, honouring index specifiers where it uses them so a
    language that reorders its arguments still gets the right one in each. }
  Builder := '';
  Sequential := 0;
  for Index := 0 to High(TargetParts) do
  begin
    Builder := Builder + TargetParts[Index].Literal;
    if TargetParts[Index].PlaceholderIndex < 0 then
      Continue;
    if TargetParts[Index].PlaceholderIndex < Length(Arguments) then
      Argument := Arguments[TargetParts[Index].PlaceholderIndex]
    else if Sequential < Length(Arguments) then
      Argument := Arguments[Sequential]
    else
      Argument := '';
    Inc(Sequential);
    Builder := Builder + Argument;
  end;

  ARewritten := Copy(AText, 1, MatchStart - 1) + Builder +
    Copy(AText, MatchEnd, Length(AText) - MatchEnd + 1);
  Result := ARewritten <> AText;
end;

class function TDATTemplateRewriter.Rewrite(const AText: string;
  const APack: TRuntimeLanguagePack; out ARewritten: string): Boolean;
var
  Pair: TPair<string, string>;
  SourceTemplate: string;
  Translated: string;
begin
  Result := False;
  if (APack = nil) or (Trim(AText) = '') then
    Exit;
  for Pair in APack.SourceTemplates do
  begin
    { Current packs store sourceTemplates as source text -> translated text.
      Early integration packs stored stable key -> source text and kept the
      translation under that key in templates. Accept both forms so a pack
      already deployed by a developer remains usable while newly exported
      packs follow the canonical runtime-pack contract. }
    if APack.Templates.TryGetValue(Pair.Key, Translated) then
      SourceTemplate := Pair.Value
    else
    begin
      SourceTemplate := Pair.Key;
      Translated := Pair.Value;
    end;
    if Translated = SourceTemplate then
      Continue;
    if RewriteWith(AText, SourceTemplate, Translated, ARewritten) then
      Exit(True);
  end;
end;

end.
