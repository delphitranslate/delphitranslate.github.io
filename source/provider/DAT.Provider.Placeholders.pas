unit DAT.Provider.Placeholders;

{ Keeping format specifiers alive across a translation service.

  A string like

    %.2f GB used / %.2f GB free of %.2f GB (%.1f%%)

  is half sentence and half instruction. The words are for the translator; the
  specifiers are for Format, and they must come back byte for byte or the
  application prints its own source code at the user.

  Sent to Arabic, they did not come back. Every % became a 0:

    ... 0.2f ... 0.2f ... (0.1f%)

  German and Spanish returned all six unharmed through the same code on the
  same day, so this is the engine and the target language rather than anything
  here. That is precisely why it cannot be left to the engine: it worked twice
  and then quietly stopped working, and the only reason it was noticed is that
  the catalog validator refuses a pack whose placeholders do not match.

  So the specifiers are taken out before the text is sent and put back after.
  What the engine sees in their place is a short token of capital letters and
  a digit - ZQPH0ZQPH - which no translator has any reason to alter, and which
  carries its own index so that a token the engine has moved still comes back
  as the right specifier. Right-to-left languages move things.

  A string that is nothing but specifiers is not sent at all. "%.2d/%.2d" is a
  date format with no words in it; there is nothing to translate, the engine
  can only damage it, and asking costs money. }

interface

type
  TPlaceholderProtection = record
  public
    { True when the text has no words for a translator - only specifiers,
      punctuation and spacing. Such a string is returned unchanged rather than
      sent. }
    class function IsOnlyPlaceholders(const AText: string): Boolean; static;
    { The text with each format specifier replaced by a token, and the
      specifiers themselves in the order they were found. }
    class function Protect(const AText: string;
      out ASpecifiers: TArray<string>): string; static;
    { The tokens replaced by the specifiers they stand for. Tokens the engine
      has moved, spaced or changed the case of are still recognised; a token it
      has destroyed outright is left alone, and the catalog validator remains
      the backstop for that. }
    class function Restore(const AText: string;
      const ASpecifiers: TArray<string>): string; static;
    { Whether a round trip kept every specifier. Used to decide whether to
      trust a translation or fall back to the source text. }
    class function Matches(const ASource, ATranslated: string): Boolean; static;
  end;

implementation

uses
  System.Character,
  System.Classes,
  System.SysUtils;

const
  { Deliberately ugly and deliberately ASCII. A run of capitals with no vowel
    pattern is left alone by every engine tried, and being ASCII it cannot be
    damaged by an encoding round trip the way an exotic character could. }
  TokenPrefix = 'ZQPH';
  TokenSuffix = 'ZQPH';

{ Every Delphi format specifier in a string, in order.

  Delphi's grammar is "%" [index ":"] ["-"] [width] ["." precision] type,
  where width and precision may each be "*". The type letters are the ones
  Format accepts. "%%" is a literal percent and is protected too: an engine
  that halves it changes what the user reads. }
function FindSpecifiers(const AText: string): TArray<string>;
var
  Found: TStringList;
  Index: Integer;
  Start: Integer;
  Length_: Integer;

  function AtType(const APosition: Integer): Boolean;
  begin
    Result := (APosition <= System.Length(AText)) and
      CharInSet(AText[APosition],
        ['d', 'D', 'u', 'U', 'e', 'E', 'f', 'F', 'g', 'G', 'n', 'N',
         'm', 'M', 'p', 'P', 's', 'S', 'x', 'X']);
  end;

