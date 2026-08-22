program CalendarTermSmokeTests;

{ Day and month names are answered from the operating system, not asked of a
  service.

  A three-letter day abbreviation carries no context a service can use, and
  several of them are also ordinary words: given one on its own a service
  returns the word, which for a number of languages is a verb in the past
  tense. The answer is defensible as a translation of the letters and is not a
  day of the week.

  Windows already holds the whole closed set for every locale it supports, in
  both forms and spelled the way that language spells it. This checks that the
  set is recognized, that the form and the letter case of the source are
  carried onto the answer, and - just as important - that ordinary words are
  left alone. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DAT.Provider.CalendarTerms in '..\..\source\provider\DAT.Provider.CalendarTerms.pas';

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

{ Resolves, and to something that is not the English it started as. }
procedure CheckResolves(const AText, ATarget, AWhat: string);
var
  Answer: string;
begin
  if not TCalendarTerms.TryResolve(AText, 'en-US', ATarget, Answer) then
  begin
    Writeln('  FAIL  ', AWhat, ': "', AText, '" was not recognized at all.');
    Inc(Failures);
    Exit;
  end;
  Writeln(Format('        %-10s -> %-16s (%s)', [AText, Answer, ATarget]));
  Check(Answer <> '', AWhat + ': an answer came back.');
  Check(not SameText(Answer, AText),
    AWhat + ': and it is not the English it started as.');
end;

procedure CheckLeftAlone(const AText, ATarget, AWhat: string);
var
  Answer: string;
begin
  Check(not TCalendarTerms.TryResolve(AText, 'en-US', ATarget, Answer),
    AWhat + ': "' + AText + '" is left for the service.');
end;

var
  Answer: string;
  Probe: string;
begin
  try
    { Nothing here can run on a machine whose Windows has no support for the
      locales being asked about. Say so rather than reporting a false pass. }
    if not TCalendarTerms.TryResolve('Monday', 'en-US', 'de-DE', Probe) then
    begin
      Writeln('This machine cannot answer for de-DE, so these checks cannot ' +
        'run. Install the language and try again.');
      Halt(2);
    end;

    Writeln;
    Writeln('=== the closed set is recognized ===');
    CheckResolves('Wed', 'de-DE', 'A day abbreviation');
    CheckResolves('Sat', 'fr-FR', 'A day abbreviation');
    CheckResolves('Sun', 'es-ES', 'The day that is also a star');
    CheckResolves('Wednesday', 'de-DE', 'A full day name');
    CheckResolves('Jan', 'fr-FR', 'A month abbreviation');

    { An answer that matches the English is legitimate rather than a
      failure to resolve: German abbreviates January to Jan as well.
      What matters is that it came from the locale. }
    Check(TCalendarTerms.TryResolve('Jan', 'en-US', 'de-DE', Answer) and
      (Answer = 'Jan'),
      'A language that happens to agree with English still resolves.');
    CheckResolves('September', 'fr-FR', 'A full month name');

    Writeln;
    Writeln('=== the form of the source is carried onto the answer ===');
    TCalendarTerms.TryResolve('Wed', 'en-US', 'de-DE', Answer);
    Probe := Answer;
    TCalendarTerms.TryResolve('Wednesday', 'en-US', 'de-DE', Answer);
    Writeln('        abbreviated "', Probe, '"  full "', Answer, '"');
    Check(Length(Probe) < Length(Answer),
      'An abbreviation comes back abbreviated and a full name comes back ' +
      'full, rather than both coming back the same.');

    TCalendarTerms.TryResolve('MON', 'en-US', 'de-DE', Answer);
    Writeln('        MON -> ', Answer);
    Check(Answer = Answer.ToUpper,
      'An upper-case source gets an upper-case answer.');

    TCalendarTerms.TryResolve('Mon.', 'en-US', 'de-DE', Answer);
    Writeln('        Mon. -> ', Answer);
    Check(Answer.EndsWith('.'),
      'A trailing period is part of the form and is carried back.');

    Writeln;
    Writeln('=== everything else is left for the service ===');
    CheckLeftAlone('Close', 'de-DE', 'An ordinary caption');
    CheckLeftAlone('Play Date From', 'de-DE', 'A phrase');
    CheckLeftAlone('Wed 12 May', 'de-DE', 'A composed string');
    CheckLeftAlone('%.2d/%.2d', 'de-DE', 'A format string');
    CheckLeftAlone('', 'de-DE', 'An empty string');

    Writeln;
    Writeln('=== the table is English, and says so ===');
    Check(not TCalendarTerms.TryResolve('Mittwoch', 'de-DE', 'fr-FR', Answer),
      'A catalog whose source is not English falls through untouched.');
    Check(not TCalendarTerms.TryResolve('Wed', 'en-US', 'en-GB', Answer),
      'English to English has nothing to resolve.');
    Check(not TCalendarTerms.TryResolve('Wed', 'en-US', 'zz-ZZ', Answer),
      'A locale Windows does not know is left for the service.');

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Calendar term smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Calendar term smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
