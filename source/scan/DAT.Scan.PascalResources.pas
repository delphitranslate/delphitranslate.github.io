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
  System.RegularExpressions,
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
     'Description', 'Prompt', 'PromptText', 'StatusText', 'Message',
     'DisplayText']);
end;

function TryClassifyRuntimeAssignment(const ALeftSide: string;
  out APropertyName: string): Boolean;
var
  LowerLeft: string;
begin
  APropertyName := LastIdentifier(ALeftSide);
  Result := IsRuntimeTextProperty(APropertyName);
  if Result then
    Exit;

  LowerLeft := LowerCase(StringReplace(ALeftSide, ' ', '', [rfReplaceAll]));
  if ContainsText(LowerLeft, '.cells[') then
  begin
    APropertyName := 'GridCell';
    Exit(True);
  end;
  if ContainsText(LowerLeft, '.rows[') or ContainsText(LowerLeft, '.row[') then
  begin
    APropertyName := 'GridCell';
    Exit(True);
  end;
  if ContainsText(LowerLeft, '.columns[') and
    (ContainsText(LowerLeft, '.header') or ContainsText(LowerLeft, '.text')) then
  begin
    APropertyName := 'GridHeader';
    Exit(True);
  end;
  if ContainsText(LowerLeft, '.header') and
    (ContainsText(LowerLeft, 'column') or ContainsText(LowerLeft, 'grid')) then
  begin
    APropertyName := 'GridHeader';
    Exit(True);
  end;
  if ContainsText(LowerLeft, '.items[') or ContainsText(LowerLeft, '.strings[') then
  begin
    APropertyName := 'Items';
    Exit(True);
  end;
  { A short word returned from a helper function is very often a value the user
    reads. Applications label rows this way rather than by assigning a control
    property, so the text appears in no form file and never reaches the
    catalog. A schedule classifying its rows as 'Time' or 'Song' had one of
    them translated only because a column header happened to carry the same
    word. Claim these, leaving the literal itself to decide whether it is
    prose or plumbing. }
  if SameText(Trim(ALeftSide), 'Result') then
  begin
    APropertyName := 'RuntimeValue';
    Exit(True);
  end;
end;

function RuntimeComponentClassName(const ALeftSide,
  APropertyName: string): string;
var
  LeftLower: string;
  NamePart: string;
  DotAt: Integer;
begin
  Result := '';
  LeftLower := LowerCase(StringReplace(ALeftSide, ' ', '', [rfReplaceAll]));
  NamePart := ALeftSide;
  DotAt := Pos('.', NamePart);
  if DotAt > 0 then
    NamePart := Copy(NamePart, 1, DotAt - 1);
  NamePart := LowerCase(Trim(NamePart));
  if ContainsText(APropertyName, 'Grid') or ContainsText(LeftLower, 'grid') then
    Exit('TStringGrid');
  if ContainsText(LeftLower, 'menu') or StartsText('mnu', NamePart) then
    Exit('TMenuItem');
  if StartsText('btn', NamePart) or ContainsText(NamePart, 'button') then
    Exit('TButton');
  if StartsText('lbl', NamePart) or ContainsText(NamePart, 'label') then
    Exit('TLabel');
  if StartsText('chk', NamePart) or ContainsText(NamePart, 'checkbox') then
    Exit('TCheckBox');
  if StartsText('rdo', NamePart) or ContainsText(NamePart, 'radio') then
    Exit('TRadioButton');
  if StartsText('cmb', NamePart) or StartsText('cbo', NamePart) or
    ContainsText(NamePart, 'combo') then
    Exit('TComboBox');
  if StartsText('edt', NamePart) or ContainsText(NamePart, 'edit') then
    Exit('TEdit');
  if StartsText('mem', NamePart) or ContainsText(NamePart, 'memo') then
    Exit('TMemo');
  if ContainsText(NamePart, 'browser') or ContainsText(APropertyName, 'Browser') then
    Exit('TWebBrowser');
  if ContainsText(APropertyName, 'Dialog') then
    Exit('TRuntimeDialog');
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
        { A closing bracket at the outer level is the end of the call, and so
          the end of its first argument. Reading past it returned the argument
          with its own punctuation still attached - 'text'); rather than 'text'
          - which any careful reader of the expression then refuses, correctly.
          The looser reader this replaced simply ignored the trailing
          characters, which hid the fault until the reader was tightened. }
        ')', ']':
          if Depth > 0 then
            Dec(Depth)
          else
            Exit(Trim(Copy(AExpression, 1, Index - 1)));
        ',': if Depth = 0 then Exit(Trim(Copy(AExpression, 1, Index - 1)));
      end;
  end;
end;

{ One string written across several lines, joined back into the one string the
  program actually builds.

  The joining is only legitimate when the expression is literals and nothing
  else. Written to pick every quoted run out of an expression and glue them
  together regardless of what sat between them, this produced strings that
  exist nowhere in the program and that no guard downstream could recognise.

    Result := 'logs' + PathDelim + 'ApplicationActivity.log';

  yields logsApplicationActivity.log, a file name with its separator missing, which
  then passes the very test that rejects paths and file names because it is
  neither any more. The activity-log path was translated on the strength of it.

  The same fault at scale swallowed the best part of five thousand characters
  of Pascal - every literal in a long run of code, glued end to end - and sent
  it to the translator, which rendered begin, end and then into Spanish and put
  the result in the shipped language pack.

  So: literals separated by the addition operator, and nothing else. Where any
  other term appears between them the pieces are not one string, and the answer
  is to claim none of it rather than to invent something. }
{ A term that only puts a line break between two pieces of text.

  A phrase written as 'Remaining events for Today:' + sLineBreak is still a
  phrase; the line break is punctuation, not data. Requiring pure literals kept
  variables out, which is what it was for, but it also threw away every heading
  an application ends with a newline - and that is a common way to write one. }
function IsLineBreakTerm(const AToken: string): Boolean;
var
  CharIndex: Integer;
  Token: string;
