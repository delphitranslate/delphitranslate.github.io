program HyphenationSmokeTests;

{ Whether a long word can be broken, and whether the breaks are in defensible
  places.

  Soft hyphens are invisible until a line actually has to break at one, so the
  test cannot look at a screen to judge them - it has to read the marks
  directly. That is what this does: it asks for the breaks, prints the word
  with them shown as ordinary hyphens so a person can see what was decided,
  and checks the rules that must hold in every language. }

{$APPTYPE CONSOLE}

uses
  System.JSON,
  System.SysUtils,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.RuntimePack in '..\..\source\core\DAT.Core.RuntimePack.pas',
  DAT.Core.Hyphenation in '..\..\source\core\DAT.Core.Hyphenation.pas';

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

{ The marks made visible, for a person reading the test output. }
function Shown(const AText: string): string;
begin
  Result := StringReplace(AText, SoftHyphen, '-', [rfReplaceAll]);
end;

function BreakCount(const AText: string): Integer;
var
  Character: Char;
begin
  Result := 0;
  for Character in AText do
    if Character = SoftHyphen then
      Inc(Result);
end;

{ A caption long enough to need breaking, and a format string that must not
  be touched, put through the runtime pack the way a real one goes. }
procedure CheckThePack;
var
  Catalog: TTranslationCatalog;
  Entry: TTranslationEntry;
  Pack: string;
  Root: TJSONObject;
  Caption: string;
  Template: string;
  Source: string;

  procedure Add(const AKey, AText, ATranslated: string;
    const ARole: TRuntimeTextRole);
  begin
    Entry := TTranslationEntry.Create;
    Entry.Key := AKey;
    Entry.SourceText := AText;
    Entry.TranslatedText := ATranslated;
    Entry.FormName := 'frmMain';
    Entry.ComponentName := 'lblOne';
    Entry.ComponentClassName := 'TLabel';
    Entry.PropertyName := 'Caption';
    Entry.SourceKind := 'dfm';
    Entry.SourceFileName := 'Main.dfm';
    Entry.SourceChecksum := 'abc';
    Entry.Status := tsReviewed;
    Entry.RuntimeTextRole := ARole;
    Entry.RuntimeApplication := rakAutomatic;
    Entry.RuntimeWiringConfirmed := True;
    Catalog.Entries.Add(Entry);
  end;

begin
  Catalog := TTranslationCatalog.Create;
  try
    Catalog.ApplicationId := 'Carillon';
    Catalog.ApplicationVersion := '1.0';
    Catalog.SourceLanguage := 'en-US';
    Catalog.Locale.LanguageCode := 'de-DE';
    Catalog.Framework := tfVCL;
    Catalog.Locale.NativeLanguageName := 'Deutsch';
    Catalog.Locale.TextDirection := 'ltr';
    Catalog.Locale.ShortDateFormat := 'dd.mm.yyyy';
    Catalog.Locale.LongDateFormat := 'dddd, d. mmmm yyyy';
    Catalog.Locale.ShortTimeFormat := 'hh:nn';
    Catalog.Locale.LongTimeFormat := 'hh:nn:ss';
    Catalog.Locale.DecimalSeparator := ',';
    Catalog.Locale.ThousandSeparator := '.';
    Catalog.Locale.CurrencySymbol := 'EUR';
    Add('frmMain.lblOne.Caption', 'Notification Settings',
      'Benachrichtigungseinstellungen', rtrStaticText);
    Add('frmMain.lblTwo.Caption', '%s files',
      '%s Benachrichtigungseinstellungen', rtrRuntimeTemplate);
    try
      Pack := TRuntimePackBuilder.Serialize(Catalog);
    except
      on E: Exception do
      begin
        Writeln('  pack could not be built: ', E.Message);
        Inc(Failures);
        Exit;
      end;
    end;
    { The pack is JSON, and JSON writes a soft hyphen as an escape, so the
      marks have to be read back out rather than looked for in the text. }
    Root := TJSONObject.ParseJSONValue(Pack) as TJSONObject;
    try
      { Values[] rather than GetValue<>: a key with a dot in it is read as a
        path by the latter, and every key in a pack has dots. }
      Caption := (Root.Values['strings'] as TJSONObject)
        .Values['frmMain.lblOne.Caption'].Value;
      Template := (Root.Values['templates'] as TJSONObject)
        .Values['frmMain.lblTwo.Caption'].Value;
      Source := (Root.Values['sources'] as TJSONObject)
        .Values['frmMain.lblOne.Caption'].Value;
      Writeln('  pack caption : ', Shown(Caption));
      Writeln('  pack template: ', Shown(Template));
      Check(ContainsText(Caption, SoftHyphen),
        'A caption in the runtime pack carries its break marks.');
      Check(not ContainsText(Template, SoftHyphen),
        'A format string is left exactly as the translator wrote it.');
      Check(Source = 'Notification Settings',
        'The English source text is never marked.');
    finally
      Root.Free;
    end;
  finally
    Catalog.Free;
  end;
