unit DAT.Scan.Context;

interface

uses
  DAT.Scan.Types;

type
  TScanContextAnalyzer = class
  public
    class procedure Analyze(const AItem: TScanItem); static;
  end;

implementation

uses
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

  if SameText(AItem.PropertyName, 'resourcestring') then
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

end.
