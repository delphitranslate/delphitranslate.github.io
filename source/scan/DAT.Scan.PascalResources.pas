unit DAT.Scan.PascalResources;

interface

uses
  DAT.Scan.Types;

type
  TPascalResourceStringScanner = class
  public
    class procedure ScanFile(const AFileName: string;
      const AResult: TProjectScanResult); static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.Types,
  DAT.Scan.TextCodec;

function IsSectionBoundary(const ALine: string): Boolean;
var
  FirstWord: string;
  SpacePosition: Integer;
begin
  FirstWord := LowerCase(Trim(ALine));
  SpacePosition := Pos(' ', FirstWord);
  if SpacePosition > 0 then
    FirstWord := Copy(FirstWord, 1, SpacePosition - 1);
  Result := (FirstWord = 'const') or (FirstWord = 'type') or
    (FirstWord = 'var') or (FirstWord = 'threadvar') or
    (FirstWord = 'implementation') or (FirstWord = 'procedure') or
    (FirstWord = 'function') or (FirstWord = 'begin');
end;

function FindStatementTerminator(const AText: string): Integer;
var
  InString: Boolean;
  Index: Integer;
begin
  Result := 0;
  InString := False;
  Index := 1;
  while Index <= Length(AText) do
  begin
    if AText[Index] = '''' then
    begin
      if InString and (Index < Length(AText)) and
        (AText[Index + 1] = '''') then
        Inc(Index)
      else
        InString := not InString;
    end
    else if (AText[Index] = ';') and not InString then
      Exit(Index);
    Inc(Index);
  end;
end;

function ReadUnitName(const ALines: TStrings;
  const AFileName: string): string;
var
  LineText: string;
begin
  Result := TPath.GetFileNameWithoutExtension(AFileName);
  for LineText in ALines do
    if StartsText('unit ', Trim(LineText)) then
    begin
      Result := Trim(Copy(Trim(LineText), 6, MaxInt));
      if EndsText(';', Result) then
        Delete(Result, Length(Result), 1);
      Exit;
    end;
end;

procedure AddResourceItem(const AResult: TProjectScanResult;
  const AFileName, AUnitName, AStatement: string;
  const ASourceLine: Integer);
var
  EqualsPosition: Integer;
  Expression: string;
  ScanItem: TScanItem;
  SymbolName: string;
  ValueText: string;
begin
  EqualsPosition := Pos('=', AStatement);
  if EqualsPosition = 0 then
    Exit;

  SymbolName := Trim(Copy(AStatement, 1, EqualsPosition - 1));
  Expression := Trim(Copy(AStatement, EqualsPosition + 1, MaxInt));
  if EndsText(';', Expression) then
    Delete(Expression, Length(Expression), 1);
  if (SymbolName = '') or
    not TryDecodeDelphiStringExpression(Expression, ValueText) or
    (ValueText = '') then
    Exit;

  ScanItem := TScanItem.Create;
  ScanItem.Key := AUnitName + '.' + SymbolName;
  ScanItem.SourceText := ValueText;
  ScanItem.ComponentName := SymbolName;
  ScanItem.PropertyName := 'resourcestring';
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := ASourceLine;
  ScanItem.CollectionIndex := -1;
  ScanItem.Framework := tfUnknown;
  ScanItem.Kind := stkResourceString;
  AResult.Items.Add(ScanItem);
end;

class procedure TPascalResourceStringScanner.ScanFile(
  const AFileName: string; const AResult: TProjectScanResult);
var
  InResourceStrings: Boolean;
  LineIndex: Integer;
  Lines: TStringList;
  SourceLine: Integer;
  Statement: string;
  TerminatorPosition: Integer;
  TrimmedLine: string;
  UnitName: string;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    UnitName := ReadUnitName(Lines, AFileName);
    InResourceStrings := False;
    Statement := '';
    SourceLine := 0;

    for LineIndex := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[LineIndex]);
      if not InResourceStrings then
      begin
        if SameText(TrimmedLine, 'resourcestring') then
          InResourceStrings := True;
        Continue;
      end;

      if (Statement = '') and IsSectionBoundary(TrimmedLine) then
      begin
        InResourceStrings := False;
        Continue;
      end;

      if (TrimmedLine = '') or StartsText('//', TrimmedLine) then
        Continue;

      if Statement = '' then
      begin
        Statement := TrimmedLine;
        SourceLine := LineIndex + 1;
      end
      else
        Statement := Statement + ' ' + TrimmedLine;

      TerminatorPosition := FindStatementTerminator(Statement);
      if TerminatorPosition > 0 then
      begin
        AddResourceItem(AResult, AFileName, UnitName,
          Copy(Statement, 1, TerminatorPosition), SourceLine);
        Statement := Trim(Copy(Statement, TerminatorPosition + 1, MaxInt));
      end;
    end;
  finally
    Lines.Free;
  end;
end;

end.