begin
  Token := LowerCase(Trim(AToken));
  Result := (Token = 'slinebreak') or (Token = 'slinefeed') or
    (Token = 'sconstlinebreak');
  if Result or (Token = '') then
    Exit;
  { Character literals: #13, #10, #13#10. }
  if Token[1] <> '#' then
    Exit(False);
  for CharIndex := 1 to Length(Token) do
    if not CharInSet(Token[CharIndex], ['#', '0'..'9']) then
      Exit(False);
  Result := True;
end;

{ True when everything separating two literals is addition and line breaks. }
function IsJoinFragment(const AFragment: string;
  out AHasLineBreak: Boolean): Boolean;
var
  Part: string;
  Parts: TArray<string>;
begin
  AHasLineBreak := False;
  Result := False;
  if Pos('+', AFragment) = 0 then
    Exit;
  Parts := AFragment.Split(['+']);
  for Part in Parts do
  begin
    if Trim(Part) = '' then
      Continue;
    if not IsLineBreakTerm(Part) then
      Exit(False);
    AHasLineBreak := True;
  end;
  Result := True;
end;

function ExtractLiteralPhrase(const AExpression: string;
  out APhrase: string): Boolean;
var
  Decoded: string;
  EndAt: Integer;
  Index: Integer;
  Segment: string;
  StartAt: Integer;
  Between: string;
  SeenLiteral: Boolean;
  HasLineBreak: Boolean;
  PendingLineBreak: Boolean;
begin
  APhrase := '';
  SeenLiteral := False;
  PendingLineBreak := False;
  EndAt := 0;
  Index := 1;
  while Index <= Length(AExpression) do
  begin
    if AExpression[Index] <> '''' then
    begin
      Inc(Index);
      Continue;
    end;
    { What separated this literal from the one before it. Only whitespace and a
      single addition operator may. }
    if SeenLiteral then
    begin
      Between := Trim(Copy(AExpression, EndAt + 1, Index - EndAt - 1));
      if not IsJoinFragment(Between, HasLineBreak) then
        Exit(False);
      { A break between two literals belongs in the phrase: it is where the
        author put it, and it is what the application holds when it asks for
        this text. }
      PendingLineBreak := HasLineBreak;
    end
    else if Trim(Copy(AExpression, 1, Index - 1)) <> '' then
      { Something stands before the first literal, so the expression is not a
        string written out in pieces. }
      Exit(False);
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
    if not TryDecodeDelphiStringExpression(Segment, Decoded) then
      Exit(False);
    if PendingLineBreak then
    begin
      APhrase := APhrase + sLineBreak;
      PendingLineBreak := False;
    end;
    APhrase := APhrase + Decoded;
    SeenLiteral := True;
    Inc(Index);
  end;
  { And nothing may follow the last literal either. }
  { A trailing line break is punctuation too, so it may follow the last
    literal; anything else may not. }
  Between := Trim(Copy(AExpression, EndAt + 1, MaxInt));
  if not SeenLiteral then
    Exit(False);
  if (Between <> '') and not IsJoinFragment(Between, HasLineBreak) then
    Exit(False);
  APhrase := Trim(APhrase);
  Result := APhrase <> '';
end;

function ArgumentAt(const AExpression: string; const AWantedIndex: Integer;
  out AArgument: string): Boolean;
var
  ArgumentIndex: Integer;
  ArgumentStart: Integer;
  Depth: Integer;
  InString: Boolean;
  Index: Integer;
begin
  Result := False;
  AArgument := '';
  if AWantedIndex < 0 then
    Exit;
  ArgumentIndex := 0;
  ArgumentStart := 1;
  Depth := 0;
  InString := False;
  Index := 1;
  while Index <= Length(AExpression) do
  begin
    if AExpression[Index] = '''' then
    begin
      if InString and (Index < Length(AExpression)) and
        (AExpression[Index + 1] = '''') then
        Inc(Index, 2)
      else
      begin
        InString := not InString;
        Inc(Index);
      end;
      Continue;
    end;
    if not InString then
      case AExpression[Index] of
        '(', '[': Inc(Depth);
        ')', ']':
          if Depth > 0 then
            Dec(Depth)
          else
          begin
            if ArgumentIndex = AWantedIndex then
            begin
              AArgument := Trim(Copy(AExpression, ArgumentStart,
                Index - ArgumentStart));
              Result := AArgument <> '';
            end;
            Exit;
          end;
        ',':
          if Depth = 0 then
          begin
            if ArgumentIndex = AWantedIndex then
            begin
              AArgument := Trim(Copy(AExpression, ArgumentStart,
                Index - ArgumentStart));
              Exit(AArgument <> '');
            end;
            Inc(ArgumentIndex);
            ArgumentStart := Index + 1;
          end;
      end;
    Inc(Index);
  end;
  if ArgumentIndex = AWantedIndex then
  begin
    AArgument := Trim(Copy(AExpression, ArgumentStart, MaxInt));
    if EndsText(';', AArgument) then
      Delete(AArgument, Length(AArgument), 1);
    Result := AArgument <> '';
  end;
end;

function IsSemanticTextVariable(const ALeftSide: string): Boolean;
var
  Name: string;
begin
  Name := LowerCase(LastIdentifier(ALeftSide));
  Result := ContainsText(Name, 'playing') or ContainsText(Name, 'status') or
    ContainsText(Name, 'message') or ContainsText(Name, 'caption') or
    ContainsText(Name, 'prompt') or ContainsText(Name, 'title') or
    ContainsText(Name, 'displaytext');
end;

{ Converts a concatenated caption into the same placeholder shape the runtime
  already understands. Literal words remain literal, while file names,
  counters, Format calls and other live expressions become %s. A previously
  assigned semantic text variable may contribute its template to a later
  visible Caption assignment. }
function ExtractConcatTemplate(const AExpression: string;
  const AKnownTemplates: TDictionary<string, string>;
  out ATemplate: string): Boolean;
var
  Current: string;
  Decoded: string;
  Index: Integer;
  InString: Boolean;
  ParenthesisDepth: Integer;
  SawLiteral: Boolean;
  SawPlaceholder: Boolean;
  Term: string;

  procedure AppendPlaceholder;
  begin
    if not EndsText('%s', ATemplate) then
      ATemplate := ATemplate + '%s';
    SawPlaceholder := True;
  end;

  procedure AppendTerm;
  var
    Known: string;
    Name: string;
  begin
    Term := Trim(Current);
    Current := '';
    if Term = '' then
      Exit;
    if TryDecodeDelphiStringExpression(Term, Decoded) then
    begin
      ATemplate := ATemplate + Decoded;
      SawLiteral := SawLiteral or (Trim(Decoded) <> '');
      Exit;
    end;
    if IsLineBreakTerm(Term) then
    begin
      ATemplate := ATemplate + sLineBreak;
      Exit;
    end;
    Name := LastIdentifier(Term);
    if (AKnownTemplates <> nil) and
      (AKnownTemplates.TryGetValue(Trim(Term), Known) or
       AKnownTemplates.TryGetValue(Name, Known)) then
    begin
      ATemplate := ATemplate + Known;
      SawLiteral := True;
      SawPlaceholder := SawPlaceholder or ContainsText(Known, '%s');
      Exit;
    end;
    AppendPlaceholder;
  end;

begin
  ATemplate := '';
  Current := '';
  InString := False;
  ParenthesisDepth := 0;
  SawLiteral := False;
  SawPlaceholder := False;
  Index := 1;
  while Index <= Length(AExpression) do
  begin
    if AExpression[Index] = '''' then
    begin
      Current := Current + AExpression[Index];
      if InString and (Index < Length(AExpression)) and
        (AExpression[Index + 1] = '''') then
      begin
        Inc(Index);
        Current := Current + AExpression[Index];
      end
      else
        InString := not InString;
    end
    else if not InString and (AExpression[Index] = '(') then
    begin
      Inc(ParenthesisDepth);
      Current := Current + AExpression[Index];
    end
    else if not InString and (AExpression[Index] = ')') then
    begin
      Dec(ParenthesisDepth);
      Current := Current + AExpression[Index];
    end
    else if not InString and (ParenthesisDepth = 0) and
      (AExpression[Index] = '+') then
      AppendTerm
    else
      Current := Current + AExpression[Index];
    Inc(Index);
  end;
  AppendTerm;
  ATemplate := Trim(ATemplate);
  Result := SawLiteral and SawPlaceholder and (Length(ATemplate) >= 4);
end;

procedure AddRuntimeItem(const AResult: TProjectScanResult;
  const AFileName, AUnitName, ALeftSide, APropertyName, ASourceText: string;
  const ASourceLine: Integer; const ARuntimeRole: TRuntimeTextRole); forward;
function ExtractFormatTemplate(const AExpression: string;
  out ATemplate: string): Boolean; forward;

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

{ The heading a list is given before its rows are added to it.

  The blanket refusal to read Items.Add and Lines.Add is right about what it
  refuses: rows, logs, file names and generated HTML. A heading is none of
  those, and an application writes one exactly the same way - a schedule
  dialog can open with

    ScheduleStr.Add('Remaining events for Today:' + sLineBreak);

  and then adds a line per event, each built from a time and a file path.

  Two things separate the heading from the rows, and both are required here.
  The phrase must be written entirely as literals, which every row fails
  because each is assembled from variables. And it must end in a colon, which
  is what makes it a heading rather than an item: "Close window" sitting in a
  hint list is not a heading and is left alone, as it was before.

  This is a convention rather than a rule of the language, so it is drawn
  narrowly on purpose. A heading written without a colon is missed, which is a
  better failure than a thousand data rows claimed as captions. }
procedure ScanListHeading(const AStatement: TRuntimeStatement;
  const AResult: TProjectScanResult; const AFileName, AUnitName: string);
var
  ArgumentText: string;
  CallAt: Integer;
  Phrase: string;
  StartAt: Integer;
begin
  CallAt := Pos('.add(', LowerCase(AStatement.Text));
  if CallAt = 0 then
    Exit;
  StartAt := CallAt + Length('.add(');
  ArgumentText := FirstArgument(Copy(AStatement.Text, StartAt, MaxInt));
  if not ExtractLiteralPhrase(ArgumentText, Phrase) then
    Exit;
  if not EndsText(':', TrimRight(Phrase)) then
    Exit;
  AddRuntimeItem(AResult, AFileName, AUnitName, 'Add', 'ListHeading',
    Phrase, AStatement.SourceLine, rtrRuntimeTemplate);
end;

procedure AddExplicitTranslationItem(const AResult: TProjectScanResult;
  const AFileName, AUnitName, AKey, ASourceText: string;
  const ASourceLine: Integer);
var
  ScanItem: TScanItem;
begin
  if (Trim(AKey) = '') or (Trim(ASourceText) = '') then
    Exit;
  ScanItem := TScanItem.Create;
  ScanItem.Key := AKey;
  ScanItem.SourceText := ASourceText;
  ScanItem.ComponentName := 'GeneratedContent';
  ScanItem.ComponentClassName := 'TGeneratedDocument';
  ScanItem.PropertyName := 'GeneratedText';
  ScanItem.SourceFileName := AFileName;
  ScanItem.SourceLine := ASourceLine;
  ScanItem.CollectionIndex := -1;
  ScanItem.Framework := tfUnknown;
  ScanItem.Kind := stkRuntimeAssignment;
  ScanItem.RuntimeTextRole := rtrRuntimeTemplate;
  TScanContextAnalyzer.Analyze(ScanItem);
  TScanQualityAnalyzer.Analyze(ScanItem);
  AResult.Items.Add(ScanItem);
end;

function ScanExplicitTranslationCall(const AStatement: TRuntimeStatement;
  const AResult: TProjectScanResult; const AFileName, AUnitName,
  ACallName: string): Boolean;
var
  CallAt: Integer;
  FallbackExpression: string;
  FallbackText: string;
  KeyExpression: string;
  KeyText: string;
  LowerStatement: string;
  SearchFrom: Integer;
begin
  Result := False;
  LowerStatement := LowerCase(AStatement.Text);
  SearchFrom := 1;
  while SearchFrom <= Length(LowerStatement) do
  begin
    CallAt := PosEx(LowerCase(ACallName + '('), LowerStatement, SearchFrom);
    if CallAt = 0 then
      Exit;
    SearchFrom := CallAt + Length(ACallName) + 1;
    if (CallAt > 1) and
      CharInSet(LowerStatement[CallAt - 1], ['A'..'Z', 'a'..'z',
        '0'..'9', '_']) then
      Continue;
    if ArgumentAt(Copy(AStatement.Text, SearchFrom, MaxInt), 0,
      KeyExpression) and
      ArgumentAt(Copy(AStatement.Text, SearchFrom, MaxInt), 1,
      FallbackExpression) and
      TryDecodeDelphiStringExpression(KeyExpression, KeyText) and
      TryDecodeDelphiStringExpression(FallbackExpression, FallbackText) then
    begin
      AddExplicitTranslationItem(AResult, AFileName, AUnitName, KeyText,
        FallbackText, AStatement.SourceLine);
      Result := True;
    end;
  end;
end;

{ A formatted row added to a string list that is later shown as a dialog.

  Broad Items.Add scanning remains deliberately excluded: those calls usually
  carry data, paths or logs. This narrower case first proves that the receiving
  variable is passed to a dialog, then takes only a Format template. The live
  time, filename or other data remains in placeholders and is never translated. }
procedure ScanDialogListRow(const AStatement: TRuntimeStatement;
  const ADialogTextVariables: TDictionary<string, Boolean>;
  const AResult: TProjectScanResult; const AFileName, AUnitName: string);
var
  AddAt: Integer;
  ArgumentText: string;
  Receiver: string;
  Template: string;
begin
  if ADialogTextVariables = nil then
    Exit;
  AddAt := Pos('.add(', LowerCase(AStatement.Text));
  if AddAt < 2 then
    Exit;
  Receiver := LowerCase(LastIdentifier(
    Copy(AStatement.Text, 1, AddAt - 1)));
  if not ADialogTextVariables.ContainsKey(Receiver) then
    Exit;
  ArgumentText := FirstArgument(Copy(AStatement.Text,
    AddAt + Length('.add('), MaxInt));
  if not ExtractFormatTemplate(ArgumentText, Template) then
    Exit;
  AddRuntimeItem(AResult, AFileName, AUnitName, 'DialogListRow',
    'DialogMessage', Template, AStatement.SourceLine, rtrRuntimeTemplate);
end;

{ A file name, as opposed to a sentence that happens to contain a dot. Both
  tests matter: the extension must be a short run of letters or digits, and the
  text must carry no whitespace, because no file name written in a program does
  and every sentence does. }
function LooksLikeFileName(const AText: string): Boolean;
var
  DotAt: Integer;
  Extension: string;
  Index: Integer;
begin
  Result := False;
  DotAt := LastDelimiter('.', AText);
  if DotAt = 0 then
    Exit;
  for Index := 1 to Length(AText) do
    if CharInSet(AText[Index], [' ', #9]) then
      Exit;
  Extension := Copy(AText, DotAt + 1, MaxInt);
  if (Extension = '') or (Length(Extension) > 4) then
    Exit;
  for Index := 1 to Length(Extension) do
    if not CharInSet(Extension[Index],
      ['a'..'z', 'A'..'Z', '0'..'9']) then
      Exit;
  Result := True;
end;

function WordCount(const AText: string): Integer;
var
  Index: Integer;
  InWord: Boolean;
begin
  Result := 0;
  InWord := False;
  for Index := 1 to Length(AText) do
    if CharInSet(AText[Index], [' ', #9]) then
      InWord := False
    else
    begin
      if not InWord then
        Inc(Result);
      InWord := True;
    end;
end;

function IsLikelyUserFacingLiteral(const AText: string): Boolean;
var
  Trimmed: string;
  Index: Integer;
  HasLetter: Boolean;
begin
  { A function returning a short word is a promising source of on-screen text,
    but the same shape carries file names, keys and fragments of markup. Accept
    only what reads as a word or a short phrase a person would actually see. }
  Trimmed := Trim(AText);
  Result := False;
  if Length(Trimmed) < 2 then
    Exit;
  { Length is judged against what the text reads as. A short cap is right for
    a single token, where anything long is almost always a key, a path or a
    fragment of markup. It is wrong for prose: a sentence a person reads can
    run to a couple of hundred characters and still be a caption, and capping
    it at forty lost the note explaining the silence dates. Several words with
    spaces between them is the difference. }
  if WordCount(Trimmed) >= 4 then
  begin
    if Length(Trimmed) > 240 then
      Exit;
  end
  else if Length(Trimmed) > 40 then
    Exit;
  HasLetter := False;
  for Index := 1 to Length(Trimmed) do
  begin
    if CharInSet(Trimmed[Index], ['a'..'z', 'A'..'Z']) then
      HasLetter := True
    else if not CharInSet(Trimmed[Index], [' ', '-', '/', '''', '.', ',',
      ':', '(', ')', '0'..'9']) then
      Exit;
  end;
  if not HasLetter then
    Exit;
  if ContainsText(Trimmed, '\') or ContainsText(Trimmed, '%') or
    ContainsText(Trimmed, '..') then
    Exit;
  { Program text, never shown to anybody. A run of literals glued out of a
    stretch of source once reached the translator this way and came back with
    begin, end and then rendered into Spanish. }
  if ContainsText(Trimmed, ':=') or ContainsText(Trimmed, ';') then
    Exit;
  { A bare file extension, or a name carrying one, is plumbing.

    Written as a count of the characters after the final dot, this rejected
    every sentence that ends in a full stop, because a full stop at the end
    leaves nothing after it and nothing is fewer than four. Any explanatory
    note written as a proper sentence was quietly discarded, and nobody could
    see that it had been: the words simply never reached the catalogue.

    A file name is what is meant, so say so. It carries no spaces, and what
    follows its last dot is a short run of letters or digits. }
  if LooksLikeFileName(Trimmed) then
    Exit;
  Result := True;
end;

function IsLowercaseIdentifier(const AText: string): Boolean;
var
  CharacterIndex: Integer;
  Trimmed: string;
begin
  Trimmed := Trim(AText);
  Result := Trimmed <> '';
  if not Result then
    Exit;
  for CharacterIndex := 1 to Length(Trimmed) do
    if not CharInSet(Trimmed[CharacterIndex], ['a'..'z', '0'..'9', '_']) then
      Exit(False);
end;

function IsTechnicalReturnedToken(const AStatement, AText: string): Boolean;
var
  CharacterIndex: Integer;
  LiteralEnd: Integer;
  LiteralStart: Integer;
  PrefixLength: Integer;
  QuotedToken: string;
  Token: string;
begin
  { A returned Pascal/FMX token is behavior, not interface text. Two shapes are
    strong enough to protect without hiding ordinary one-word labels:

      Result := 'TComponent';
      if SameText(Result, 'alRight') then Result := 'Right';

    The first is visibly an identifier because it has an internal capital. The
    second is an enum normalization: another quoted identifier ends in the
    returned word and contributes only a short Delphi-style prefix. Human
    labels such as Time and Song have neither proof and remain translatable. }
  Result := False;
  Token := Trim(AText);
  if Token = '' then
    Exit;
  if not CharInSet(Token[1], ['A'..'Z', 'a'..'z', '_']) then
    Exit;
  for CharacterIndex := 2 to Length(Token) do
  begin
    if not CharInSet(Token[CharacterIndex],
      ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Exit;
    if CharInSet(Token[CharacterIndex], ['A'..'Z']) then
      Result := True;
  end;
  if Result then
    Exit;

  LiteralStart := 1;
  while LiteralStart <= Length(AStatement) do
  begin
    while (LiteralStart <= Length(AStatement)) and
      (AStatement[LiteralStart] <> '''') do
      Inc(LiteralStart);
    if LiteralStart > Length(AStatement) then
      Exit(False);
    LiteralEnd := LiteralStart + 1;
    while (LiteralEnd <= Length(AStatement)) and
      (AStatement[LiteralEnd] <> '''') do
      Inc(LiteralEnd);
    if LiteralEnd > Length(AStatement) then
      Exit(False);
    QuotedToken := Copy(AStatement, LiteralStart + 1,
      LiteralEnd - LiteralStart - 1);
    if (Length(QuotedToken) > Length(Token)) and
      EndsText(Token, QuotedToken) then
    begin
      PrefixLength := Length(QuotedToken) - Length(Token);
      if PrefixLength <= 4 then
      begin
        Result := True;
        for CharacterIndex := 1 to PrefixLength do
          if not CharInSet(QuotedToken[CharacterIndex], ['A'..'Z', 'a'..'z']) then
          begin
            Result := False;
            Break;
          end;
        if Result then
          Exit;
      end;
    end;
    LiteralStart := LiteralEnd + 1;
  end;
end;

{ How many times this statement assigns to Result. }
function CountReturnedAssignments(const ALowerStatement: string): Integer;
var
  Index: Integer;
  Cursor: Integer;
begin
  Result := 0;
  Cursor := 1;
  while True do
  begin
    Index := PosEx('result', ALowerStatement, Cursor);
    if Index = 0 then
      Exit;
    Cursor := Index + Length('result');
    if (Index > 1) and CharInSet(ALowerStatement[Index - 1],
      ['a'..'z', 'A'..'Z', '0'..'9', '_', '.']) then
      Continue;
    Cursor := Index + Length('result');
    while (Cursor <= Length(ALowerStatement)) and
      CharInSet(ALowerStatement[Cursor], [' ', #9]) do
      Inc(Cursor);
    if (Cursor < Length(ALowerStatement)) and
      (ALowerStatement[Cursor] = ':') and
      (ALowerStatement[Cursor + 1] = '=') then
      Inc(Result);
  end;
end;

function ScanReturnedLiterals(const AResult: TProjectScanResult;
  const AFileName, AUnitName, AStatement: string;
  const ASourceLine: Integer): Boolean;
var
  Index, Start, Stop: Integer;
  Literal: string;
  Lower: string;
begin
  { A helper that labels rows usually writes them as a single conditional:

      if Pos('STRIKE', ...) > 0 then Result := 'Time' else Result := 'Song';

    Split on the first assignment and the left side reads 'if ... then
    Result', which matches nothing, and the right side is the rest of the
    conditional rather than a literal. Look through the statement for each
    returned literal instead, so both arms are claimed. }
  Result := False;
  { Where the statement assembles its value from more than one term, the words
    a person sees are the assembled whole, not any one piece of it, and the
    pieces are frequently not words at all.

      Result := 'logs' + PathDelim + 'ApplicationActivity.log';
      Result := 'Total: ' + IntToStr(ACount) + ' items';

    Claiming the first literal of either gives a path fragment and a dangling
    label, both offered for translation and neither ever displayed. Where the
    terms really are all literals - one caption written across several source
    lines - the assembling branch elsewhere claims the whole of it, so nothing
    is lost by declining here. }
  if ContainsText(AStatement, '+') then
    Exit;
  Lower := LowerCase(AStatement);
  { This exists for the statement that returns more than one value, where
    splitting on the first assignment sees only one of them. A statement with a
    single returned value is already claimed by the assignment below, and
    claiming it here as well puts the same words in front of the reviewer twice
    under two different keys. }
  if CountReturnedAssignments(Lower) < 2 then
    Exit;
  Index := 1;
  while True do
  begin
    Index := PosEx('result', Lower, Index);
    if Index = 0 then
      Exit;
    { A whole word, not the tail of some other identifier. }
    if (Index = 1) or not CharInSet(AStatement[Index - 1],
      ['a'..'z', 'A'..'Z', '0'..'9', '_', '.']) then
    begin
      Start := Index + Length('result');
      while (Start <= Length(AStatement)) and
        CharInSet(AStatement[Start], [' ', #9]) do
        Inc(Start);
      if (Start < Length(AStatement)) and (AStatement[Start] = ':') and
        (AStatement[Start + 1] = '=') then
      begin
        Inc(Start, 2);
        while (Start <= Length(AStatement)) and
          CharInSet(AStatement[Start], [' ', #9]) do
          Inc(Start);
        if (Start <= Length(AStatement)) and
          (AStatement[Start] = '''') then
        begin
          Stop := Start + 1;
          while (Stop <= Length(AStatement)) and
            (AStatement[Stop] <> '''') do
            Inc(Stop);
          if Stop <= Length(AStatement) then
          begin
            Literal := Copy(AStatement, Start + 1, Stop - Start - 1);
            { Lowercase identifiers returned by classifiers are technical
              tokens (CSS classes, state codes, strategy names), not visible
              captions. Generated-document display labels use explicit stable
              translation keys instead. }
            if IsLikelyUserFacingLiteral(Literal) and
              not IsLowercaseIdentifier(Literal) and
              not IsTechnicalReturnedToken(AStatement, Literal) then
            begin
              { The key is built from the left side and the line, and a
                conditional puts several returned values on one statement,
                so every one of them would key the same and all but the
                first be discarded as a duplicate. Name the value in the
                left side to keep them apart. }
              AddRuntimeItem(AResult, AFileName, AUnitName,
                'Result(' + Literal + ')',
                'RuntimeValue', Literal, ASourceLine, rtrStaticText);
              Result := True;
            end;
          end;
        end;
      end;
    end;
    Inc(Index, Length('result'));
  end;
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
    ContainsText(LowerText, '<td') or
    ContainsText(LowerText, '.text') or
    ContainsText(LowerText, '.caption') or
    ContainsText(LowerText, '.checked') or
    ContainsText(LowerText, '.items') or
    ContainsText(LowerText, ' then ') or
    ContainsText(LowerText, ' else ') or
    ContainsText(LowerText, ' begin') or
    ContainsText(LowerText, ' end') or
    ContainsText(LowerText, 'encodedate') or
    ContainsText(LowerText, 'encodetime') or
    ContainsText(LowerText, 'formatdatetime') or
    ContainsText(LowerText, 'strftime') or
    ContainsText(LowerText, 'http://127.0.0.1') or
    ContainsText(LowerText, 'oauth') or
    ContainsText(LowerText, '://') or
    ContainsText(LowerText, '@') or
    ContainsText(LowerText, 'apps.googleusercontent.com');
end;

{ Every literal in a statement, run together, regardless of what lies between.

  This is the reading that must never be used on an assignment: it invents
  strings that appear nowhere in the program, and it is how a file name lost
  its separator and a run of Pascal reached the translator. It is right for one
  caller only. Markup is genuinely built in pieces across a statement, and what
  is done with the result here - taking only the text that sits between tags -
  cannot mistake code for a caption even when the joining is careless, because
  code carries no tags. }
function JoinAllLiterals(const AExpression: string;
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
        if (Index < Length(AExpression)) and
          (AExpression[Index + 1] = '''') then
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

procedure ScanHtmlText(const AStatement: TRuntimeStatement;
  const AResult: TProjectScanResult; const AFileName, AUnitName: string);
var
  CleanHtml: string;
  Decoded: string;
  RawSegment: string;
  Segments: TArray<string>;
  SegmentIndex: Integer;
  TextValue: string;

  function DecodeVisibleText(const AText: string): string;
  begin
    Result := AText;
    Result := StringReplace(Result, '&nbsp;', ' ',
      [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '&amp;', '&',
      [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '&lt;', '<',
      [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '&gt;', '>',
      [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '&quot;', '"',
      [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '&#39;', '''',
      [rfReplaceAll, rfIgnoreCase]);
    Result := Trim(TRegEx.Replace(Result, '\s+', ' '));
  end;
begin
  { Delphi source generators legitimately contain comparison operators and
    generic type syntax inside long string literals. Treating every angle
    bracket as HTML once harvested whole generated Pascal procedures. Require
    an actual user-facing HTML element before parsing text nodes. }
  if not (ContainsText(AStatement.Text, '<html') or
    ContainsText(AStatement.Text, '<head') or
    ContainsText(AStatement.Text, '<body') or
    ContainsText(AStatement.Text, '<title') or
    ContainsText(AStatement.Text, '<meta') or
    ContainsText(AStatement.Text, '<style') or
    ContainsText(AStatement.Text, '<section') or
    ContainsText(AStatement.Text, '<article') or
    ContainsText(AStatement.Text, '<div') or
    ContainsText(AStatement.Text, '<span') or
    ContainsText(AStatement.Text, '<p') or
    ContainsText(AStatement.Text, '<h1') or
    ContainsText(AStatement.Text, '<h2') or
    ContainsText(AStatement.Text, '<h3') or
    ContainsText(AStatement.Text, '<table') or
    ContainsText(AStatement.Text, '<thead') or
    ContainsText(AStatement.Text, '<tbody') or
    ContainsText(AStatement.Text, '<tr') or
    ContainsText(AStatement.Text, '<th') or
    ContainsText(AStatement.Text, '<td') or
    ContainsText(AStatement.Text, '<ul') or
    ContainsText(AStatement.Text, '<ol') or
    ContainsText(AStatement.Text, '<li') or
    ContainsText(AStatement.Text, '<a ') or
    ContainsText(AStatement.Text, '<br') or
    ContainsText(AStatement.Text, '<hr')) or
    not JoinAllLiterals(AStatement.Text, Decoded) then
    Exit;
  { Visible prose is the contract. Executable/style/template text and code
    samples remain byte-for-byte technical content and must never enter a
    translation catalog merely because an application renders HTML. }
  CleanHtml := TRegEx.Replace(Decoded,
    '<!--.*?-->|<(script|style|template|noscript|code|pre)\b[^>]*>.*?</\1\s*>',
    ' ', [roIgnoreCase, roSingleLine]);
  CleanHtml := TRegEx.Replace(CleanHtml, '<[^>]+>', sLineBreak,
    [roIgnoreCase, roSingleLine]);
  Segments := CleanHtml.Split([sLineBreak]);
  SegmentIndex := 0;
  for RawSegment in Segments do
  begin
    TextValue := DecodeVisibleText(RawSegment);
    if (TextValue <> '') and (Pos('<', TextValue) = 0) and
      (Pos('>', TextValue) = 0) and
      not ContainsText(TextValue, '%s') and
      not ContainsText(TextValue, '%d') then
    begin
      AddRuntimeItem(AResult, AFileName, AUnitName,
        Format('HtmlText.%d', [SegmentIndex]), 'BrowserText',
        TextValue, AStatement.SourceLine, rtrStaticText);
      Inc(SegmentIndex);
    end;
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
  ScanItem.ComponentClassName := RuntimeComponentClassName(ALeftSide,
    APropertyName);
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

{ The line with its comments taken out, so that what remains is program text.

  The collector had no notion of comments at all. An apostrophe inside one -
  an activity-log comment, don't, the developer's choice - opens a string literal as far
  as a naive reader is concerned, and it never closes, so every statement after
  that point in the file is swallowed into one unterminated literal and nothing
  further is scanned. Nothing announces it: the unit simply yields fewer
  strings than it holds, and which ones depends on where the apostrophe falls.

  Quotes are tracked as well as comments, because the two decide each other: a
  brace inside a string opens no comment, and a quote inside a comment opens no
  string. ABlockDepth carries brace nesting across lines, AInDirective carries
  the older parenthesis-star form. }
function StripPascalComments(const ALine: string; var ABlockDepth: Integer;
  var AInDirective: Boolean): string;
var
  Index: Integer;
  InString: Boolean;
begin
  Result := '';
  InString := False;
  Index := 1;
  while Index <= Length(ALine) do
  begin
    if AInDirective then
    begin
      if (ALine[Index] = '*') and (Index < Length(ALine)) and
        (ALine[Index + 1] = ')') then
      begin
        AInDirective := False;
        Inc(Index, 2);
      end
      else
        Inc(Index);
      Continue;
    end;
    if ABlockDepth > 0 then
    begin
      if ALine[Index] = '}' then
        Dec(ABlockDepth)
      else if ALine[Index] = '{' then
        Inc(ABlockDepth);
      Inc(Index);
      Continue;
    end;
    if InString then
    begin
      Result := Result + ALine[Index];
      if ALine[Index] = '''' then
        InString := False;
      Inc(Index);
      Continue;
    end;
    if ALine[Index] = '''' then
    begin
      InString := True;
      Result := Result + ALine[Index];
      Inc(Index);
      Continue;
    end;
    if (ALine[Index] = '/') and (Index < Length(ALine)) and
      (ALine[Index + 1] = '/') then
      Break;
    if ALine[Index] = '{' then
    begin
      Inc(ABlockDepth);
      Inc(Index);
      Continue;
    end;
    if (ALine[Index] = '(') and (Index < Length(ALine)) and
      (ALine[Index + 1] = '*') then
    begin
      AInDirective := True;
      Inc(Index, 2);
      Continue;
    end;
    Result := Result + ALine[Index];
    Inc(Index);
  end;
  { A literal left open at the end of a line is a line the reader has
    misunderstood, or a construct this scanner does not handle. Either way the
    safe answer is to claim nothing from it rather than to run on into the rest
    of the file. }
  if InString then
    Result := '';
  Result := Trim(Result);
end;

procedure CollectRuntimeStatements(const ALines: TStrings;
  const AStatements: TList<TRuntimeStatement>);
var
  BlockDepth: Integer;
  InDirective: Boolean;
  LineIndex: Integer;
  SourceLine: Integer;
  Statement: string;
  StatementRecord: TRuntimeStatement;
  TerminatorAt: Integer;
  TrimmedLine: string;
begin
  Statement := '';
  SourceLine := 0;
  BlockDepth := 0;
  InDirective := False;
  for LineIndex := 0 to ALines.Count - 1 do
  begin
    TrimmedLine := StripPascalComments(ALines[LineIndex], BlockDepth,
      InDirective);
    if TrimmedLine = '' then
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
  HasExplicitTranslation: Boolean;
  LeftSide: string;
  PropertyName: string;
  Statement: TRuntimeStatement;
  Statements: TList<TRuntimeStatement>;
  DialogTextVariables: TDictionary<string, Boolean>;
  TextVariables: TDictionary<string, string>;
  ValueText: string;
begin
  Statements := TList<TRuntimeStatement>.Create;
  DialogTextVariables := TDictionary<string, Boolean>.Create;
  TextVariables := TDictionary<string, string>.Create;
  try
    CollectRuntimeStatements(ALines, Statements);
    { Prove which string-list variables are eventually displayed. The Add
      calls normally occur before this ShowMessage call, so discovery is a
      separate pass over the collected statements. }
    for Statement in Statements do
    begin
      AssignAt := Pos('showmessage(', LowerCase(Statement.Text));
      if AssignAt = 0 then
        Continue;
      Expression := FirstArgument(Copy(Statement.Text,
        AssignAt + Length('showmessage('), MaxInt));
      if EndsText('.text', LowerCase(Trim(Expression))) then
      begin
        Delete(Expression, Length(Expression) - Length('.text') + 1,
          Length('.text'));
        Expression := LowerCase(LastIdentifier(Expression));
        if Expression <> '' then
          DialogTextVariables.AddOrSetValue(Expression, True);
      end;
    end;
    { Learn semantic text variables before scanning visible assignments. A
      timer method may use a field near the top of the unit even though the
      playback method which gives that field its caption template appears
      hundreds of lines later. Source order must not decide whether the user
      sees a complete template. }
    for Statement in Statements do
    begin
      AssignAt := Pos(':=', Statement.Text);
      if AssignAt = 0 then
        Continue;
      LeftSide := Trim(Copy(Statement.Text, 1, AssignAt - 1));
      if not IsSemanticTextVariable(LeftSide) then
        Continue;
      Expression := Trim(Copy(Statement.Text, AssignAt + 2, MaxInt));
      if EndsText(';', Expression) then
        Delete(Expression, Length(Expression), 1);
      if ExtractConcatTemplate(Expression, TextVariables, FormatTemplate) then
      begin
        TextVariables.AddOrSetValue(Trim(LeftSide), FormatTemplate);
        TextVariables.AddOrSetValue(LastIdentifier(LeftSide), FormatTemplate);
      end;
    end;
    for Statement in Statements do
    begin
      HasExplicitTranslation := ScanExplicitTranslationCall(Statement,
        AResult, AFileName, AUnitName, 'DATTranslateText');
      if ScanExplicitTranslationCall(Statement, AResult, AFileName, AUnitName,
        'TranslateText') then
        HasExplicitTranslation := True;
      if ScanExplicitTranslationCall(Statement, AResult, AFileName, AUnitName,
        'DATFormatText') then
        HasExplicitTranslation := True;
      if ScanExplicitTranslationCall(Statement, AResult, AFileName, AUnitName,
        'TranslateFormat') then
        HasExplicitTranslation := True;
      { A stable-key call owns every literal inside its statement. Running the
        broad HTML/assignment scanners too creates synthetic keys from the key
        and fallback joined together, then offers the same text twice. }
      if HasExplicitTranslation then
        Continue;
      ScanHtmlText(Statement, AResult, AFileName, AUnitName);
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'ShowMessage', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'MessageDlg', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'MessageDialog', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'InputBox', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'InputQuery', 'DialogMessage');
      ScanRuntimeCall(Statement, AResult, AFileName, AUnitName,
        'ShowScheduleDialog', 'DialogTitle');
      ScanListHeading(Statement, AResult, AFileName, AUnitName);
      ScanDialogListRow(Statement, DialogTextVariables, AResult, AFileName,
        AUnitName);
      { Do not harvest broad Items.Add/Lines.Add/Strings.Add or canvas
        drawing calls. In real applications these are commonly data rows,
        logs, filenames, generated HTML, or owner-drawn runtime values rather
        than stable UI captions. Collecting them caused thousands of false
        "translatable" strings in a production application and made the runtime try to
        translate behavior/data. Designer-authored Items/Lines are still
        scanned from .fmx/.dfm files; intentional runtime UI text should use
        explicit visual property assignment, resourcestring, or a dialog call. }
      AssignAt := Pos(':=', Statement.Text);
      { Returned literals are scanned from the whole statement, because a
        conditional puts more than one of them on a single line. }
      ScanReturnedLiterals(AResult, AFileName, AUnitName, Statement.Text,
        Statement.SourceLine);
      if AssignAt = 0 then
        Continue;
      LeftSide := Trim(Copy(Statement.Text, 1, AssignAt - 1));
      Expression := Trim(Copy(Statement.Text, AssignAt + 2, MaxInt));
      if EndsText(';', Expression) then
        Delete(Expression, Length(Expression), 1);
      if IsSemanticTextVariable(LeftSide) and
        ExtractConcatTemplate(Expression, TextVariables, FormatTemplate) then
      begin
        TextVariables.AddOrSetValue(Trim(LeftSide), FormatTemplate);
        TextVariables.AddOrSetValue(LastIdentifier(LeftSide), FormatTemplate);
      end;
      if TryClassifyRuntimeAssignment(LeftSide, PropertyName) then
      begin
        if TryDecodeDelphiStringExpression(Expression, ValueText) then
        begin
          if not IsNonUiAssignment(LeftSide, ValueText) and
            (not SameText(PropertyName, 'RuntimeValue') or
             (IsLikelyUserFacingLiteral(ValueText) and
              not IsTechnicalReturnedToken(Statement.Text, ValueText))) then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, ValueText, Statement.SourceLine, rtrStaticText);
        end
        else if ExtractFormatTemplate(Expression, FormatTemplate) then
        begin
          if not IsNonUiAssignment(LeftSide, FormatTemplate) and
            not SameText(PropertyName, 'RuntimeValue') then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, FormatTemplate, Statement.SourceLine,
              rtrRuntimeTemplate);
        end
        else if ExtractConcatTemplate(Expression, TextVariables,
          FormatTemplate) then
        begin
          if not IsNonUiAssignment(LeftSide, FormatTemplate) and
            not SameText(PropertyName, 'RuntimeValue') then
            AddRuntimeItem(AResult, AFileName, AUnitName, LeftSide,
              PropertyName, FormatTemplate, Statement.SourceLine,
              rtrRuntimeTemplate);
        end
        else if ContainsText(Expression, '+') and
          ExtractLiteralPhrase(Expression, ValueText) then
        begin
          { The same test the decoded branch above applies. A value a function
            returns is as likely to be a path or a key as a caption, and this
            branch was accepting whatever it had joined without asking. }
          if not IsNonUiAssignment(LeftSide, ValueText) and
            (not SameText(PropertyName, 'RuntimeValue') or
             (IsLikelyUserFacingLiteral(ValueText) and
              not IsTechnicalReturnedToken(Statement.Text, ValueText))) then
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
    TextVariables.Free;
    DialogTextVariables.Free;
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
    LoadDelphiTextFile(AFileName, Lines);
    UnitName := ReadUnitName(Lines, AFileName);
    { DAT runtime/component units are infrastructure copied beside a target
      project. Their language codes, directions and internal diagnostics are
      not application content and must not enter the application's catalog. }
    if StartsText('DAT.', UnitName) then
      Exit;
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
