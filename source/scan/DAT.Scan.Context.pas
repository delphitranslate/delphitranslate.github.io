unit DAT.Scan.Context;

interface

uses
  DAT.Scan.Types;

type
  TScanContextAnalyzer = class
  public
    class procedure Analyze(const AItem: TScanItem); static;
    { Everything the scan knows that one item cannot know on its own: what the
      application is about, and what stands beside this control. Run once the
      scan is complete. }
    class procedure Enrich(const AResult: TProjectScanResult;
      const AApplicationName: string); static;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils;

function ContainsAny(const AValue: string;
  const AParts: array of string): Boolean;
var
  Part: string;
begin
  Result := False;
  for Part in AParts do
    if ContainsText(AValue, Part) then
      Exit(True);
end;

class procedure TScanContextAnalyzer.Analyze(const AItem: TScanItem);
var
  Identity: string;
  TextValue: string;
begin
  if AItem = nil then
    Exit;
  Identity := LowerCase(AItem.FormName + ' ' + AItem.ComponentName + ' ' +
    AItem.ComponentClassName + ' ' + AItem.PropertyName);
  TextValue := LowerCase(Trim(StringReplace(AItem.SourceText, '&', '',
    [rfReplaceAll])));
  AItem.ContextConfidence := 'inferred';
  AItem.SemanticConcept := '';

  if SameText(AItem.PropertyName, 'resourcestring') or
    ContainsText(AItem.PropertyName, 'DialogMessage') then
    AItem.ContextKind := 'runtime message'
  else if ContainsAny(AItem.ComponentClassName,
    ['button', 'menuitem', 'action']) then
    AItem.ContextKind := 'user command'
  else if ContainsAny(AItem.ComponentClassName,
    ['combobox', 'listbox', 'radiobutton', 'checkbox']) or
    ContainsText(AItem.PropertyName, 'items') then
    AItem.ContextKind := 'selectable option'
  else if ContainsAny(Identity, ['title', 'heading', 'header']) then
    AItem.ContextKind := 'heading'
  else if ContainsAny(AItem.PropertyName, ['textprompt', 'prompt', 'hint']) then
    AItem.ContextKind := 'input prompt or tooltip'
  else if ContainsText(Identity, 'status') then
    AItem.ContextKind := 'status message'
  else
    AItem.ContextKind := 'interface text';

  if MatchText(TextValue, ['open', 'open...']) then
    AItem.SemanticConcept := 'command.open'
  else if MatchText(TextValue, ['close', 'close window']) then
    AItem.SemanticConcept := 'command.close'
  else if SameText(TextValue, 'save and close') then
    AItem.SemanticConcept := 'command.saveClose'
  else if SameText(TextValue, 'save') then
    AItem.SemanticConcept := 'command.save'
  else if SameText(TextValue, 'cancel') then
    AItem.SemanticConcept := 'command.cancel'
  else if SameText(TextValue, 'activate') then
    AItem.SemanticConcept := 'command.activate'
  else if SameText(TextValue, 'enable') then
    AItem.SemanticConcept := 'command.enable'
  else if SameText(TextValue, 'schedule') then
  begin
    if ContainsText(AItem.ComponentClassName, 'menuitem') then
      AItem.SemanticConcept := 'noun.schedule'
    else if SameText(AItem.ContextKind, 'user command') then
      AItem.SemanticConcept := 'command.schedule'
    else
      AItem.SemanticConcept := 'noun.schedule';
  end
  else if SameText(TextValue, 'show remaining schedule') then
    AItem.SemanticConcept := 'media.showRemainingSchedule'
  else if MatchText(TextValue, ['language', 'language:']) then
    AItem.SemanticConcept := 'noun.language'
  else if SameText(TextValue, 'open all') then
    AItem.SemanticConcept := 'command.openAll'
  else if SameText(TextValue, 'close all') then
    AItem.SemanticConcept := 'command.closeAll'
  else if SameText(TextValue, 'play') then
  begin
    if ContainsAny(Identity, ['music', 'audio', 'song', 'bell', 'carillon',
      'media', 'playlist', 'sound']) then
      AItem.SemanticConcept := 'media.play'
    else if ContainsAny(Identity, ['game', 'player', 'poker']) then
      AItem.SemanticConcept := 'game.play'
    else if ContainsAny(Identity, ['instrument', 'piano', 'organ']) then
      AItem.SemanticConcept := 'instrument.play'
    else
    begin
      AItem.SemanticConcept := 'ambiguous.play';
      AItem.ContextConfidence := 'unknown';
    end;
  end
  else if SameText(TextValue, 'move') then
    AItem.SemanticConcept := 'command.move'
  else if SameText(TextValue, 'exit') then
    AItem.SemanticConcept := 'command.exit'
  else if SameText(TextValue, 'help') then
    AItem.SemanticConcept := 'command.help'
  else if SameText(TextValue, 'settings') then
    AItem.SemanticConcept := 'command.settings'
  else if SameText(TextValue, 'properties') then
    AItem.SemanticConcept := 'command.properties'
  else if MatchText(TextValue, ['add', 'delete', 'save', 'cancel']) then
    AItem.SemanticConcept := 'command.' + TextValue
  else if MatchText(TextValue, ['mon', 'monday']) then
    AItem.SemanticConcept := 'calendar.monday'
  else if MatchText(TextValue, ['tue', 'tues', 'tuesday']) then
    AItem.SemanticConcept := 'calendar.tuesday'
  else if MatchText(TextValue, ['wed', 'wednesday']) then
    AItem.SemanticConcept := 'calendar.wednesday'
  else if MatchText(TextValue, ['thu', 'thur', 'thurs', 'thursday']) then
    AItem.SemanticConcept := 'calendar.thursday'
  else if MatchText(TextValue, ['fri', 'friday']) then
    AItem.SemanticConcept := 'calendar.friday'
  else if MatchText(TextValue, ['sat', 'saturday']) then
    AItem.SemanticConcept := 'calendar.saturday'
  else if MatchText(TextValue, ['sun', 'sunday']) then
    AItem.SemanticConcept := 'calendar.sunday'
  else if MatchText(TextValue, ['play schedule', 'play schedules']) then
    AItem.SemanticConcept := 'media.playSchedule'
  else if MatchText(TextValue, ['play date:', 'play dates:']) then
    AItem.SemanticConcept := 'media.playDates'
  else if MatchText(TextValue, ['play time:', 'play times:',
    'play time(s):']) then
    AItem.SemanticConcept := 'media.playTime'
  else if SameText(TextValue, 'time') then
    AItem.SemanticConcept := 'media.clockTime'
  else if SameText(TextValue, 'type') then
    AItem.SemanticConcept := 'noun.type'
  else if SameText(TextValue, 'song') then
    AItem.SemanticConcept := 'media.song'
  else if SameText(TextValue, 'song/purpose') then
    AItem.SemanticConcept := 'media.songPurpose'
  else if MatchText(TextValue, ['times to play:', 'number of times to play:']) then
    AItem.SemanticConcept := 'media.timesToPlay'
  else if SameText(TextValue, 'play on the following days:') then
    AItem.SemanticConcept := 'media.playFollowingDays'
  else if MatchText(TextValue, ['play date from', 'play date from:']) then
    AItem.SemanticConcept := 'media.playDateFrom'
  else if MatchText(TextValue, ['play date to', 'play date to:']) then
    AItem.SemanticConcept := 'media.playDateTo'
  else if MatchText(TextValue, ['play time', 'play time:']) then
    AItem.SemanticConcept := 'media.playTime'
  else if SameText(TextValue, 'group') or SameText(TextValue, 'group:') then
    AItem.SemanticConcept := 'noun.group'
  else if SameText(TextValue, 'pause') then
    AItem.SemanticConcept := 'media.pause'
  else if SameText(TextValue, 'stop') then
    AItem.SemanticConcept := 'media.stop'
  else if SameText(TextValue, 'playing') then
    AItem.SemanticConcept := 'media.playing'
  else if SameText(TextValue, 'paused') then
    AItem.SemanticConcept := 'media.paused'
  else if SameText(TextValue, 'stopped') then
    AItem.SemanticConcept := 'media.stopped'
  else if SameText(TextValue, 'refresh') then
    AItem.SemanticConcept := 'command.refresh'
  else if SameText(TextValue, 'themes') then
    AItem.SemanticConcept := 'noun.themes'
  else if SameText(TextValue, 'song name') then
    AItem.SemanticConcept := 'media.songName'
  else if SameText(TextValue, 'duration') then
    AItem.SemanticConcept := 'media.duration'
  else if SameText(TextValue, 'date / time') then
    AItem.SemanticConcept := 'calendar.dateTime'
  else if SameText(TextValue, 'event') then
    AItem.SemanticConcept := 'noun.event'
  else if SameText(TextValue, 'schedule enabled') then
    AItem.SemanticConcept := 'schedule.enabled'
  else if SameText(TextValue, 'schedule disabled') then
    AItem.SemanticConcept := 'schedule.disabled'
  else if ContainsText(TextValue, 'uptime:') and ContainsText(TextValue, '%d') then
    AItem.SemanticConcept := 'runtime.uptime';

  if AItem.SemanticConcept <> '' then
    AItem.ContextDescription := Format(
      'Text used as %s in a desktop application. Meaning: %s.',
      [AItem.ContextKind, StringReplace(AItem.SemanticConcept, '.', ' ',
        [rfReplaceAll])])
  else
    AItem.ContextDescription := Format(
      'Text used as %s in a desktop application.', [AItem.ContextKind]);
