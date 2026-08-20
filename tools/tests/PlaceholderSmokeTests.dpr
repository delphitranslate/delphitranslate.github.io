program PlaceholderSmokeTests;

{ Whether a format specifier survives a translation service.

  The case that produced this is real and is quoted exactly. Carillon's disk
  message went to Arabic and came back with every % turned into a 0, which
  would have printed "0.2f gigabytes" at the user for ever. German and Spanish
  returned the same string unharmed on the same day through the same code, so
  the damage is the engine and the language rather than anything here - and
  that is the whole argument for not leaving it to the engine. It worked twice
  and then quietly stopped.

  The tests below do not call a service. They stand in for one: text goes out
  protected, something plausible is done to it, and it comes back. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  DAT.Provider.Placeholders in '..\..\source\provider\DAT.Provider.Placeholders.pas';

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

var
  Specifiers: TArray<string>;
  Sent: string;
  Came: string;
  Restored: string;
begin
  try
    Writeln;
    Writeln('=== what is sent ===');

    Sent := TPlaceholderProtection.Protect(
      '%.2f GB used / %.2f GB free of %.2f GB (%.1f%%)', Specifiers);
    Writeln('  sent to the engine: ', Sent);
    Check(Length(Specifiers) = 5,
      Format('All five specifiers are taken out, not %d.',
        [Length(Specifiers)]));
    Check(not ContainsText(Sent, '%'),
      'Nothing the engine can misread is left in the text.');
    Check(ContainsText(Sent, 'GB used'),
      'The words are untouched, so there is still something to translate.');
    { Three identical %.2f must not become one token used three times, or two
      of the three come back in the wrong place. }
    Check(ContainsText(Sent, 'ZQPH0ZQPH') and ContainsText(Sent, 'ZQPH1ZQPH')
      and ContainsText(Sent, 'ZQPH2ZQPH'),
      'Identical specifiers get tokens of their own.');

    Writeln;
    Writeln('=== what comes back ===');

    { An engine that translates the words and leaves the tokens alone. }
    Came := StringReplace(Sent, 'GB used', 'GB benutzt', []);
    Came := StringReplace(Came, 'GB free of', 'GB frei von', []);
    Restored := TPlaceholderProtection.Restore(Came, Specifiers);
    Writeln('  restored: ', Restored);
    Check(Restored = '%.2f GB benutzt / %.2f GB frei von %.2f GB (%.1f%%)',
      'The specifiers come back exactly, in their places.');

    { An engine that moves the tokens about, which is what a right-to-left
      language does. Each token carries its own index, so each still comes
      back as the specifier it stood for. }
    Came := 'ZQPH3ZQPH x ZQPH0ZQPH y ZQPH1ZQPH z ZQPH2ZQPH ZQPH4ZQPH';
    Restored := TPlaceholderProtection.Restore(Came, Specifiers);
    Writeln('  reordered: ', Restored);
    Check(Restored = '%.1f x %.2f y %.2f z %.2f %%',
      'A token the engine moved still returns as its own specifier.');

    { An engine that lower-cases a run of capitals. }
    Came := LowerCase(Sent);
    Restored := TPlaceholderProtection.Restore(Came, Specifiers);
    Check(not ContainsText(Restored, 'zqph'),
      'A token the engine lower-cased is still recognised.');

    Writeln;
    Writeln('=== the strings that should never be sent ===');

    Check(TPlaceholderProtection.IsOnlyPlaceholders('%.2d/%.2d'),
      'A bare date format has no words in it and is not sent.');
    Check(TPlaceholderProtection.IsOnlyPlaceholders('%s'),
      'Neither has a lone %s.');
    Check(TPlaceholderProtection.IsOnlyPlaceholders('%d - %d'),
      'Nor two numbers and a dash.');
    Check(not TPlaceholderProtection.IsOnlyPlaceholders('%d files'),
      'But a string with a word in it is sent.');
    Check(not TPlaceholderProtection.IsOnlyPlaceholders('Play'),
      'and so is one with no specifiers at all.');
    Check(not TPlaceholderProtection.IsOnlyPlaceholders(''),
      'An empty string is not treated as a format.');

    Writeln;
    Writeln('=== judging a round trip ===');

    Check(TPlaceholderProtection.Matches('%d of %d', '%d von %d'),
      'A translation that kept its specifiers is accepted.');
    Check(TPlaceholderProtection.Matches('%s: %d', '%d :%s'),
      'Reordering is allowed - a translator may put the number first.');
    { Exactly what Arabic did. }
    Check(not TPlaceholderProtection.Matches(
      '%.2f GB used / %.2f GB free of %.2f GB (%.1f%%)',
      '0.2f / 0.2f (0.1f%)'),
      'The real Arabic damage is recognised as damage.');
    Check(not TPlaceholderProtection.Matches('%.2d/%.2d', '0.2d/0.2d'),
      'and so is the date format it broke.');
    Check(not TPlaceholderProtection.Matches('%d of %d', '%d'),
      'A translation that lost one is not accepted.');

    Writeln;
    Writeln('=== a specifier that is not one ===');
    Check(TPlaceholderProtection.Matches('100% cotton', '100% coton'),
      'A percent that begins nothing is not a specifier and is left alone.');

    if Failures = 0 then
    begin
      Writeln('Placeholder protection smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Placeholder protection smoke tests failed: %d',
      [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
