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
  System.SysUtils,
  DAT.Scan.DomainProfile;

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
{ What part of speech the string has to be.

  A button says what pressing it will do, so its caption is an instruction:
  Save, Close, Play. A menu item names a thing. A column heading names what is
  under it. English hides the difference because its imperative and its
  dictionary form are the same word, and a service asked to translate "Help"
  with nothing else to go on will happily return a statement - Arabic gave
  back the third person singular, "he helps", for Help, Close and Play alike.
  Grammatical, and useless on a button.

  Every string already knows its control class, so this costs nothing to say
  and is exactly the kind of thing a context field is for. }
function GrammarNote(const AItem: TScanItem): string;
var
  ClassText: string;
  PropertyText: string;
begin
  ClassText := LowerCase(AItem.ComponentClassName);
  PropertyText := LowerCase(AItem.PropertyName);

  if ContainsText(PropertyText, 'title.caption') or
    ContainsText(ClassText, 'column') then
    Exit('Translate it as a noun or a short noun phrase naming what the ' +
      'column contains, not as a sentence.');
  if ContainsText(ClassText, 'menuitem') then
    Exit('Translate it the way a menu item is written in the target ' +
      'language - usually a noun, and in the form that language uses for ' +
      'menus rather than a statement about someone acting.');
  if ContainsText(ClassText, 'button') or ContainsText(ClassText, 'action') then
    Exit('It is a command the user gives, so translate it as an imperative ' +
      'in the form that language uses on buttons - never as a statement ' +
      'such as "he closes" or "it plays".');
  if ContainsText(ClassText, 'checkbox') or
    ContainsText(ClassText, 'radiobutton') then
    Exit('Translate it as the name of an option that can be turned on or ' +
      'off, not as a sentence.');
  if ContainsText(ClassText, 'groupbox') or ContainsText(ClassText, 'panel') then
    Exit('Translate it as a heading naming the group, not as a sentence.');
  if ContainsText(PropertyText, 'hint') then
    Exit('It is a tooltip, so a short phrase or sentence is right.');
  Result := '';
end;

{ ---------------------------------------------------------------------------
  What the whole application knows, said for one string.

  The domain used to be recognised from a list of six subjects. It is now read
  from the application itself - see DAT.Scan.DomainProfile - because no list
  covers a file utility, a laboratory system, a point of sale and a CAD
  package, and the ones it misses are the majority.
  --------------------------------------------------------------------------- }

class procedure TScanContextAnalyzer.Enrich(const AResult: TProjectScanResult;
  const AApplicationName: string);
var
  Profile: TApplicationDomainProfile;
  Item: TScanItem;
  Neighbour: TScanItem;
  Neighbours: string;
  Note: string;
  Sentence: string;
  Count: Integer;
begin
  if AResult = nil then
    Exit;

  Profile := TDomainProfiler.Profile(AResult, AApplicationName);
  try
    for Item in AResult.Items do
    begin
      if Trim(Item.SourceText) = '' then
        Continue;

      Sentence := Format('This is %s', [ControlDescription(Item)]);
      if Profile.ApplicationName <> '' then
        Sentence := Sentence + Format(' in %s', [Profile.ApplicationName]);
      Sentence := Sentence + '.';

      if Trim(Item.FormName) <> '' then
        Sentence := Sentence + Format(' It appears on the %s screen.',
          [Item.FormName]);

      { What the application is about, in its own words rather than in a
        category somebody chose in advance. }
      if Profile.VocabularySentence <> '' then
        Sentence := Sentence + ' ' + Profile.VocabularySentence;

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

      { And which sense this application means by any word in the string that
        has more than one. This is the part that stops "Play Date From"
        becoming an afternoon arranged between children. }
      Note := Profile.SensesWithin(Item.SourceText);
      if Note <> '' then
        Sentence := Sentence + ' ' + Note;

      { What kind of word it has to come back as. }
      Note := GrammarNote(Item);
      if Note <> '' then
        Sentence := Sentence + ' ' + Note;

      Item.ContextDescription := Sentence;
    end;
  finally
    Profile.Free;
  end;
end;

end.
