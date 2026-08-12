unit DAT.Scan.Quality;

interface

uses
  DAT.Scan.Types;

type
  TScanQualityAnalyzer = class
  public
    class procedure Analyze(const AItem: TScanItem); static;
  end;

implementation

uses
  System.Character,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.Types;

function HasRepeatedCharacterRun(const AText: string): Boolean;
var
  CurrentRun: Integer;
  Index: Integer;
begin
  Result := False;
  CurrentRun := 1;
  for Index := 2 to Length(AText) do
  begin
    if AText[Index].IsLetterOrDigit and
      SameText(AText[Index], AText[Index - 1]) then
      Inc(CurrentRun)
    else
      CurrentRun := 1;
    if CurrentRun >= 8 then
      Exit(True);
  end;
end;

function HasLongUnbrokenToken(const AText: string): Boolean;
var
  CurrentRun: Integer;
  CharacterValue: Char;
begin
  Result := False;
  CurrentRun := 0;
  for CharacterValue in AText do
  begin
    if CharacterValue.IsWhiteSpace then
      CurrentRun := 0
    else
      Inc(CurrentRun);
    if CurrentRun >= 64 then
      Exit(True);
  end;
end;

function LooksLikeControlName(const AText: string): Boolean;
const
  Prefixes: array[0..10] of string = ('lbl', 'btn', 'edt', 'cmb', 'cbo',
    'mem', 'frm', 'pnl', 'tab', 'chk', 'rdo');
var
  Prefix: string;
begin
  Result := False;
  if Pos(' ', Trim(AText)) > 0 then
    Exit;
  for Prefix in Prefixes do
    if StartsText(Prefix, AText) and (Length(AText) > Length(Prefix)) then
      Exit(True);
end;

class procedure TScanQualityAnalyzer.Analyze(const AItem: TScanItem);
var
  LowerText: string;
begin
  if AItem = nil then
    Exit;
  AItem.SuspiciousReason := '';
  LowerText := LowerCase(Trim(AItem.SourceText));
  if HasRepeatedCharacterRun(AItem.SourceText) then
    AItem.SuspiciousReason := 'Contains a repeated-character run that resembles accidental input.'
  else if HasLongUnbrokenToken(AItem.SourceText) then
    AItem.SuspiciousReason := 'Contains an unusually long unbroken token.'
  else if LooksLikeControlName(Trim(AItem.SourceText)) then
    AItem.SuspiciousReason := 'Looks like an internal Delphi control name exposed to users.'
  else if ContainsText(LowerText, 'lorem ipsum') or
    MatchText(LowerText, ['todo', 'tbd', 'test text', 'placeholder']) then
    AItem.SuspiciousReason := 'Looks like placeholder or test text.'
  else if StartsText('your ', LowerText) and ContainsText(LowerText, ' here') then
    AItem.SuspiciousReason := 'Looks like setup placeholder text; confirm whether it is user-visible.';

  if AItem.SuspiciousReason <> '' then
    AItem.TextOwnership := tokSuspicious
  else if AItem.Kind = stkRuntimeAssignment then
    AItem.TextOwnership := tokRuntimeUnwired
  else if AItem.RuntimeTextRole in [rtrDataValue, rtrIdentifier] then
    AItem.TextOwnership := tokApplicationData
  else if AItem.RuntimeTextRole = rtrExcluded then
    AItem.TextOwnership := tokExcluded
  else
    AItem.TextOwnership := tokDesignerAutomatic;
end;

end.
