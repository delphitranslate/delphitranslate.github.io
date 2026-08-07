unit DAT.Integration.DelphiSource;

interface

type
  TDelphiIntegrationSourceEditor = class
  public
    class function AddProjectUnitReference(const ASourceText,
      AUnitName, AUnitFileName: string): string; static;
    class function AddFormLanguageHandler(const ASourceText,
      AFormClassName, AIntegrationUnitName: string): string; static;
    class function AddFormDesignerMenuDeclarations(const ASourceText,
      AFormClassName, AMenuUnitName, AMenuName, AMenuClassName,
      AContainerName, AContainerClassName: string): string; static;
    class function AddFMXFormCreateTranslation(const ASourceText,
      AFormClassName, AHandlerName,
      AIntegrationUnitName: string): string; static;
    class function AddProjectStartup(const ASourceText,
      AIntegrationUnitName, AIntegrationUnitFileName: string;
      const ASkipFirstFormApply: Boolean = False): string; static;
    class function AddProjectReference(const AProjectXml,
      AIntegrationUnitFileName: string): string; static;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils;

function LineIndent(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Length(ALine) - Length(TrimLeft(ALine)));
end;

function FindLineContaining(const ALines: TStrings; const AText: string;
  const AStartIndex: Integer = 0): Integer;
var
  LineIndex: Integer;
begin
  Result := -1;
  for LineIndex := AStartIndex to ALines.Count - 1 do
    if ContainsText(ALines[LineIndex], AText) then
      Exit(LineIndex);
end;

procedure AddImplementationUnit(const ALines: TStrings;
  const AUnitName: string);
var
  ImplementationIndex: Integer;
  LineIndex: Integer;
  SemicolonIndex: Integer;
  UsesIndex: Integer;
begin
  if ContainsText(ALines.Text, AUnitName) then
    Exit;
  ImplementationIndex := FindLineContaining(ALines, 'implementation');
  if ImplementationIndex < 0 then
    raise Exception.Create('The Pascal unit has no implementation section.');

  UsesIndex := -1;
  for LineIndex := ImplementationIndex + 1 to ALines.Count - 1 do
  begin
    if SameText(Trim(ALines[LineIndex]), 'uses') then
    begin
      UsesIndex := LineIndex;
      Break;
    end;
    if StartsText('procedure ', Trim(ALines[LineIndex])) or
      StartsText('function ', Trim(ALines[LineIndex])) or
      StartsText('{$R ', Trim(ALines[LineIndex])) then
      Break;
  end;

  if UsesIndex < 0 then
  begin
    ALines.Insert(ImplementationIndex + 1, '');
    ALines.Insert(ImplementationIndex + 2, 'uses');
    ALines.Insert(ImplementationIndex + 3, '  ' + AUnitName + ';');
    Exit;
  end;

  SemicolonIndex := UsesIndex + 1;
  while (SemicolonIndex < ALines.Count) and
    not ContainsText(ALines[SemicolonIndex], ';') do
    Inc(SemicolonIndex);
  if SemicolonIndex >= ALines.Count then
    raise Exception.Create('The implementation uses clause is incomplete.');
  ALines[SemicolonIndex] := StringReplace(
    ALines[SemicolonIndex], ';', ',', []);
  ALines.Insert(SemicolonIndex + 1, '  ' + AUnitName + ';');
end;

procedure AddInterfaceUnit(const ALines: TStrings;
  const AUnitName: string);
var
  ImplementationIndex: Integer;
  InterfaceIndex: Integer;
  LineIndex: Integer;
  SemicolonIndex: Integer;
  UsesIndex: Integer;
begin
  InterfaceIndex := FindLineContaining(ALines, 'interface');
  ImplementationIndex := FindLineContaining(ALines, 'implementation');
  if (InterfaceIndex < 0) or (ImplementationIndex < 0) then
    raise Exception.Create(
      'The Pascal unit interface section could not be identified.');
  for LineIndex := InterfaceIndex + 1 to ImplementationIndex - 1 do
    if ContainsText(ALines[LineIndex], AUnitName) then
      Exit;

  UsesIndex := -1;
  for LineIndex := InterfaceIndex + 1 to ImplementationIndex - 1 do
    if SameText(Trim(ALines[LineIndex]), 'uses') then
    begin
      UsesIndex := LineIndex;
      Break;
    end;
  if UsesIndex < 0 then
  begin
    ALines.Insert(InterfaceIndex + 1, '');
    ALines.Insert(InterfaceIndex + 2, 'uses');
    ALines.Insert(InterfaceIndex + 3, '  ' + AUnitName + ';');
    Exit;
  end;

  SemicolonIndex := UsesIndex + 1;
  while (SemicolonIndex < ImplementationIndex) and
    not ContainsText(ALines[SemicolonIndex], ';') do
    Inc(SemicolonIndex);
  if SemicolonIndex >= ImplementationIndex then
    raise Exception.Create('The interface uses clause is incomplete.');
  ALines[SemicolonIndex] := StringReplace(
    ALines[SemicolonIndex], ';', ',', []);
  ALines.Insert(SemicolonIndex + 1, '  ' + AUnitName + ';');
