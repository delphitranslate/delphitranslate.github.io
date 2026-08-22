unit DAT.Provider.CalendarTerms;

{ Day and month names, answered from the operating system rather than asked of
  a translation service.

  A translation service sees one short string and no calendar. Given a
  three-letter day abbreviation on its own it returns whatever that sequence of
  letters means as a word, which for several languages is a verb: the past
  tense of "to marry", the past tense of "to sit", the name of a star. Each
  answer is a defensible translation of the letters and none of them is a day
  of the week.

  Context does not rescue this. The strings are too short to carry any, and
  even a correct description of the control does not tell the service that
  "Wed" is an abbreviation rather than a word.

  But day and month names are a closed set, and every Windows installation
  already holds them for every locale it supports, in the abbreviated and the
  full form, spelled and capitalized the way that language does it. So they are
  never sent. This is the same reasoning that already stops a string of nothing
  but format specifiers being sent: the service cannot improve on what is
  already known, and can only damage it.

  Two limits are worth stating plainly.

  The source must be English, because the table being matched is English. A
  catalog whose source language is anything else falls through and is
  translated normally.

  And a three-letter abbreviation is not always a date. An application about
  astronomy may legitimately have a control captioned "Sun", and this unit will
  turn it into the local word for Sunday. That is wrong - but sending it
  produces the local word for the star, which is equally wrong, less
  recognizable in review, and wrong for every application rather than for the
  rare one. Full names carry no such ambiguity at all. }

interface

type
  TCalendarTerms = record
  public
    { True when AText is an English day or month name, in which case
      ATranslated holds the name that ATargetLanguage uses for it, in the same
      form - abbreviated for an abbreviation, full for a full name - and
      carrying back the source's trailing period and letter case.

      False for everything else, including any source language other than
      English, and including a language Windows cannot answer for. A caller
      that gets False should translate the string in the ordinary way. }
    class function TryResolve(const AText, ASourceLanguage,
      ATargetLanguage: string; out ATranslated: string): Boolean; static;
  end;

implementation

uses
  System.Character,
  System.StrUtils,
  System.SysUtils;

{ Declared here rather than taken from Winapi.Windows, so that this unit
  compiles the same way whatever that unit exposes in a given release. }
