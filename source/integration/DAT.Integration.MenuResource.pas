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
    FNewText: string;
  public
    property FileName: string read FFileName write FFileName;
    property FormClassName: string read FFormClassName write FFormClassName;
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
    if ContainsText(FileName, '\Localization\') or
      ContainsText(FileName, '\bin\') or ContainsText(FileName, '\dcu\') then
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
      Result.NewText := FormLines.Text;
      Exit;
    finally
      FormLines.Free;
    end;
  end;

  raise Exception.CreateFmt(
    'The designer menu "%s" was not found in a text %s resource.',
    [AMenuName, Copy(Extension, 2, MaxInt)]);
end;

end.