end;

class function TDelphiIntegrationSourceEditor.AddFormDesignerMenuDeclarations(
  const ASourceText, AFormClassName,
  AMenuUnitName, AMenuName, AMenuClassName, AContainerName,
  AContainerClassName: string): string;
var
  ClassIndex: Integer;
  FormLines: TStringList;
  InsertIndex: Integer;
  MemberIndent: string;
begin
  FormLines := TStringList.Create;
  try
    FormLines.Text := ASourceText;
    AddInterfaceUnit(FormLines, AMenuUnitName);
    ClassIndex := FindLineContaining(FormLines,
      AFormClassName + ' = class');
    if ClassIndex < 0 then
      raise Exception.CreateFmt(
        'Form class %s was not found in its Pascal unit.',
        [AFormClassName]);
    InsertIndex := ClassIndex + 1;
    MemberIndent := LineIndent(FormLines[ClassIndex]) + '  ';
    if (Trim(AContainerName) <> '') and
       not ContainsText(FormLines.Text,
         AContainerName + ': ' + AContainerClassName + ';') then
    begin
      FormLines.Insert(InsertIndex, MemberIndent + AContainerName +
        ': ' + AContainerClassName + ';');
      Inc(InsertIndex);
    end;
    if not ContainsText(FormLines.Text,
      AMenuName + ': ' + AMenuClassName + ';') then
      FormLines.Insert(InsertIndex, MemberIndent + AMenuName +
        ': ' + AMenuClassName + ';');
    Result := FormLines.Text;
  finally
    FormLines.Free;
  end;
end;

class function TDelphiIntegrationSourceEditor.AddFormLanguageHandler(
  const ASourceText, AFormClassName, AIntegrationUnitName: string): string;
const
  HandlerName = 'datLanguageMenuItemClick';
var
  ClassIndex: Integer;
  EndIndex: Integer;
  FormLines: TStringList;
  InsertIndex: Integer;
  MethodIndent: string;
begin
  if ContainsText(ASourceText, 'procedure ' + AFormClassName + '.' +
    HandlerName + '(') then
    Exit(ASourceText);

  FormLines := TStringList.Create;
  try
    FormLines.Text := ASourceText;
    ClassIndex := FindLineContaining(FormLines,
      AFormClassName + ' = class');
    if ClassIndex < 0 then
      raise Exception.CreateFmt(
        'Form class %s was not found in its Pascal unit.',
        [AFormClassName]);

    InsertIndex := ClassIndex + 1;
    while InsertIndex < FormLines.Count do
    begin
      if SameText(Trim(FormLines[InsertIndex]), 'private') or
        SameText(Trim(FormLines[InsertIndex]), 'protected') or
        SameText(Trim(FormLines[InsertIndex]), 'public') or
        SameText(Trim(FormLines[InsertIndex]), 'published') or
        SameText(Trim(FormLines[InsertIndex]), 'end;') then
        Break;
      Inc(InsertIndex);
    end;
    MethodIndent := LineIndent(FormLines[ClassIndex]) + '  ';
    FormLines.Insert(InsertIndex, MethodIndent + 'procedure ' +
      HandlerName + '(Sender: TObject);');

    AddImplementationUnit(FormLines, 'System.Classes');
    AddImplementationUnit(FormLines, AIntegrationUnitName);
    EndIndex := FormLines.Count - 1;
    while (EndIndex >= 0) and
      not SameText(Trim(FormLines[EndIndex]), 'end.') do
      Dec(EndIndex);
    if EndIndex < 0 then
      raise Exception.Create('The Pascal unit terminator was not found.');

    FormLines.Insert(EndIndex, '');
    FormLines.Insert(EndIndex + 1, 'procedure ' + AFormClassName + '.' +
      HandlerName + '(Sender: TObject);');
    FormLines.Insert(EndIndex + 2, 'begin');
    FormLines.Insert(EndIndex + 3,
      '  SelectLanguageMenuItem(TComponent(Sender).Name);');
    FormLines.Insert(EndIndex + 4, 'end;');
    Result := FormLines.Text;
  finally
    FormLines.Free;
  end;
