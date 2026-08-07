unit DAT.Integration.MenuResource;

interface

uses
  System.Generics.Collections,
  DAT.Core.Types,
  DAT.Runtime.LanguagePack;

type
  TMenuResourceEdit = class
  private
    FFileName: string;
    FFormClassName: string;
    FFormCreateHandlerName: string;
    FNewText: string;
  public
    property FileName: string read FFileName write FFileName;
    property FormClassName: string read FFormClassName write FFormClassName;
    property FormCreateHandlerName: string read FFormCreateHandlerName
      write FFormCreateHandlerName;
    property NewText: string read FNewText write FNewText;
  end;

  TLanguageMenuResourceEditor = class
  public
    class function Build(const AProfile: TProjectProfile;
      const AMenuName, ASourceLanguageCode: string;
      const ALanguages: TObjectList<TLanguagePackDescriptor>):
      TMenuResourceEdit; static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils;

function ObjectDepthDelta(const ALine: string): Integer;
var
  TrimmedLine: string;
begin
  Result := 0;
  TrimmedLine := Trim(ALine);
  if StartsText('object ', TrimmedLine) or
    StartsText('inherited ', TrimmedLine) or
    StartsText('inline ', TrimmedLine) then
    Result := 1
  else if SameText(TrimmedLine, 'end') then
    Result := -1;
end;

function FindObjectEnd(const ALines: TStrings;
  const AStartIndex: Integer): Integer;
var
  Depth: Integer;
  LineIndex: Integer;
begin
  Depth := 0;
  for LineIndex := AStartIndex to ALines.Count - 1 do
  begin
    Inc(Depth, ObjectDepthDelta(ALines[LineIndex]));
    if Depth = 0 then
      Exit(LineIndex);
  end;
  raise Exception.Create('The form resource contains an unterminated object.');
end;

function FindMenuObject(const ALines: TStrings;
  const AMenuName: string): Integer;
var
  LineIndex: Integer;
  TrimmedLine: string;
begin
  Result := -1;
  for LineIndex := 0 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if StartsText('object ' + AMenuName + ':', TrimmedLine) or
      StartsText('inherited ' + AMenuName + ':', TrimmedLine) then
      Exit(LineIndex);
  end;
end;

function FindObjectByClass(const ALines: TStrings;
  const AClassName: string): Integer;
var
  LineIndex: Integer;
  TrimmedLine: string;
begin
  Result := -1;
  for LineIndex := 0 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if (StartsText('object ', TrimmedLine) or
        StartsText('inherited ', TrimmedLine)) and
       EndsText(': ' + AClassName, TrimmedLine) then
      Exit(LineIndex);
  end;
end;

function RootChildIndex(const ALines: TStrings): Integer;
var
  LineIndex: Integer;
  TrimmedLine: string;
begin
  for LineIndex := 1 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if StartsText('object ', TrimmedLine) or
       StartsText('inherited ', TrimmedLine) or
       StartsText('inline ', TrimmedLine) then
      Exit(LineIndex);
  end;
  Result := FindObjectEnd(ALines, 0);
end;

function AddDesignerMenu(const ALines: TStrings;
  const AFramework: TTargetFramework; const AMenuName,
  ATextPropertyName: string): Integer;
var
  ContainerIndex: Integer;
  Indent: string;
  InsertIndex: Integer;
