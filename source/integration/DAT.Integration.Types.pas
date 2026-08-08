unit DAT.Integration.Types;

interface

uses
  System.Generics.Collections;

type
  TIntegrationChangeKind = (
    ickLanguagePack,
    ickRuntimeUnit,
    ickGeneratedUnit,
    ickFormResource,
    ickFormSource,
    ickProjectSource,
    ickProjectMetadata
  );

  TIntegrationFileChange = class
  private
    FKind: TIntegrationChangeKind;
    FTargetFileName: string;
    FDescription: string;
    FOriginalExists: Boolean;
    FOriginalText: string;
    FNewText: string;
  public
    function ExactReviewText: string;
    property Kind: TIntegrationChangeKind read FKind write FKind;
    property TargetFileName: string read FTargetFileName write FTargetFileName;
    property Description: string read FDescription write FDescription;
    property OriginalExists: Boolean read FOriginalExists write FOriginalExists;
    property OriginalText: string read FOriginalText write FOriginalText;
    property NewText: string read FNewText write FNewText;
  end;

  TIntegrationChangeSet = class
  private
    FProjectDirectory: string;
    FProjectName: string;
    FChanges: TObjectList<TIntegrationFileChange>;
  public
    constructor Create;
    destructor Destroy; override;
    function FindChange(const ATargetFileName: string): TIntegrationFileChange;
    procedure AddTextChange(const AKind: TIntegrationChangeKind;
      const ATargetFileName, ADescription, ANewText: string);
    property ProjectDirectory: string read FProjectDirectory
      write FProjectDirectory;
    property ProjectName: string read FProjectName write FProjectName;
    property Changes: TObjectList<TIntegrationFileChange> read FChanges;
  end;

function IntegrationChangeKindDisplayName(
  const AKind: TIntegrationChangeKind): string;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils;

function NumberedDiffLine(const APrefix: string;
  const AOriginalLine, AProposedLine: Integer;
  const AText: string): string;
const
  MissingLineNumber = '     ';
var
  OriginalNumber: string;
  ProposedNumber: string;
begin
  if AOriginalLine < 0 then
    OriginalNumber := MissingLineNumber
  else
    OriginalNumber := Format('O:%4.4d', [AOriginalLine + 1]);
  if AProposedLine < 0 then
    ProposedNumber := MissingLineNumber
  else
    ProposedNumber := Format('N:%4.4d', [AProposedLine + 1]);
  Result := Format('%s %s %s | %s',
    [APrefix, OriginalNumber, ProposedNumber, AText]);
end;

function TIntegrationFileChange.ExactReviewText: string;
var
  Column: Integer;
  CurrentColumn: Integer;
  CurrentRow: Integer;
  DiffLines: TStringList;
  LongestCommonSubsequence: TArray<TArray<Integer>>;
  NewLines: TStringList;
  OriginalLines: TStringList;
  Row: Integer;
