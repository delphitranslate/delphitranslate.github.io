program TemplateRewriteSmokeTests;

{ Recognising text the application built for itself.

  The case that drove this: a caption rebuilt every second as an English
  literal plus a Format call. The format string ships translated, as a
  template, and the application never asks for it - so the translation has to
  recognise the application's output instead of the other way round.

  The interesting tests here are the ones that must NOT match. A rewriter that
  translates everything it is shown is worse than none: it corrupts strings
  somebody is reading, and it does so silently. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DAT.Runtime.TemplateRewrite in '..\..\source\runtime\DAT.Runtime.TemplateRewrite.pas',
  DAT.Runtime.LanguagePack in '..\..\source\runtime\DAT.Runtime.LanguagePack.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

procedure ExpectRewrite(const AText, ASource, ATarget, AExpected,
  AMessage: string);
var
  Actual: string;
begin
  if not TDATTemplateRewriter.RewriteWith(AText, ASource, ATarget, Actual) then
  begin
    Writeln('  FAIL  ', AMessage, ' (no match)');
    Inc(Failures);
    Exit;
  end;
  if Actual <> AExpected then
  begin
    Writeln('  FAIL  ', AMessage);
    Writeln('          wanted: ', AExpected);
    Writeln('          got:    ', Actual);
    Inc(Failures);
    Exit;
  end;
  Writeln('  ok    ', AMessage);
end;

procedure ExpectNoRewrite(const AText, ASource, ATarget, AMessage: string);
var
  Actual: string;
begin
  Check(not TDATTemplateRewriter.RewriteWith(AText, ASource, ATarget, Actual),
    AMessage);
end;

begin
  try
    Writeln('Template rewriting');
    Writeln;

    { The real one, prefix and all. The literal in front of the template is
      the application's and is not ours to touch - it stays exactly as it was. }
    ExpectRewrite(
      'Carillon Bells Schedule   Uptime: 0 years 3 months',
      'Uptime: %d years %d months',
      'Betriebszeit: %d Jahre %d Monate',
      'Carillon Bells Schedule   Betriebszeit: 0 Jahre 3 Monate',
      'A template is recognised inside a longer caption, and the rest is left alone.');

    { Arguments move across as text. Nothing is parsed, so nothing can fail to
      parse - and a value the application formatted its own way survives. }
    ExpectRewrite(
      'Played 1,234 songs today',
      'Played %d songs today',
      'Heute %d Lieder gespielt',
      'Heute 1,234 Lieder gespielt',
      'An argument keeps the form the application gave it.');

    { A translation is free to put its arguments in a different order. }
    ExpectRewrite(
      'from Monday to Friday',
      'from %s to %s',
      'bis %1:s ab %0:s',
      'bis Friday ab Monday',
      'A translation that reorders its placeholders gets the right argument in each.');

    Writeln;

    { --- and now the ones that must not fire --------------------------- }

    ExpectNoRewrite(
      'Some entirely unrelated caption',
      'Uptime: %d years',
      'Betriebszeit: %d Jahre',
      'Text that does not contain the template is left alone.');

    { The whole reason for a minimum: a bare placeholder would otherwise
      match every string in the application. }
    ExpectNoRewrite(
      'anything at all',
      '%s',
      '%s',
      'A template with no fixed text of its own is refused.');

    ExpectNoRewrite(
      'Uptime: 4 years',
      'Uptime: 4 years',
      'Betriebszeit: 4 Jahre',
      'A template with no placeholders is left to the ordinary string path.');

    { Half a match is not a match. }
    ExpectNoRewrite(
      'Uptime: 3 years',
      'Uptime: %d years %d months',
      'Betriebszeit: %d Jahre %d Monate',
      'A template whose later literals are missing does not half-apply.');

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Template rewrite smoke tests passed.');
      ExitCode := 0;
    end
    else
    begin
      Writeln('Template rewrite smoke tests failed: ', Failures);
      ExitCode := 1;
    end;
  except
    on E: Exception do
    begin
      Writeln('Template rewrite smoke tests error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