begin
  if AFramework = tfVCL then
    ContainerIndex := FindObjectByClass(ALines, 'TMainMenu')
  else
    ContainerIndex := FindObjectByClass(ALines, 'TMenuBar');

  if ContainerIndex >= 0 then
  begin
    InsertIndex := FindObjectEnd(ALines, ContainerIndex);
    Indent := Copy(ALines[ContainerIndex], 1,
      Length(ALines[ContainerIndex]) -
      Length(TrimLeft(ALines[ContainerIndex]))) + '  ';
    ALines.Insert(InsertIndex, Indent + 'object ' + AMenuName +
      ': TMenuItem');
    ALines.Insert(InsertIndex + 1, Indent + '  ' + ATextPropertyName +
      ' = ''&Language''');
    ALines.Insert(InsertIndex + 2, Indent + 'end');
    Exit(InsertIndex);
  end;

  InsertIndex := RootChildIndex(ALines);
  if AFramework = tfVCL then
  begin
    ALines.Insert(InsertIndex,
      '  object datTranslationMainMenu: TMainMenu');
    ALines.Insert(InsertIndex + 1, '    object ' + AMenuName +
      ': TMenuItem');
    ALines.Insert(InsertIndex + 2, '      Caption = ''&Language''');
    ALines.Insert(InsertIndex + 3, '    end');
    ALines.Insert(InsertIndex + 4, '  end');
    Result := InsertIndex + 1;
  end
  else
  begin
    ALines.Insert(InsertIndex,
      '  object datTranslationMenuBar: TMenuBar');
    ALines.Insert(InsertIndex + 1, '    Align = Top');
    ALines.Insert(InsertIndex + 2,
      '    Size.Width = 800.000000000000000000');
    ALines.Insert(InsertIndex + 3,
      '    Size.Height = 24.000000000000000000');
    ALines.Insert(InsertIndex + 4,
      '    Size.PlatformDefault = False');
    ALines.Insert(InsertIndex + 5, '    object ' + AMenuName +
      ': TMenuItem');
    ALines.Insert(InsertIndex + 6, '      Text = ''&Language''');
    ALines.Insert(InsertIndex + 7, '    end');
    ALines.Insert(InsertIndex + 8, '  end');
    Result := InsertIndex + 5;
  end;
end;

function RootFormClassName(const ALines: TStrings): string;
var
  ColonPosition: Integer;
  DeclarationText: string;
begin
  if ALines.Count = 0 then
    raise Exception.Create('The form resource is empty.');
  DeclarationText := Trim(ALines[0]);
  ColonPosition := Pos(':', DeclarationText);
  if ColonPosition = 0 then
    raise Exception.Create('The root form declaration is invalid.');
  Result := Trim(Copy(DeclarationText, ColonPosition + 1, MaxInt));
end;