begin
  OriginalLines := TStringList.Create;
  NewLines := TStringList.Create;
  DiffLines := TStringList.Create;
  try
    if OriginalExists then
      OriginalLines.Text := OriginalText;
    NewLines.Text := NewText;

    SetLength(LongestCommonSubsequence, OriginalLines.Count + 1);
    for Row := 0 to OriginalLines.Count do
      SetLength(LongestCommonSubsequence[Row], NewLines.Count + 1);
    for Row := OriginalLines.Count - 1 downto 0 do
      for Column := NewLines.Count - 1 downto 0 do
        if OriginalLines[Row] = NewLines[Column] then
          LongestCommonSubsequence[Row][Column] :=
            LongestCommonSubsequence[Row + 1][Column + 1] + 1
        else if LongestCommonSubsequence[Row + 1][Column] >=
          LongestCommonSubsequence[Row][Column + 1] then
          LongestCommonSubsequence[Row][Column] :=
            LongestCommonSubsequence[Row + 1][Column]
        else
          LongestCommonSubsequence[Row][Column] :=
            LongestCommonSubsequence[Row][Column + 1];

    DiffLines.Add('FILE: ' + TargetFileName);
    DiffLines.Add('CHANGE: ' + Description);
    if OriginalExists then
      DiffLines.Add('--- ORIGINAL')
    else
      DiffLines.Add('--- ORIGINAL (new file)');
    DiffLines.Add('+++ PROPOSED');
    DiffLines.Add('Legend: - removed, + added, two spaces unchanged');
    DiffLines.Add('');

    CurrentRow := 0;
    CurrentColumn := 0;
    while (CurrentRow < OriginalLines.Count) or
      (CurrentColumn < NewLines.Count) do
    begin
      if (CurrentRow < OriginalLines.Count) and
         (CurrentColumn < NewLines.Count) and
         (OriginalLines[CurrentRow] = NewLines[CurrentColumn]) then
      begin
        DiffLines.Add(NumberedDiffLine(' ',
          CurrentRow, CurrentColumn, OriginalLines[CurrentRow]));
        Inc(CurrentRow);
        Inc(CurrentColumn);
      end
      else if (CurrentRow < OriginalLines.Count) and
        ((CurrentColumn >= NewLines.Count) or
         (LongestCommonSubsequence[CurrentRow + 1][CurrentColumn] >=
          LongestCommonSubsequence[CurrentRow][CurrentColumn + 1])) then
      begin
        DiffLines.Add(NumberedDiffLine('-',
          CurrentRow, -1, OriginalLines[CurrentRow]));
        Inc(CurrentRow);
      end
      else
      begin
        DiffLines.Add(NumberedDiffLine('+',
          -1, CurrentColumn, NewLines[CurrentColumn]));
        Inc(CurrentColumn);
      end;
    end;
    Result := DiffLines.Text;
  finally
    DiffLines.Free;
    NewLines.Free;
    OriginalLines.Free;
  end;
end;

constructor TIntegrationChangeSet.Create;
begin
  inherited Create;
  FChanges := TObjectList<TIntegrationFileChange>.Create(True);
end;

destructor TIntegrationChangeSet.Destroy;
begin
  FChanges.Free;
  inherited Destroy;
end;

function TIntegrationChangeSet.FindChange(
  const ATargetFileName: string): TIntegrationFileChange;
var
  Change: TIntegrationFileChange;
begin
  Result := nil;
  for Change in FChanges do
    if SameText(Change.TargetFileName, ATargetFileName) then
      Exit(Change);
end;

procedure TIntegrationChangeSet.AddTextChange(
  const AKind: TIntegrationChangeKind; const ATargetFileName,
  ADescription, ANewText: string);
var
  Change: TIntegrationFileChange;
begin
  Change := FindChange(ATargetFileName);
  if Change = nil then
  begin
    Change := TIntegrationFileChange.Create;
    Change.TargetFileName := ATargetFileName;
    Change.OriginalExists := TFile.Exists(ATargetFileName);
    if Change.OriginalExists then
      Change.OriginalText := TFile.ReadAllText(ATargetFileName);
    FChanges.Add(Change);
  end;
  Change.Kind := AKind;
  Change.Description := ADescription;
  Change.NewText := ANewText;
end;

function IntegrationChangeKindDisplayName(
  const AKind: TIntegrationChangeKind): string;
begin
  case AKind of
    ickLanguagePack:
      Result := 'Language pack';
    ickRuntimeUnit:
      Result := 'Runtime unit';
    ickGeneratedUnit:
      Result := 'Generated unit';
    ickFormResource:
      Result := 'Form resource';
    ickFormSource:
      Result := 'Form source';
    ickProjectSource:
      Result := 'Project source';
    ickProjectMetadata:
      Result := 'Project metadata';
  else
    Result := 'Integration file';
  end;
end;

end.
