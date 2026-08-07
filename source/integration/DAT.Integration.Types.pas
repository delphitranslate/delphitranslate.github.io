unit DAT.Integration.Types;

interface

uses
  System.Generics.Collections;

type
  TIntegrationChangeKind = (
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
  System.IOUtils,
  System.SysUtils;

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
