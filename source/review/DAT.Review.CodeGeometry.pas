unit DAT.Review.CodeGeometry;

{ Which controls the application positions or sizes itself.

  Carillon centres its main heading in code, once, at start-up:

    lblMainHeader.Left := (Screen.Width - lblMainHeader.Width) div 2;

  The planner knew nothing of that. It read the designer geometry - Left 303,
  Width 545 - proposed Left 286 and Width 579, and overwrote a decision the
  application had already made. Returning to the source language then restored
  the designed 303 rather than the centre the application had computed, and
  that line never runs again, so nothing put it right.

  The numbers were not wrong. 303 + 545/2 and 286 + 579/2 are both 575.5, so
  the caption's own centre was held exactly. They were simply answers to a
  question the application had already answered differently.

  So the rule is: a control whose geometry is assigned in code gets its text
  translated and its geometry left alone. Reading the source unit beside the
  form is enough to know which those are, and the same reading works for both
  frameworks because the syntax being looked for is Pascal rather than VCL or
  FireMonkey.

  This is deliberately literal. It looks for an assignment to a geometry
  property of a named identifier and nothing cleverer: no expression analysis,
  no following of variables, no with-statements. A control it fails to
  recognise is treated as it was before, which is the behaviour that has been
  shipping; a control it recognises wrongly loses only the layout adjustments,
  and its text is still translated. Both directions fail softly. }

interface

uses
  System.Classes;

type
  TCodeGeometry = record
  public
    { The component names whose geometry is assigned somewhere in the Pascal
      unit belonging to a form file. Caller owns the list. Empty when there is
      no such unit, which is the ordinary case for a form nobody lays out by
      hand. }
    class function ControlsPositionedInCode(
      const AFormFileName: string): TStringList; static;
    { Component/property pairs assigned by the form's Pascal unit, written as
      Component.Property. This lets the planner respect the coordinate the
      application owns without needlessly surrendering the other three. }
    class function PropertiesAssignedInCode(
      const AFormFileName: string): TStringList; static;
  end;

implementation

uses
  System.Character,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils;

const
  { The properties that decide where a control is and how big. FireMonkey
    spells two of them differently and means the same thing. }
  GeometryProperties: array[0..7] of string = (
    'Left', 'Top', 'Width', 'Height',
    'Position.X', 'Position.Y',
    'BoundsRect', 'Align');

{ The identifier immediately before a dot, reading backwards from APosition.
  "lblMainHeader.Left := ..." at the dot gives lblMainHeader. A qualified name
  such as Self.lblHeading or frmMain.lblHeading gives the last part, which is
  the component name the planner knows it by. }
function IdentifierBefore(const ALine: string; const APosition: Integer): string;
var
  Index: Integer;
  First: Integer;
begin
  Result := '';
  Index := APosition;
  while (Index >= 1) and (ALine[Index] <= ' ') do
    Dec(Index);
  First := Index;
  while (First >= 1) and (ALine[First].IsLetterOrDigit or
    (ALine[First] = '_')) do
    Dec(First);
  if First >= Index then
    Exit;
  Result := Copy(ALine, First + 1, Index - First);
end;

{ Everything before a comment or a string on this line, so that a mention
  inside either is not mistaken for code. }
function CodeOnly(const ALine: string): string;
var
  Index: Integer;
  InString: Boolean;
begin
  Result := ALine;
  InString := False;
  for Index := 1 to Length(ALine) do
  begin
    if ALine[Index] = '''' then
      InString := not InString
    else if not InString then
    begin
      if (ALine[Index] = '{') or
        ((ALine[Index] = '/') and (Index < Length(ALine)) and
         (ALine[Index + 1] = '/')) or
        ((ALine[Index] = '(') and (Index < Length(ALine)) and
         (ALine[Index + 1] = '*')) then
        Exit(Copy(ALine, 1, Index - 1));
    end;
  end;
end;

class function TCodeGeometry.ControlsPositionedInCode(
  const AFormFileName: string): TStringList;
var
  Assigned: TStringList;
  Item: string;
  DotAt: Integer;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Assigned := PropertiesAssignedInCode(AFormFileName);
  try
    for Item in Assigned do
    begin
      DotAt := Pos('.', Item);
      if (DotAt > 1) and (Result.IndexOf(Copy(Item, 1, DotAt - 1)) < 0) then
        Result.Add(Copy(Item, 1, DotAt - 1));
    end;
  finally
    Assigned.Free;
  end;
end;

class function TCodeGeometry.PropertiesAssignedInCode(
  const AFormFileName: string): TStringList;
var
  UnitFileName: string;
  Lines: TStringList;
  Line: string;
  Trimmed: string;
  PropertyName: string;
  At: Integer;
  Assignment: Integer;

  procedure Note(const AName, AProperty: string);
  begin
    if (AName <> '') and (AProperty <> '') and
      (Result.IndexOf(AName + '.' + AProperty) < 0) then
      Result.Add(AName + '.' + AProperty);
  end;

  procedure NoteAll(const AName: string);
  begin
    Note(AName, 'Left');
    Note(AName, 'Top');
    Note(AName, 'Width');
    Note(AName, 'Height');
  end;

begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  try
    UnitFileName := TPath.ChangeExtension(AFormFileName, '.pas');
    if not TFile.Exists(UnitFileName) then
      Exit;

    Lines := TStringList.Create;
    try
      try
        Lines.LoadFromFile(UnitFileName);
      except
        { A unit that cannot be read tells us nothing, which is the same as a
          unit that says nothing. }
        Exit;
      end;

      for Line in Lines do
      begin
        Trimmed := CodeOnly(Line);
        if Trimmed = '' then
          Continue;

        Assignment := Pos(':=', Trimmed);

        { Name.Property := something }
        if Assignment > 1 then
          for PropertyName in GeometryProperties do
          begin
            At := Pos('.' + PropertyName, Trimmed, 1);
            while (At > 0) and (At < Assignment) do
            begin
              { The property must be what is being assigned, not part of a
                longer word and not on the right-hand side. }
              if (At + Length(PropertyName) + 1 > Length(Trimmed)) or
                not (Trimmed[At + Length(PropertyName) + 1].IsLetterOrDigit or
                     (Trimmed[At + Length(PropertyName) + 1] = '_')) then
              begin
                if SameText(PropertyName, 'Position.X') then
                  Note(IdentifierBefore(Trimmed, At - 1), 'Left')
                else if SameText(PropertyName, 'Position.Y') then
                  Note(IdentifierBefore(Trimmed, At - 1), 'Top')
                else if SameText(PropertyName, 'BoundsRect') or
                  SameText(PropertyName, 'Align') then
                  NoteAll(IdentifierBefore(Trimmed, At - 1))
                else
                  Note(IdentifierBefore(Trimmed, At - 1), PropertyName);
              end;
              At := Pos('.' + PropertyName, Trimmed, At + 1);
            end;
          end;

        { Name.SetBounds(...) says all four at once. }
        At := Pos('.SetBounds', Trimmed);
        while At > 0 do
        begin
          NoteAll(IdentifierBefore(Trimmed, At - 1));
          At := Pos('.SetBounds', Trimmed, At + 1);
        end;
      end;
    finally
      Lines.Free;
    end;
  except
    { Never let a reading of somebody else's source stop a translation. }
  end;
end;

end.
