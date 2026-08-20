program LanguageCodeSmokeTests;

{ The codes a service is actually sent.

  The first Arabic run through DeepL stopped with

    HTTP 400 Bad Request

  and the message named the key, the plan, the billing and the network -
  everything except the real cause, because the code that raised it could not
  know. The request was well formed and the key was good. The target language
  was ar-SA, and DeepL's target list has AR.

  A catalog names languages the way Windows does. DeepL takes two-letter codes
  and a short published list of regional variants, and nothing else. So the
  region is kept where the service is known to accept it and dropped
  everywhere else - dropping being the safe direction, since the general code
  works for every language DeepL supports. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DAT.Provider.LanguageCodes in '..\..\source\provider\DAT.Provider.LanguageCodes.pas';

var
  Failures: Integer = 0;

procedure CheckDeepL(const ACatalogCode, AExpected: string;
  const AIsTarget: Boolean; const AWhy: string);
var
  Actual: string;
begin
  Actual := TProviderLanguageCodes.DeepL(ACatalogCode, AIsTarget);
  if SameText(Actual, AExpected) then
    Writeln(Format('  ok    %-8s -> %-7s  %s', [ACatalogCode, Actual, AWhy]))
  else
  begin
    Writeln(Format('  FAIL  %-8s -> %-7s  expected %s (%s)',
      [ACatalogCode, Actual, AExpected, AWhy]));
    Inc(Failures);
  end;
end;

begin
  try
    Writeln;
    Writeln('=== the one that failed ===');
    CheckDeepL('ar-SA', 'AR', True, 'Arabic has no regional variant at DeepL');

    Writeln;
    Writeln('=== other languages a catalog will name with a region ===');
    CheckDeepL('es-ES', 'ES', True, 'Spanish is ES; only ES-419 is a variant');
    CheckDeepL('he-IL', 'HE', True, 'Hebrew');
    CheckDeepL('ja-JP', 'JA', True, 'Japanese');
    CheckDeepL('it-IT', 'IT', True, 'Italian');
    CheckDeepL('nl-NL', 'NL', True, 'Dutch');

    Writeln;
    Writeln('=== the variants DeepL does accept, which must survive ===');
    CheckDeepL('en-US', 'EN-US', True, 'American English');
    CheckDeepL('en-GB', 'EN-GB', True, 'British English');
    CheckDeepL('pt-BR', 'PT-BR', True, 'Brazilian Portuguese');
    CheckDeepL('pt-PT', 'PT-PT', True, 'European Portuguese');
    CheckDeepL('de-DE', 'DE-DE', True, 'German, a listed variant');
    CheckDeepL('fr-FR', 'FR-FR', True, 'French, a listed variant');
    CheckDeepL('es-419', 'ES-419', True, 'Latin American Spanish');

    Writeln;
    Writeln('=== a source language never carries a region ===');
    CheckDeepL('en-US', 'EN', False, 'source English');
    CheckDeepL('de-DE', 'DE', False, 'source German');
    CheckDeepL('pt-BR', 'PT', False, 'source Portuguese');

    Writeln;
    Writeln('=== shapes that must not crash ===');
    CheckDeepL('fr', 'FR', True, 'already bare');
    CheckDeepL('zh_HANS', 'ZH-HANS', True, 'underscore separator');
    CheckDeepL('  de-DE  ', 'DE-DE', True, 'surrounding space');
    CheckDeepL('', '', True, 'nothing at all');

    Writeln;
    Writeln('=== Google takes the plain code ===');
    if TProviderLanguageCodes.Google('ar-SA') = 'ar' then
      Writeln('  ok    ar-SA    -> ar')
    else
    begin
      Writeln('  FAIL  Google code for ar-SA');
      Inc(Failures);
    end;

    if Failures = 0 then
    begin
      Writeln('Language code smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Language code smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