function GetLocaleInfoEx(lpLocaleName: PWideChar; LCType: Cardinal;
  lpLCData: PWideChar; cchData: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'GetLocaleInfoEx';

const
  { Monday through Sunday, then January through December, each in the full and
    the abbreviated form. These are the documented LCTYPE values. }
  LOCALE_SDAYNAME1        = $0000002A;
  LOCALE_SABBREVDAYNAME1  = $00000031;
  LOCALE_SMONTHNAME1      = $00000038;
  LOCALE_SABBREVMONTHNAME1 = $00000044;

  { Lower case, because every comparison here is case-insensitive and the
    answer's capitalization comes from the locale rather than from these. }
  FullDayNames: array [0 .. 6] of string = ('monday', 'tuesday', 'wednesday',
    'thursday', 'friday', 'saturday', 'sunday');

  FullMonthNames: array [0 .. 11] of string = ('january', 'february', 'march',
    'april', 'may', 'june', 'july', 'august', 'september', 'october',
    'november', 'december');

  { The abbreviations an English form actually carries. More than one spelling
    per day, because designers write whichever they prefer and all of them are
    the same day. }
  AbbreviatedDayNames: array [0 .. 6] of string = ('mon|mo', 'tue|tues|tu',
    'wed|weds|we', 'thu|thur|thurs|th', 'fri|fr', 'sat|sa', 'sun|su');

  AbbreviatedMonthNames: array [0 .. 11] of string = ('jan', 'feb', 'mar',
    'apr', 'may', 'jun', 'jul', 'aug', 'sep|sept', 'oct', 'nov', 'dec');

{ The locale's own word, or an empty string where Windows does not know this
  locale - which is the answer for a language the machine has no support for,
  and a good enough reason to leave the string to the service. }
function LocaleValue(const ALocaleName: string; const AType: Cardinal): string;
var
  Buffer: array [0 .. 127] of WideChar;
  Count: Integer;
begin
  Result := '';
  if Trim(ALocaleName) = '' then
    Exit;
  Count := GetLocaleInfoEx(PWideChar(ALocaleName), AType, @Buffer[0],
    Length(Buffer));
  { The count includes the terminating null. }
  if Count > 1 then
    SetString(Result, PWideChar(@Buffer[0]), Count - 1);
end;

{ Whether Windows actually holds a calendar for this locale, or is answering
  from its invariant fallback.

  This has to be asked, and IsValidLocaleName does not answer it. Windows
  accepts any well-formed locale name: "zz-ZZ" and "xx" are both reported as
  valid and both return the English day names. Trusting that would take a
  target language the machine has no support for and quietly stamp English day
  names into the pack as though they were translations - which is worse than
  sending the string, because a service would at least have tried.

  So the whole set of abbreviated day names is compared against the English
  one. A locale that matches on all seven is the fallback rather than a
  language, since any real locale that named its days in English would be an
  English locale, and those have already been excluded by the caller. }
function LocaleHasItsOwnCalendar(const ALocaleName: string): Boolean;
const
  Invariant: array [0 .. 6] of string = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri',
    'Sat', 'Sun');
var
  Index: Integer;
  Value: string;
begin
  for Index := 0 to High(Invariant) do
  begin
    Value := LocaleValue(ALocaleName, LOCALE_SABBREVDAYNAME1 + Cardinal(Index));
    if Value = '' then
      Exit(False);
    if not SameText(Value, Invariant[Index]) then
      Exit(True);
  end;
  Result := False;
end;

{ Whether AText is one of the forms in a pipe-separated list. }
function IsOneOf(const AText, AAlternatives: string): Boolean;
var
  Alternative: string;
begin
  for Alternative in SplitString(AAlternatives, '|') do
    if SameText(AText, Alternative) then
      Exit(True);
  Result := False;
end;

{ English, whatever region is named with it. }
function IsEnglish(const ALanguage: string): Boolean;
var
  Code: string;
begin
  Code := Trim(ALanguage);
  Result := SameText(Code, 'en') or StartsText('en-', Code) or
    StartsText('en_', Code);
end;

{ The source's shape, carried onto the answer.

  Case is carried only where the source is uniformly upper or lower, which are
  deliberate choices a designer made. A mixed-case source is left to the
  locale, because the locale is right about its own language: some capitalize
  day names and some do not, and imposing English's habit on them would be a
  new defect in place of the one being fixed. }
function LikeSource(const ASource, AAnswer: string): string;
var
  Character: Char;
  HasLetter: Boolean;
  AllUpper: Boolean;
  AllLower: Boolean;
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

class function TCalendarTerms.TryResolve(const AText, ASourceLanguage,
  ATargetLanguage: string; out ATranslated: string): Boolean;
var
  Word_: string;
  Suffix: string;
  Answer: string;
  Index: Integer;
begin
  Result := False;
  ATranslated := '';
  if not IsEnglish(ASourceLanguage) then
    Exit;
  if IsEnglish(ATargetLanguage) then
    Exit;
  if not LocaleHasItsOwnCalendar(ATargetLanguage) then
    Exit;

  Word_ := Trim(AText);
  if Word_ = '' then
    Exit;

  { An abbreviation is often written with a trailing period. It is part of the
    form rather than part of the word, so it is set aside and put back. }
  Suffix := '';
  if EndsStr('.', Word_) then
  begin
    Suffix := '.';
    Word_ := Copy(Word_, 1, Length(Word_) - 1);
  end;
  if Word_ = '' then
    Exit;

  { One word only. "Wed" is a day; "Wed 12 May" is a composed string and
    belongs to whatever builds it. }
  for Index := 1 to Length(Word_) do
    if not Word_[Index].IsLetter then
      Exit;

  Answer := '';

  { Abbreviations are matched before full names so that a form which is both -
    May is written the same way either way - comes back in the short form,
    which is the one a row of month buttons wants. }
  for Index := 0 to High(AbbreviatedDayNames) do
    if IsOneOf(Word_, AbbreviatedDayNames[Index]) then
    begin
      Answer := LocaleValue(ATargetLanguage,
        LOCALE_SABBREVDAYNAME1 + Cardinal(Index));
      Break;
    end;

  if Answer = '' then
    for Index := 0 to High(AbbreviatedMonthNames) do
      if IsOneOf(Word_, AbbreviatedMonthNames[Index]) then
      begin
        Answer := LocaleValue(ATargetLanguage,
          LOCALE_SABBREVMONTHNAME1 + Cardinal(Index));
        Break;
      end;

  if Answer = '' then
    for Index := 0 to High(FullDayNames) do
      if SameText(Word_, FullDayNames[Index]) then
      begin
        Answer := LocaleValue(ATargetLanguage,
          LOCALE_SDAYNAME1 + Cardinal(Index));
        Break;
      end;

  if Answer = '' then
    for Index := 0 to High(FullMonthNames) do
      if SameText(Word_, FullMonthNames[Index]) then
      begin
        Answer := LocaleValue(ATargetLanguage,
          LOCALE_SMONTHNAME1 + Cardinal(Index));
        Break;
      end;

  if Answer = '' then
    Exit;

  ATranslated := LikeSource(Word_, Answer) + Suffix;
  Result := True;
end;

end.