end;

class function TDelphiIntegrationSourceEditor.AddFMXFormCreateTranslation(
  const ASourceText, AFormClassName, AHandlerName,
  AIntegrationUnitName: string): string;
var
  BeginIndex: Integer;
  ClassIndex: Integer;
  DeclarationText: string;
  EndIndex: Integer;
  FormLines: TStringList;
  HandlerIndex: Integer;
  InsertIndex: Integer;
  MethodIndent: string;
begin
  if Trim(AHandlerName) = '' then
    raise Exception.Create(
      'An FMX form-create handler name is required.');
  FormLines := TStringList.Create;
  try
    FormLines.Text := ASourceText;
    AddImplementationUnit(FormLines, AIntegrationUnitName);

    HandlerIndex := FindLineContaining(FormLines,
      'procedure ' + AFormClassName + '.' + AHandlerName + '(');
    if HandlerIndex >= 0 then
    begin
      BeginIndex := FindLineContaining(FormLines, 'begin',
        HandlerIndex + 1);
      if BeginIndex < 0 then
        raise Exception.CreateFmt(
          'The existing FMX OnCreate handler %s has no begin block.',
          [AHandlerName]);
      InsertIndex := BeginIndex + 1;
      while (InsertIndex < FormLines.Count) and
        not SameText(Trim(FormLines[InsertIndex]), 'end;') do
      begin
        if ContainsText(FormLines[InsertIndex],
          'ApplyTranslation(Self);') then
          Exit(FormLines.Text);
        Inc(InsertIndex);
      end;
      FormLines.Insert(BeginIndex + 1, '  ApplyTranslation(Self);');
      Exit(FormLines.Text);
    end;

    ClassIndex := FindLineContaining(FormLines,
      AFormClassName + ' = class');
    if ClassIndex < 0 then
      raise Exception.CreateFmt(
        'Form class %s was not found in its Pascal unit.',
        [AFormClassName]);
    DeclarationText := 'procedure ' + AHandlerName +
      '(Sender: TObject);';
    if not ContainsText(FormLines.Text, DeclarationText) then
    begin
      InsertIndex := ClassIndex + 1;
      while InsertIndex < FormLines.Count do
      begin
        if SameText(Trim(FormLines[InsertIndex]), 'private') or
          SameText(Trim(FormLines[InsertIndex]), 'protected') or
          SameText(Trim(FormLines[InsertIndex]), 'public') or
          SameText(Trim(FormLines[InsertIndex]), 'published') or
          SameText(Trim(FormLines[InsertIndex]), 'end;') then
          Break;
        Inc(InsertIndex);
      end;
      MethodIndent := LineIndent(FormLines[ClassIndex]) + '  ';
      FormLines.Insert(InsertIndex, MethodIndent + DeclarationText);
    end;

    EndIndex := FormLines.Count - 1;
    while (EndIndex >= 0) and
      not SameText(Trim(FormLines[EndIndex]), 'end.') do
      Dec(EndIndex);
    if EndIndex < 0 then
      raise Exception.Create('The Pascal unit terminator was not found.');
    FormLines.Insert(EndIndex, '');
    FormLines.Insert(EndIndex + 1, 'procedure ' + AFormClassName + '.' +
      AHandlerName + '(Sender: TObject);');
    FormLines.Insert(EndIndex + 2, 'begin');
    FormLines.Insert(EndIndex + 3, '  ApplyTranslation(Self);');
    FormLines.Insert(EndIndex + 4, 'end;');
    Result := FormLines.Text;
  finally
    FormLines.Free;
  end;
end;

class function TDelphiIntegrationSourceEditor.AddProjectStartup(
  const ASourceText, AIntegrationUnitName,
  AIntegrationUnitFileName: string;
  const ASkipFirstFormApply: Boolean): string;
var
  BeginIndex: Integer;
  ClosingPosition: Integer;
  CommaPosition: Integer;
  FormVariableName: string;
  FormCreateCount: Integer;
  LineIndex: Integer;
  ProjectLines: TStringList;
