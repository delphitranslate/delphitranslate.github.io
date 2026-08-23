unit DAT.Scan.TextCodec;

interface

uses
  System.Classes;

procedure LoadDelphiTextFile(const AFileName: string; const ALines: TStrings);

{ Undo one round of mis-decoded UTF-8.

  Text encoded as UTF-8 and then read back as Windows-1252 comes out with each
  non-ASCII character replaced by the two or three characters its bytes happen
  to spell in that code page. The German for Close arrived in a glossary as
  Schlie + U+00C3 + U+0178 + en, which is the two bytes of a sharp s read one
  at a time, and every translation the glossary touched inherited it.

  The damage is exactly reversible: put the characters back as Windows-1252
  bytes and read them as UTF-8 again. That only succeeds when the text really
  was mis-decoded, which is what makes it safe to attempt on everything - a
  German word that legitimately contains an A-tilde does not survive the round
  trip and is returned untouched. }
function RepairMisdecodedText(const AText: string): string;

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


function RepairMisdecodedText(const AText: string): string;
var
  Encoding1252: TEncoding;
  Bytes: TBytes;
  Decoded: string;
  Index: Integer;
  Suspect: Boolean;
begin
  Result := AText;
  if AText = '' then
    Exit;
  { Mis-decoded UTF-8 always begins its damage with one of the lead-byte
    characters, so text without any of them cannot be damaged and is not put
    through the round trip. This is also what keeps Arabic and Vietnamese out
    of a code page that cannot hold them. }
  Suspect := False;
  for Index := 1 to Length(AText) do
    if CharInSet(AText[Index], [#$00C2, #$00C3, #$00C4, #$00C5]) then
    begin
      Suspect := True;
      Break;
    end;
  if not Suspect then
    Exit;
  Encoding1252 := TEncoding.GetEncoding(1252);
  try
    try
      Bytes := Encoding1252.GetBytes(AText);
      { A round trip that loses anything was never a mis-decoding of this code
        page, so there is nothing here to undo. }
      if Encoding1252.GetString(Bytes) <> AText then
        Exit;
    except
      { A character this code page cannot hold means the same thing. }
      on EEncodingError do
        Exit;
    end;
  finally
    Encoding1252.Free;
  end;
  Decoded := TEncoding.UTF8.GetString(Bytes);
  if (Decoded = '') or (Decoded = AText) then
    Exit;
  { Invalid UTF-8 decodes to replacement characters, and ordinary text read
    this way is invalid UTF-8. Their presence means this was not damage. }
  if Pos(#$FFFD, Decoded) > 0 then
    Exit;
  Result := Decoded;
end;

end.
