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
    if SameText(AItem.ContextKind, 'user command') then
      AItem.SemanticConcept := 'command.schedule'
    else
      AItem.SemanticConcept := 'noun.schedule';
  end
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
    AItem.SemanticConcept := 'command.properties';

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