end;

{ What kind of thing this control is, said plainly enough to be useful to a
  translator who cannot see the screen. }
function ControlDescription(const AItem: TScanItem): string;
var
  ClassText: string;
  PropertyText: string;
begin
  ClassText := LowerCase(AItem.ComponentClassName);
  PropertyText := LowerCase(AItem.PropertyName);

  if ContainsText(PropertyText, 'title.caption') or
    ContainsText(ClassText, 'column') then
    Exit('the heading of a column in a data grid');
  if ContainsText(PropertyText, 'hint') then
    Exit('the tooltip of a control');
  if ContainsText(ClassText, 'menuitem') then
    Exit('an item on a menu');
  if ContainsText(ClassText, 'button') then
    Exit('the caption of a button the user presses');
  if ContainsText(ClassText, 'checkbox') or
    ContainsText(ClassText, 'radiobutton') then
    Exit('the caption beside a tick box');
  if ContainsText(ClassText, 'groupbox') or ContainsText(ClassText, 'panel') then
    Exit('the heading of a group of controls');
  if ContainsText(PropertyText, 'items') or ContainsText(PropertyText, 'lines') then
    Exit('one entry in a list the user chooses from');
  if ContainsText(ClassText, 'label') or ContainsText(ClassText, 'text') then
    Exit('a caption on a form, usually naming the field beside or below it');
  if ContainsText(ClassText, 'form') then
    Exit('the title of a window');
  Result := 'text shown on a form';
