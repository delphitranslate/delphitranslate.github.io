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
  System.Generics.Collections,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  DAT.Core.Types,
  DAT.Scan.TextCodec,
  DAT.Scan.Context,
  DAT.Scan.Quality;

type
  TRuntimeStatement = record
    SourceLine: Integer;
    Text: string;
  end;

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
  ScanItem.RuntimeTextRole := rtrRuntimeTemplate;
  TScanContextAnalyzer.Analyze(ScanItem);
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

function LastIdentifier(const AValue: string): string;
var
  DotAt: Integer;
begin
  Result := Trim(AValue);
  DotAt := LastDelimiter('.', Result);
  if DotAt > 0 then
    Result := Trim(Copy(Result, DotAt + 1, MaxInt));
end;

function IsRuntimeTextProperty(const APropertyName: string): Boolean;
begin
  Result := MatchText(APropertyName,
    ['Text', 'Caption', 'Header', 'Hint', 'TextPrompt', 'Title',
     'Description']);
end;

function FirstArgument(const AExpression: string): string;
var
  Depth: Integer;
  InString: Boolean;
  Index: Integer;
begin
  Result := Trim(AExpression);
  Depth := 0;
  InString := False;
  for Index := 1 to Length(AExpression) do
  begin
    if AExpression[Index] = '''' then
    begin
      if InString and (Index < Length(AExpression)) and
        (AExpression[Index + 1] = '''') then
        Continue;
      InString := not InString;
    end
    else if not InString then
      case AExpression[Index] of
        '(', '[': Inc(Depth);
        ')', ']': if Depth > 0 then Dec(Depth);
        ',': if Depth = 0 then Exit(Trim(Copy(AExpression, 1, Index - 1)));
      end;
  end;
end;

function ExtractLiteralPhrase(const AExpression: string;
  out APhrase: string): Boolean;
var
  Decoded: string;
  EndAt: Integer;
  Index: Integer;
  Segment: string;
  StartAt: Integer;