begin
  ProjectLines := TStringList.Create;
  try
    ProjectLines.Text := AddProjectUnitReference(
      ASourceText, AIntegrationUnitName, AIntegrationUnitFileName);

    if not ContainsText(ProjectLines.Text, 'InitializeTranslation;') then
    begin
      BeginIndex := FindLineContaining(
        ProjectLines, 'Application.Initialize;');
      if BeginIndex < 0 then
        raise Exception.Create(
          'Application.Initialize was not found in the DPR.');
      ProjectLines.Insert(BeginIndex + 1, '  InitializeTranslation;');
    end;

    LineIndex := 0;
    FormCreateCount := 0;
    while LineIndex < ProjectLines.Count do
    begin
      if ContainsText(ProjectLines[LineIndex],
        'Application.CreateForm(') then
      begin
        Inc(FormCreateCount);
        CommaPosition := Pos(',', ProjectLines[LineIndex]);
        ClosingPosition := PosEx(');', ProjectLines[LineIndex],
          CommaPosition + 1);
        if (CommaPosition > 0) and (ClosingPosition > CommaPosition) then
        begin
          FormVariableName := Trim(Copy(ProjectLines[LineIndex],
            CommaPosition + 1, ClosingPosition - CommaPosition - 1));
          if (FormVariableName <> '') and not ContainsText(
            ProjectLines.Text, 'ApplyTranslation(' +
              FormVariableName + ');') and
             not (ASkipFirstFormApply and
               (FormCreateCount = 1)) then
          begin
            ProjectLines.Insert(LineIndex + 1,
              '  ApplyTranslation(' + FormVariableName + ');');
            Inc(LineIndex);
          end;
        end;
      end;
      Inc(LineIndex);
    end;
    Result := ProjectLines.Text;
  finally
    ProjectLines.Free;
  end;
end;

class function TDelphiIntegrationSourceEditor.AddProjectUnitReference(
  const ASourceText, AUnitName, AUnitFileName: string): string;
var
  BeginIndex: Integer;
  LastReferenceIndex: Integer;
  ProjectLines: TStringList;
  SemicolonPosition: Integer;
  UsesIndex: Integer;
begin
  if ContainsText(ASourceText, AUnitName + ' in ') then
    Exit(ASourceText);
  ProjectLines := TStringList.Create;
  try
    ProjectLines.Text := ASourceText;
    UsesIndex := FindLineContaining(ProjectLines, 'uses');
    BeginIndex := FindLineContaining(ProjectLines, 'begin', UsesIndex + 1);
    if (UsesIndex < 0) or (BeginIndex < 0) then
      raise Exception.Create('The DPR uses block could not be identified.');
    LastReferenceIndex := BeginIndex - 1;
    while (LastReferenceIndex > UsesIndex) and
      not ContainsText(ProjectLines[LastReferenceIndex], ';') do
      Dec(LastReferenceIndex);
    SemicolonPosition := LastDelimiter(
      ';', ProjectLines[LastReferenceIndex]);
    if SemicolonPosition = 0 then
      raise Exception.Create('The final DPR unit reference is invalid.');
    ProjectLines[LastReferenceIndex] :=
      Copy(ProjectLines[LastReferenceIndex], 1,
        SemicolonPosition - 1) + ',';
    ProjectLines.Insert(LastReferenceIndex + 1,
      '  ' + AUnitName + ' in ''' + AUnitFileName + ''';');
    Result := ProjectLines.Text;
  finally
    ProjectLines.Free;
  end;
end;

class function TDelphiIntegrationSourceEditor.AddProjectReference(
  const AProjectXml, AIntegrationUnitFileName: string): string;
var
  ClosingItemGroupPosition: Integer;
  ReferencePosition: Integer;
begin
  Result := AProjectXml;
  if ContainsText(Result,
    'DCCReference Include="' + AIntegrationUnitFileName + '"') then
    Exit;

  ReferencePosition := Pos('<DCCReference Include=', Result);
  if ReferencePosition = 0 then
    raise Exception.Create(
      'The DPROJ contains no Delphi source references.');
  ClosingItemGroupPosition := PosEx(
    '</ItemGroup>', Result, ReferencePosition);
  if ClosingItemGroupPosition = 0 then
    raise Exception.Create(
      'The DPROJ source-reference group is incomplete.');
  Insert('        <DCCReference Include="' +
    AIntegrationUnitFileName + '"/>' + sLineBreak,
    Result, ClosingItemGroupPosition);
end;

end.