end;

{ The subject the application is about, read from everything it says.

  One string on its own tells a translator nothing: "Play Date From" could be
  a database column in a scheduler or a note about children visiting. All the
  other words on all the other forms settle it, and they cost nothing to
  gather because the scan has already read them. }
function DomainSummary(const AResult: TProjectScanResult): string;
var
  Item: TScanItem;
  Corpus: string;
  Subjects: TStringList;

  procedure Note(const AWords, ASubject: array of string);
  var
    Word: string;
  begin
    for Word in AWords do
      if ContainsText(Corpus, Word) then
      begin
        if Subjects.IndexOf(ASubject[0]) < 0 then
          Subjects.Add(ASubject[0]);
        Exit;
      end;
  end;

begin
  Result := '';
  if AResult = nil then
    Exit;
  Corpus := '';
  for Item in AResult.Items do
    Corpus := Corpus + ' ' + LowerCase(Item.SourceText);

  Subjects := TStringList.Create;
  try
    Note(['song', 'music', 'audio', 'volume', 'chime', 'bell', 'carillon',
      'playlist', 'mp3'], ['playing recorded music']);
    Note(['schedule', 'scheduling', 'calendar', 'weekday', 'monday',
      'recurring'], ['scheduling events by date and time']);
    Note(['invoice', 'customer', 'order', 'payment', 'account'],
      ['business records']);
    Note(['patient', 'clinic', 'diagnosis'], ['clinical records']);
    Note(['email', 'smtp', 'recipient'], ['sending email']);
    Note(['backup', 'restore', 'archive'], ['backing up data']);
    if Subjects.Count = 0 then
      Exit('');
    Subjects.Delimiter := ';';
    Result := StringReplace(Subjects.DelimitedText, ';', ' and ',
      [rfReplaceAll]);
    Result := StringReplace(Result, '"', '', [rfReplaceAll]);
  finally
    Subjects.Free;
  end;
