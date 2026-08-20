program ContextBatchingSmokeTests;

{ How strings are grouped when each one carries its own context.

  DeepL takes one `context` per request, not one per string. The first
  implementation batched fifty strings and concatenated all fifty of their
  contexts into that single field, so "Help" arrived with forty-nine
  descriptions of other controls attached to it. The context was present,
  paid for in nothing, and diluted into uselessness - which is the likeliest
  reason the Arabic run still returned "Help" as a verb meaning "he helps".

  Billing is per translated character, not per request. Sending each string on
  its own therefore costs exactly what batching costs - 6,471 characters for
  the whole of Carillon either way - and buys a context that actually applies
  to the string it is attached to. The only price is round trips, once per
  language, for a result that is then stored.

  So strings are grouped by the context they share. Identical contexts still
  travel together; different ones do not. This exercises the grouping alone,
  with no service involved. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  DAT.Provider.Batching in '..\..\source\provider\DAT.Provider.Batching.pas';

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

function Describe(const AGroups: TArray<TContextGroup>): string;
var
  Group: TContextGroup;
begin
  Result := '';
  for Group in AGroups do
  begin
    if Result <> '' then
      Result := Result + '  ';
    Result := Result + Format('[%d:%s]', [Length(Group.Indexes),
      Copy(Group.Context, 1, 12)]);
  end;
end;

var
  Groups: TArray<TContextGroup>;
  Texts: TArray<string>;
  Contexts: TArray<string>;
  Total: Integer;
  Group: TContextGroup;
begin
  try
    Writeln;
    Writeln('=== every string has its own context ===');
    Texts := ['Help', 'Close', 'Play'];
    Contexts := ['a menu item', 'a button', 'a button on a media bar'];
    Groups := TContextBatching.Group(Texts, Contexts, 50);
    Writeln('  groups: ', Describe(Groups));
    Check(Length(Groups) = 3,
      'Three different contexts make three requests, not one blurred one.');
    Check((Length(Groups[0].Indexes) = 1) and (Groups[0].Indexes[0] = 0),
      'and each carries the one string it belongs to.');
    Check(Groups[0].Context = 'a menu item',
      'with that string''s own context, undiluted.');

    Writeln;
    Writeln('=== strings that share a context still travel together ===');
    Texts := ['One', 'Two', 'Three', 'Four'];
    Contexts := ['same', 'same', 'other', 'same'];
    Groups := TContextBatching.Group(Texts, Contexts, 50);
    Writeln('  groups: ', Describe(Groups));
    Check(Length(Groups) = 2,
      'Two distinct contexts make two requests, however the strings are ordered.');
    Total := 0;
    for Group in Groups do
      Total := Total + Length(Group.Indexes);
    Check(Total = 4, 'and no string is lost or sent twice.');
    for Group in Groups do
      if Group.Context = 'same' then
        Check(Length(Group.Indexes) = 3,
          'Strings sharing a context are gathered even when not adjacent.');

    Writeln;
    Writeln('=== no context at all ===');
    Texts := ['One', 'Two', 'Three'];
    Contexts := ['', '', ''];
    Groups := TContextBatching.Group(Texts, Contexts, 50);
    Writeln('  groups: ', Describe(Groups));
    Check(Length(Groups) = 1,
      'Strings with nothing to say about them are batched as before.');

    Writeln;
    Writeln('=== the batch ceiling still holds ===');
    SetLength(Texts, 120);
    SetLength(Contexts, 120);
    for Total := 0 to 119 do
    begin
      Texts[Total] := IntToStr(Total);
      Contexts[Total] := '';
    end;
    Groups := TContextBatching.Group(Texts, Contexts, 50);
    Writeln('  groups: ', Describe(Groups));
    Check(Length(Groups) = 3,
      'A hundred and twenty identical contexts still respect the batch size.');
    Check(Length(Groups[0].Indexes) = 50, 'and fill each batch before opening another.');

    Writeln;
    Writeln('=== nothing to do ===');
    SetLength(Texts, 0);
    SetLength(Contexts, 0);
    Groups := TContextBatching.Group(Texts, Contexts, 50);
    Check(Length(Groups) = 0, 'An empty request makes no groups.');

    if Failures = 0 then
    begin
      Writeln('Context batching smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Context batching smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
