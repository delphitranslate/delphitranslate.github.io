unit DAT.Provider.LanguageCodes;

{ Turning a catalog language code into one a service will accept.

  A catalog names a language the way Windows does - ar-SA, es-ES, he-IL. DeepL
  does not take those. Its target list is almost entirely two-letter codes,
  with a short list of regional variants that are spelled out explicitly, and
  anything else is rejected outright:

    HTTP 400 Bad Request

  which is indistinguishable, from the outside, from a bad key or a billing
  problem. The first Arabic run through DeepL failed for exactly this reason:
  ar-SA was passed through untouched and DeepL wanted AR.

  So a region is kept only where the service is known to accept it, and
  dropped everywhere else. Dropping is always safe - the general code is
  accepted for every language DeepL supports - which means a language added
  after this was written still works, just without its regional variant. }

interface

type
  TProviderLanguageCodes = record
  public
    { For DeepL. A source language is always the plain two-letter code; a
      target keeps its region only if DeepL lists that variant. }
    class function DeepL(const ACode: string;
      const AIsTarget: Boolean): string; static;
    { For Google, which takes the plain code. }
    class function Google(const ACode: string): string; static;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

const
  { The regional variants DeepL accepts as a target, from its own supported
    languages page. Anything not here is reduced to two letters. Adding to
    this list is safe; guessing at it is not. }
  DeepLTargetVariants: array[0..10] of string = (
    'EN-GB', 'EN-US',
    'PT-BR', 'PT-PT',
    'ZH-HANS', 'ZH-HANT',
    'ES-419',
    'DE-DE', 'DE-CH',
    'FR-CA', 'FR-FR');

class function TProviderLanguageCodes.DeepL(const ACode: string;
  const AIsTarget: Boolean): string;
var
  Normalized: string;
  Variant_: string;
begin
  Normalized := UpperCase(StringReplace(Trim(ACode), '_', '-',
    [rfReplaceAll]));
  if Normalized = '' then
    Exit('');

  { A source language never carries a region. }
  if not AIsTarget then
    Exit(Copy(Normalized, 1, 2));

  for Variant_ in DeepLTargetVariants do
    if SameText(Normalized, Variant_) then
      Exit(Variant_);

  Result := Copy(Normalized, 1, 2);
end;

class function TProviderLanguageCodes.Google(const ACode: string): string;
var
  Normalized: string;
  SeparatorPosition: Integer;
begin
  Normalized := Trim(ACode);
  SeparatorPosition := Pos('-', Normalized);
  if SeparatorPosition > 0 then
    Normalized := Copy(Normalized, 1, SeparatorPosition - 1);
  Result := Normalized;
end;

end.
