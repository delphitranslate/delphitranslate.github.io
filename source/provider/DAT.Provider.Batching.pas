unit DAT.Provider.Batching;

{ Grouping strings by the context they share.

  A translation service takes one context per request. The first attempt here
  batched fifty strings and concatenated all fifty of their contexts into that
  one field, so every string arrived wearing forty-nine descriptions of other
  controls. The context was generated, sent, and diluted into uselessness -
  the likeliest reason an Arabic run still returned "Help" as a verb, which
  means "he helps".

  Billing is per translated character, not per request. Sending each string on
  its own therefore costs exactly what batching costs: the whole of Carillon is
  6,471 characters either way. What it buys is a context that actually belongs
  to the string it is attached to. The price is round trips - a minute for an
  application, once per language, for a result that is then stored for ever.

  So strings are grouped by identical context. Where a context is unique the
  group holds one string; where many strings share a context, or have none,
  they still travel together as before. }

interface

type
  { One request: the context to send with it, and which of the caller's
    strings belong to it. Indexes are into the original array so the answers
    can be put back where they came from. }
  TContextGroup = record
    Context: string;
    Indexes: TArray<Integer>;
  end;

  TContextBatching = record
  public
    { Strings longer than AIndividualContextLimit are grouped together
      instead of each opening a request of its own. Pass 0 to give every
      string its own context regardless of length. }
    class function Group(const ATexts, AContexts: TArray<string>;
      const AMaximumBatchSize: Integer;
      const AIndividualContextLimit: Integer = 60):
      TArray<TContextGroup>; static;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils;

const
  { Deliberately a sentence rather than an empty string: the strings that
    land here are prose, and saying so is still worth more than saying
    nothing. }
  LongStringContext =
    'Body text shown in a desktop application interface.';

class function TContextBatching.Group(const ATexts, AContexts: TArray<string>;
  const AMaximumBatchSize: Integer;
  const AIndividualContextLimit: Integer): TArray<TContextGroup>;
var
  Groups: TList<TContextGroup>;
  OpenGroup: TDictionary<string, Integer>;
  Index: Integer;
  Context: string;
  Position: Integer;
  Entry: TContextGroup;
  Ceiling: Integer;
begin
  Ceiling := AMaximumBatchSize;
  if Ceiling < 1 then
    Ceiling := 1;

  Groups := TList<TContextGroup>.Create;
  { Which group is currently taking strings for a given context. A group that
    reaches the ceiling is closed and forgotten, so the next string with that
    context opens a fresh one. }
  OpenGroup := TDictionary<string, Integer>.Create;
  try
    for Index := 0 to High(ATexts) do
    begin
      if Index <= High(AContexts) then
        Context := AContexts[Index]
      else
        Context := '';

      { A long string is its own context. Forty words of prose tell a
        service far more about themselves than any description of the
        control they sit on, so isolating them buys nothing and costs a
        round trip each. Precision matters for the short ones - Help,
        Close, Play, a bare day abbreviation - where there is nothing to
        go on but the description. Long strings therefore share one
        context and travel together, which is what they did before
        per-string context existed. }
      if (AIndividualContextLimit > 0) and
        (Length(ATexts[Index]) > AIndividualContextLimit) then
        Context := LongStringContext;

      if not OpenGroup.TryGetValue(Context, Position) then
      begin
        Entry.Context := Context;
        SetLength(Entry.Indexes, 0);
        Groups.Add(Entry);
        Position := Groups.Count - 1;
        OpenGroup.AddOrSetValue(Context, Position);
      end;

      Entry := Groups[Position];
      SetLength(Entry.Indexes, Length(Entry.Indexes) + 1);
      Entry.Indexes[High(Entry.Indexes)] := Index;
      Groups[Position] := Entry;

      if Length(Entry.Indexes) >= Ceiling then
        OpenGroup.Remove(Context);
    end;
    Result := Groups.ToArray;
  finally
    OpenGroup.Free;
    Groups.Free;
  end;
end;

end.