function IsExcludedProjectFile(const AFileName: string): Boolean;
begin
  Result := ContainsText(AFileName, '\Localization\') or
    ContainsText(AFileName, '\bin\') or
    ContainsText(AFileName, '\dcu\');
end;

function ProjectMainFormClassName(const AProfile: TProjectProfile): string;
var
  ClosingPosition: Integer;
  CommaPosition: Integer;
  DprFileName: string;
  OpenPosition: Integer;
  ProjectText: string;
begin
  Result := '';
  if SameText(TPath.GetExtension(AProfile.ProjectFileName), '.dpr') then
    DprFileName := AProfile.ProjectFileName
  else
    DprFileName := TPath.ChangeExtension(AProfile.ProjectFileName, '.dpr');
  if not TFile.Exists(DprFileName) then
    Exit;
  ProjectText := TFile.ReadAllText(DprFileName);
  OpenPosition := Pos('application.createform(', LowerCase(ProjectText));
  if OpenPosition = 0 then
    Exit;
  Inc(OpenPosition, Length('application.createform('));
  CommaPosition := PosEx(',', ProjectText, OpenPosition);
  ClosingPosition := PosEx(')', ProjectText, OpenPosition);
  if (CommaPosition = 0) or
     ((ClosingPosition > 0) and (ClosingPosition < CommaPosition)) then
    Exit;
  Result := Trim(Copy(ProjectText, OpenPosition,
    CommaPosition - OpenPosition));
end;

function PrimaryFormResourceFileName(const AProfile: TProjectProfile;
  const AExtension: string): string;
var
  CandidateFiles: TStringList;
  FileName: string;
  FormLines: TStringList;
  MainFormClassName: string;
  ProjectDirectory: string;
begin
  Result := '';
  ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
  MainFormClassName := ProjectMainFormClassName(AProfile);
  CandidateFiles := TStringList.Create;
  try
    for FileName in TDirectory.GetFiles(ProjectDirectory, AExtension,
      TSearchOption.soAllDirectories) do
      if not IsExcludedProjectFile(FileName) then
        CandidateFiles.Add(FileName);
    CandidateFiles.Sort;
    if CandidateFiles.Count = 0 then
      raise Exception.CreateFmt(
        'No text %s form resource was found in the project.',
        [Copy(AExtension, 2, MaxInt)]);
    if MainFormClassName <> '' then
      for FileName in CandidateFiles do
      begin
        FormLines := TStringList.Create;
        try
          FormLines.LoadFromFile(FileName);
          if SameText(RootFormClassName(FormLines), MainFormClassName) then
            Exit(FileName);
        finally
          FormLines.Free;
        end;
      end;
    Result := CandidateFiles[0];
  finally
    CandidateFiles.Free;
  end;
end;

function EnsureFMXFormCreateHandler(const ALines: TStrings): string;
const
  GeneratedHandlerName = 'datTranslationFormCreate';
var
  EqualsPosition: Integer;
  InsertIndex: Integer;
  LineIndex: Integer;
  TrimmedLine: string;
begin
  Result := '';
  InsertIndex := ALines.Count;
  for LineIndex := 1 to ALines.Count - 1 do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if StartsText('OnCreate =', TrimmedLine) then
    begin
      EqualsPosition := Pos('=', TrimmedLine);
      Exit(Trim(Copy(TrimmedLine, EqualsPosition + 1, MaxInt)));
    end;
    if StartsText('object ', TrimmedLine) or
      StartsText('inherited ', TrimmedLine) or
      StartsText('inline ', TrimmedLine) then
    begin
      InsertIndex := LineIndex;
      Break;
    end;
  end;
  ALines.Insert(InsertIndex, '  OnCreate = ' + GeneratedHandlerName);
  Result := GeneratedHandlerName;
end;

function PascalString(const AValue: string): string;
begin
  Result := StringReplace(AValue, '''', '''''', [rfReplaceAll]);
end;

function LanguageComponentSuffix(const ALanguageCode: string): string;
var
  Character: Char;
begin
  Result := '';
  for Character in ALanguageCode do
    if CharInSet(Character, ['A'..'Z', 'a'..'z', '0'..'9']) then
      Result := Result + Character
    else
      Result := Result + '_';
end;

function SourceLanguageName(const ASourceLanguageCode: string): string;
begin
  if StartsText('en', ASourceLanguageCode) then
    Result := 'English'
  else
    Result := ASourceLanguageCode;
end;

procedure AddMenuItem(const ALines: TStrings; const AInsertIndex: Integer;
  const AIndent, ALanguageCode, ADisplayName, ATextPropertyName: string);
var
  LineIndex: Integer;
  ItemLines: TStringList;
begin
  ItemLines := TStringList.Create;
  try
    ItemLines.Add(AIndent + 'object datLanguage_' +
      LanguageComponentSuffix(ALanguageCode) + ': TMenuItem');
    ItemLines.Add(AIndent + '  ' + ATextPropertyName + ' = ''' +
      PascalString(ADisplayName) + '''');
    ItemLines.Add(AIndent +
      '  OnClick = datLanguageMenuItemClick');
    ItemLines.Add(AIndent + 'end');
    for LineIndex := 0 to ItemLines.Count - 1 do
      ALines.Insert(AInsertIndex + LineIndex, ItemLines[LineIndex]);
  finally
    ItemLines.Free;
  end;
end;

procedure RemoveGeneratedMenuItems(const ALines: TStrings;
  const AMenuStartIndex: Integer);
var
  ItemEndIndex: Integer;
  LineIndex: Integer;
  MenuEndIndex: Integer;
  TrimmedLine: string;
begin
  MenuEndIndex := FindObjectEnd(ALines, AMenuStartIndex);
  LineIndex := AMenuStartIndex + 1;
  while LineIndex < MenuEndIndex do
  begin
    TrimmedLine := Trim(ALines[LineIndex]);
    if StartsText('object datLanguage_', TrimmedLine) then
    begin
      ItemEndIndex := FindObjectEnd(ALines, LineIndex);
      while ItemEndIndex >= LineIndex do
      begin
        ALines.Delete(ItemEndIndex);
        Dec(ItemEndIndex);
        Dec(MenuEndIndex);
      end;
      Continue;
    end;
    Inc(LineIndex);
  end;
end;

class function TLanguageMenuResourceEditor.Build(
  const AProfile: TProjectProfile; const AMenuName,
  ASourceLanguageCode: string;
  const ALanguages: TObjectList<TLanguagePackDescriptor>): TMenuResourceEdit;
var
  Descriptor: TLanguagePackDescriptor;
  Extension: string;
  FileName: string;
  FormLines: TStringList;
  Indent: string;
  InsertIndex: Integer;
  MenuIndex: Integer;
  ProjectDirectory: string;
  TextPropertyName: string;
begin
  ProjectDirectory := TPath.GetDirectoryName(AProfile.ProjectFileName);
  if AProfile.Framework = tfVCL then
  begin
    Extension := '*.dfm';
    TextPropertyName := 'Caption';
  end
  else
  begin
    Extension := '*.fmx';
    TextPropertyName := 'Text';
  end;

  for FileName in TDirectory.GetFiles(
    ProjectDirectory, Extension, TSearchOption.soAllDirectories) do
  begin
    if IsExcludedProjectFile(FileName) then
      Continue;
    FormLines := TStringList.Create;
    try
      FormLines.LoadFromFile(FileName);
      MenuIndex := FindMenuObject(FormLines, AMenuName);
      if MenuIndex < 0 then
        Continue;

      RemoveGeneratedMenuItems(FormLines, MenuIndex);
      InsertIndex := FindObjectEnd(FormLines, MenuIndex);
      Indent := Copy(FormLines[MenuIndex], 1,
        Length(FormLines[MenuIndex]) - Length(TrimLeft(FormLines[MenuIndex]))) +
        '  ';
      AddMenuItem(FormLines, InsertIndex, Indent,
        ASourceLanguageCode, SourceLanguageName(ASourceLanguageCode),
        TextPropertyName);
      Inc(InsertIndex, 4);
      for Descriptor in ALanguages do
      begin
        if SameText(Descriptor.LanguageCode, ASourceLanguageCode) then
          Continue;
        AddMenuItem(FormLines, InsertIndex, Indent,
          Descriptor.LanguageCode, Descriptor.NativeLanguageName,
          TextPropertyName);
        Inc(InsertIndex, 4);
      end;

      Result := TMenuResourceEdit.Create;
      Result.FileName := FileName;
      Result.FormClassName := RootFormClassName(FormLines);
      if AProfile.Framework = tfFireMonkey then
        Result.FormCreateHandlerName :=
          EnsureFMXFormCreateHandler(FormLines);
      Result.NewText := FormLines.Text;
      Exit;
    finally
      FormLines.Free;
    end;
  end;

  FileName := PrimaryFormResourceFileName(AProfile, Extension);
  FormLines := TStringList.Create;
  try
    FormLines.LoadFromFile(FileName);
    MenuIndex := AddDesignerMenu(FormLines, AProfile.Framework,
      AMenuName, TextPropertyName);
    InsertIndex := FindObjectEnd(FormLines, MenuIndex);
    Indent := Copy(FormLines[MenuIndex], 1,
      Length(FormLines[MenuIndex]) - Length(TrimLeft(FormLines[MenuIndex]))) +
      '  ';
    AddMenuItem(FormLines, InsertIndex, Indent,
      ASourceLanguageCode, SourceLanguageName(ASourceLanguageCode),
      TextPropertyName);
    Inc(InsertIndex, 4);
    for Descriptor in ALanguages do
    begin
      if SameText(Descriptor.LanguageCode, ASourceLanguageCode) then
        Continue;
      AddMenuItem(FormLines, InsertIndex, Indent,
        Descriptor.LanguageCode, Descriptor.NativeLanguageName,
        TextPropertyName);
      Inc(InsertIndex, 4);
    end;

    Result := TMenuResourceEdit.Create;
    Result.FileName := FileName;
    Result.FormClassName := RootFormClassName(FormLines);
    if AProfile.Framework = tfFireMonkey then
      Result.FormCreateHandlerName := EnsureFMXFormCreateHandler(FormLines);
    Result.NewText := FormLines.Text;
  finally
    FormLines.Free;
  end;
end;

end.