end;

{ A word that means different things in different applications, with the sense
  this one uses. The provider is told outright rather than left to guess: told
  nothing, it read "Play Date From" as an afternoon arranged between children
  and produced Spielverabredungen for a column of broadcast times. }
function AmbiguityNote(const AText, ADomain: string): string;
begin
  Result := '';
  if ContainsText(ADomain, 'recorded music') then
  begin
    if ContainsText(AText, 'play') then
      Result := Result + ' Here "play" means to play a sound recording, ' +
        'never a game and never a theatre play.';
  end;
  if ContainsText(AText, 'close') then
    Result := Result + ' Here "close" is the action of shutting a window, ' +
      'not the adjective meaning nearby.';
  if ContainsText(AText, 'record') then
    Result := Result + ' Here "record" is a stored row of data unless the ' +
      'surrounding words say otherwise.';
  Result := Trim(Result);
end;

class procedure TScanContextAnalyzer.Enrich(const AResult: TProjectScanResult;
  const AApplicationName: string);
var
  Domain: string;
  Item: TScanItem;
  Neighbour: TScanItem;
  Neighbours: string;
  Note: string;
  Sentence: string;
  Count: Integer;
begin
  if AResult = nil then
    Exit;
  Domain := DomainSummary(AResult);

  for Item in AResult.Items do
  begin
    if Trim(Item.SourceText) = '' then
      Continue;

    Sentence := Format('This is %s', [ControlDescription(Item)]);
    if Trim(AApplicationName) <> '' then
      Sentence := Sentence + Format(' in %s', [Trim(AApplicationName)]);
    if Domain <> '' then
      Sentence := Sentence + Format(', an application for %s', [Domain]);
    Sentence := Sentence + '.';

    if Trim(Item.FormName) <> '' then
      Sentence := Sentence + Format(' It appears on the %s screen.',
        [Item.FormName]);

    { The other headings of the same grid say more about a column than any
      description could. }
    if ContainsText(LowerCase(Item.PropertyName), 'title.caption') then
    begin
      Neighbours := '';
      Count := 0;
      for Neighbour in AResult.Items do
        if (Neighbour <> Item) and
          SameText(Neighbour.FormName, Item.FormName) and
          SameText(Neighbour.ComponentName, Item.ComponentName) and
          ContainsText(LowerCase(Neighbour.PropertyName), 'title.caption') and
          (Trim(Neighbour.SourceText) <> '') and (Count < 6) then
        begin
          if Neighbours <> '' then
            Neighbours := Neighbours + ', ';
          Neighbours := Neighbours + Neighbour.SourceText;
          Inc(Count);
        end;
      if Neighbours <> '' then
        Sentence := Sentence + Format(
          ' The other columns of the same grid are: %s.', [Neighbours]);
      Sentence := Sentence + ' Keep it short: it has to fit a column heading.';
    end;

    if Item.SemanticConcept <> '' then
      Sentence := Sentence + Format(' Meaning: %s.',
        [StringReplace(Item.SemanticConcept, '.', ' ', [rfReplaceAll])]);

    Note := AmbiguityNote(LowerCase(Item.SourceText), Domain);
    if Note <> '' then
      Sentence := Sentence + ' ' + Note;

    Item.ContextDescription := Sentence;
  end;
end;

end.