unit DAT.Scan.Types;

interface

uses
  System.Generics.Collections,
  DAT.Core.Types;

type
  TScannedTextKind = (
    stkFormProperty,
    stkResourceString
  );

  TScanDiagnosticSeverity = (
    sdsInformation,
    sdsWarning,
    sdsError
  );

  TScanItem = class
  private
    FKey: string;
    FSourceText: string;
    FFormName: string;
    FComponentName: string;
    FComponentClassName: string;
    FPropertyName: string;
    FSourceFileName: string;
    FSourceLine: Integer;
    FCollectionIndex: Integer;
    FFramework: TTargetFramework;
    FKind: TScannedTextKind;
    FRuntimeTextRole: TRuntimeTextRole;
  public
    property Key: string read FKey write FKey;
    property SourceText: string read FSourceText write FSourceText;
    property FormName: string read FFormName write FFormName;
    property ComponentName: string read FComponentName write FComponentName;
    property ComponentClassName: string read FComponentClassName write FComponentClassName;
    property PropertyName: string read FPropertyName write FPropertyName;
    property SourceFileName: string read FSourceFileName write FSourceFileName;
    property SourceLine: Integer read FSourceLine write FSourceLine;
    property CollectionIndex: Integer read FCollectionIndex write FCollectionIndex;
    property Framework: TTargetFramework read FFramework write FFramework;
    property Kind: TScannedTextKind read FKind write FKind;
    property RuntimeTextRole: TRuntimeTextRole read FRuntimeTextRole
      write FRuntimeTextRole;
  end;

  TScanDiagnostic = class
  private
    FSeverity: TScanDiagnosticSeverity;
    FMessageText: string;
    FSourceFileName: string;
    FSourceLine: Integer;
  public
    property Severity: TScanDiagnosticSeverity read FSeverity write FSeverity;
    property MessageText: string read FMessageText write FMessageText;
    property SourceFileName: string read FSourceFileName write FSourceFileName;
    property SourceLine: Integer read FSourceLine write FSourceLine;
  end;

  TProjectScanResult = class
  private
    FItems: TObjectList<TScanItem>;
    FDiagnostics: TObjectList<TScanDiagnostic>;
    FFilesScanned: Integer;
    FFormFilesScanned: Integer;
    FSourceFilesScanned: Integer;
    FElapsedMilliseconds: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    function CountByKind(const AKind: TScannedTextKind): Integer;
    function FindItem(const AKey: string): TScanItem;
    property Items: TObjectList<TScanItem> read FItems;
    property Diagnostics: TObjectList<TScanDiagnostic> read FDiagnostics;
    property FilesScanned: Integer read FFilesScanned write FFilesScanned;
    property FormFilesScanned: Integer read FFormFilesScanned write FFormFilesScanned;
    property SourceFilesScanned: Integer read FSourceFilesScanned write FSourceFilesScanned;
    property ElapsedMilliseconds: Int64 read FElapsedMilliseconds write FElapsedMilliseconds;
  end;

function ScannedTextKindDisplayName(const AKind: TScannedTextKind): string;

implementation

uses
  System.SysUtils;

constructor TProjectScanResult.Create;
begin
  inherited Create;
  FItems := TObjectList<TScanItem>.Create(True);
  FDiagnostics := TObjectList<TScanDiagnostic>.Create(True);
end;

destructor TProjectScanResult.Destroy;
begin
  FDiagnostics.Free;
  FItems.Free;
  inherited Destroy;
end;

function TProjectScanResult.CountByKind(const AKind: TScannedTextKind): Integer;
var
  ScanItem: TScanItem;
begin
  Result := 0;
  for ScanItem in FItems do
    if ScanItem.Kind = AKind then
      Inc(Result);
end;

function TProjectScanResult.FindItem(const AKey: string): TScanItem;
var
  ScanItem: TScanItem;
begin
  Result := nil;
  for ScanItem in FItems do
    if SameText(ScanItem.Key, AKey) then
      Exit(ScanItem);
end;

function ScannedTextKindDisplayName(const AKind: TScannedTextKind): string;
begin
  case AKind of
    stkFormProperty:
      Result := 'Form property';
    stkResourceString:
      Result := 'Resource string';
  else
    Result := 'Unknown';
  end;
end;

end.
