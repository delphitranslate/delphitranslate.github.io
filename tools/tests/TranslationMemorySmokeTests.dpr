program TranslationMemorySmokeTests;

{ The translation memory, and the round trip through TMX and TBX.

  A memory is not a dictionary. A dictionary holds agreed terms; a memory holds
  whole segments, so the second application that asks "Are you sure you want to
  delete this item?" gets the wording the first one settled rather than paying
  to have it translated again and possibly differently.

  What matters most here is the line between a match that may be applied
  without a human and one that may not. An exact match, and a match differing
  only in spacing or case, are the same segment. Anything else is a suggestion,
  and a memory that quietly substitutes an almost-right sentence is worse than
  one that says nothing, because nobody reviews what they were not told about.

  The interchange half is checked by round trip: what goes out must come back,
  including the characters XML has opinions about. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.Glossary in '..\..\source\core\DAT.Core.Glossary.pas',
  DAT.Core.TranslationMemory in '..\..\source\core\DAT.Core.TranslationMemory.pas',
  DAT.Core.Interchange in '..\..\source\core\DAT.Core.Interchange.pas';

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

procedure AddEntry(const ACatalog: TTranslationCatalog;
  const ASource, ATranslated: string; const AStatus: TTranslationStatus);
var
  Entry: TTranslationEntry;
begin
  Entry := TTranslationEntry.Create;
  Entry.Key := 'frm.' + IntToStr(ACatalog.Entries.Count) + '.Caption';
  Entry.SourceText := ASource;
  Entry.TranslatedText := ATranslated;
  Entry.Status := AStatus;
  ACatalog.Entries.Add(Entry);
end;

const
  Sentence = 'Are you sure you want to delete this item?';
  German = 'Sind Sie sicher, dass Sie dieses Element loeschen moechten?';
  Awkward = 'Save & Close <all> "now"';
  AwkwardGerman = 'Speichern & Schliessen <alle> "jetzt"';

var
  Memory: TTranslationMemory;
  Imported: TTranslationMemory;
  Match: TMemoryMatch;
  Catalog: TTranslationCatalog;
  Glossary: TProjectGlossary;
  Restored: TProjectGlossary;
  Term: TProjectGlossaryTerm;
  Folder, TmxFile, TbxFile: string;
  Count_: Integer;
begin
  try
    Folder := TPath.Combine(TPath.GetTempPath, 'dat-memory-tests');
    TDirectory.CreateDirectory(Folder);
    TmxFile := TPath.Combine(Folder, 'memory.tmx');
    TbxFile := TPath.Combine(Folder, 'terms.tbx');

    Writeln;
    Writeln('=== what may be applied without a human, and what may not ===');
    Memory := TTranslationMemory.Create('de-DE');
    try
      Check(Memory.Remember(Sentence, German, 'FirstApp', '2026-08-22'),
        'A segment is remembered.');
      Check(not Memory.Remember(Sentence, 'Etwas anderes', 'SecondApp',
        '2026-08-22'),
        'and a later application does not silently rewrite it.');

      Match := Memory.Lookup(Sentence);
      Check(Match.Kind = mmkExact, 'The same string matches exactly.');
      Check(Match.Applies and (Match.TranslatedText = German),
        'and may be applied.');

      Match := Memory.Lookup('  Are you sure   you want to delete this item? ');
      Check(Match.Kind = mmkNormalized,
        'Different spacing is the same segment.');
      Check(Match.Applies, 'and may still be applied.');

      Match := Memory.Lookup('ARE YOU SURE YOU WANT TO DELETE THIS ITEM?');
      Check(Match.Kind = mmkNormalized, 'So is different case.');
      Check(Match.TranslatedText = Match.TranslatedText.ToUpper,
        'and the answer takes the source''s capitalization.');

      Match := Memory.Lookup('Are you sure you want to delete this file?');
      Writeln(Format('        one word different scored %d', [Match.Score]));
      Check(Match.Kind = mmkSimilar,
        'A sentence one word different is offered as a suggestion.');
      Check(not Match.Applies,
        'and must NOT be applied - that distinction is the whole point.');

      Match := Memory.Lookup('Print the monthly summary');
      Check(Match.Kind = mmkNone, 'Something unrelated matches nothing.');

      Match := Memory.Lookup('');
      Check(Match.Kind = mmkNone, 'An empty string matches nothing.');

      Writeln;
      Writeln('=== only reviewed work is contributed ===');
      Catalog := TTranslationCatalog.Create;
      try
        Catalog.ApplicationId := 'ThirdApp';
        AddEntry(Catalog, 'Open the file', 'Datei oeffnen', tsApproved);
        AddEntry(Catalog, 'Close the file', 'Datei schliessen', tsReviewed);
        AddEntry(Catalog, 'Rename the file', 'Datei umbenennen', tsEdited);
        AddEntry(Catalog, 'Delete the file', 'Datei loeschen',
          tsMachineTranslated);
        AddEntry(Catalog, 'Copy the file', 'Datei kopieren',
          tsNeedsTranslation);
        Count_ := Memory.RememberCatalog(Catalog, '2026-08-22');
        Writeln(Format('        contributed %d of 5 entries', [Count_]));
        Check(Count_ = 3,
          'Approved, reviewed and edited work is contributed.');
        Check(Memory.Lookup('Delete the file').Kind = mmkNone,
          'Machine output is not, because a memory of unreviewed guesses ' +
          'spreads one bad translation everywhere.');
      finally
        Catalog.Free;
      end;

      Writeln;
      Writeln('=== TMX round trip ===');
      Memory.Remember(Awkward, AwkwardGerman, 'FirstApp', '2026-08-22');
      Count_ := TTmxInterchange.Export_(Memory, TmxFile, 'en-US');
      Writeln(Format('        exported %d segment(s)', [Count_]));
      Check(Count_ = Memory.Units.Count, 'Every segment was written out.');
      Check(TFile.Exists(TmxFile), 'The TMX file exists.');
    finally
      Memory.Free;
    end;

    Imported := TTranslationMemory.Create('de-DE');
    try
      Count_ := TTmxInterchange.Import_(Imported, TmxFile, 'en-US',
        'Imported', '2026-08-22');
      Writeln(Format('        imported %d segment(s)', [Count_]));
      Check(Count_ = 5, 'Everything that went out came back.');

      Match := Imported.Lookup(Sentence);
      Check(Match.Applies and (Match.TranslatedText = German),
        'A segment survives the round trip intact.');

      Match := Imported.Lookup(Awkward);
      Writeln('        awkward: ', Match.TranslatedText);
      Check(Match.Applies and (Match.TranslatedText = AwkwardGerman),
        'and so do the characters XML has opinions about: & < > and quotes.');

      Check(Imported.Lookup('Delete the file').Kind = mmkNone,
        'What was never remembered is still not there.');

      { A second import of the same file adds nothing, which is what makes it
        safe to point at a folder of files and let it run. }
      Count_ := TTmxInterchange.Import_(Imported, TmxFile, 'en-US',
        'Imported', '2026-08-22');
      Check(Count_ = 0, 'Importing the same file twice adds nothing.');
    finally
      Imported.Free;
    end;

    Writeln;
    Writeln('=== TBX round trip ===');
    Glossary := TProjectGlossary.Create;
    try
      Glossary.ApplicationId := 'TermSample';
      Glossary.SourceLanguage := 'en-US';
      Glossary.TargetLanguage := 'de-DE';
      Term := TProjectGlossaryTerm.Create;
      Term.SourceText := 'Playlist';
      Term.TargetText := 'Wiedergabeliste';
      Term.Approved := True;
      Glossary.Terms.Add(Term);
      Term := TProjectGlossaryTerm.Create;
      Term.SourceText := 'Save & Exit';
      Term.TargetText := 'Speichern & Beenden';
      Term.Approved := True;
      Glossary.Terms.Add(Term);

      Count_ := TTbxInterchange.Export_(Glossary, TbxFile);
      Check(Count_ = 2, 'Both terms were written out.');
    finally
      Glossary.Free;
    end;

    Restored := TProjectGlossary.Create;
    try
      Restored.SourceLanguage := 'en-US';
      Restored.TargetLanguage := 'de-DE';
      Count_ := TTbxInterchange.Import_(Restored, TbxFile);
      Writeln(Format('        imported %d term(s)', [Count_]));
      Check(Count_ = 2, 'Both came back.');
      Check((Restored.Terms.Count = 2) and
        (Restored.Terms[0].SourceText = 'Playlist') and
        (Restored.Terms[0].TargetText = 'Wiedergabeliste'),
        'with their source and target intact.');
      Check(Restored.Terms[1].SourceText = 'Save & Exit',
        'and an ampersand survives the round trip.');

      Count_ := TTbxInterchange.Import_(Restored, TbxFile);
      Check(Count_ = 0, 'A term already known is left as it is.');
    finally
      Restored.Free;
    end;

    Writeln;
    Writeln('=== a language nobody has used loads empty rather than failing ===');
    Imported := TTranslationMemory.Load('zz-Never-Used');
    try
      Check(Imported <> nil, 'It loads.');
      Check(Imported.Units.Count = 0, 'and holds nothing.');
      Check(Imported.Lookup('anything').Kind = mmkNone,
        'and matches nothing, rather than faulting.');
    finally
      Imported.Free;
    end;

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Translation memory smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Translation memory smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
