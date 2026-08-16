unit DAT.Scan.TextCodec;

interface

uses
  System.Classes;

procedure LoadDelphiTextFile(const AFileName: string; const ALines: TStrings);

function TryDecodeDelphiStringExpression(const AExpression: string;
  out AValue: string): Boolean;

implementation

uses
  System.IOUtils,
  System.SysUtils;

procedure LoadDelphiTextFile(const AFileName: string; const ALines: TStrings);
var
  Bytes: TBytes;
  Encoding: TEncoding;
  PreambleLength: Integer;
  Text: string;
begin
  if ALines = nil then
    raise EArgumentNilException.Create('A target line list is required.');

  Bytes := TFile.ReadAllBytes(AFileName);
  if Length(Bytes) = 0 then
  begin
    ALines.Clear;
    Exit;
  end;

  Encoding := nil;
  PreambleLength := TEncoding.GetBufferEncoding(Bytes, Encoding, nil);
  if Encoding <> nil then
    Text := Encoding.GetString(Bytes, PreambleLength,
      Length(Bytes) - PreambleLength)
  else
  begin
    try
      Text := TEncoding.UTF8.GetString(Bytes);
    except
      Text := TEncoding.Default.GetString(Bytes);
    end;
  end;
  ALines.Text := Text;
end;

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