begin
  APhrase := '';
  Index := 1;
  while Index <= Length(AExpression) do
  begin
    if AExpression[Index] <> '''' then
    begin
      Inc(Index);
      Continue;
    end;
    StartAt := Index;
    Inc(Index);
    while Index <= Length(AExpression) do
    begin
      if AExpression[Index] = '''' then
      begin
        if (Index < Length(AExpression)) and (AExpression[Index + 1] = '''') then
          Inc(Index, 2)
        else
          Break;
      end
      else
        Inc(Index);
    end;
    EndAt := Index;
    Segment := Copy(AExpression, StartAt, EndAt - StartAt + 1);
    if TryDecodeDelphiStringExpression(Segment, Decoded) then
      APhrase := APhrase + Decoded;
    Inc(Index);
  end;
  APhrase := Trim(APhrase);
  Result := APhrase <> '';
end;

procedure AddRuntimeItem(const AResult: TProjectScanResult;
  const AFileName, AUnitName, ALeftSide, APropertyName, ASourceText: string;
  const ASourceLine: Integer; const ARuntimeRole: TRuntimeTextRole); forward;

procedure ScanRuntimeCall(const AStatement: TRuntimeStatement;
  const AResult: TProjectScanResult; const AFileName, AUnitName,
  ACallName, APropertyName: string);
var
  ArgumentText: string;
  CallAt: Integer;
  Phrase: string;
  StartAt: Integer;
begin
  CallAt := Pos(LowerCase(ACallName + '('), LowerCase(AStatement.Text));
  if CallAt = 0 then
    Exit;
  StartAt := CallAt + Length(ACallName) + 1;
  if SameText(APropertyName, 'OwnerDrawText') then
    ArgumentText := Copy(AStatement.Text, StartAt, MaxInt)
  else
    ArgumentText := FirstArgument(Copy(AStatement.Text, StartAt, MaxInt));
  if TryDecodeDelphiStringExpression(ArgumentText, Phrase) or
    ExtractLiteralPhrase(ArgumentText, Phrase) then
    AddRuntimeItem(AResult, AFileName, AUnitName,
      ACallName, APropertyName, Phrase, AStatement.SourceLine,
      rtrRuntimeTemplate);
end;

function IsNonUiAssignment(const ALeftSide, ASourceText: string): Boolean;
var
  LowerLeft: string;
  LowerText: string;
begin
  LowerLeft := LowerCase(StringReplace(ALeftSide, ' ', '', [rfReplaceAll]));
  LowerText := LowerCase(Trim(ASourceText));
  Result := ContainsText(LowerLeft, '.sql.') or
    EndsText('.sql.text', LowerLeft) or
    StartsText('select ', LowerText) or StartsText('update ', LowerText) or
    StartsText('insert ', LowerText) or StartsText('delete ', LowerText) or
    StartsText('pragma ', LowerText) or ContainsText(LowerText, '<tr') or
    ContainsText(LowerText, '<td');
end;

procedure ScanHtmlText(const AStatement: TRuntimeStatement;
  const AResult: TProjectScanResult; const AFileName, AUnitName: string);
var
  CloseAt: Integer;
  Decoded: string;
  OpenAt: Integer;
  Segment: string;
  StartAt: Integer;
  TextValue: string;
begin
  if not ContainsText(AStatement.Text, '<') or
    not ExtractLiteralPhrase(AStatement.Text, Decoded) then
    Exit;
  StartAt := 1;
  while StartAt <= Length(Decoded) do
  begin
    OpenAt := PosEx('>', Decoded, StartAt);
    if OpenAt = 0 then
      Break;
    CloseAt := PosEx('<', Decoded, OpenAt + 1);
    if CloseAt = 0 then
      Break;
    Segment := Trim(Copy(Decoded, OpenAt + 1, CloseAt - OpenAt - 1));
    TextValue := StringReplace(Segment, '&nbsp;', ' ', [rfReplaceAll,
      rfIgnoreCase]);
    if (TextValue <> '') and (Pos('<', TextValue) = 0) and
      (Pos('>', TextValue) = 0) and
      not ContainsText(TextValue, '%s') and
      not ContainsText(TextValue, '%d') then
      AddRuntimeItem(AResult, AFileName, AUnitName, 'HtmlText',
        'BrowserText', TextValue, AStatement.SourceLine, rtrStaticText);
    StartAt := CloseAt + 1;
  end;
end;

function ExtractFormatTemplate(const AExpression: string;
  out ATemplate: string): Boolean;
var
  CloseAt: Integer;
  CommaAt: Integer;
  InString: Boolean;
  Index: Integer;
  OpenAt: Integer;
  TemplateExpression: string;
begin
  Result := False;
  ATemplate := '';
  OpenAt := Pos('Format(', AExpression);
  if OpenAt = 0 then
    Exit;
  Inc(OpenAt, Length('Format('));
  InString := False;
  CommaAt := 0;
  CloseAt := 0;
  Index := OpenAt;
  while Index <= Length(AExpression) do
  begin
    if AExpression[Index] = '''' then
    begin
      if InString and (Index < Length(AExpression)) and
        (AExpression[Index + 1] = '''') then
        Inc(Index)
      else
        InString := not InString;
    end
    else if not InString then
    begin
      if AExpression[Index] = ',' then
      begin
        CommaAt := Index;
        Break;
      end;
      if AExpression[Index] = ')' then
      begin
        CloseAt := Index;
        Break;
      end;
    end;
    Inc(Index);
  end;
  if CommaAt > 0 then
    CloseAt := CommaAt;
  if CloseAt = 0 then
    Exit;
  TemplateExpression := Trim(Copy(AExpression, OpenAt,
    CloseAt - OpenAt));
  Result := TryDecodeDelphiStringExpression(TemplateExpression, ATemplate) and
    (ATemplate <> '');
end;

procedure AddRuntimeItem(const AResult: TProjectScanResult;
  const AFileName, AUnitName, ALeftSide, APropertyName, ASourceText: string;
  const ASourceLine: Integer; const ARuntimeRole: TRuntimeTextRole);
var
  Context: string;
  ScanItem: TScanItem;
begin
  if Trim(ASourceText) = '' then
    Exit;
  Context := StringReplace(Trim(ALeftSide), ' ', '', [rfReplaceAll]);
  ScanItem := TScanItem.Create;
  ScanItem.Key := Format('%s.Runtime.%s.%d',
    [AUnitName, Context, ASourceLine]);
  ScanItem.SourceText := ASourceText;
  ScanItem.ComponentName := Context;
  ScanItem.ComponentClassName := '';
  ScanItem.PropertyName := APropertyName;
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := ASourceLine;
  ScanItem.CollectionIndex := -1;
  ScanItem.Framework := tfUnknown;
  ScanItem.Kind := stkRuntimeAssignment;
  ScanItem.RuntimeTextRole := ARuntimeRole;
  TScanContextAnalyzer.Analyze(ScanItem);
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

procedure CollectRuntimeStatements(const ALines: TStrings;
  const AStatements: TList<TRuntimeStatement>);
var
  LineIndex: Integer;
  SourceLine: Integer;
  Statement: string;
  StatementRecord: TRuntimeStatement;
  TerminatorAt: Integer;
  TrimmedLine: string;
begin
  Statement := '';
  SourceLine := 0;
  for LineIndex := 0 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if (TrimmedLine = '') or StartsText('//', TrimmedLine) then
      Continue;
    if (Statement = '') and
      (SameText(TrimmedLine, 'begin') or SameText(TrimmedLine, 'end') or
       SameText(TrimmedLine, 'end.') or SameText(TrimmedLine, 'try') or
       SameText(TrimmedLine, 'finally') or SameText(TrimmedLine, 'else') or
       EndsText(' then', TrimmedLine) or EndsText(' do', TrimmedLine) or
       EndsText(' begin', TrimmedLine)) then
      Continue;
    if Statement = '' then
    begin
      Statement := TrimmedLine;
      SourceLine := LineIndex + 1;
    end
    else
      Statement := Statement + ' ' + TrimmedLine;
    repeat
      TerminatorAt := FindStatementTerminator(Statement);
      if TerminatorAt > 0 then
      begin
        StatementRecord.SourceLine := SourceLine;
        StatementRecord.Text := Trim(Copy(Statement, 1, TerminatorAt));
        AStatements.Add(StatementRecord);
        Statement := Trim(Copy(Statement, TerminatorAt + 1, MaxInt));
        SourceLine := LineIndex + 1;
      end;
    until TerminatorAt = 0;
  end;
end;

procedure ScanRuntimeTextAssignments(const ALines: TStrings;
  const AFileName, AUnitName: string; const AResult: TProjectScanResult);
var
  AssignAt: Integer;
  Expression: string;
  FormatTemplate: string;
  LeftSide: string;
  PropertyName: string;
  Statement: TRuntimeStatement;
  Statements: TList<TRuntimeStatement>;
  ValueText: string;
begin
  Statements := TList<TRuntimeStatement>.Create;
  try
    CollectRuntimeStatements(ALines, Statements);
    for Statement in Statements do
    begin
      ScanHtmlText(Statement, AResult, AFileName, AUnitName);
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'ShowMessage', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'MessageDlg', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'MessageDialog', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'Items.Add', 'Items');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'Items.AddObject', 'Items');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'FillText', 'OwnerDrawText');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'TextOut', 'OwnerDrawText');
      AssignAt := Pos(':=', Statement.Text);
      if AssignAt = 0 then
        Continue;
      LeftSide := Trim(Copy(Statement.Text, 1, AssignAt - 1));
      Expression := Trim(Copy(Statement.Text, AssignAt + 2, MaxInt));
      if EndsText(';', Expression) then
        Delete(Expression, Length(Expression), 1);
      PropertyName := LastIdentifier(LeftSide);
      if IsRuntimeTextProperty(PropertyName) then
      begin
        if TryDecodeDelphiStringExpression(Expression, ValueText) then
        begin
          if not IsNonUiAssignment(LeftSide, ValueText) then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, ValueText, Statement.SourceLine, rtrStaticText);
        end
        else if ExtractFormatTemplate(Expression, FormatTemplate) then
        begin
          if not IsNonUiAssignment(LeftSide, FormatTemplate) then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, FormatTemplate, Statement.SourceLine,
              rtrRuntimeTemplate);
        end
        else if ContainsText(Expression, '+') and
          ExtractLiteralPhrase(Expression, ValueText) then
        begin
          if not IsNonUiAssignment(LeftSide, ValueText) then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, ValueText, Statement.SourceLine,
              rtrRuntimeTemplate);
        end;
      end
      else if ExtractFormatTemplate(Expression, FormatTemplate) and
        ContainsText(LowerCase(LeftSide), 'displaytext') and
        not IsNonUiAssignment(LeftSide, FormatTemplate) then
        AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
          'FormatTemplate', FormatTemplate, Statement.SourceLine,
          rtrRuntimeTemplate);
    end;
  finally
    Statements.Free;
  end;
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
    ScanRuntimeTextAssignments(Lines, AFileName, UnitName, AResult);
  finally
    Lines.Free;
  end;
end;

end.