begin
  Found := TStringList.Create;
  try
    Index := 1;
    Length_ := System.Length(AText);
    while Index <= Length_ do
    begin
      if AText[Index] <> '%' then
      begin
        Inc(Index);
        Continue;
      end;
      Start := Index;
      Inc(Index);
      if (Index <= Length_) and (AText[Index] = '%') then
      begin
        { A literal percent. }
        Inc(Index);
        Found.Add(Copy(AText, Start, Index - Start));
        Continue;
      end;
      { index, flags, width and precision, in whatever combination }
      while (Index <= Length_) and
        (AText[Index].IsDigit or CharInSet(AText[Index],
          [':', '-', '.', '*'])) do
        Inc(Index);
      if AtType(Index) then
      begin
        Inc(Index);
        Found.Add(Copy(AText, Start, Index - Start));
      end;
      { A lone % that begins nothing is left where it is: it is not a
        specifier, and inventing one would be worse than ignoring it. }
    end;
    Result := Found.ToStringArray;
  finally
    Found.Free;
  end;
end;

function TokenFor(const AIndex: Integer): string;
begin
  Result := TokenPrefix + IntToStr(AIndex) + TokenSuffix;
end;

class function TPlaceholderProtection.IsOnlyPlaceholders(
  const AText: string): Boolean;
var
  Remaining: string;
  Specifier: string;
  Character: Char;
begin
  Result := False;
  if Trim(AText) = '' then
    Exit;
  Remaining := AText;
  for Specifier in FindSpecifiers(AText) do
    Remaining := StringReplace(Remaining, Specifier, '', []);
  { Whatever is left has to be free of letters and digits before the string
    counts as wordless. A separator, a bracket or a space is not a word. }
  for Character in Remaining do
    if Character.IsLetter or Character.IsDigit then
      Exit;
  Result := Length(FindSpecifiers(AText)) > 0;
end;

class function TPlaceholderProtection.Protect(const AText: string;
  out ASpecifiers: TArray<string>): string;
var
  Specifier: string;
  Index: Integer;
  At: Integer;
  Taken: Integer;
begin
  ASpecifiers := FindSpecifiers(AText);
  { Built in one pass rather than by replacement. Two identical specifiers -
    and "%.2f GB used / %.2f GB free" has three - must become two different
    tokens, which a search-and-replace cannot do. }
  Result := '';
  Index := 1;
  Taken := 0;
  while Index <= Length(AText) do
  begin
    if (AText[Index] = '%') and (Taken <= High(ASpecifiers)) then
    begin
      Specifier := ASpecifiers[Taken];
      At := Length(Specifier);
      if Copy(AText, Index, At) = Specifier then
      begin
        Result := Result + TokenFor(Taken);
        Inc(Taken);
        Inc(Index, At);
        Continue;
      end;
    end;
    Result := Result + AText[Index];
    Inc(Index);
  end;
end;

class function TPlaceholderProtection.Restore(const AText: string;
  const ASpecifiers: TArray<string>): string;
var
  Index: Integer;
  Token: string;
begin
  Result := AText;
  for Index := 0 to High(ASpecifiers) do
  begin
    Token := TokenFor(Index);
    { Case-insensitively, because an engine may decide a run of capitals is
      shouting and quietly lower it. }
    Result := StringReplace(Result, Token, ASpecifiers[Index],
      [rfReplaceAll, rfIgnoreCase]);
  end;
end;

class function TPlaceholderProtection.Matches(const ASource,
  ATranslated: string): Boolean;
var
  Left, Right: TArray<string>;
  Index: Integer;
  LeftList, RightList: TStringList;
begin
  Left := FindSpecifiers(ASource);
  Right := FindSpecifiers(ATranslated);
  if Length(Left) <> Length(Right) then
    Exit(False);
  { Order may legitimately differ - a translator may put the number after the
    unit, and a right-to-left language moves things about - so this compares
    what is present rather than the sequence. }
  LeftList := TStringList.Create;
  RightList := TStringList.Create;
  try
    for Index := 0 to High(Left) do
      LeftList.Add(Left[Index]);
    for Index := 0 to High(Right) do
      RightList.Add(Right[Index]);
    LeftList.Sort;
    RightList.Sort;
    Result := LeftList.Text = RightList.Text;
  finally
    RightList.Free;
    LeftList.Free;
  end;
end;

end.
