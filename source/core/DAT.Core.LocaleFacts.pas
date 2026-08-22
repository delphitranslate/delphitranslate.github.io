unit DAT.Core.LocaleFacts;

{ What a language expects of dates, numbers, money, and reading direction,
  answered by the operating system.

  A catalog carries a locale block as well as words, and it matters more than
  it looks: applying a language sets the running application's format settings
  from it, so a date written 08/22/2026 in one language is written 22.08.2026
  in another without the application doing anything. Getting the words right
  and the formats wrong produces an application that is half translated in a
  way users notice immediately.

  Windows already holds all of it for every locale it supports. Nothing here is
  a table this product has to maintain, which matters because a table of date
  formats for forty languages is a table that is wrong somewhere and nobody
  finds out until a customer does.

  The same caution as everywhere else that asks Windows about a locale: it
  accepts invented names. "zz-ZZ" is reported as valid and answers with
  invariant English values. A caller that cannot tell the difference would
  stamp English conventions into a pack as though they had been looked up, so
  Known answers that question first. }

interface

type
  TLocaleFacts = record
    NativeName: string;
    ShortDateFormat: string;
    LongDateFormat: string;
    ShortTimeFormat: string;
    LongTimeFormat: string;
    DecimalSeparator: string;
    ThousandSeparator: string;
    CurrencySymbol: string;
    { 'rtl' for Arabic, Hebrew, Farsi, Urdu and their kin; 'ltr' otherwise.
      Taken from the locale's own reading layout rather than from a list of
      languages kept here. }
    TextDirection: string;
  end;

  TLocaleFactsReader = record
  public
    { Whether Windows genuinely knows this locale, as opposed to accepting the
      name and answering with invariant values. }
    class function Known(const ALocaleName: string): Boolean; static;

    { Everything above for one locale. An unknown locale answers with empty
      strings and 'ltr', which a caller should treat as "fill these in
      yourself" rather than as fact. }
    class function Read(const ALocaleName: string): TLocaleFacts; static;
  end;

implementation

uses
  System.SysUtils;

function GetLocaleInfoEx(lpLocaleName: PWideChar; LCType: Cardinal;
  lpLCData: PWideChar; cchData: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'GetLocaleInfoEx';

const
  LOCALE_SNATIVEDISPLAYNAME = $00000073;
  LOCALE_SSHORTDATE         = $0000001F;
  LOCALE_SLONGDATE          = $00000020;
  LOCALE_SSHORTTIME         = $00000079;
  LOCALE_STIMEFORMAT        = $00001003;
  LOCALE_SDECIMAL           = $0000000E;
  LOCALE_STHOUSAND          = $0000000F;
  LOCALE_SCURRENCY          = $00000014;
  { 0 means left to right, 1 means right to left. }
  LOCALE_IREADINGLAYOUT     = $00000070;
  LOCALE_SABBREVDAYNAME1    = $00000031;

function Value(const ALocaleName: string; const AType: Cardinal): string;
var
  Buffer: array [0 .. 127] of WideChar;
  Count: Integer;
begin
  Result := '';
  if Trim(ALocaleName) = '' then
    Exit;
  Count := GetLocaleInfoEx(PWideChar(ALocaleName), AType, @Buffer[0],
    Length(Buffer));
  if Count > 1 then
    SetString(Result, PWideChar(@Buffer[0]), Count - 1);
end;

class function TLocaleFactsReader.Known(const ALocaleName: string): Boolean;
const
  Invariant: array [0 .. 6] of string = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri',
    'Sat', 'Sun');
var
  Index: Integer;
  Day: string;
begin
  { IsValidLocaleName is no help: Windows accepts any well-formed name and
    answers for it. Whether it holds a calendar of its own is the question that
    actually distinguishes a language from the fallback. }
  for Index := 0 to High(Invariant) do
  begin
    Day := Value(ALocaleName, LOCALE_SABBREVDAYNAME1 + Cardinal(Index));
    if Day = '' then
      Exit(False);
    if not SameText(Day, Invariant[Index]) then
      Exit(True);
  end;
  { Every day matched English. Either this is an English locale, in which case
    the facts are still correct, or it is the invariant fallback. English is
    the only real language this can be. }
  Result := SameText(Copy(Trim(ALocaleName), 1, 2), 'en');
end;

class function TLocaleFactsReader.Read(
  const ALocaleName: string): TLocaleFacts;
begin
  Result := Default(TLocaleFacts);
  Result.TextDirection := 'ltr';
  if not Known(ALocaleName) then
    Exit;

  Result.NativeName := Value(ALocaleName, LOCALE_SNATIVEDISPLAYNAME);
  Result.ShortDateFormat := Value(ALocaleName, LOCALE_SSHORTDATE);
  Result.LongDateFormat := Value(ALocaleName, LOCALE_SLONGDATE);
  Result.ShortTimeFormat := Value(ALocaleName, LOCALE_SSHORTTIME);
  Result.LongTimeFormat := Value(ALocaleName, LOCALE_STIMEFORMAT);
  Result.DecimalSeparator := Value(ALocaleName, LOCALE_SDECIMAL);
  Result.ThousandSeparator := Value(ALocaleName, LOCALE_STHOUSAND);
  Result.CurrencySymbol := Value(ALocaleName, LOCALE_SCURRENCY);
  if Trim(Value(ALocaleName, LOCALE_IREADINGLAYOUT)) = '1' then
    Result.TextDirection := 'rtl';
end;

end.
