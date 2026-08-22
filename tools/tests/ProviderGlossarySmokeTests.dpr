program ProviderGlossarySmokeTests;

{ What may be handed to a service to enforce, and what may not.

  A glossary held on the service's side binds it: for the pairs it supports,
  a term comes back the way it was agreed rather than the way the engine would
  otherwise have rendered it. That is stronger than describing terminology in
  a context field and hoping.

  Which is exactly why the filtering matters. Everything in a project glossary
  is a suggestion; only some of it is safe to make binding, and one bad entry
  can take the whole upload down with it. These checks are on the decision, not
  on the HTTP, because the decision is the part most likely to be wrong. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  DAT.Core.Types in '..\..\source\core\DAT.Core.Types.pas',
  DAT.Core.Glossary in '..\..\source\core\DAT.Core.Glossary.pas',
  DAT.Provider.Glossary in '..\..\source\provider\DAT.Provider.Glossary.pas';

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

procedure AddTerm(const AGlossary: TProjectGlossary;
  const ASource, ATarget: string; const AApproved: Boolean);
var
  Term: TProjectGlossaryTerm;
begin
  Term := TProjectGlossaryTerm.Create;
  Term.SourceText := ASource;
  Term.TargetText := ATarget;
  Term.Approved := AApproved;
  AGlossary.Terms.Add(Term);
end;

function Has(const AEntries: TArray<TGlossaryEntry>;
  const ASource: string): Boolean;
var
  Entry: TGlossaryEntry;
begin
  for Entry in AEntries do
    if SameText(Entry.SourceTerm, ASource) then
      Exit(True);
  Result := False;
end;

var
  Glossary: TProjectGlossary;
  Entries: TArray<TGlossaryEntry>;
  Wire: string;
begin
  try
    Glossary := TProjectGlossary.Create;
    try
      Glossary.SourceLanguage := 'en-US';
      Glossary.TargetLanguage := 'de-DE';

      AddTerm(Glossary, 'Playlist', 'Wiedergabeliste', True);
      AddTerm(Glossary, 'Schedule', 'Zeitplan', True);
      { Not approved: a guess offered once is useful, a guess enforced for ever
        is not. }
      AddTerm(Glossary, 'Volume', 'Lautstaerke', False);
      { A format specifier matched as glossary text invites the engine to move
        or duplicate it. }
      AddTerm(Glossary, '%d items', '%d Elemente', True);
      { A tab would break the entry after this one rather than this one. }
      AddTerm(Glossary, 'Two' + #9 + 'columns', 'Zwei Spalten', True);
      AddTerm(Glossary, 'Line' + #13#10 + 'break', 'Zeilenumbruch', True);
      { Punctuation is not terminology. }
      AddTerm(Glossary, '---', '---', True);
      { Half an entry is no entry. }
      AddTerm(Glossary, 'Orphan', '', True);
      AddTerm(Glossary, '', 'Waise', True);
      { DeepL rejects the whole upload for one duplicated source term. }
      AddTerm(Glossary, 'playlist', 'Abspielliste', True);

      Entries := TProviderGlossary.Eligible(Glossary);
      Writeln;
      Writeln(Format('=== %d of %d terms may be enforced ===',
        [Length(Entries), Glossary.Terms.Count]));

      Check(Has(Entries, 'Playlist') and Has(Entries, 'Schedule'),
        'An approved, plain term is sent.');
      Check(not Has(Entries, 'Volume'),
        'An unapproved term is not.');
      Check(not Has(Entries, '%d items'),
        'Neither is one carrying a format specifier.');
      Check(not Has(Entries, 'Two' + #9 + 'columns'),
        'Nor one carrying a tab, which would break the next entry.');
      Check(not Has(Entries, 'Line' + #13#10 + 'break'),
        'Nor one carrying a line break.');
      Check(not Has(Entries, '---'),
        'Nor punctuation, which is not terminology.');
      Check(not Has(Entries, 'Orphan'),
        'Nor a term with no translation.');
      Check(Length(Entries) = 2,
        Format('Two survive, not %d - and the duplicate source was dropped ' +
          'rather than left to fail the whole upload.', [Length(Entries)]));

      Writeln;
      Writeln('=== the wire format ===');
      Wire := TProviderGlossary.ToTabSeparated(Entries);
      Writeln('        ', StringReplace(StringReplace(Wire, #9, ' -> ',
        [rfReplaceAll]), #10, ' | ', [rfReplaceAll]));
      Check(ContainsStr(Wire, 'Playlist' + #9 + 'Wiedergabeliste'),
        'One entry per line, source, tab, target.');
      Check(Length(Wire) - Length(StringReplace(Wire, #10, '',
        [rfReplaceAll])) = 1,
        'Two entries make one separator, not a trailing one.');
      Check(TProviderGlossary.ToTabSeparated(nil) = '',
        'Nothing eligible produces nothing, rather than an empty glossary.');
    finally
      Glossary.Free;
    end;

    Writeln;
    Writeln('=== only the pairs the service actually supports ===');
    Check(TProviderGlossary.SupportsPair('en-US', 'de-DE'),
      'English to German is supported, region and all.');
    Check(TProviderGlossary.SupportsPair('en', 'fr'),
      'and so is the bare pair.');
    Check(not TProviderGlossary.SupportsPair('en-US', 'ar-SA'),
      'A pair the service has no glossary for is known before the request, ' +
      'not after it is refused.');
    Check(not TProviderGlossary.SupportsPair('de-DE', 'ja-JP'),
      'and so is a pair that exists in neither direction.');

    Writeln;
    if Failures = 0 then
    begin
      Writeln('Provider glossary smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Provider glossary smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
