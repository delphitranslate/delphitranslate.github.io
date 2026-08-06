unit DAT.Scan.TextCodec;

interface

function TryDecodeDelphiStringExpression(const AExpression: string;
  out AValue: string): Boolean;

implementation

uses
  System.SysUtils;

function TryDecodeDelphiStringExpression(const AExpression: string;
  out AValue: string): Boolean;
var
  CharacterCode: Integer;
  CodeText: string;
  Index: Integer;
  StartIndex: Integer;
begin
  Result := False;
  AValue := '';
  Index := 1;

  while Index <= Length(AExpression) do
  begin
    while (Index <= Length(AExpression)) and
      CharInSet(AExpression[Index], [' ', #9, '+']) do
      Inc(Index);
    if Index > Length(AExpression) then
      Break;

    if AExpression[Index] = '''' then
    begin
      Inc(Index);
      while Index <= Length(AExpression) do
      begin
        if AExpression[Index] = '''' then
        begin
          if (Index < Length(AExpression)) and
            (AExpression[Index + 1] = '''') then
          begin
            AValue := AValue + '''';
            Inc(Index, 2);
          end
          else
          begin
            Inc(Index);
            Break;
          end;
        end
        else
        begin
          AValue := AValue + AExpression[Index];
          Inc(Index);
        end;
      end;
      Continue;
    end;

    if AExpression[Index] = '#' then
    begin
      Inc(Index);
      StartIndex := Index;
      if (Index <= Length(AExpression)) and (AExpression[Index] = '$') then
      begin
        Inc(Index);
        while (Index <= Length(AExpression)) and
          CharInSet(AExpression[Index], ['0'..'9', 'A'..'F', 'a'..'f']) do
          Inc(Index);
        CodeText := Copy(AExpression, StartIndex + 1,
          Index - StartIndex - 1);
        if not TryStrToInt('$' + CodeText, CharacterCode) then
          Exit;
      end
      else
      begin
        while (Index <= Length(AExpression)) and
          CharInSet(AExpression[Index], ['0'..'9']) do
          Inc(Index);
        CodeText := Copy(AExpression, StartIndex, Index - StartIndex);
        if not TryStrToInt(CodeText, CharacterCode) then
          Exit;
      end;
      AValue := AValue + Char(CharacterCode);
      Continue;
    end;

    Exit;
  end;

  Result := True;
end;

end.