end;

var
  German: TDATHyphenationDictionary;
  Spanish: TDATHyphenationDictionary;
  Marked: string;
begin
  try
    Check(TDATHyphenation.EnsureInstalled('de-DE'),
      'Adding German installs its companion hyphenation dictionary.');
    Check(TDATHyphenation.EnsureInstalled('es-ES'),
      'And Spanish installs its own.');
    Writeln('  dictionaries in ', TDATHyphenation.Directory);
    Writeln;

    German := TDATHyphenation.Load('de-DE');
    Spanish := TDATHyphenation.Load('es-ES');
    try
      Check(German <> nil, 'The German dictionary loads.');
      Check(Spanish <> nil, 'The Spanish dictionary loads.');

      Marked := German.Hyphenate('Benachrichtigungseinstellungen');
      Writeln('  German : ', Shown(Marked));
      Check(BreakCount(Marked) >= 3,
        'A thirty-letter German compound is given somewhere to break.');
      Check(not StartsText(SoftHyphen, Marked),
        'Never at the very start.');
      Check(not EndsText(SoftHyphen, Marked),
        'Never at the very end.');
      Check(not ContainsText(Marked, 'sc' + SoftHyphen + 'h'),
        'And never inside sch, which is one sound.');

      Marked := German.Hyphenate('Spielverabredungen');
      Writeln('  German : ', Shown(Marked));
      Check(BreakCount(Marked) >= 2, 'The playdates word can break too.');

      Marked := Spanish.Hyphenate('reproduciendo');
      Writeln('  Spanish: ', Shown(Marked));
      Check(BreakCount(Marked) >= 2, 'A long Spanish word can break.');

      Marked := Spanish.Hyphenate('desarrollo');
      Writeln('  Spanish: ', Shown(Marked));
      Check(not ContainsText(Marked, 'r' + SoftHyphen + 'r'),
        'Spanish rr is one letter and is never split.');

      { An umlaut is a vowel, and a dictionary that has lost its umlauts
        treats it as a consonant and breaks in the wrong places. The letter is
        written as an escape here for the same reason it is in the dictionary
        itself: a Pascal source without a byte order mark is read in the ANSI
        codepage, and the character would arrive wrong. }
      Marked := German.Hyphenate('W' + #$00E4 + 'rmeversorgungsanlagen');
      Writeln('  German : ', Shown(Marked));
      Check(ContainsText(Marked, 'W' + #$00E4 + 'r' + SoftHyphen),
        'An umlaut counts as a vowel, so the word breaks after it.');

      Writeln;
      Check(German.Hyphenate('Zeit') = 'Zeit',
        'A short word is left exactly as it is.');
      Check(German.Hyphenate('E-Mail-Einstellungen') = 'E-Mail-Einstellungen',
        'A word already hyphenated by its author is left alone.');

      Marked := German.HyphenateText('Die Benachrichtigungseinstellungen '
        + 'sind hier.');
      Writeln('  sentence: ', Shown(Marked));
      Check(ContainsText(Marked, SoftHyphen),
        'A sentence has its long words marked.');
      Check(ContainsText(Marked, 'Die ') and ContainsText(Marked, ' sind '),
        'and its short ones and spacing untouched.');

      Writeln;
      CheckThePack;
    finally
      Spanish.Free;
      German.Free;
    end;

    if Failures = 0 then
    begin
      Writeln('Hyphenation smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Hyphenation smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
